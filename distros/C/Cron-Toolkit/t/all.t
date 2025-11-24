#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;
use Time::Moment;
use lib 'lib';
use Cron::Toolkit;

my $json  = do { local $/; open my $fh, '<', 't/data/cron_tests.json' or die $!; <$fh> };
my $tests = decode_json($json);

my $valid = grep { !$_->{invalid} } @$tests;

for my $t (@$tests) {
   next if $t->{invalid};

   my $c = eval {
      my $obj = Cron::Toolkit->new( expression => $t->{expr} );
      $obj->time_zone( $t->{tz} )          if $t->{tz};
      $obj->utc_offset( $t->{utc_offset} ) if exists $t->{utc_offset} && defined $t->{utc_offset};
      $obj;
   };

   ok($c, "tree") or diag "Error: $@";
   diag $c->dump_tree;

   SKIP: {
      my $string = $c->as_string;
      my $quartz_string = $c->as_quartz_string;
      my $describe = $c->describe;
      my $base = $t->{base_epoch};
      my $next = $c->next($base);
      my $prev = $c->previous($base);
      my $utc_offset = $c->utc_offset;

      diag "string: $string";
      diag "quartz string: $quartz_string";
      diag "describe: $describe";
      diag "base: $t->{base_epoch}";
      diag "utc_offset: $utc_offset";
      diag "next: $next" if $next;
      diag "prev: $prev" if $prev;

      is( $string, $t->{as_string}, "as_string");
      is( $quartz_string, $t->{as_quartz_string}, "as_quartz_string");
      is( $describe, $t->{desc}, "describe");
      is( $next, $t->{next_epoch}, "next" );
      is( $prev, $t->{prev_epoch}, "previous" );
      diag "\n";
   }
}

done_testing;
