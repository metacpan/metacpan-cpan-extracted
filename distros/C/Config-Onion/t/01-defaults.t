use strict;
use warnings;

use Test::Exception;
use Test::More;

use Config::Onion;

# GH5: don't die if config is empty
{
  lives_ok { Config::Onion->new->get } q(empty config isn't fatal);
}

# construct bare, then add/retrieve default values
{
  my $cfg = Config::Onion->new;
  isa_ok($cfg, 'Config::Onion', 'construct bare config');
  $cfg->set_default(foo => 1);
  is($cfg->get->{foo}, 1, 'retrieve single value');
  is_deeply($cfg->get, { foo => 1 }, 'retrieve full config');
}

# construct by setting default values
{
  my $cfg = Config::Onion->set_default(bar => 2);
  isa_ok($cfg, 'Config::Onion', 'construct with set_default');
  is($cfg->get->{bar}, 2, 'retrieve value after set_default construction');
}

# override existing defaults with new defaults
{
  my $cfg = Config::Onion->set_default(foo => 3);
  $cfg->set_default(bar => 'baz');
  is($cfg->get->{foo}, 3, 'merge defaults preserves old values');
  is($cfg->get->{bar}, 'baz', 'merge defaults sets new values');
  $cfg->set_default(foo => 'new');
  is($cfg->get->{foo}, 'new', 'merge defaults overwrites old values');
}

# accept defaults as either hash or hashref(s)
{
  my $cfg = Config::Onion->set_default({ a => 1 });
  is($cfg->get->{a}, 1, 'set defaults with hashref');
  $cfg->set_default({ b => 2 }, { c => 3 }, d => 4);
  is_deeply( $cfg->get, { a => 1, b => 2, c => 3, d => 4 },
    'set defaults with mixed hashrefs and hash'
  );
}

done_testing;

