package Attribute::GlobalEnable::TestModule;

use strict;
use warnings;
#use Exporter;
#use base qw( Exporter );

use Attribute::GlobalEnable(
  ENABLE_CHK  => \%ENV,
  ENABLE_ATTR => { Test => 'TEST_MODULE', Bench => 'BENCH_ME' },
  ENABLE_FLAG => { Test => ['TEST_FLAG_A'] },
);

use base qw( Attribute::GlobalEnable );

sub attrTest_1 {
  my $pak = shift();
  my $ref = $_[2];
  my $sub = $_[1];

  return sub {
    return &$ref('Test_1');
  }
}

sub attrTest_2 {
  my $pak = shift();
  my $ref = $_[2];
  my $sub = $_[1];

  return sub {
    return &$ref('Test_2');
  }
}

sub attrTest_3 {
  my $pak = shift();
  my $ref = $_[2];
  my $sub = $_[1];

  return sub {
    return &$ref('Test_3');
  }
}

sub ourTest_1 {
  my $message = shift();

  return "test 1: $message";
}

sub ourTest_2 {
  my $message = shift();

  return "test 2: $message";
}



sub attrBench_1 {
  my $pak = shift();
  my $ref = $_[2];
  my $sub = $_[1];

  return sub {
    return &$ref('Bench_1');
  }
}


sub ourBench_1 {
  my $message = shift();
  return "bench 1: $message";
}


1;

