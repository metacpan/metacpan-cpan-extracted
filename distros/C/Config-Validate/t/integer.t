#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::Integer;

use base qw(Test::Class);
use Test::More;
use Data::Dumper;

use Config::Validate;

sub positive :Test {
my $cv = Config::Validate->new;

  $cv->schema({ testinteger => { type => 'integer' }});
  my $value = { testinteger => 1 };
  eval { $cv->validate($value) };
  is ($@, '', 'normal case succeeded');
  return;
}

sub negative :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testinteger => { type => 'integer' }});
  my $value = { testinteger => -1 };
  eval { $cv->validate($value) };
  is ($@, '', 'negative case succeeded');
  return;
}

sub success_with_limits :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testinteger => { type => 'integer',
                                min => 1,
                                max => 50,
                              }});
  my $value = { testinteger => 25 };
  eval { $cv->validate($value) };
  is ($@, '', 'size limits succeeded');
  return;
}

sub failure_max_size :Test {
  my $cv = Config::Validate->new;
  $cv->schema({testinteger => { type => 'integer',
                               min => 1,
                               max => 1,
                             }});
  my $value = { testinteger => 50 };
  eval { $cv->validate($value) };
  like($@, qr/50 is larger than the maximum allowed \(1\)/, 
       "max failed (expected)");
  return;
}

sub failure_min_size :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testinteger => { type => 'integer',
                                min => 1000,
                                max => 1000,
                              }});
  my $value = { testinteger => 25 };
  eval { $cv->validate($value) };
  like($@, qr/25 is smaller than the minimum allowed \(1000\)/, 
       "min failed (expected)");
  return;
}

sub failure_not_a_number :Test {
  my $cv = Config::Validate->new;
  $cv->schema({ testinteger => { type => 'integer',
                               }});
  my $value = { testinteger => 'not an integer' };
  eval { $cv->validate($value) };
  like($@, qr/should be an integer, but has value of 'not an integer'/, 
       "not an integer (expected)");
  return;
}

