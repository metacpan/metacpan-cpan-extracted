package Alien::WiX::Version30;

use 5.008;
use warnings;
use strict;
use Carp;
use File::Spec;
use base qw( Exporter );
use vars qw( $VERSION @EXPORT_OK %EXPORT_TAGS);
use Readonly qw( Readonly );
use Win32::TieRegistry qw( KEY_READ );
use version; $VERSION = version->new('5419.1')->numify();

# http://wix.sourceforge.net/releases/3.0.5419.0/Wix3(-x64).msi

Readonly my $WIX_REGISTRY_KEY =>
  'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows Installer XML/3.0';
@EXPORT_OK =
  qw(wix_binary wix_library wix_version wix_version_number wix_bin_candle wix_bin_light wix_lib_wixui);
%EXPORT_TAGS = (
	GENERAL => [qw(wix_binary wix_library wix_version wix_version_number)],
	ALL     => [@EXPORT_OK] );

my $_wix_registry;

sub import { ## no critic (RequireArgUnpacking)
	_wix_registry();                   # So we die quick if WiX is not installed.
	Alien::WiX::Version30->export_to_level( 1, @_ );

	return;
}

sub _wix_registry {

	# 0x200 = KEY_WOW64_32KEY
	$_wix_registry ||= Win32::TieRegistry->new(
		$WIX_REGISTRY_KEY => {
			Access    => KEY_READ() | 0x200,
			Delimiter => q{/},
		} );

	if ( not defined $_wix_registry ) {
		croak 'Windows Installer XML not installed, cannot continue';
	}

	return $_wix_registry;
} ## end sub _wix_registry

sub _wix_root {
	return _wix_registry->TiedRef->{'InstallRoot'};
}

sub wix_version {
	return _wix_registry->TiedRef->{'ProductVersion'};
}

sub wix_version_number {
	my $version = wix_version();
	if ( $version =~ m/3.0.(\d+).0/msx ) {
		return $1;
	}

	return;
}

sub wix_binary {
	my $file = File::Spec->catfile( _wix_root(), "$_[0].exe" );
	croak "Cannot execute $file" unless ( -x $file );
	return $file;
}

sub wix_library {
	my $file = File::Spec->catfile( _wix_root(), "$_[0]Extension.dll" );
	croak "Cannot find $file" unless ( -f $file );
	return $file;
}

sub wix_bin_candle {
	return wix_binary('candle');
}

sub wix_bin_light {
	return wix_binary('light');
}

sub wix_lib_wixui {
	return wix_library('WixUI');
}

1;

__END__

=head1 NAME

Alien::WiX::Version30 - Implements the Alien::WiX interface.

=head1 VERSION

This document describes Alien::WiX::Version30 version 5419.0.

=head1 SYNOPSIS

    use Alien::WiX qw(:GENERAL);
	...
	
	# If we specifically want to rely on a 3.0.x version of WiX,
	# then do this:
    use Alien::WiX::Version30 qw(:GENERAL);
	...
	
    
=head1 DESCRIPTION

Installing this module will also install Windows Installer XML (otherwise 
known as WiX) version 3.0.5419.0, if it (or a later version) has not 
already been installed.

This module provides utility subroutines that would be useful for programs
that use WiX to create Windows Installer (.msi) installation packages.

=head1 INTERFACE 

This module implements the interface documented for L<Alien::WiX|Alien::WiX>.

=head1 INCOMPATIBILITIES

If you want to install WiX in a non-default location, you will want to install 
it yourself before installing this module.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Alien-WiX@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See 
L<perlartistic|perlartistic>.

The software installed by this module has its own licenses and copyrights, 
and is not included in this license and copyright.

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

=begin Pod::Coverage

wix_version

wix_version_number

wix_binary

wix_library

wix_bin_candle

wix_bin_light

wix_lib_wixui 

=end Pod::Coverage
