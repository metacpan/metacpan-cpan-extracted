# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Template;
use DBIx::RoboQuery;

my $pod_example =
[
  q|color == 'red'|,
  q|color == 'green'|,
  q|smell == 'good'|
];
my $place =
[
  q|place == 'here'|,
  q|place == 'there' OR place == 'over there' OR place == 'back here'|
];
my $fruit = [
  q|name == 'orange'|,
  q|color == 'green'|,
  q|stem|
];
my $_private = [
  q|_private == 1|,
  q|_private == 2|,
];
my @tests = (
  # [ winning record (starting from 1), ["rule", "rule"], {r => 1}, {r => 2} ]
  [
    2, $pod_example,
    {color => 'blue',  smell => 'good'},
    {color => 'green', smell => 'bad'}
  ],
  [
    2, $pod_example,
    {color => 'blue',   smell => 'ok'},
    {color => 'orange', smell => 'good'},
    {color => 'yellow', smell => 'bad'}
  ],
  [
    3, $pod_example,
    {color => 'blue',  smell => 'ok'},
    {color => 'green', smell => 'bad'},
    {color => 'red',   smell => 'ok'}
  ],
  [
    2, $place,
    {place => 'nowhere', name => 'Gourd'},
    {place => 'here', name => 'Jimmy'},
    {place => 'over there', name => 'Jerry'}
  ],
  [
    1, $place,
    {place => 'here', name => 'Jimmy'},
    {place => 'over there', name => 'Jerry'},
    {place => 'nowhere', name => 'Gourd'}
  ],
  [
    3, $place,
    {place => 'nowhere', name => 'Gourd'},
    {place => 'over there', name => 'Jerry'},
    {place => 'here', name => 'Jimmy'}
  ],
  [
    2, $place,
    {place => 'there', name => 'Eric'},
    {place => 'over there', name => 'Bob'},
    {place => 'nowhere', name => 'Goober'}
  ],
  [
    3, $place,
    {place => 'nowhere', name => 'Goober'},
    {place => 'nowhere', name => 'Eric'},
    {place => 'nowhere', name => 'Bob'}
  ],
  [
    2, $fruit,
    {name => 'grape',  color => 'red',    stem => 0},
    {name => 'apple',  color => 'red',    stem => 1},
    {name => 'banana', color => 'yellow', stem => 0}
  ],
  [
    2, $fruit,
    {name => 'grape',  color => 'red',    stem => 0},
    {name => 'orange', color => 'orange', stem => 0},
    {name => 'banana', color => 'green',  stem => 0}
  ],
  [
    3, $fruit,
    {name => 'grape',  color => 'red',    stem => 0},
    {name => 'pear',   color => 'yellow', stem => 0},
    {name => 'banana', color => 'yellow', stem => 0}
  ],
  [
    2, $_private,
    {_private => 3, allow_priv => 1},
    {_private => 1, allow_priv => 1},
    {_private => 2, allow_priv => 1},
  ],
  [
    1, $_private,
    {_private => 2, allow_priv => 1},
    {_private => 3, allow_priv => 1},
    {_private => 4, allow_priv => 1},
  ],
  # without deactivating private vars these will always pick the last
  [
    3, $_private,
    {_private => 3},
    {_private => 1},
    {_private => 2},
  ],
  [
    3, $_private,
    {_private => 2},
    {_private => 3},
    {_private => 4},
  ],
);

foreach my $test ( @tests ){
  my $p = shift @$test;
  my $prefs = shift @$test;

  my @args = (sql => '');

  # where are you Test::Routine?
  my $expect_err = 0;
  if( $test->[0]->{allow_priv} ){
    push @args, (template_private_vars => undef);
  }
  elsif( $test->[0]->{_private} ){
    $expect_err = 1;
  }

  my $desc = join ' / ', @$prefs;
  my $cmp = sub { cmp_pref(shift, $test, $p, $desc, $expect_err); };

  my $q = DBIx::RoboQuery->new(@args);
  $q->prefer(@$prefs);
  my $r2 = $q->resultset;

  is_deeply($r2->{preferences}, $prefs, 'preferences ready');

  {
    my $preferred = eval { $r2->preference(@$test) };
    my $e = $@;
    if( $expect_err ){
      like($e, qr/\Qvar.undef error - undefined variable: _private\E/, "error for $desc");
    }
    else {
      is_deeply($preferred, $$test[$p-1], "expected record for $desc");
    }
  }
}

done_testing;
