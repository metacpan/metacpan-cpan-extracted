# Arch Perl library, Copyright (C) 2004-2005 Mikhael Goikhman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use 5.005;
use strict;

package Arch::Registry;

use Arch::Util qw(run_tla run_cmd save_file load_file);
use Arch::Backend qw(has_register_archive_name_arg);
use Arch::LiteWeb;
use Arch::TempFiles;

my $SUPERMIRROR_REGISTRY_URL = $ENV{ARCH_SUPERMIRROR_REGISTRY_URL}
	|| "http://arch.debian.org/registry";
my $SUPERMIRROR_ARCHIVES_URL = "$SUPERMIRROR_REGISTRY_URL/archives.gz";
my $SUPERMIRROR_VERSIONS_URL = "$SUPERMIRROR_REGISTRY_URL/versions.gz";

sub new ($%) {
	my $class = shift;
	my %args = @_;
	my $self = { };
	return bless $self, $class;
}

sub register_archive ($$;$) {
	my $self = shift;
	my $location = shift;
	my $archive = shift;

	my @name_arg = $archive && has_register_archive_name_arg()?
		$archive: ();
	my @args = ('register-archive --force', @name_arg, $location);
	run_tla(@args);
	return $? == 0;
}

sub unregister_archive ($$) {
	my $self = shift;
	my $archive = shift;

	my @args = ('register-archive --force --delete', $archive);
	run_tla(@args);
	return $? == 0;
}

sub _convert_lines_to_hash ($;$) {
	my $lines = shift || die;
	my $multiple = shift || 0;
	my %hash = ();
	my $key = undef;
	my $values = [];
	while (@$lines || @$values) {
		my $line = shift @$lines;
		if ($line && $line =~ s/^(\s+)//) {
			die "Unexpected initial line with spaces '$1$line'" unless $key;
			push @$values, $line;
		} else {
			$hash{$key} = $multiple? $values: ($values->[0] || die "No expected value line for '$key'") if $key;
			$key = $line;
			$values = [];
		}
	}
	return \%hash;
}

sub registered_archives ($) {
	my $self = shift;
	my @lines = run_tla('archives');
	my $locations = _convert_lines_to_hash(\@lines);
	return wantarray? %$locations: $locations;
}

sub set_web_cache ($%) {
	my $self = shift;
	my %args = @_;
	my $dir = $args{dir};
	if ($dir && -d $dir) {
		$self->{web_cache} = {
			dir => $dir,
			ttl => $args{ttl} || 3 * 60 * 60,
		};
		$self->{web_cache_flag} = "enabled";
	} else {
		$self->{web_cache} = undef;
	}
	$self->{archive_locations} = undef;
	$self->{archive_versions} = undef;
	return $self;
}

sub flag_web_cache ($;$) {
	my $self = shift;
	my $val = shift || "disabled";
	$val = "enabled" unless $val =~ /^disabled|noread|nowrite$/;
	$self->{web_cache_flag} = $val;
	return $self;
}

sub _get_and_parse_gzipped_url ($$;$) {
	my $self = shift;
	my $url = shift;
	my $multiple = shift;

	my $web = $self->{web} ||= Arch::LiteWeb->new;
	my $tmp = $self->{tmp} ||= Arch::TempFiles->new;
	my $read_cache =
		$self->{web_cache} && $self->{web_cache_flag} =~ /^enabled|nowrite$/;
	my $write_cache =
		$self->{web_cache} && $self->{web_cache_flag} =~ /^enabled|noread$/;

	my $cached_file_name;
	my $content;
	my $content_from_cache = 0;
	if ($read_cache || $write_cache) {
		$url =~ m!/([^/]+)$! || die "Invalid url [$url]\n";
		$cached_file_name = "$self->{web_cache}->{dir}/$1";
	}
	if (
		$read_cache && -f $cached_file_name && (60 * 60 * 24 *
			-M $cached_file_name < $self->{web_cache}->{ttl})
	) {
		$content = load_file($cached_file_name);
		$content_from_cache = 1;
	}
	$self->{content_from_cache} = $content_from_cache;

	$content ||= $web->get($url);
	return unless $content;

	save_file($cached_file_name, \$content)
		if $write_cache && !$content_from_cache;
	my $file_name = $tmp->name;
	save_file("$file_name.gz", \$content);
	run_cmd("gzip -d", "$file_name.gz");
	return if $?;
	my $lines = [];
	load_file($file_name, $lines);
	unlink($file_name);
	return _convert_lines_to_hash($lines, $multiple);
}

sub supermirror_archives ($) {
	my $self = shift;

	$self->{content_from_cache} = 1;
	return $self->{supermirror_archive_locations}
		||= $self->_get_and_parse_gzipped_url($SUPERMIRROR_ARCHIVES_URL);
}

sub supermirror_archive_versions ($) {
	my $self = shift;

	$self->{content_from_cache} = 1;
	return $self->{supermirror_archive_versions}
		||= $self->_get_and_parse_gzipped_url($SUPERMIRROR_VERSIONS_URL, 1);
}

sub search_supermirror ($;$$$) {
	my $self = shift;
	my $archive_regexp = shift || '.*';
	my $version_regexp = shift || '.*';
	my $return_versions = shift;
	my $archive_versions = $self->supermirror_archive_versions;
	return undef unless $archive_versions;

	my @matching_archives =
		eval { grep /$archive_regexp/, sort keys %$archive_versions };
	return \@matching_archives unless $return_versions;

	my $want_hashref = $return_versions eq 'hashref';
	my @matching_archive_versions = ();
	my $matching_archive_versions = {};
	foreach my $archive (@matching_archives) {
		my $versions = $archive_versions->{$archive};
		my @versions = eval { grep /$version_regexp/, @$versions };
		if ($want_hashref) {
			$matching_archive_versions->{$archive} = \@versions if @versions;
		} else {
			push @matching_archive_versions, map { "$archive/$_" } @versions;
		}
	}

	return $matching_archive_versions if $want_hashref;
	return \@matching_archive_versions;
}

sub web_error ($) {
	my $self = shift;
	return undef unless $self->{web};
	return undef if $self->{content_from_cache};
	return $self->{web}->error_with_url;
}

1;

__END__

=head1 NAME

Arch::Registry - manage registered archives, search archives on the web

=head1 SYNOPSIS 

    use Arch::Registry;
    my $registry = Arch::Registry->new;

    my %archive_locations = $registry->registered_archives;
    $registry->register_archive('http://john.com/archives/main');
    $registry->unregister_archive('john@mail.com--tux');

    %archive_locations = $registry->supermirror_archives;
    die $registry->web_error if $registry->web_error;

    my @john_versions = @{
        $registry->supermirror_archive_versions->{'john@mail.com--tux')
    };

    my $archives = $registry->search_supermirror('.*', '--cset-gui--');
    die $registry->web_error unless defined $archives;

    my $versions = $registry->search_supermirror('john@', '^tla\b', 1);
    print map { "$_\n" } @$versions;  # print john@mail.com--tux/tla...

=head1 DESCRIPTION

This class provides the way to register and unregister GNU Arch archives for
the caller user and list all registered archives. It also provides the way
to search the supermirror (currently mirrors.sourcecontrol.net) by archive
name or archive/category/branch/version regexp.

=head1 METHODS

The following class methods are available:

B<new>,
B<register_archive>,
B<unregister_archive>,
B<registered_archives>,
B<set_web_cache>,
B<flag_web_cache>,
B<supermirror_archives>,
B<supermirror_archive_versions>,
B<search_supermirror>,
B<web_error>.

=over 4

=item B<new>

Construct Arch::Registry object.

=item B<register_archive> I<location> [I<archive>]

Register archive at the given I<location> and optional I<archive> (if
missing then the location is actually accessed to find the archive name).
Returns true on success.

=item B<unregister_archive> I<archive>

Unregister I<archive>. Returns true on success.

=item B<registered_archives>

Returns a hash (or hashref in scalar context) of registered archives,
that is pairs I<archive> => I<location>.

=item B<set_web_cache> [ I<named-values> ]

Define the web cache to use with operations on the supermirror.

The keys of I<named-values> are I<dir> (the web cache directory) and I<ttl>
(time to live in minutes). If I<named-values> is empty or misses I<dir>,
or I<dir> does not exist, the cache is unset.

This method has a side effect of forgetting memoized real-web-or-cache
content fetches. So you may call it with or without parameters to reset the
memoized values, although this should rarely be needed.

=item B<flag_web_cache> [I<value>]

Turn on or off the web cache depending on the parameter.

I<value> may be "enabled", "disabled", "nowrite" and "noread". Additionally,
the false I<value> will be taken as "disabled", the true I<value> as "enabled".

=item B<supermirror_archives>

Returns a hash (or hashref in scalar context) of archives mirrored on
the supermirror, that is pairs I<archive> => I<location>.

=item B<supermirror_archive_versions>

Returns a hashref of archives mirrored on the supermirror and all their
versions, that is pairs I<archive> => [ I<version>, .. ].

=item B<search_supermirror>

=item B<search_supermirror> I<archive_regexp>

=item B<search_supermirror> I<archive_regexp> I<version_regexp>

=item B<search_supermirror> I<archive_regexp> I<version_regexp> I<return_versions>

Search the archives (and possibly their branches/versions) by I<archive>
and I<version> regular expressions given.

If I<return_versions> is unset, returns arrayref that is all matching
[ I<archive>, .. ]. If I<return_versions> is set to 'joined', returns arrayref
that is all matching [ I<archive>/I<version>, .. ]. If I<return_versions> is
set to 'hashref', returns hashref similar to B<supermirror_archive_versions>
that is all matching { I<archive> => [ I<version>, .. ], ... }.

If B<web_error> occurred, returns undef.

I<archive_regexp> defaults to "any", I<version_regexp> defaults to "any",
I<return_versions> defaults to false.

=item B<web_error>

Returns the string containing the error while fetching one or another
supermirror url (the last one). Returns undef if no error occured.

=back

=head1 BUGS

Waiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Util>, L<Arch::LiteWeb>.

=cut
