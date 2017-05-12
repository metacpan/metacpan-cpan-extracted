package Alien::Packages::Dpkg;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::Dpkg - get's information from Debian's package database via dpkg-query

=cut

$VERSION = "0.003";

require Alien::Packages::Base;

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::Rpm
    ISA Alien::Packages::Base

=cut

require IPC::Cmd;

my $dpkg_query;

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true when the C<dpkg-query> command could be found in the path.

=cut

sub usable
{
    unless ( defined($dpkg_query) )
    {
        $dpkg_query = IPC::Cmd::can_run('dpkg-query');
        $dpkg_query ||= '';
    }

    return $dpkg_query;
}

=head2 list_packages

Returns the list of installed I<dpkg> packages.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      $self->_run_ipc_cmd(
                     command => [ $dpkg_query, '-W', q(-f=${Package}:${Version}:${Description}\n) ],
                     verbose => 0, );

    if ($success)
    {
        chomp $stdout_buf->[0];
        my @pkglist = split( /\n/, $stdout_buf->[0] );
        my %pkg_details;
        foreach my $pkg (@pkglist)
        {
            if ( 0 == index( $pkg, ' ' ) )
            {
                push( @{ $pkg_details{Description} }, $pkg );
            }
            else
            {
                %pkg_details and push( @packages, {%pkg_details} );
                @pkg_details{ 'Package', 'Version', 'Summary' } = split( ':', $pkg );
                $pkg_details{Description} = [];
            }
        }
        %pkg_details and push( @packages, {%pkg_details} );
    }

    return @packages;
}

=head2 list_fileowners

Returns the I<dpkg> packages which are associated to requested file(s).

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    foreach my $file (@files)
    {
        my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
          $self->_run_ipc_cmd( command => [ $dpkg_query, '-S', $file ],
                               verbose => 0, );

        if ($success)
        {
            chomp $stdout_buf->[0];
            my @pkglist = split( /\n/, $stdout_buf->[0] );
            foreach my $pkg (@pkglist)
            {
                if ( my ( $pkg_names, $fn ) = $pkg =~ m/^([^:]+):\s+([^\s].*)$/ )
                {
                    foreach my $pkg_name (split /\s*,\s*/, $pkg_names)
                    {
                        push( @{ $file_owners{$fn} }, { Package => $pkg_name } );
                    }
                }
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
