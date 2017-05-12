package Alien::WiX;

use 5.008;
use warnings;
use strict;
use Carp;
use base qw( Exporter );
use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS);
use version; $VERSION = version->new('1.305419001')->numify();

eval { require Alien::WiX::Version35; 1; } or eval {
	require Alien::WiX::Version30;
	Alien::WiX::Version30->VERSION(5419.1);
	1;
}
  or croak @_;

@EXPORT_OK =
  qw(wix_binary wix_library wix_version wix_version_number wix_bin_candle wix_bin_light wix_lib_wixui);
%EXPORT_TAGS = (
	GENERAL => [qw(wix_binary wix_library wix_version wix_version_number)],
	ALL     => [@EXPORT_OK] );

sub import { ## no critic (RequireArgUnpacking)
	my @import = @_;
	shift @import;

	if ( defined $Alien::WiX::Version35::VERSION ) {
		Alien::WiX::Version35->import(@import);
	} else {
		Alien::WiX::Version30->import(@import);
	}
	Alien::WiX->export_to_level( 1, @_ );

	return;
} ## end sub import


1;

__END__

=head1 NAME

Alien::WiX - Installing and finding Windows Installer XML (WiX)

=head1 VERSION

This document describes Alien::WiX version 1.305419001.

Note that the first digit will change if the API changes 
in an incompatible or major manner, while the other digits change 
when the version of WiX that is installed by this module 
changes.

There is no incompatibility between 0.x and 1.x versions, however.

=head1 SYNOPSIS

    use Alien::WiX qw(:GENERAL);

    print wix_version();
    # Prints 3.0.5419.0, usually.
    
    $version_number = wix_version_number();
    die 'WiX beta-exit build or better required, stopping' 
        if ($version_number < 4805)
    
    print wix_binary('candle'), " exists\n";
    print wix_library('WixFirewall'), " exists\n";
    
    use Alien::WiX 0.305419 qw(:ALL);
    
    print wix_bin_candle(), " exists\n";
    print wix_bin_light(), " exists\n";
    print wix_lib_wixui(), " exists\n";
    
=head1 DESCRIPTION

Installing this module will also install Windows Installer XML (otherwise 
known as WiX) version 3.0.5419.0, if it (or a later version) has not 
already been installed.

This module provides utility subroutines that would be useful for programs
that use WiX to create Windows Installer (.msi) installation packages.

=head1 INTERFACE 

All routines will C<croak> when errors occur.
C<use>ing the module will also croak if WiX is not installed.

=head2 wix_version

Returns the version of Windows Installer XML (i.e. 3.0.5419.0) as a string.

=head2 wix_version_number

Returns the third portion of the version of Windows Installer XML 
(i.e. if wix_version returns 3.0.5419.0, this returns 5419) as a number.

=head2 wix_binary

Returns the location of the WiX program specified as its first parameter.
The '.exe' part is not required.

=head2 wix_library

Returns the location of the WiX extension library specified as its first parameter.
The 'Extension.dll' part is not required.

=head2 wix_bin_candle

=head2 wix_bin_light

Returns the location of candle.exe or light.exe.

=head2 wix_lib_wixui

Returns the location of the WixUI extension library.

=head1 DIAGNOSTICS

=over 

=item C<< Windows Installer XML not installed, cannot continue >>

The module could not find the registry key for WiX 3.0.

=item C<< Cannot execute %s >>

The file wix_binary or a wix_bin routine was attempting to find 
could not be found or it could not be executed.

=item C<< Cannot find %s >>

The file wix_library or a wix_lib routine was attempting to find 
could not be found.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Alien::WiX requires no configuration files or environment variables.

It checks the registry entries that WiX's installer wrote to the
Windows registry to get its return values.

Note that this module checks if Windows Installer XML is INSTALLED, NOT 
that it successfully executes.

=head1 DEPENDENCIES

This module requires Perl 5.8.0.

Non-core perl modules required are L<Win32API::Registry|Win32API::Registry>
(which is required to be installed in order to run the 
Makefile.PL or Build.PL successfully), L<Module::Build|Module::Build> 
(which is required to install this module), 
L<Win32::TieRegistry|Win32::TieRegistry>, L<version|version>, 
and L<Readonly|Readonly>.

Installation of Alien::WiX will install Microsoft .NET Framework 2.0 SP1 
and Windows Installer XML 3.0.5419.0 by downloading them from the 
appropriate sites unless otherwise specified.

=head1 INCOMPATIBILITIES

If you want to install WiX in a non-default location, you will want to install 
it yourself before installing this module.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Alien-WiX-Version30@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See 
L<perlartistic|perlartistic>.

The software installed by this module has its own licenses and copyrights, and is
not included in this license and copyright.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
