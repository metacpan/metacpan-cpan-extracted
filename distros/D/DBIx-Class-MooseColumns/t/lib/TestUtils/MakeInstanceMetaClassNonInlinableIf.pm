package TestUtils::MakeInstanceMetaClassNonInlinableIf;

use strict;
use warnings;

use Class::MOP;

sub import {
  my ($pkg, $make_non_inlinable) = @_;

  return unless $make_non_inlinable;

  my $meta = caller->meta->instance_metaclass->meta;
  my $immutable_options
    = $meta->is_immutable ? { $meta->immutable_options } : undef;
  $meta->make_mutable if $immutable_options;

  $meta->add_around_method_modifier(
    is_inlinable => sub { 0 }
  );

  $meta->make_immutable(%$immutable_options) if $immutable_options;
}

1;
