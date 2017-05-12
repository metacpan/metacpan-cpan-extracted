#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::Array;

use base qw(Test::Class);
use Test::More;

use Config::Validate qw(validate);

sub no_subtype :Test {
  my $schema = {arraytest => { type => 'array' }};
  eval { validate({arraytest => [] }, $schema); };
  like($@, qr/No subtype specified for /i);

  return;
}

sub invalid_subtype :Test {
  my $schema = {arraytest => { type => 'array',
                               subtype => 'invalid',
                              }};
  eval { validate({arraytest => [] }, $schema); };
  like($@, qr/Invalid subtype 'invalid' specified for/i);

  return;
}

sub scalar_with_coerce :Test(5) {
  my $schema = {arraytest => { type => 'array',
                               subtype => 'string',
                             }
               };
  my $cv = Config::Validate->new(schema => $schema);

  my $data = { arraytest => "blah" };
  my $result;
  eval { $result = $cv->validate($data) };
  is($@, '', 'validated without error');
  isa_ok($result, 'HASH', 'Returned hash ref');
  isa_ok($result->{arraytest}, 'ARRAY', "string coerced to array");
  is(scalar @{$result->{arraytest}}, 1, "array has a single element");
  is($result->{arraytest}[0], 'blah', "coerced corrently");

  return;
}

sub scalar_without_coerce :Test(1) {
  my $schema = {arraytest => { type => 'array',
                               subtype => 'string',
                             }
               };
  my $cv = Config::Validate->new(schema => $schema,
                                 array_allows_scalar => 0,
                                );

  my $data = { arraytest => "blah" };
  eval { $cv->validate($data) };
  like($@, qr/should be an 'ARRAY', but instead is a 'SCALAR'/, 
       "coercion failed as expected");

  return;
}

sub not_array_ref_or_scalar :Test(1) {
  my $schema = {arraytest => { type => 'array',
                               subtype => 'string',
                             }
               };
  my $cv = Config::Validate->new(schema => $schema);

  my $data = { arraytest => {} };
  eval { $cv->validate($data) };
  like($@, qr/should be an 'ARRAY', but instead is a 'REF'/, 
       "coercion failed as expected");

  return;
}

sub child_with_default :Test(5) {
  my $schema = {arraytest => { type => 'array',
                               subtype => 'string',
                             }
               };
  my $cv = Config::Validate->new(schema => $schema);

  my $result;
  my $testarray = [ qw(abc 123 foo bar) ];
  my $data = { arraytest => $testarray };
  eval { $result = $cv->validate($data) };
  is($@, '', 'array test w/default');
  
  for (my $i = 0; $i < @$testarray; $i++) {
    is($result->{arraytest}[$i], $testarray->[$i], 
       "array content test ($i == $testarray->[$i])");
  }

  return;
}

