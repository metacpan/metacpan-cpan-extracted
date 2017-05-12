#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib qw{t/lib lib};
BEGIN {
   use_ok('CAPDBICTest::Schema');

   $ENV{CGI_APP_RETURN_ONLY} = 1;
   use_ok('CAPDBICTest::CGIApp');
}

my $t1_obj = CAPDBICTest::CGIApp->new();
my $t1_output = $t1_obj->run();

my $schema = CAPDBICTest::Schema->connect( $CAPDBICTest::CGIApp::CONNECT_STR );
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
   [qw{10  awesome bitchin   }],
   [qw{11  cool    bad       }],
   [qw{12  tubular righeous  }],
   [qw{13  rad     totally   }],
   [qw{14  sweet   beesknees }],
   [qw{15  gnarly  killer    }],
   [qw{16  hot     legit     }],
   [qw{17  groovy  station   }],
   [qw{18  wicked  out       }],
   [qw{19  awesome bitchin   }],
   [qw{20  cool    bad       }],
   [qw{21  tubular righeous  }],
   [qw{22  rad     totally   }],
   [qw{23  sweet   beesknees }],
   [qw{24  gnarly  killer    }],
   [qw{25  hot     legit     }],
   [qw{26  groovy  station   }],
]);

ok $t1_obj->schema->isa('DBIx::Class::Schema'), 'schema() method returns DBIx::Class schema';
ok $t1_obj->schema->resultset('Stations'), 'resultset correctly found';

PAGE_AND_SORT: {
   $t1_obj->query->param(limit => 3);
   $t1_obj->query->param(dir => 'asc');
   $t1_obj->query->param(sort => 'bill');
   my $paged_and_sorted =
      $t1_obj->page_and_sort($t1_obj->schema->resultset('Stations'));
   is $paged_and_sorted->count => 3, 'page_and_sort correctly pages';
   cmp_deeply [map $_->bill, $paged_and_sorted->all],
              [sort map $_->bill, $paged_and_sorted->all],
         'page_and_sort correctly sorts';
   $t1_obj->query->delete_all;
}

PAGINATE: {
   $t1_obj->query->param(limit => 3);
   my $paginated = $t1_obj->paginate($t1_obj->schema->resultset('Stations'));
   cmp_ok $paginated->count, '>=', 3,
      'paginate gave the correct amount of results';

   $t1_obj->query->param(start => 3);
   my $paginated_with_start =
      $t1_obj->paginate($t1_obj->schema->resultset('Stations'));
   my %hash;
   @hash{map $_->id, $paginated->all} = ();
   ok !grep({ exists $hash{$_} } map $_->id, $paginated_with_start->all ),
      'pages do not intersect';
   $t1_obj->query->delete_all;
}

SEARCH: {
   my $searched = $t1_obj->search('Stations');
   cmp_deeply [map $_->id, $searched->all], [3], q{controller_search get's called by search};
   $t1_obj->query->delete_all;
}

SORT: {
   my $sort = $t1_obj->sort('Stations');
   cmp_deeply [map $_->bill, $sort->all], [sort map $_->bill, $sort->all], q{controller_sort get's called by sort};
   $t1_obj->query->delete_all;
}

SIMPLE_SEARCH: {
   $t1_obj->query->param('bill', 'oo');
   my $simple_searched = $t1_obj->simple_search({ rs => 'Stations' });

   is scalar(grep { $_->bill =~ m/oo/ } $simple_searched->all),
      scalar($simple_searched->all), 'simple search found the right results';

   $t1_obj->query->delete_all;

   $t1_obj->query->param( -name => 'bill', -values => ['ubu', 'oo'] );
   $simple_searched = $t1_obj->simple_search({ rs => 'Stations' });

   is scalar(grep { $_->bill =~ m/oo|ubu/ } $simple_searched->all),
      scalar($simple_searched->all), 'simple search found the right results';

   $t1_obj->query->delete_all;
}

SIMPLE_SORT: {
   my $simple_sorted =
      $t1_obj->simple_sort($t1_obj->schema->resultset('Stations'));
   cmp_deeply [map $_->id, $simple_sorted->all], [1..26], 'default sort is id';

   $t1_obj->query->param(dir => 'asc');
   $t1_obj->query->param(sort => 'bill');
   $simple_sorted =
      $t1_obj->simple_sort($t1_obj->schema->resultset('Stations'));
   cmp_deeply [map $_->bill, $simple_sorted->all],
              [sort map $_->bill, $simple_sorted->all], 'alternate sort works';

   $t1_obj->query->param(dir => 'desc');
   $simple_sorted =
      $t1_obj->simple_sort($t1_obj->schema->resultset('Stations'));
   cmp_deeply [map $_->bill, $simple_sorted->all],
              [reverse sort map $_->bill, $simple_sorted->all],
         'alternate sort works';
   $t1_obj->query->delete_all;
}

PAGE_SIZE: {
   my $paginated = $t1_obj->paginate($t1_obj->schema->resultset('Stations'));
   is $paginated->count, 25, 'default page size is 25';

   $t1_obj->dbic_config({
      schema    => 'CAPDBICTest::Schema',
      page_size => 20,
   });

   $paginated = $t1_obj->paginate($t1_obj->schema->resultset('Stations'));
   is $paginated->count, 20, 'default page size can be changed with dbic_config';
}

SIMPLE_DELETION: {
   $t1_obj->query->param('to_delete', 1, 2, 3);
   cmp_bag [map $_->id, $t1_obj->schema->resultset('Stations')->all] => [1..26],
      'values are not deleted';
   my $simple_deletion = $t1_obj->simple_deletion({ rs => 'Stations' });
   cmp_bag $simple_deletion => [1,2,3], 'values appear to be deleted';
   cmp_bag [map $_->id, $t1_obj->schema->resultset('Stations')->all] => [4..26],
      'values are deleted';
   $t1_obj->query->delete_all;
}

done_testing;
