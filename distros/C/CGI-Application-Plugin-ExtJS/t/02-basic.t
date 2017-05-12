#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

BEGIN { use_ok('CAPExtTest::Schema') };
BEGIN {
   $ENV{CGI_APP_RETURN_ONLY} = 1;
   use_ok('CAPExtTest::CGIApp');;
};

my $t1_obj = CAPExtTest::CGIApp->new();
my $t1_output = $t1_obj->run();

my $schema = CAPExtTest::Schema->connect( $CAPExtTest::CGIApp::CONNECT_STR );
$schema->deploy();
$schema->populate(Stations => [
   [qw{id bill    ted       }],
   [qw{1  awesome bitchin   }],
   [qw{2  cool    bad       }],
   [qw{3  tubular righeous  }],
   [qw{4  rad     totally   }],
   [qw{5  sweet   beesknees }],
   [qw{6  gnarly  killer    }],
   [qw{7  hot     legit     }],
   [qw{8  groovy  station   }],
   [qw{9  wicked  out       }],
]);

ok $t1_obj->schema->resultset('Stations'), 'resultset correctly found';

{
   $t1_obj->query->param(limit => 3);
   my $paginated =
   $t1_obj->ext_paginate(
      $t1_obj->paginate(
	 $t1_obj->schema->resultset('Stations')
      )
   );
   cmp_deeply $paginated,
	      {
		 total => 9,
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
   $t1_obj->query->delete_all;
}

{
   $t1_obj->query->param(limit => 3);
   my $paginated =
   $t1_obj->ext_paginate(
      $t1_obj->paginate(
	 $t1_obj->schema->resultset('Stations')
      ), sub {
	 {
	    id => $_[0]->id
	 }
      }
   );
   cmp_deeply $paginated,
	      {
		 total => 9,
		 data=> set({
		    id => 1,
		 },{
		    id => 2,
		 },{
		    id => 3,
		 })
	      },
	      'ext_paginate with coderef correctly builds structure';
   $t1_obj->query->delete_all;
}

{
   my $data =
   $t1_obj->ext_parcel(
      [qw{foo bar baz}]
   );
   cmp_deeply $data,
	      {
		 total => 3,
		 data=> [qw{foo bar baz}],
	      },
	      'ext_parcel correctly parcels and defaults data';
}


{
   my $data =
   $t1_obj->ext_parcel(
      [qw{foo bar baz}], 5
   );
   cmp_deeply $data,
	      {
		 total => 5,
		 data=> [qw{foo bar baz}],
	      },
	      'ext_parcel correctly parcels data';
}




done_testing;
END { unlink $CAPExtTest::CGIApp::DBFILE };
