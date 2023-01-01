use strict;
use warnings;
package Data::Rx::Type::Perl::Code 0.011;
# ABSTRACT: experimental / perl coderef type
use parent 'Data::Rx::CommonType::EasyNew';

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Rx;
#pod   use Data::Rx::Type::Perl::Code;
#pod   use Test::More tests => 2;
#pod
#pod   my $rx = Data::Rx->new({
#pod     prefix  => {
#pod       perl => 'tag:codesimply.com,2008:rx/perl/',
#pod     },
#pod     type_plugins => [ 'Data::Rx::Type::Perl::Code' ]
#pod   });
#pod
#pod   my $is_code = $rx->make_schema({
#pod     type       => '/perl/code',
#pod   });
#pod
#pod   ok($is_code->check( sub {} ), "a coderef is code");
#pod   ok(! $is_code->check( 1 ),    "1 is not code");
#pod
#pod =head1 ARGUMENTS
#pod
#pod If given, the C<prototype> argument will require that the code has the given
#pod prototype.
#pod
#pod =cut

use Carp ();
use Scalar::Util ();

sub type_uri { 'tag:codesimply.com,2008:rx/perl/code' }

sub guts_from_arg {
  my ($class, $arg, $rx) = @_;
  $arg ||= {};

  for my $key (keys %$arg) {
    next if $key eq 'prototype';
    Carp::croak(
      "unknown argument $key in constructing " . $class->type_uri .  " type",
    );
  }

  my $prototype_schema
    = (! exists $arg->{prototype})
    ? undef

    : (! defined $arg->{prototype})
    ? $rx->make_schema('tag:codesimply.com,2008:rx/core/nil')

    : $rx->make_schema({
        type  => 'tag:codesimply.com,2008:rx/core/str',
        value => $arg->{prototype}
      });

  return { prototype_schema => $prototype_schema };
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (ref $value) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not a ref",
      value   => $value,
    });
  }

  # Should probably be checking _CALLABLE. -- rjbs, 2009-03-12
  unless (Scalar::Util::reftype($value) eq 'CODE') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not a CODE ref",
      value   => $value,
    });
  }

  if (
    defined $self->{prototype_schema}
    && ! $self->{prototype_schema}->check(prototype $value)
  ) {
    $self->fail({
      error   => [ qw(prototype) ],
      message => "subroutine prototype does not match requirement",
      value   => $value,
      # data_path => [[ 'prototype', 'prototype', sub { "prototype($_[0])" } ]],
    });
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::Type::Perl::Code - experimental / perl coderef type

=head1 VERSION

version 0.011

=head1 SYNOPSIS

  use Data::Rx;
  use Data::Rx::Type::Perl::Code;
  use Test::More tests => 2;

  my $rx = Data::Rx->new({
    prefix  => {
      perl => 'tag:codesimply.com,2008:rx/perl/',
    },
    type_plugins => [ 'Data::Rx::Type::Perl::Code' ]
  });

  my $is_code = $rx->make_schema({
    type       => '/perl/code',
  });

  ok($is_code->check( sub {} ), "a coderef is code");
  ok(! $is_code->check( 1 ),    "1 is not code");

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ARGUMENTS

If given, the C<prototype> argument will require that the code has the given
prototype.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
