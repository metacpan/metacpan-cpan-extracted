package Alien::Packages::Msi;

use strict;
use warnings;
use vars qw($VERSION @ISA);

=head1 NAME

Alien::Packages::Msi - deals with package information of Microsoft Installer

=cut

$VERSION = "0.003";

require Alien::Packages::Base;

@ISA = qw(Alien::Packages::Base);

=head1 ISA

    Alien::Packages::Msi
    ISA Alien::Packages::Base

=head1 SUBROUTINES/METHODS

=head2 usable

Returns true when Win32::TieRegistry is available and can connect to C<HKLM>.

=cut

my ( $haveWin32TieRegistry, $win32TieRegistry );

sub usable
{
    unless ( defined($win32TieRegistry) )
    {
        $haveWin32TieRegistry = 0;
        eval {
            require Win32::TieRegistry;
            $win32TieRegistry = $Win32::TieRegistry::Registry->Clone();
            $win32TieRegistry->Delimiter("/");
            my $machKey = $win32TieRegistry->Open(
                                                   "LMachine",
                                                   {
                                                     Access    => Win32::TieRegistry::KEY_READ(),
                                                     Delimiter => "/"
                                                   }
                                                 ) or die "Can't open HKEY_LOCAL_MACHINE key: $^E\n";
            $haveWin32TieRegistry = 1;
        };
    }

    return $haveWin32TieRegistry;
}

=head2 list_packages

Scans the packages below
C<HKLM/SOFTWARE/Microsoft/Windows/CurrentVersion/Installer/UserData/*/Products/*/InstallProperties>
and returns the values of DisplayName and DisplayVersion for each key
below C<*/Products/*/>.

=cut

sub list_packages
{
    my $self = $_[0];
    my @packages;

    my $machKey = $win32TieRegistry->Open(
                                           "LMachine",
                                           {
                                              Access    => Win32::TieRegistry::KEY_READ(),
                                              Delimiter => "/"
                                           }
                                         ) or die "Can't open HKEY_LOCAL_MACHINE key: $^E\n";
    my $regInstallRoot =
      $machKey->Open("SOFTWARE/Microsoft/Windows/CurrentVersion/Installer/UserData");
    foreach my $user ( keys %$regInstallRoot )
    {
        my $userProdKey = $regInstallRoot->Open( $user . "Products" );
        foreach my $product ( keys %$userProdKey )
        {
            my $instPropKey = $userProdKey->Open( $product . "InstallProperties" );
            my %pkginfo = (
                            Package     => $product,
                            Description => $instPropKey->{DisplayName},
                            Version     => $instPropKey->{DisplayVersion},
                          );
            $pkginfo{Package} =~ s|/$||;
            push( @packages, \%pkginfo );
        }
    }

    return @packages;
}

=head2 list_fileowners

Returns an empty hash - MSI doesn't register installed files by MSI
packages (or better: I do not know where it stores this information).

=cut

sub list_fileowners
{
    my ( $self, @files ) = @_;
    my %file_owners;

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
