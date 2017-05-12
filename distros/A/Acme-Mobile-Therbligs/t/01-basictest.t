#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 100;

use_ok('Acme::Mobile::Therbligs', '0.04');

my $obj = new Acme::Mobile::Therbligs();
ok(defined $obj);

foreach my $key (qw( a d g j m p t w )) {
  ok($obj->count_therbligs($key)     == 1);
  ok($obj->count_therbligs(uc($key)) == 1);
}

foreach my $key (qw( b e h k n q u x 0 )) {
  ok($obj->count_therbligs($key)     == 2);
  ok($obj->count_therbligs(uc($key)) == 2);
}

foreach my $key (qw( c f i l o r v y )) {
  ok($obj->count_therbligs($key)     == 3);
  ok($obj->count_therbligs(uc($key)) == 3);
}

foreach my $key (qw( s z )) {
  ok($obj->count_therbligs($key)     == 4);
  ok($obj->count_therbligs(uc($key)) == 4);
}

ok($obj->count_therbligs("") == 0);
ok($obj->count_therbligs("this is silly") == 37);

ok(count_therbligs("") == 0);
ok(count_therbligs("this is silly") == 37);


ok(count_therbligs("this is silly",1) == 39);

ok(count_therbligs("This is silly",1) == 37);
ok(count_therbligs("THIS is silly",1) == 39);

ok(count_therbligs("This. Is silly",1) == 38);
ok(count_therbligs("This. is silly",1) == 40);
ok(count_therbligs("This. IS silly",1) == 40);
ok(count_therbligs("This. IS SILLY",1) == 39);

use IO::File;
{
  my $fh = new IO::File('./sample-1.yml');
  $obj = new Acme::Mobile::Therbligs($fh, {
    NO_SHIFT => 1,
  });
  ok(defined $obj, 'Custom configuration file');

  foreach my $key (qw( A D G J M P T W )) {
    ok($obj->count_therbligs($key,1)     == 1);
    ok($obj->count_therbligs(uc($key),1) == 1);
    ok($obj->count_therbligs(lc($key),0) == 1);
    ok($obj->count_therbligs(lc($key),1) != 1);
  }

}


