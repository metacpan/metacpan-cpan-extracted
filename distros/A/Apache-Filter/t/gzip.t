#!/usr/bin/perl

$|=1;
use strict;
use lib 't/lib';  # Until my changes are merged into the main distro
use Apache::test qw(skip_test have_httpd test);
use Test;

BEGIN {
  skip_test unless have_httpd;
  skip_test unless eval{require Apache::Compress};
  plan tests => 3;
}

my %requests = 
  (
   3  => '/docs/compress.cp',
   4  => {uri=>'/docs/compress.cp',
          headers=>{'Accept-Encoding' => 'gzip'},
         },
  );

my %special_tests = 
  (
   3  => { 'test' => sub { !defined($_[1]->header('Content-Encoding')) } },
   4  => { 'test' => sub { $_[1]->header('Content-Encoding') =~ /gzip/ } },
  );

ok(1); # Loaded successfully

foreach my $testnum (sort {$a<=>$b} keys %requests) {
  &test_outcome(Apache::test->fetch($requests{$testnum}), $testnum);
}

#############################

sub test_outcome {
  my ($response, $i) = @_;
  
  my $content = $response->content;
  $content = $special_tests{$i}{content}->($content, $response)
    if $special_tests{$i}{content};
  
  if ($special_tests{$i}{'test'}) {
    ok $special_tests{$i}{'test'}->($content, $response);
  } else {
    ok $content, scalar `cat t/docs.check/$i`;
  }
}
