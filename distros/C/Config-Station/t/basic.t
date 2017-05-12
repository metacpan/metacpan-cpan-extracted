#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp 'tmpnam';

use Config::Station;

sub load {
   Config::Station->new(
      env_key      => 'A',
      config_class => 'A::Config',
   )->load
}

{
   ok(my $c = load(), 'Config loads');
   ok(!$c->id && !$c->name, 'Config is blank');
}

{
   local $ENV{A_ID} = 1;
   local $ENV{A_NAME} = 'frew';
   ok(my $c = load(), 'Config loads');
   is($c->id, 1, 'id set from env');
   is($c->name, 'frew', 'name set from env');
}

{
   local $ENV{FILE_A} = 't/config.json';
   local $ENV{A_ID} = 1;
   ok(my $c = load(), 'Config loads');
   is($c->id, 1, 'id set from env');
   is($c->name, 'herp', 'name set from file');
}

{
   local $ENV{FILE_A} = 't/config.json';
   local $ENV{A_ID} = 1;
   local $ENV{A_NAME} = 'wins';
   ok(my $c = load(), 'Config loads');
   is($c->name, 'wins', 'env overrides file');
}

my $tmp = tmpnam();
{
   local $ENV{FILE_A} = $tmp;
   local $ENV{A_ID} = 1;
   local $ENV{A_NAME} = 'dwarznot';
   ok(my $c = load(), 'Config loads');
   is($c->name, 'dwarznot', 'env overrides file');

   Config::Station->new(
      env_key      => 'A',
      config_class => 'A::Config',
   )->store($c)
}

{
   local $ENV{FILE_A} = $tmp;
   ok(my $c = load(), 'Config loads');
   is($c->name, 'dwarznot', 'store worked');
}

unlink $tmp;

done_testing;

BEGIN {
   package A::Config;

   use Moo;

   has [qw( name id )] => ( is => 'ro' );

   sub serialize { +{ map { $_ => $_[0]->$_ } qw( name id ) } }
}
