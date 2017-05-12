#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::Basic;

use base qw(Test::Class);
use Test::More;
use Data::Dumper;
use Storable qw(dclone);

use Config::Validate qw(validate);

sub missing_arguments :Test(2) {
  eval { validate() };
  like($@, qr/requires at least two arguments/, 
       "Failed with no arguments (expected)");
  eval { validate({}) };
  like($@, qr/requires at least two arguments/, 
       "Failed with one argument (expected)");
  return;
}

sub no_type_specified :Test(1) {
  my $cv = Config::Validate->new;
  $cv->schema({test => {}});
  eval { $cv->validate({blah => 1}) };
  like($@, qr/No type specified for \[\/test\]/, 
       'no type specified: failed (expected)');
  return;
}

sub invalid_type_specified :Test(1) {

  my $cv = Config::Validate->new;
  $cv->schema({test => { type => 'blah' }});
  eval { $cv->validate({blah => 1}) };
  like($@, qr/Invalid type 'blah' specified for \[\/test\]/, 
       'no type specified: failed (expected)');
  return;
}

sub invalid_key_in_data :Test(1) {
  my $cv = Config::Validate->new;
  $cv->schema({test => { type => 'boolean' }});
  eval { $cv->validate({test => 1, blah2 => 1, blah3 => 1}) };
  like($@, qr/unknown items were found: blah2, blah3/, 
       'invalid key found (expected)');
  return;
}

sub required_key_missing :Test(1) {
  my $cv = Config::Validate->new;
  $cv->schema({test => { type => 'boolean' }});
  eval { $cv->validate({blah2 => 1, blah3 => 1}) };
  like($@, qr/Required item \[\/test\] was not found/, 
       'invalid key found (expected)');
  return;
}

sub mandatory_parameter_not_found :Test(1) {
  my $cv = Config::Validate->new;
  $cv->schema({test => { type => 'boolean',
                         optional => 0,
                       },
              }
             );
  eval { $cv->validate({blah2 => 1, blah3 => 1}) };
  like($@, qr/Required item \[\/test\] was not found/, 
       'invalid key found (expected)');
  return;
}

sub method_works_with_named_params :Test(1) {
  my $cv = Config::Validate->new;
  $cv->schema({test => { type => 'boolean' } });

  eval { $cv->validate(config => { test => 1}) };
  is($@, '', 'boolean validated correctly.');
  return;
}

sub function_works_with_named_params :Test(1) {
  eval { 
    validate(config => { test => 1},
             schema => {test => { type => 'boolean' } },
            );
  };
  is($@, '', 'boolean validated correctly.');
  return;
}
