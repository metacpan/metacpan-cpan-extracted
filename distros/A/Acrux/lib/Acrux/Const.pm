package Acrux::Const;
use strict;
use utf8;
use feature ':5.16';

=encoding utf8

=head1 NAME

Acrux::Const - The Acrux constants

=head1 SYNOPSIS

    use Acrux::Const;

=head1 DESCRIPTION

This module contains constants definitions

=head2 TAGS

=over 8

=item B<:dir>

Exports FHS DIR constants

See L<See https://www.pathname.com/fhs/pub/fhs-2.3.html>,
L<http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html>,
L<Sys::Path>

=item B<:general>

Exports common constants

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Acrux>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

use base qw/Exporter/;

use Config qw//;
use File::Spec qw//;

use constant {
    # System constants
    IS_TTY              => !!(-t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT))), # See Prompt::Timeout
    IS_ROOT             => !!($> == 0),

    # Date and time formats (see strftime(3))
    DATE_FORMAT         => '%Y-%m-%d', # POSIX::strftime(DATE_FORMAT, localtime($t))
    TIME_FORMAT         => '%H:%M:%S', # POSIX::strftime(TIME_FORMAT, localtime($t))
    DATETIME_FORMAT     => '%Y-%m-%dT%H:%M:%S', # POSIX::strftime(DATETIME_FORMAT, localtime($t))
    DATE_TIME_FORMAT    => '%Y-%m-%d %H:%M:%S', # POSIX::strftime(DATE_TIME_FORMAT, localtime($t))
};

# Named groups of exports
our %EXPORT_TAGS = (
    'GENERAL' => [qw/
        IS_TTY IS_ROOT
        DATE_FORMAT TIME_FORMAT DATETIME_FORMAT DATE_TIME_FORMAT
    /],
    'DIR' => [qw/
        PREFIX LOCALSTATEDIR SYSCONFDIR SRVDIR
        BINDIR SBINDIR DATADIR DOCDIR LOCALEDIR MANDIR LOCALBINDIR
        CACHEDIR LOGDIR SPOOLDIR RUNDIR LOCKDIR SHAREDSTATEDIR WEBDIR
    /],
);

# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
our @EXPORT = (
        @{$EXPORT_TAGS{GENERAL}},
    );

# Other items we are prepared to export if requested
our @EXPORT_OK = (
        map {@{$_}} values %EXPORT_TAGS
    );

# Correct tags: makes lowercase tags as aliases of original uppercase tags
foreach my $k (keys %EXPORT_TAGS) {
    next if exists $EXPORT_TAGS{(lc($k))};
    $EXPORT_TAGS{(lc($k))} = $EXPORT_TAGS{$k} if $k =~ /^[A-Z_]+$/;
}

#
# Filesystem Hierarchy Standard
#
# See http://www.gnu.org/software/autoconf/manual/html_node/Installation-Directory-Variables.html
# See https://www.pathname.com/fhs/pub/fhs-2.3.html
#
my $prefix          = $Config::Config{'prefix'} // '';
my $bindir          = $Config::Config{'bin'} // File::Spec->catdir($prefix, 'bin');
my $localstatedir   = $prefix eq '/usr' ? '/var' : File::Spec->catdir($prefix, 'var');
my $sysconfdir      = $prefix eq '/usr' ? '/etc' : File::Spec->catdir($prefix, 'etc');
my $srvdir          = $prefix eq '/usr' ? '/srv' : File::Spec->catdir($prefix, 'srv');

# Root dirs
*PREFIX = sub { $prefix };                  # prefix              /usr
*LOCALSTATEDIR = sub { $localstatedir };    # localstatedir       /var
*SYSCONFDIR = sub { $sysconfdir };          # sysconfdir          /etc
*SRVDIR = sub { $srvdir };                  # srvdir              /srv

# Prefix related dirs
*BINDIR = sub { $bindir };                                                              # bindir    /usr/bin
*SBINDIR = sub { state $sbindir = File::Spec->catdir($prefix, 'sbin') };                # sbindir   /usr/sbin
*DATADIR = sub { state $datadir = File::Spec->catdir($prefix, 'share') };               # datadir   /usr/share
*DOCDIR = sub { state $docdir = File::Spec->catdir($prefix, 'share', 'doc') };          # docdir    /usr/share/doc
*LOCALEDIR = sub { state $localedir = File::Spec->catdir($prefix, 'share', 'locale') }; # localedir /usr/share/locale
*MANDIR = sub { state $mandir = File::Spec->catdir($prefix, 'share', 'man') };          # mandir    /usr/share/man
*LOCALBINDIR = sub { state $localbindir = File::Spec->catdir($prefix, 'local', 'bin') };# localbindir  /usr/local/bin

# Local State related Dirs
*CACHEDIR = sub { state $cachedir = File::Spec->catdir($localstatedir, 'cache') };      # cachedir  /var/cache
*LOGDIR = sub { state $logdir = File::Spec->catdir($localstatedir, 'log') };            # logdir    /var/log
*SPOOLDIR = sub { state $spooldir = File::Spec->catdir($localstatedir, 'spool') };      # spooldir  /var/spool
*RUNDIR = sub { state $rundir = File::Spec->catdir($localstatedir, 'run') };            # rundir    /var/run
*LOCKDIR = sub { state $lockdir = File::Spec->catdir($localstatedir, 'lock') };         # lockdir   /var/lock
*SHAREDSTATEDIR = sub { state $sharedstatedir = File::Spec->catdir($localstatedir, 'lib') }; # sharedstatedir  /var/lib
*WEBDIR = sub { state $webdir =  File::Spec->catdir($localstatedir, 'www') };           # webdir    /var/www

1;

__END__
