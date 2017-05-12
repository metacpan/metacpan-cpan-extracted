#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Dancer::Plugin::GearmanXS;
use Gearman::XS qw/:constants/;

my $client = Gearman::XS::Client->new;
$client->set_timeout(2000);
$client->add_server( '127.0.0.1', 4730 );

( $client->echo("Test") == GEARMAN_SUCCESS )
  or plan skip_all => "Need gearman server running. Error echo: " . $client->error;

diag "Gearman is running...";
ok(1);

done_testing;
