#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::AddDefaultType;

use base qw(Test::Class);
use Test::More;

use Config::Validate;

sub teardown :Test(teardown) {
  Config::Validate::reset_default_types();
}

sub no_args :Test {
  eval { Config::Validate::add_default_type(); };
  like($@, qr/Mandatory parameter 'name' missing in call/i, 
       "No argument test");
  return;
}

sub name_only :Test {
  eval { Config::Validate->add_default_type(name => 'name_only'); };
  like($@, qr/No callbacks defined for type 'name_only'/i, 
       "Name only test");
  return;
}

sub validate_fail_on_type_with_init_hook :Test(2) {
  my $init_ran = 0;
  Config::Validate->add_default_type(name => 'init_hook',
                                     init => sub { $init_ran++ },
                                    ); 

  my $cv = Config::Validate->new(schema => {test => {type => 'init_hook'}});
  eval { $cv->validate({test => 1}); };
  like($@, qr/No callback defined for type 'init_hook'/, 
       "validate failed as expected");
  ok($init_ran, "init ran");

  return;
}

sub init_hook :Test(5) {
  my $init_ran = 0;

  my $schema = { test => { type => 'integer' } };
  my $cfg = { test => 1 };
  my $cb = sub { 
    my ($self_arg, $schema_arg, $cfg_arg) = @_;
    isa_ok($self_arg, 'Config::Validate', 
           "param 1 isa Config::Validate");
    is_deeply($schema, $schema_arg, "param 2 matches"); 
    is_deeply($cfg, $cfg_arg, "param 3 matches"); 
    $init_ran++;
    return;
  };

  Config::Validate->add_default_type(name => 'init_hook',
                                     init => $cb,
                                    ); 

  my $cv = Config::Validate->new(schema => $schema);
  eval { $cv->validate($cfg); };
  is($@, '', "validate completed without error");
  is($init_ran, 1, "init ran once");

  return;
}

sub finish_hook :Test(5) {
  my $finish_ran = 0;

  my $schema = { test => { type => 'integer' } };
  my $cfg = { test => 1 };
  my $cb = sub { 
    my ($self_arg, $schema_arg, $cfg_arg) = @_;
    isa_ok($self_arg, 'Config::Validate', 
           "param 1 isa Config::Validate");
    is_deeply($schema, $schema_arg, "param 2 matches"); 
    is_deeply($cfg, $cfg_arg, "param 3 matches"); 
    $finish_ran++;
    return;
  };

  Config::Validate->add_default_type(name => 'finish_hook',
                                     finish => $cb,
                                    ); 

  my $cv = Config::Validate->new(schema => $schema);
  eval { $cv->validate($cfg); };
  is($@, '', "validate completed without error");
  is($finish_ran, 1, "finish ran once");
  
  return;
}

sub class_method_validate :Test(2) {
  my $counter = 0;
  Config::Validate->add_default_type(name => 'class_method_validate',
                                     validate => sub { $counter++ },
                                    ); 

  my $cv = Config::Validate->new(schema => 
                                 { test => {
                                   type => 'class_method_validate'}
                                 }
                                );

  eval { $cv->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($counter, 1, "callback ran");

  return;
}

sub function_validate :Test(2) {
  my $counter = 0;
  Config::Validate::add_default_type(name => 'function_validate',
                                     validate => sub { $counter++ },
                                    );

  my $cv = Config::Validate->new(schema => 
                                 { test => { 
                                   type => 'function_validate' },
                                 }
                                );

  eval { $cv->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($counter, 1, "callback ran");

  return;
}

sub instance_validate :Test(4) {
  my $cv = Config::Validate->new();

  my $counter = 0;
  $cv->add_default_type(name => 'instance_validate',
                        validate => sub { $counter++ },
                       );

  $cv->schema({ test => { type => 'instance_validate' }});

  eval { $cv->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($counter, 1, "callback ran");

  # Check to make sure it was added to the default table also, by
  # creating a new instance.
  $cv = Config::Validate->new(schema => 
                              { test => { 
                                type => 'instance_validate' },
                              }
                             );

  eval { $cv->validate({test => 1}); };
  is($@, '', "validate completed without error second time");
  is($counter, 2, "callback ran second time");

  return;
}

sub duplicate_type :Test(1) {
  my $counter = 0;
  Config::Validate::add_default_type(name => 'duplicate_type',
                                     validate => sub { },
                                    );
  
  eval {
    Config::Validate::add_default_type(name => 'duplicate_type',
                                       validate => sub { },
                                      );
  };
  like($@, qr/Attempted to add type 'duplicate_type' that already/, 
       "adding duplicate type failed as expected");

  return;
}
