#!/sw/bin/perl

use strict;
use warnings;
use Test::More;

eval 'use Config::General';
plan(skip_all => 'Config::General required for test') if $@;

Test::Class->runtests;

package Test::DataPath;

use base qw(Test::Class);
use Test::More;
use Config::Validate;

sub normal :Test(1) {
  my $cv = Config::Validate->new(schema => {test => { type => 'boolean' } });
  my $result;
  my $cg = Config::General->new(-String => "test = yes");
  eval { 
    $result = $cv->validate(config => $cg);
  };
  is($@, '', 'boolean from Config::General validated correctly.');

  return;
}
