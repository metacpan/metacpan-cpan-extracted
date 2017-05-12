use Test::More tests => 23;

use FindBin;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );
use strict;
use warnings;

require_ok( 'DBIx::Schema::Changelog' );
use_ok 'DBIx::Schema::Changelog';

require_ok( 'MooseX::Types::Path::Class' );
use_ok 'MooseX::Types::Path::Class';

require_ok( 'DBI' );
use_ok 'DBI';

require_ok( 'Hash::MD5' );
use_ok 'Hash::MD5';

require_ok( 'DBI' );
use_ok 'DBI';

require_ok( 'YAML::XS' );
use_ok 'YAML::XS';

require_ok( 'Moose' );
use_ok 'Moose';

require_ok( 'MooseX::HasDefaults::RO' );
use_ok 'MooseX::HasDefaults::RO';

require_ok( 'YAML' );
use_ok 'YAML';

require_ok( 'Getopt::Long' );
use_ok 'Getopt::Long';

require_ok( 'MooseX::Types::Moose' );
use_ok 'MooseX::Types::Moose';

use_ok 'DBIx::Schema::Changelog';
