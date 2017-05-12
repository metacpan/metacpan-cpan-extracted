# -*- mode: cperl -*-

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 3;
BEGIN { use_ok('DBIx::Class::EasyConf::YAML') };
BEGIN { use_ok('MyApp::Schema::Result::SomeTable') };
BEGIN { use_ok('MyApp::Schema::Result::SomeOtherTable') };
