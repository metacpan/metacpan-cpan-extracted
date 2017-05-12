use strict;
use warnings;

use Test::More 0.88;

use Data::Hive;
use Data::Hive::Store::Hash;

use Try::Tiny;

sub exception (&) {
  my ($code) = @_;

  return try { $code->(); return } catch { return $_ };
}

isnt(
  exception { Data::Hive->NEW },
  undef,
  "we can't create a hive with no means to make a store",
);

isnt(
  exception { Data::Hive->NEW({}) },
  undef,
  "we can't create a hive with no means to make a store",
);

ok(
  exception {
    my $store = Data::Hive::Store::Hash->new;
    Data::Hive->NEW({ store => $store, store_class => 'Hash' });
  },
  "we can't make a hive with both a store and a store_class",
);

for my $bad (
  [ '(undef)'      => undef ],
  [ 'empty string' => ''    ],
  [ 'array ref'    => []    ],
) {
  my ($str, $val) = @$bad;

  like(
    exception {
      my $hive = Data::Hive->NEW({ store_class => 'Hash' });
      $hive->HIVE($val);
    },
    qr/illegal.+path part/,
    "$str is not a valid path part",
  );
}

like(
  exception { Data::Hive->NEW({ store_class => 'Hash' })->DOESNT_EXIST },
  qr/all-caps method names are reserved/,
  'all-caps method names are reserved',
);

{
  my $hive = Data::Hive->NEW({ store_class => 'Hash' });

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $hive->foo->bar(1)->baz->GET;
  }

  is(@warnings, 1, "we get a warning when passing args to hive descenders");
  like($warnings[0], qr{arguments passed}, "...and it is what we expect");
}


done_testing;
