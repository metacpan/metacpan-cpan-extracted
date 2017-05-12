#!perl

use strict;
use warnings;

use FindBin;
use JSON;
use Test::More;
use Test::Deep;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';
use TestApp::Schema;
my $schema = TestApp::Schema->connect( 'dbi:SQLite:dbname=test.db' );
$schema->deploy();
$schema->populate(Stations => [
   [qw{id bill    ted       }],
   [qw{1  awesome bitchin   }],
   [qw{2  cool    bad       }],
   [qw{3  tubular righeous  }],
   [qw{4  rad     totalAmountly   }],
   [qw{5  sweet   beesknees }],
   [qw{6  gnarly  killer    }],
   [qw{7  hot     legit     }],
   [qw{8  groovy  station   }],
   [qw{9  wicked  out       }],
]);

{
   my $data = from_json(get('/test_paginate?limit=3'));
   cmp_deeply $data,
	      {
		 totalAmount => 9,
		 data=> set({
		    id => 1,
		    bill => 'awesome'
		 },{
		    id => 2,
		    bill => 'cool'
		 },{
		    id => 3,
		    bill => 'tubular'
		 })
	      },
	      'ext_paginate correctly builds structure';
}

{
   my $data = from_json(get('/test_paginate2?limit=3'));
   cmp_deeply $data,
	      {
		 totalAmount => 9,
		 data=> set({
		    id => 1,
		 },{
		    id => 2,
		 },{
		    id => 3,
		 })
	      },
	      'ext_paginate with coderef correctly builds structure';
}

{
   my $data = from_json(get('/test_parcel?limit=3'));
   cmp_deeply $data,
	      {
		 totalAmount => 3,
		 data=> set({
		    id => 1,
		 },{
		    id => 2,
		 },{
		    id => 3,
		 })
	      },
	      'ext_parcel correctly builds structure with default totalAmount';
}

{
   my $data = from_json(get('/test_parcel2?limit=3'));
   cmp_deeply $data,
	      {
		 totalAmount => 1_000_000,
		 data=> set({
		    id => 1,
		 },{
		    id => 2,
		 },{
		    id => 3,
		 })
	      },
	      'ext_parcel correctly builds structure';
}
done_testing;

END { unlink 'test.db' if stat 'test.db' }
