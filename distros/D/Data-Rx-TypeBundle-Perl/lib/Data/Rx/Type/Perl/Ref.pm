use strict;
use warnings;
package Data::Rx::Type::Perl::Ref 0.010;
# ABSTRACT: experimental / perl reference type
use parent 'Data::Rx::CommonType::EasyNew';

#pod =head1 SYNOPSIS
#pod
#pod   use Data::Rx;
#pod   use Data::Rx::Type::Perl::Ref;
#pod   use Test::More tests => 2;
#pod
#pod   my $rx = Data::Rx->new({
#pod     prefix  => {
#pod       perl => 'tag:codesimply.com,2008:rx/perl/',
#pod     },
#pod     type_plugins => [ 'Data::Rx::Type::Perl::Ref' ]
#pod   });
#pod
#pod   my $int_ref_rx = $rx->make_schema({
#pod     type       => '/perl/ref',
#pod     referent   => '//int',
#pod   });
#pod
#pod   ok(  $int_ref_rx->check(  1 ), "1 is not a ref to an integer");
#pod   ok(! $int_ref_rx->check( \1 ), "\1 is a ref to an integer");
#pod
#pod =head1 ARGUMENTS
#pod
#pod "referent" indicates another type to which the reference must refer.
#pod
#pod =cut

use Carp ();
use Scalar::Util ();

sub type_uri { 'tag:codesimply.com,2008:rx/perl/ref' }

sub guts_from_arg {
  my ($class, $arg, $rx) = @_;
  $arg ||= {};

  for my $key (keys %$arg) {
    next if $key eq 'referent';
    Carp::croak(
      "unknown argument $key in constructing " . $class->type_uri .  " type",
    );
  }

  my $guts = { };

  if ($arg->{referent}) {
    my $ref_checker = $rx->make_schema($arg->{referent});

    $guts->{referent} = $ref_checker;
  }

  return $guts;
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (ref $value and (ref $value eq 'REF' or ref $value eq 'SCALAR')) {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not a scalar reference",
      value   => $value,
    });
  }

  if ($self->{referent}) {
    $self->perform_subchecks([
      [
        $$value,
        $self->{referent},
        {
          data_path  => [ [ 'scalar_deref', 'deref', sub { "\${$_[0]}" } ] ],
          check_path => [ [ 'referent', 'key' ] ],
        },
      ],
    ]);
  }

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::Type::Perl::Ref - experimental / perl reference type

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use Data::Rx;
  use Data::Rx::Type::Perl::Ref;
  use Test::More tests => 2;

  my $rx = Data::Rx->new({
    prefix  => {
      perl => 'tag:codesimply.com,2008:rx/perl/',
    },
    type_plugins => [ 'Data::Rx::Type::Perl::Ref' ]
  });

  my $int_ref_rx = $rx->make_schema({
    type       => '/perl/ref',
    referent   => '//int',
  });

  ok(  $int_ref_rx->check(  1 ), "1 is not a ref to an integer");
  ok(! $int_ref_rx->check( \1 ), "\1 is a ref to an integer");

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ARGUMENTS

"referent" indicates another type to which the reference must refer.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
