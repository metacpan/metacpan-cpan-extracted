#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::Float;
use base qw(Test::Class);
use Test::More;
use Data::Dumper;

use Config::Validate;

sub positive :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testfloat => { type => 'float' }});
  my $value = { testfloat => 1.1 };
  eval { $cv->validate($value) };
  is ($@, '', 'normal case succeeded');
  return;
}

sub negative :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testfloat => { type => 'float' }});
  my $value = { testfloat => -1.1 };
  eval { $cv->validate($value) };
  is ($@, '', 'negative case succeeded');
  return;
}

sub success_with_limits :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testfloat => { type => 'float',
                                min => 1.1,
                                max => 50.1,
                              }});
  my $value = { testfloat => 25.5 };
  eval { $cv->validate($value) };
  is ($@, '', 'size limits succeeded');
  return;
}

sub failure_with_max :Test {
  my $cv = Config::Validate->new;
  $cv->schema({testfloat => { type => 'float',
                               min => 1.1,
                               max => 1.1,
                             }});
  my $value = { testfloat => 50.1 };
  eval { $cv->validate($value) };
  like($@, qr/50.1\d* is larger than the maximum allowed \(1.1\d*\)/, 
       "max failed (expected)");
  return;
}

sub failure_with_min :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testfloat => { type => 'float',
                                min => 1000.1,
                                max => 1000.1,
                              }});
  my $value = { testfloat => 25.5 };
  eval { $cv->validate($value) };
  like($@, qr/25.5\d* is smaller than the minimum allowed \(1000.1\d*\)/, 
       "min failed (expected)");
  return;
}

sub failure_not_a_number :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testfloat => { type => 'float',
                                min => 1000.1,
                                max => 1000.1,
                              }});
  my $value = { testfloat => 'not a float' };
  eval { $cv->validate($value) };
  like($@, qr/should be an float, but has value of 'not a float'/, 
       "not a float (expected)");
  return;
}

