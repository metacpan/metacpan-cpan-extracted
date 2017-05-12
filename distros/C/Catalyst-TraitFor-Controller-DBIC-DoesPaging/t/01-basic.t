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
unlink 'test.db' if -e 'test.db';
my $schema = TestApp::Schema->connect( 'dbi:SQLite:dbname=test.db' );
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

$schema->populate(MultiPk => [
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

PAGE_AND_SORT: {
   my $data = from_json(get('/test_page_and_sort?limit=3&dir=asc&sort=bill'));
   cmp_ok scalar @{$data}, '<=', 3, 'page_and_sort correctly pages';
   cmp_deeply [map $_->{bill}, @{$data}],
              [sort map $_->{bill}, @{$data}],
         'page_and_sort correctly sorts';
}

PAGINATE: {
   my $data = from_json(get('/test_paginate?limit=3'));
   cmp_ok scalar @{$data}, '<=', 3,
      'paginate gave the correct amount of results';

   my $data2 = from_json(get('/test_paginate?limit=3&start=3'));
   my %hash;
   @hash{map $_->{id}, @{$data}} = ();
   ok !grep({ exists $hash{$_} } map $_->{id}, @{$data2} ),
      'pages do not intersect';
}

SEARCH: {
   my $data = from_json(get('/test_search'));
   cmp_deeply [map $_->{id}, @{$data}], [3], q{controller_search get's called by search};
}

SORT: {
   my $data = from_json(get('/test_sort'));
   cmp_deeply [map $_->{bill}, @{$data}], [sort map $_->{bill}, @{$data}], q{controller_sort get's called by sort};
}

SIMPLE_SEARCH: {
   my $data = from_json(get('/test_simple_search?bill=oo'));
   is scalar(grep { $_->{bill} =~ m/oo/ } @{$data}),
      scalar(@{$data}), 'simple search found the right results';

   $data = from_json(get('/test_simple_search?bill=oo&bill=ubu'));
   is scalar(grep { $_->{bill} =~ m/oo|ubu/ } @{$data}),
      scalar(@{$data}), 'simple search found the right results';
}

SIMPLE_SORT: {
   my $data = from_json(get('/test_simple_sort'));
   cmp_deeply [map $_->{id}, @{$data}], [1..9], 'default sort is id';

   $data = from_json(get('/test_simple_sort?dir=asc&sort=bill'));
   cmp_deeply [map $_->{bill}, @{$data}],
              [sort map $_->{bill}, @{$data}], 'alternate sort works';

   $data = from_json(get('/test_simple_sort?dir=desc&sort=bill'));
   cmp_deeply [map $_->{bill}, @{$data}],
              [reverse sort map $_->{bill}, @{$data}],
         'alternate sort works';
}

SIMPLE_DELETION: {
   cmp_bag [map $_->id, $schema->resultset('Stations')->all] => [1..9], 'values are not deleted';
   my $data = from_json(get('/test_simple_deletion?'.join q{&}, map "to_delete=$_", 1,2,3 ));
   cmp_bag $data => [1,2,3], 'values appear to be deleted';
   cmp_bag [map $_->id, $schema->resultset('Stations')->all] => [4..9], 'values are deleted';
}

MULTIPK_DELETION: {
   cmp_bag [map $_->id, $schema->resultset('MultiPk')->all] => [1..9], 'values are not deleted';
   my $data = from_json(get('/test_simple_deletion_multipk?'.join q{&}, map "to_delete=$_", ( 'awesome,bitchin','cool,bad','tubular,righeous' )));
   cmp_bag $data => [ 'awesome,bitchin','cool,bad','tubular,righeous' ], 'values appear to be deleted';
   cmp_bag [map $_->id, $schema->resultset('MultiPk')->all] => [4..9], 'values are deleted';
}

done_testing;

