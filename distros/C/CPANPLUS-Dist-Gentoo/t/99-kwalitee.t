#!perl

use strict;
use warnings;

use Test::More;

eval { require Parse::RecDescent; 'Parse::RecDescent'->VERSION('1.967006') }
  or plan skip_all => 'Parse::RecDescent version 1.967006 or greater required';

eval { require Module::ExtractUse; 'Module::ExtractUse'->VERSION('0.24') }
  or plan skip_all => 'Module::ExtractUse version 0.24 or greater required';

eval { require Test::Kwalitee; 1 }
  or plan skip_all => 'Test::Kwalitee required';

SKIP: {
 eval { Test::Kwalitee->import(); };
 if (my $err = $@) {
  1 while chomp $err;
  require Test::Builder;
  my $Test = Test::Builder->new;
  my $plan = $Test->has_plan;
  $Test->skip_all($err) if not defined $plan or $plan eq 'no_plan';
  skip $err => $plan - $Test->current_test;
 }
}
