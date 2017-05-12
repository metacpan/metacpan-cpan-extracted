# Arch Perl library, Copyright (C) 2004 Mikhael Goikhman
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

package Arch::Log;

use Arch::Changes qw(:type);
use Arch::Util qw(standardize_date parse_creator_email date2age);

sub new ($$%) {
	my $class = shift;
	my $message = shift || die "Arch::Log::new: no message\n";
	my %init = @_;

	my $self = {
		message => $message,
		headers => undef,
		hide_ids => $init{hide_ids},
	};

	return bless $self, $class;
}

sub get_message ($) {
	my $self = shift;
	return $self->{message};
}

use vars qw($SPECIAL_HEADERS);
$SPECIAL_HEADERS = {
	modified_directories => 1,
	modified_files       => 1,
	new_directories      => 1,
	new_files            => 1,
	new_patches          => -1,
	removed_directories  => 1,
	removed_files        => 1,
	renamed_directories  => 2,
	renamed_files        => 2,
};

sub get_headers ($) {
	my $self = shift;
	return $self->{headers} if defined $self->{headers};

	my $message = $self->{message};
	my ($headers_str, $body) = $message =~ /^(.*?\n)\n(.*)$/s
		or die "Incorrect message:\n\n$message\n\n- No body delimeter\n";

	my $headers = { body => $body };
	$headers_str =~ s{^([\w-]+):[ \t]*(.*\n(?:[ \t]+.*\n)*)}{
		my ($header, $value) = (lc($1), $2);
		$header =~ s/-/_/sg;
		die "Duplicate header $header in message:\n\n$message\n"
			if exists $headers->{$header};
		chomp($value);

		# handle special headers (lists, lists of pairs, files but ids)
		my $type = $SPECIAL_HEADERS->{$header};
		if ($type) {
			$value = [ split(/[ \n]+/, $value) ];
			$value = [ grep { !m:(^|/).arch-ids/: } @$value ]
				if $type > 0 && $self->{hide_ids};
			if ($type == 2) {
				my @pairs = ();
				push @pairs, [ splice @$value, 0, 2 ] while @$value;
				$value = \@pairs;
			}
		}
		$headers->{$header} = $value;
		""
	}meg;
	#print "*** $_: $headers->{$_} ***\n" foreach keys %$headers;

	return $self->{headers} = $headers;
}

sub header ($$;$) {
	my $self = shift;
	my $header = shift;
	return $self->get_headers->{$header} unless @_;
	$self->get_headers->{$header} = shift;
}

sub get_changes ($) {
	my $self = shift;

	my $changes = Arch::Changes->new;

	# make a workaround for tla bug: missing New-directories in import log;
	# still, there is no way to figure out empty directory added on import
	my @import_dirs = ();
	if ($self->get_revision_kind eq 'import' && !$self->header('new_directories')) {
		my %import_dirs = ();
		foreach (@{$self->header('new_files') || []}) {
			my $file = $_;
			$import_dirs{$1} = 1 while $file =~ s!^(.+)/.+$!$1!;
		}
		@import_dirs = sort keys %import_dirs;
	}

	# new dirs
	foreach my $path (@{$self->header('new_directories') || []}, @import_dirs) {
		$changes->add(ADD, 1, $path);
	}

	# new files
	foreach my $path (@{$self->header('new_files') || []}) {
		$changes->add(ADD, 0, $path);
	}

	# removed dirs
	foreach my $path (@{$self->header('removed_directories') || []}) {
		$changes->add(DELETE, 1, $path);
	}

	# removed files
	foreach my $path (@{$self->header('removed_files') || []}) {
		$changes->add(DELETE, 0, $path);
	}

	# modified dirs
	foreach my $path (@{$self->header('modified_directories') || []}) {
		# directories cannot be MODIFY'ed
		$changes->add(META_MODIFY, 1, $path);
	}

	# modified files
	foreach my $path (@{$self->header('modified_files') || []}) {
		# logs don't distinguish MODIFY and META_MODIFY
		$changes->add(MODIFY, 0, $path);
	}

	# moved dirs
	foreach my $paths (@{$self->header('renamed_directories') || []}) {
		$changes->add(RENAME, 1, @{$paths});
	}

	# moved files
	foreach my $paths (@{$self->header('renamed_files') || []}) {
		$changes->add(RENAME, 0, @{$paths});
	}

	return $changes;
}

sub split_version ($) {
	my $self = shift;

	my $full_revision = $self->get_revision;
	die "Invalid archive/revision ($full_revision) in log:\n$self->{message}"
		unless $full_revision =~ /^(.+)--(.+)/;

	return ($1, $2);
}

sub get_version ($) {
	my $self = shift;
	($self->split_version)[0];
}

sub get_revision ($) {
	my $self = shift;
	$self->header('archive') . "/" . $self->header('revision');
}

sub get_revision_kind ($) {
	my $self = shift;

	return $self->header('continuation_of')? 'tag':
		$self->header('revision') =~ /--base-0$/? 'import': 'cset';
}

sub get_revision_desc ($) {
	my $self = shift;

	my ($version, $name) = $self->split_version;
	my $summary = $self->header('summary') || '(none)';
	my ($creator, $email, $username) = parse_creator_email($self->header('creator') || "N.O.Body");
	my $date = $self->header('standard_date') || standardize_date($self->header('date') || "no-date");
	my $age = date2age($date);
	my $kind = $self->get_revision_kind;

	return {
		name     => $name,
		version  => $version,
		summary  => $summary,
		creator  => $creator,
		email    => $email,
		username => $username,
		date     => $date,
		age      => $age,
		kind     => $kind,
	};
}

sub dump ($) {
	my $self = shift;
	my $headers = $self->get_headers;
	require Data::Dumper;
	my $dumper = Data::Dumper->new([$headers]);
	$dumper->Sortkeys(1) if $dumper->can('Sortkeys');
	return $dumper->Quotekeys(0)->Indent(1)->Terse(1)->Dump;
}

sub AUTOLOAD ($@) {
	my $self = shift;
	my @params = @_;

	my $method = $Arch::Log::AUTOLOAD;

	# remove the package name
	$method =~ s/.*://;
	# DESTROY messages should never be propagated
	return if $method eq 'DESTROY';

	if (exists $self->get_headers->{$method}) {
		$self->header($method, @_);
	} else {
		die "Arch::Log: no such header or method ($method)\n";
	}
}

1;

__END__

=head1 NAME

Arch::Log - class representing Arch patch-log

=head1 SYNOPSIS 

    use Arch::Log;
    my $log = Arch::Log->new($rfc2822_message_string);
    printf "Patch log date: %s\n", $log->header('standard_date');
    print $log->dump;
    my $first_new_file = $log->get_headers->{new_files}->[0];

=head1 DESCRIPTION

This class represents the patch-log concept in Arch and provides some
useful methods.

=head1 METHODS

The following class methods are available:

B<get_message>,
B<get_headers>,
B<header>,
B<get_changes>,
B<split_version>,
B<get_version>,
B<get_revision>,
B<get_revision_kind>,
B<get_revision_desc>,
B<dump>.

=over 4

=item B<get_message>

Return the original message with that the object was constructed.

=item B<get_headers>

Return the hashref of all headers including body, see also C<header> method.

=item B<header> name

=item B<header> name [new_value]

Get or set the named header. The special name 'body' represents the
message body (the text following the headers).

=item B<body> [new_value]

=item existing_header_name [new_value]

This is just a shortcut for C<header>('I<method>'). However unlike
C<header>('I<method>'), I<method> fails instead of returning undef if the log
does not have the given header name.

=item B<get_changes>

Return a list of changes in the corresponding changeset.

B<ATTENTION!> Patch logs do not distinguish metadata (ie permission)
changes from ordinary content changes. Permission changes will be
represented with a change type of 'M'. This is different from
L<Arch::Changeset>::B<get_changes> and L<Arch::Tree>::B<get_changes>.

=item B<split_version>

Return a list of 2 strings: full version and patch-level.

=item B<get_version>

Return the full version name, not unlike B<split_version>.

=item B<get_revision>

Return the full revision name.  This is currently a concatination of
headers Archive and Revision with '/' separator.

=item B<get_revision_kind>

Return one of the strings 'tag', 'import' or 'cset' depending on the
revision kind this log represents.

=item B<get_revision_desc>

Return revision description hashref with the keys:
name, version, summary, creator, email, date, kind.

=item B<dump>

Returns the object dump using L<Data::Dumper>.

=back

=head1 BUGS

Awaiting for your reports.

=head1 AUTHORS

Mikhael Goikhman (migo@homemail.com--Perl-GPL/arch-perl--devel).

=head1 SEE ALSO

For more information, see L<tla>, L<Arch::Session>, L<Arch::Library>,
L<Arch::Changes>.

=cut
