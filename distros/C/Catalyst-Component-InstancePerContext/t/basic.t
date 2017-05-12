#!/usr/bin/perl -w

use strict;
use warnings;
use Scalar::Util qw/refaddr/;

{
  package TestModule;
  use Moose;
}

{
  package TestComponent;

  use Moose;
  with "Catalyst::Component::InstancePerContext";

  sub build_per_context_instance {
    return TestModule->new;
  }
}

{
  package MyMockContext;
  use Moose;
  has stash => (isa => 'HashRef', is => 'ro', required => 1, default => sub{{}});
}

use Test::More tests => 7;

my $ctx1 = MyMockContext->new;
isa_ok($ctx1, 'MyMockContext');

my $component = TestComponent->new;
isa_ok($component, 'TestComponent');
can_ok($component, 'ACCEPT_CONTEXT', 'build_per_context_instance');

my $instance = TestComponent->ACCEPT_CONTEXT($ctx1);
is(refaddr( TestComponent->ACCEPT_CONTEXT($ctx1) ), refaddr $instance,
   'does not create second instance');
is(refaddr $ctx1->stash->{"__InstancePerContext_TestComponent"}, refaddr $instance,
   'Correct key storage');

my $instance2 = $component->ACCEPT_CONTEXT($ctx1);
my $addr = refaddr $component;
is(refaddr $component->ACCEPT_CONTEXT($ctx1), refaddr $instance2,
   'does not create second instance');
is(refaddr $ctx1->stash->{"__InstancePerContext_${addr}"}, refaddr $instance2,
   'Correct key storage');


