#
# $Id$
#

use strict;
use warnings;

#########################

use Test::More tests => 7;
BEGIN { use_ok('ExtUtils::PkgConfig') };

require 't/swallow_stderr.inc';

#########################

require PkgConfig::LibPkgConf;
diag ("Testing against PkgConfig::LibPkgConf $PkgConfig::LibPkgConf::VERSION");

$ENV{PKG_CONFIG_PATH} = './t/';

my %pkg;

# test 1 for success
eval { %pkg = ExtUtils::PkgConfig->find(qw/test_glib-2.0/); };
ok( not $@ );
ok( $pkg{modversion} and $pkg{cflags} and $pkg{libs} );

# test 1 for failure
swallow_stderr (sub {
  eval { %pkg = ExtUtils::PkgConfig->find(qw/bad1/); };
  ok( $@ );
});

# test 2 for success
eval { %pkg = ExtUtils::PkgConfig->find(qw/bad1 test_glib-2.0/); };
ok( not $@ );
ok( $pkg{modversion} and $pkg{cflags} and $pkg{libs} );

# test 2 for failure
swallow_stderr (sub {
  eval { %pkg = ExtUtils::PkgConfig->find(qw/bad1 bad2/); };
  ok( $@ );
});
