package Alien::Packages::Rpm;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::Rpm - get's information from RedHat Package Manager CLI

=cut

$VERSION = "0.003";

require Alien::Packages::Base;

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::Rpm
    ISA Alien::Packages::Base

=cut

require IPC::Cmd;

my $rpm;

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true when the rpm database access is not available (when
L<RPM::Database> is not available) and the C<rpm> command could be
found in the path.

=cut

sub usable
{
    unless ( defined($rpm) )
    {
        local $@;
        eval { require Alien::Packages::RpmDB; };
        if ( !$@ && Alien::Packages::RpmDB->usable() )
        {
            $rpm = '';
        }
        else
        {
            $rpm = IPC::Cmd::can_run('rpm');
            $rpm ||= '';
        }
    }

    return $rpm;
}

=head2 list_packages

Returns the list of installed I<rpm> packages.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) =
      $self->_run_ipc_cmd(
        command => [ $rpm, '-qa', '--queryformat', '"%{NAME}:%{VERSION}:%{RELEASE}:%{SUMMARY}\n"' ],
        verbose => 0, );

    if ($success)
    {
        my @pkglist = split( /\n/, $stdout_buf->[0] );
        foreach my $pkg (@pkglist)
        {
            next if ( $pkg =~ m/^#/ );
            my @pkg_details = split( ':', $pkg );
            push(
                  @packages,
                  {
                     Package => $pkg_details[0],
                     Version => $pkg_details[1],
                     Release => $pkg_details[2],
                     Summary => $pkg_details[3],
                  }
                );
        }
    }

    return @packages;
}

=head2 list_fileowners

Returns the I<rpm> packages which are associated to requested file(s).

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

    foreach my $file (@files)
    {
        my ( $success, $error_code, $full_buf, $stdout_buf, $stderr_buf ) = $self->_run_ipc_cmd(
                       command => [ $rpm, '-qf', $file ],    # XXX received with or without versions
                       verbose => 0, );

        if ($success)
        {
            chomp $stdout_buf->[0];
            push( @{ $file_owners{$file} }, { Package => $stdout_buf->[0] } );
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
