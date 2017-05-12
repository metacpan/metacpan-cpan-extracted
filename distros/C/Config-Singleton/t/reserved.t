#!perl -T

use Test::More tests => 2;

use lib 't/lib';

require_ok('Config::Singleton');

eval {
  package YourApp::Config;
  Config::Singleton->import(-setup => {
    template => { import => undef },
  });
};

like(
  $@,
  qr/reserved/,
  "you can't have methods like 'new' or 'import' in template",
);
