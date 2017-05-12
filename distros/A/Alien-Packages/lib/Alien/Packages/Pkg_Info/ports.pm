package Alien::Packages::Pkg_Info::ports;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::Pkg_Info::ports - deals with FreeBSD's Ports

=cut

$VERSION = "0.003";

require Alien::Packages::Base;

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::Pkg_Info::ports
    ISA Alien::Packages::Base

=cut

require IPC::Cmd;

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true, when the command C<pkg_info> could be found in the path and
C<pkg_info -qP> returns a valid release date.

=cut

my $pkg_info;

sub usable
{
    unless ( defined($pkg_info) )
    {
        my @pkg_info;

        local $@;
        eval {
            require File::Which;
            @pkg_info = File::Which::where('pkg_info');
        };
        if ($@)
        {
            @pkg_info = grep { $_ } ( IPC::Cmd::can_run('pkg_info') );
        }

        foreach my $piexe (@pkg_info)
        {
            my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
              IPC::Cmd::run( command => [ $piexe, '-qP' ],
                             verbose => 0, );
            my $ports = $success && @{$stdout_buf} && $stdout_buf->[0] =~ m/^\d{4}\d{2}\d{2}$/;
            $ports and $pkg_info = $piexe and last;
        }

        defined($pkg_info) or $pkg_info = '';
    }

    return $pkg_info;
}

=head2 list_packages

Returns the list of installed FreeBSD ports.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      $self->_run_ipc_cmd( command => [$pkg_info],
                           verbose => 0, );

    if ($success)
    {
        my @pkglist = split( /\n/, $stdout_buf->[0] );
        foreach my $pkg (@pkglist)
        {
            my @pkg_details = split( ' ', $pkg, 2 );
            if ( $pkg_details[0] =~ m/^(.*)-([^-]*)$/ )
            {
                push(
                      @packages,
                      {
                         Package => $1,
                         Version => $2,
                         Summary => $pkg_details[1]
                      }
                    );
            }
        }
    }

    return @packages;
}

=head2 list_fileowners

Returns the names of the ports which have installed the requested files.

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    foreach my $file (@files)
    {
        my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
          $self->_run_ipc_cmd( command => [ $pkg_info, '-q', '-W', $file ],
                               verbose => 0, );

        if ($success)
        {
            chomp $stdout_buf->[0];
            if ( $stdout_buf->[0] =~ m/^(.*)-([^-]*)$/ )
            {
                push( @{ $file_owners{$file} }, { Package => $1 } );
            }
        }
    }

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
