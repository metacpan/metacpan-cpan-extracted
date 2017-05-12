#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;

use My::Schema::DataDictionary qw(PK NAME SHORT_NAME);

cmp_deeply(
  PK,
  { data_type         => 'integer',
    is_nullable       => 0,
    is_auto_increment => 1,
  }
);

cmp_deeply(
  PK(is_nullable => 1),
  { data_type         => 'integer',
    is_nullable       => 1,
    is_auto_increment => 1,
  }
);

cmp_deeply(
  NAME,
  { data_type   => 'varchar',
    is_nullable => 0,
    size        => 100,
  }
);

cmp_deeply(
  SHORT_NAME,
  { data_type   => 'varchar',
    is_nullable => 0,
    size        => 40,
  }
);

cmp_deeply(
  NAME(size => 200),
  { data_type   => 'varchar',
    is_nullable => 0,
    size        => 200,
  }
);

done_testing();
