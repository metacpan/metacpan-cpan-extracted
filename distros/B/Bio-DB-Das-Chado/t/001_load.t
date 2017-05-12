# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;

BEGIN { 
  use_ok( 'Bio::DB::Das::Chado' ); 
  use_ok( 'Bio::DB::Das::Chado::Segment');
  use_ok( 'Bio::DB::Das::Chado::Segment::Feature');
}



