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

use Test::More;

############################################################################
if ( $ENV{RELEASE_TESTING} ) {
  if ( eval 'use Test::Pod::Coverage 1.00; return 1;' ) { ## no critic (ProhibitStringyEval)
    all_pod_coverage_ok();
  }
  else {
    plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD';
  }
}
else {
  plan skip_all => 'RELEASE_TESTING is not enabled';
}

############################################################################
1;
