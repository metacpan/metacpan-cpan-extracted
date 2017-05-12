use Test::More tests => 6;

use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, '..', 'lib' );

require_ok('FindBin');
use_ok 'FindBin';

require_ok('File::Spec');
use_ok 'File::Spec';

require_ok( 'DBIx::Schema::Changelog::Command::Base' );
use_ok 'DBIx::Schema::Changelog::Command::Base';

