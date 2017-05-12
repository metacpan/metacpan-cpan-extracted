package Alien::Packages::PkgInfo;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::PkgInfo - handles Sun's pkginfo

=cut

$VERSION = "0.003";

require Alien::Packages::Base;

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::PkgInfo
    ISA Alien::Packages::Base

=cut

require File::Spec;
require IPC::Cmd;

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true when the commands C<pkginfo> and C<pkgchk> could be found in
the path.

=cut

my ( $pkginfo, $pkgchk );

sub usable
{
    unless ( defined($pkginfo) )
    {
        $pkginfo = IPC::Cmd::can_run('pkginfo');
        $pkginfo ||= '';
    }

    unless ( defined($pkgchk) )
    {
        $pkgchk = IPC::Cmd::can_run('pkgchk');
        $pkgchk ||= '';
    }

    return $pkginfo && $pkgchk;
}

=head2 list_packages

Returns the list of installed packages.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      $self->_run_ipc_cmd( command => [ $pkginfo, '-x' ],
                           verbose => 0, );

    if ($success)
    {
        while ( $stdout_buf->[0] =~ m/(\w+)\s+([^\s].*)\s+(\(\w+\))\s(\d[\d.]+,REV=[^\s]+)/gx )
        {
            push(
                  @packages,
                  {
                     Package => $1,
                     Version => $4,
                     Summary => $2,
                  }
                );
        }
    }

    return @packages;
}

=head2 list_fileowners

Returns the packages which have a registered dependency on specified files.

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    my $tmpfile =
      File::Spec->catfile( File::Spec->tmpdir(), join( "_", qw(alias pkg list fileowner), $$ ) );

    foreach my $file (@files)
    {
        my $fh;
        open( $fh, ">", $tmpfile ) or die "Can't open $tmpfile: $!";
        print $fh "$file\n";
        close($fh) or die "Can't close $tmpfile: $!";

        # that seems to fail on OpenSolaris - Solaris 10u8 on sparc64 succeeds
        my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
          $self->_run_ipc_cmd( command => [ $pkgchk, '-i', $tmpfile, '-l' ],
                               verbose => 0, );

        if ($success)
        {
            while ( $stdout_buf->[0] =~
                m/Pathname:\s*(.*?)\n.*Referenced\sby\sthe\sfollowing\spackages:\s+([A-Za-z0-9]+)/xsg
              )
            {
                push( @{ $file_owners{$1} }, { Package => $2 } );
            }
        }
    }

    unlink $tmpfile;

    return %file_owners;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
