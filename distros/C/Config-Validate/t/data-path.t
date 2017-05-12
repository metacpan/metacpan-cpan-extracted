#!/sw/bin/perl

use strict;
use warnings;
use Test::More;

eval 'use Data::Path';
plan(skip_all => 'Data::Path required for test') if $@;

Test::Class->runtests;

package Test::DataPath;

use base qw(Test::Class);
use Test::More;
use Config::Validate;

sub normal :Test(2) {
  my $cv = Config::Validate->new(schema => {test => { type => 'boolean' } },
                                 data_path => 1);
  my $result;
  eval { 
    $result = $cv->validate(config => { test => 'yes '});
  };
  is($@, '', 'boolean validated correctly.');
  isa_ok($result, 'Data::Path', "results object isa Data::Path");

  return;
}
