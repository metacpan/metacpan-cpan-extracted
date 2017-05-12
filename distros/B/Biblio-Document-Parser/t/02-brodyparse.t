#!/bin/env perl

BEGIN {
  unless(grep /blib/, @INC) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
  }
}

use strict;
use Test;

BEGIN { plan tests => 4 }

{

  use Biblio::Document::Parser::Brody;
  my $doc_parse = new Biblio::Document::Parser::Brody(-debug=>0);
  ok(open(FILE,"t/test2.txt"));
  my @references = $doc_parse->parse(\*FILE);
  close(FILE);
  ok(scalar @references == 5);
  ok($references[0] =~ /A Reference$/);
  ok($references[2] =~ /Yet another reference$/);
}
