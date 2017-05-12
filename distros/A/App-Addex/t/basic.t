#!perl
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;

use_ok('App::Addex');

my @calls;

my $callback = sub {
  my ($self, $addex, $entry) = @_;
  push @calls, ($entry->emails)[0]->address;
};

my $addex = App::Addex->new({
  classes => {
    addressbook => 'App::Addex::AddressBook::Test',
    output      => [ 'App::Addex::Output::Callback' ],
  },
  'App::Addex::Output::Callback' => {
    callback => $callback,
  },
});

isa_ok($addex, 'App::Addex');

$addex->run;

is(@calls, 6, "callback called twice");

eval { App::Addex->new; };

like(
  $@,
  qr/no addressbook class/,
  "exception thrown when no addressbook class given",
);

eval {
  App::Addex->new({
    classes => { addressbook => 'App::Addex::AddressBook::Test' }
  });
};

like(
  $@,
  qr/no output class/,
  "exception thrown when no output classes given",
);

eval {
  App::Addex->new({
    classes => {
      addressbook => 'App::Addex::AddressBook::Test',
      output      => [ 'App::Addex::FailsToLoad' ],
    }
  });
};

like(
  $@,
  qr/FailsToLoad/,
  "if a plugin fails to load, the exception is propagated",
);
