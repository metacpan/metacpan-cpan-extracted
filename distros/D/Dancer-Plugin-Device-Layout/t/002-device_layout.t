## no critic (RequireExplicitPackage RequireVersionVar)
############################################################################
# Dancer::Plugin::Device::Layout - Dancer v1 plugin Dancer::Plugin::Device::Layout dynamically changes layout to match user agent's best layout.
# @author     BURNERSK <burnersk@cpan.org>
# @license    http://opensource.org/licenses/artistic-license-2.0 Artistic License 2.0
# @copyright  © 2013, BURNERSK. Some rights reserved.
############################################################################
use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More ( tests => 1 + 5 );
use Test::NoWarnings;

use Dancer::Plugin::Device::Layout;

############################################################################
# Simple tests.
is(
  Dancer::Plugin::Device::Layout::device_layout( override_device => $_ ), ## no critic (ProtectPrivateSubs)
  $_,
  qq{override_device $_},
) for qw( normal tablet mobile );

############################################################################
# Return tests.
{
  my $device_layout =
    Dancer::Plugin::Device::Layout::device_layout( override_device => 'normal' );
  is( $device_layout, 'normal', 'do not want array' );
}
{
  my %options =
    Dancer::Plugin::Device::Layout::device_layout( override_device => 'normal' );
  is( $options{layout}, 'normal', 'want array' );
}

############################################################################
1;
