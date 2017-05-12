#!perl

use strict;
use warnings;

use Test::More tests => 7;

my $class = 'App::Addex::AddressBook::Abook';

use_ok($class);

my $abook = $class->new({
  filename     => 't/data/addressbook',
  folder_field => 'custom1',
  sig_field    => 'custom3',
});

isa_ok($abook, $class);

my @entries = $abook->entries;

is(@entries, 2, "there are two entries: 3 minus 1 with no emails");

is_deeply(
  [ $entries[0]->emails ],
  [ qw(jsmith@example.com joeysmith@example.com) ],
  "correct email addresses for first entry",
);

is($entries[0]->nick, 'joey', "correct nick for joe");

is($entries[0]->field('folder'), 'joe', "correct folder for joe");

is($entries[1]->field('folder'), 'family/wife', "correct folder for wifey");
