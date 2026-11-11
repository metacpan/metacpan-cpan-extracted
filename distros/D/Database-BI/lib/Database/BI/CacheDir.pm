package Database::BI::CacheDir;

use strict;
use warnings;

use version; our $VERSION = version->declare('0.023.0');

use Carp	qw(carp);
use Mojo::File	();
use Readonly;

# The configuration file the application reads when MOJO_CONFIG does not name
# another (Mojolicious takes it from the moniker).
Readonly my $CONFIG_FILE => 'database_bi.conf';

# The environment variables read after Object::Configure, in order.
Readonly my @ENV_KEYS => qw(CACHEDIR CACHE_DIR);

=head1 NAME

Database::BI::CacheDir - Where a cache keeps its files

=head1 VERSION

0.023.0

=head1 SYNOPSIS

    use Database::BI::CacheDir;

    sub new {
        my ($class, %args) = @_;
        my $dir = Database::BI::CacheDir::resolve(
            class   => $class,
            params  => \%args,
            default => '.bi/geocode-cache',
        );
        ...
    }

=head1 DESCRIPTION

Every object in this distribution that keeps a cache on disc asks C<resolve()>
for its directory when it is made, so one setting moves them all.

=head1 SUBROUTINES

=head2 resolve

Returns the first of these that is set:

=over 4

=item 1. C<cache_dir> from L<Object::Configure> for C<class>: its config files
(F<~/.conf/E<lt>classE<gt>.yml> and the rest), then the environment variable
C<E<lt>ClassE<gt>__cache_dir> (C<::> written C<__>, e.g.
C<Database__BI__Model__Geocode__cache_dir>).  A C<cache_dir> in C<params> is
what those fall back on;

=item 2. C<$ENV{CACHEDIR}>;

=item 3. C<$ENV{CACHE_DIR}>;

=item 4. C<cache_dir> in F<database_bi.conf>; a relative one is under the
application home;

=item 5. C<default>.

=back

The directory is not made here; the cache makes it when it first stores
something.

=head3 API SPECIFICATION

=head4 INPUT

    class   => string,   # optional; the class being made, for Object::Configure
    params  => hashref,  # optional; the arguments to its new(), read for cache_dir
    config  => hashref,  # optional; the application's config; when the key is absent, database_bi.conf is read (see bi_config)
    home    => string,   # optional; the folder a relative config cache_dir is under
    default => string,   # optional; the directory when nothing else is set

=head4 OUTPUT

A directory name, or C<undef> when nothing is set and there is no C<default>.
A config file Object::Configure cannot read is reported with C<carp> and
skipped.

=cut

# resolve(%args) -> $directory | undef
#
# The one place the directory a cache keeps its files in is chosen, so every
# object that caches on disc reads the same settings in the same order:
#
#   1. Object::Configure, for the class being made (its config files, then the
#      environment variable <Class__Name>__cache_dir; a cache_dir the caller
#      passed is what they fall back on, as Object::Configure always does);
#   2. $ENV{CACHEDIR};
#   3. $ENV{CACHE_DIR};
#   4. cache_dir in database_bi.conf (relative: under the application home);
#   5. the caller's default (relative: as given).
#
# Object::Configure is given an array for its logger, which no config file can
# replace: a universal.yml that logs to syslog would otherwise be opened for
# every object made.  A config file it cannot read is reported and skipped, so
# a broken ~/.conf costs the cache its setting, not the page.
sub resolve {
	local ($@, $!);
	my (%args) = @_;

	my $params = $args{params} // {};

	if (defined(my $class = $args{class})) {
		my $configured;
		my $ok = eval {
			require Object::Configure;
			$configured = Object::Configure::configure($class, {
				(_set($params->{cache_dir}) ? (cache_dir => $params->{cache_dir}) : ()),
				logger => [],
			});
			1;
		};
		carp("Object::Configure could not configure $class: " . ($@ || 'no reason given'))
			unless $ok;
		return $configured->{cache_dir}
			if $ok && ref($configured) eq 'HASH' && _set($configured->{cache_dir});
	}
	return $params->{cache_dir} if _set($params->{cache_dir});

	for my $key (@ENV_KEYS) {
		return $ENV{$key} if _set($ENV{$key});
	}

	my ($config, $home) = exists($args{config})
		? ($args{config}, $args{home})
		: bi_config();
	if (ref($config) eq 'HASH' && _set($config->{cache_dir})) {
		my $dir = Mojo::File->new($config->{cache_dir});
		$dir = Mojo::File->new($home)->child($config->{cache_dir})
			if !$dir->is_abs && _set($home);
		return $dir->to_string;
	}

	return _set($args{default}) ? $args{default} : undef;
}

=head2 bi_config

    my ($config, $home) = Database::BI::CacheDir::bi_config();

The application's configuration for a caller outside it: the file
C<$ENV{MOJO_CONFIG}> names, else F<database_bi.conf> in the current directory.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

C<($config_hashref, $home)>, where C<$home> is the file's folder; an empty
list when there is no file or it does not read (the second is reported with
C<carp>).

=cut

# bi_config() -> ($config_hashref, $home) | ()
#
# database_bi.conf for a caller outside the web application (a script, or a
# library user): the file MOJO_CONFIG names, else database_bi.conf in the
# current directory.  Its folder is the home a relative setting is under.  No
# file, or one that does not read, gives an empty list.
sub bi_config {
	local ($@, $!);
	my $file = _set($ENV{MOJO_CONFIG}) ? $ENV{MOJO_CONFIG} : $CONFIG_FILE;

	return () unless -f $file && -r _;

	my $config;
	my $ok = eval {
		require Mojolicious::Plugin::Config;
		$config = Mojolicious::Plugin::Config->new->load($file, {}, undef);
		1;
	};
	unless ($ok) {
		carp("Cannot read $file: " . ($@ || 'no reason given'));
		return ();
	}

	return ($config, Mojo::File->new($file)->to_abs->dirname->to_string);
}

sub _set {
	my $value = shift;
	return defined($value) && !ref($value) && length($value);
}

1;

__END__

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
