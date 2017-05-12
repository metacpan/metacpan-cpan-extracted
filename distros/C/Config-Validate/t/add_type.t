#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::AddType;

use base qw(Test::Class);
use Test::More;

use Config::Validate;

sub setup :Test(setup => 1) {
  my ($self) = @_;
  $self->{schema} = { test => { type => 'test_type' } };
  $self->{cv} = Config::Validate->new();
  isa_ok($self->{cv}, 'Config::Validate');
  
  $self->{counter} = 0;
  $self->{callback} = sub { $self->{counter}++ };
  
  return;
}

sub no_args :Test {
  my ($self) = @_;

  eval { $self->{cv}->add_type(); };
  like($@, qr/Mandatory parameter 'name' missing in call/i, 
       "No argument test");
  return;
}

sub name_only :Test {
  my ($self) = @_;

  eval { $self->{cv}->add_type(name => 'name_only'); };
  like($@, qr/No callbacks defined for type 'name_only'/i, 
       "Name only test");
  return;
}

sub init_hook :Test(2) {
  my ($self) = @_;

  $self->{cv}->add_type(name => 'test_type',
                        init => $self->{callback},
                       );
  $self->{schema}{test}{type} = 'integer';
  $self->{cv}->schema($self->{schema});
  
  eval { $self->{cv}->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($self->{counter}, 1, "init ran");

  return;
}

sub finish_hook :Test(2) {
  my ($self) = @_;

  $self->{cv}->add_type(name => 'test_type',
                        finish => $self->{callback},
                       ); 
  $self->{schema}{test}{type} = 'integer';
  $self->{cv}->schema($self->{schema});

  eval { $self->{cv}->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($self->{counter}, 1, "finish ran");

  return;
}

sub validate :Test(2) {
  my ($self) = @_;

  $self->{cv}->add_type(name => 'test_type',
                        validate => $self->{callback},
                       ); 
  $self->{cv}->schema($self->{schema});

  eval { $self->{cv}->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($self->{counter}, 1, "callback ran");

  return;
}

sub duplicate_type :Test(4) {
  my ($self) = @_;

  $self->{cv}->add_type(name => 'test_type',
                        validate => $self->{callback},
                       ); 
  $self->{cv}->schema($self->{schema});

  eval { $self->{cv}->validate({test => 1}); };
  is($@, '', "validate completed without error");
  is($self->{counter}, 1, "callback ran first time");

  eval {
    $self->{cv}->add_type(name => 'test_type',
                          validate => $self->{callback},
                         ); 
  };
  like($@, qr/test/, "validate completed without error");
  is($self->{counter}, 1, "callback ran once");

  return;
}
