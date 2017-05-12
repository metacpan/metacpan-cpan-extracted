#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->parent->parent->subdir('t', 'lib')->stringify;

use Test::DBIx::Class;

fixtures_ok 'basic', 'installed the basic fixtures from configuration files';

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  lives_and {
    cmp_deeply(
      $artist1->birthday,
      (
        Isa('DateTime')
        & methods(
            ymd => '2010-06-21',
          )
      )
    );
  } "inflation works: value returned by 'birthday' accessor "
  . "is DateTime('2010-06-21')";

  lives_ok {
    $artist1->birthday('2010-01-02');
  } "calling the 'birthday' accessor to set an inflated value does not die";

  lives_and {
    cmp_deeply(
      $artist1->get_column('birthday'),
      '2010-01-02',
    );
  } "deflation works: value returned by get_column('birthday') "
    . "is '2010-01-02' (string)";
}

done_testing;
