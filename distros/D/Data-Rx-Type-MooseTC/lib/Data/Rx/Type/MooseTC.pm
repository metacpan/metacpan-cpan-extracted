use strict;
use warnings;
package Data::Rx::Type::MooseTC 0.007;
# ABSTRACT: experimental / proof of concept Rx types from Moose types
use parent 'Data::Rx::CommonType::EasyNew';

use Carp ();
use Moose::Util::TypeConstraints ();

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Rx;
#pod   use Data::Rx::Type::MooseTC;
#pod   use Test::More tests => 2;
#pod
#pod   my $rx = Data::Rx->new({
#pod     prefix  => {
#pod       moose => 'tag:rjbs.manxome.org,2008-10-04:rx/moose/',
#pod     },
#pod     type_plugins => [ 'Data::Rx::Type::MooseTC' ]
#pod   });
#pod
#pod   my $array_of_int = $rx->make_schema({
#pod     type       => '/moose/tc',
#pod     moose_type => 'ArrayRef[Int]',
#pod   });
#pod
#pod   ok($array_of_int->check([1]), "[1] is an ArrayRef[Int]");
#pod   ok(! $array_of_int->check( 1 ), "1 is not an ArrayRef[Int]");
#pod
#pod =head1 WARNING
#pod
#pod This module is primarly provided as a proof of concept and demonstration of
#pod user-written Rx type plugins.  It isn't meant to be used for serious work.
#pod Moose type constraints may change their interface in the future.
#pod
#pod =cut

sub type_uri { 'tag:rjbs.manxome.org,2008-10-04:rx/moose/tc' }

sub guts_from_arg {
  my ($class, $arg) = @_;

  Carp::croak("no type supplied for $class") unless my $mt = $arg->{moose_type};

  my $tc;

  if (ref $mt) {
    $tc = $mt;
  } else {
    package
      Moose::Util::TypeConstraints; # SUCH LONG IDENTIFIERS
    $tc = find_or_parse_type_constraint( normalize_type_constraint_name($mt) );
  }

  Carp::croak("could not make Moose type constraint from $mt")
    unless $tc->isa('Moose::Meta::TypeConstraint');

  return { tc => $tc };
}

sub assert_valid {
  my ($self, $value) = @_;

  unless ($self->{tc}->check($value)) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value does not pass type constraint",
      value   => $value,
    });
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::Type::MooseTC - experimental / proof of concept Rx types from Moose types

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  use Data::Rx;
  use Data::Rx::Type::MooseTC;
  use Test::More tests => 2;

  my $rx = Data::Rx->new({
    prefix  => {
      moose => 'tag:rjbs.manxome.org,2008-10-04:rx/moose/',
    },
    type_plugins => [ 'Data::Rx::Type::MooseTC' ]
  });

  my $array_of_int = $rx->make_schema({
    type       => '/moose/tc',
    moose_type => 'ArrayRef[Int]',
  });

  ok($array_of_int->check([1]), "[1] is an ArrayRef[Int]");
  ok(! $array_of_int->check( 1 ), "1 is not an ArrayRef[Int]");

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 WARNING

This module is primarly provided as a proof of concept and demonstration of
user-written Rx type plugins.  It isn't meant to be used for serious work.
Moose type constraints may change their interface in the future.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
