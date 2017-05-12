#!perl
use warnings;
use strict;
use Bot::BasicBot::Pluggable::Store::Storable;
use Bot::BasicBot::Pluggable::Store::DBI;

my $from = Bot::BasicBot::Pluggable::Store::Storable->new;
my $to =   Bot::BasicBot::Pluggable::Store::DBI->new(
  dsn => "dbi:mysql:test",
  table => "basicbot",
  user => "root",
);

$to->restore( $from->dump );
