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

use Test::More ( tests => 1 + 1 );
use Test::NoWarnings;

############################################################################
BEGIN { use_ok('Dancer::Plugin::Device::Layout') }

############################################################################
1;
