#!/usr/bin/env perl
use strict;
use warnings;

# DBIx::Loop on Mojo::IOLoop, promise style: to_native bridges a query future
# to a Mojo::Promise.
#
#   perl examples/mojo.pl

use File::Temp ();
use Mojo::IOLoop;
use DBIx::Loop;
use DBIx::Loop::Loop::Mojo;

my $dir = File::Temp->newdir;
my $ad  = DBIx::Loop::Loop::Mojo->new;
my $db  = DBIx::Loop->connect(
    "dbi:SQLite:dbname=$dir/demo.db", '', '',
    { RaiseError => 1, PrintError => 0 },
    loop => $ad, workers => 2,
);

my $setup = $db->do("CREATE TABLE pets (id INTEGER PRIMARY KEY, name TEXT)");
$ad->await($setup);

$ad->to_native($db->do("INSERT INTO pets (name) VALUES (?)", 'milo'))
   ->then(sub { $ad->to_native($db->query("SELECT id, name FROM pets")) })
   ->then(sub {
        my ($res) = @_;
        printf "pet: id=%d name=%s\n", @{ $res->{rows}[0] };
    })
   ->wait;

$db->disconnect;
