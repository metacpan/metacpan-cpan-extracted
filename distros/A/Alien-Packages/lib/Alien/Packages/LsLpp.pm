package Alien::Packages::LsLpp;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::LsLpp - handles AIX lslpp packaging system

=cut

$VERSION = "0.003";

require Alien::Packages::Base;

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::LsLpp
    ISA Alien::Packages::Base

=cut

require IPC::Cmd;

my $lslpp;

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true when the C<lslpp> command could be found in the path.

=cut

sub usable
{
    unless ( defined($lslpp) )
    {
        $lslpp = IPC::Cmd::can_run('lslpp');
        $lslpp ||= '';
    }

    return $lslpp;
}

=head2 pkgtype

Returns the pkg type "lpp".

=cut

sub pkgtype
{
    return 'lpp';
}

=head2 list_packages

Get's the list of installed filesets.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      $self->_run_ipc_cmd( command => [ $lslpp, '-lc' ],
                           verbose => 0, );

    if ($success)
    {
        chomp $stdout_buf->[0];
        my @pkglist = split( /\n/, $stdout_buf->[0] );
        foreach my $pkg (@pkglist)
        {
            next if ( $pkg =~ m/^#/ );
            my @pkg_details = split( ':', $pkg );
            next if ( scalar @pkg_details < 7 );
            my %pkg_details;
            @pkg_details{ 'Package', 'Version', 'Summary' } =
              ( @pkg_details[ 1, 2 ], $pkg_details[6] );
            push( @packages, \%pkg_details );
        }
    }

    return @packages;
}

=head2 list_fileowners

Returns the filesets which have installed a file.

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    foreach my $file (@files)
    {
        my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
          $self->_run_ipc_cmd( command => [ $lslpp, '-wc', $file ],
                               verbose => 0, );

        if ($success)
        {
            chomp $stdout_buf->[0];
            my @output = split( /\n/, $stdout_buf->[0] );
            foreach my $line (@output)
            {
                next if ( $line =~ m/^#/ );
                my @info = split( ":", $line );
                next if ( scalar @info < 3 );    # nonsense line
                push( @{ $file_owners{$file} }, { Package => $info[1] } );
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
