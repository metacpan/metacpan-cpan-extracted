#!/usr/bin/perl

# This test will start up a real httpd server with Apache::SSI loaded in
# it, and make several requests on that server.

use strict;
use lib 'lib', 't/lib';
use Apache::test;
use Test;

my %requests = 
  (
   3  => '/docs/bare.ssi',
   4  => '/docs/file.ssi',
   5  => '/docs/kid.ssik',
   6  => '/docs/virtual.ssi',
   7  => '/docs/incl_rel.ssi',
   8  => '/docs/incl_rel2.ssi',
   9  => '/docs/set_var.ssi',
   10 => '/docs/xssi.ssi',
   11 => '/docs/include_cgi.ssi/path?query',
   12 => '/docs/if.ssi',
   13 => '/docs/if2.ssi',
   14 => '/docs/escape.ssi',
   15 => '/docs/exec_cmd.ssi',
   16 => '/docs/kid2.ssik',
   17 => '/docs/flastmod.ssi',
   18 => '/docs/virtual.ssif',
   19 => '/docs/set_var2.ssi?query',
  );

my %special_tests = 
  (
   17 => sub {my $year = (localtime)[5]+1900; shift->content =~ /Year: $year/},
  );

plan tests => 2 + keys %requests;

ok 1;
ok 1;  # For backward numerical compatibility

foreach my $i (sort {$a<=>$b} keys %requests) {
  my $response = Apache::test->fetch($requests{$i});
  my $content = $response->content;

  if ($special_tests{$i}) {
    ok $special_tests{$i}->($response);
  } else {
    ok $content, `cat t/docs.check/$i`;
  }
}

