use strict;
use warnings;
package Data::Rx::Type::Perl::Obj 0.010;
# ABSTRACT: experimental / perl object type
use parent 'Data::Rx::CommonType::EasyNew';

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Rx;
#pod   use Data::Rx::Type::Perl::Obj;
#pod   use Test::More tests => 2;
#pod
#pod   my $rx = Data::Rx->new({
#pod     prefix  => {
#pod       perl => 'tag:codesimply.com,2008:rx/perl/',
#pod     },
#pod     type_plugins => [ 'Data::Rx::Type::Perl::Obj' ]
#pod   });
#pod
#pod   my $isa_rx = $rx->make_schema({
#pod     type       => '/perl/obj',
#pod     isa        => 'Data::Rx',
#pod   });
#pod
#pod   ok($isa_rx->check($rx),   "a Data::Rx object isa Data::Rx /perl/obj");
#pod   ok(! $isa_rx->check( 1 ), "1 is not a Data::Rx /perl/obj");
#pod
#pod =head1 ARGUMENTS
#pod
#pod "isa" and "does" ensure that the object passes the relevant test for the
#pod identifier given.
#pod
#pod =cut

use Carp ();
use Scalar::Util ();

sub type_uri { 'tag:codesimply.com,2008:rx/perl/obj' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;
  $arg ||= {};

  for my $key (keys %$arg) {
    next if $key eq 'isa' or $key eq 'does';
    Carp::croak(
      "unknown argument $key in constructing " . $class->type_uri .  " type",
    );
  }

  return {
    isa  => $arg->{isa},
    does => $arg->{does},
  };
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (Scalar::Util::blessed($value)) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not blessed",
      value   => $value,
    });
  }

  if (defined $self->{isa} and not eval { $value->isa($self->{isa}) }) {
    $self->fail({
      error   => [ qw(isa) ],
      message => "found value is not isa $self->{isa}",
      value   => $value,
    });
  }

  if (defined $self->{does} and not eval { $value->DOES($self->{does}) }) {
    $self->fail({
      error   => [ qw(does) ],
      message => "found value does not do role $self->{does}",
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

Data::Rx::Type::Perl::Obj - experimental / perl object type

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use Data::Rx;
  use Data::Rx::Type::Perl::Obj;
  use Test::More tests => 2;

  my $rx = Data::Rx->new({
    prefix  => {
      perl => 'tag:codesimply.com,2008:rx/perl/',
    },
    type_plugins => [ 'Data::Rx::Type::Perl::Obj' ]
  });

  my $isa_rx = $rx->make_schema({
    type       => '/perl/obj',
    isa        => 'Data::Rx',
  });

  ok($isa_rx->check($rx),   "a Data::Rx object isa Data::Rx /perl/obj");
  ok(! $isa_rx->check( 1 ), "1 is not a Data::Rx /perl/obj");

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ARGUMENTS

"isa" and "does" ensure that the object passes the relevant test for the
identifier given.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
