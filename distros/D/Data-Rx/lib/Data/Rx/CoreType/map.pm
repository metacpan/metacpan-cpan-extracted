use strict;
use warnings;
package Data::Rx::CoreType::map;
# ABSTRACT: the Rx //map type
$Data::Rx::CoreType::map::VERSION = '0.200007';
use parent 'Data::Rx::CoreType';

use Scalar::Util ();

sub subname   { 'map' }

sub guts_from_arg {
  my ($class, $arg, $rx, $type) = @_;

  Carp::croak("unknown arguments to new") unless
    Data::Rx::Util->_x_subset_keys_y($arg, { values => 1 });

  Carp::croak("no values constraint given") unless $arg->{values};

  return { value_constraint => $rx->make_schema($arg->{values}) };
}

sub assert_valid {
  my ($self, $value) = @_;

  unless (! Scalar::Util::blessed($value) and ref $value eq 'HASH') {
    $self->fail({
      error   => [ qw(type) ],
      message => "found value is not a hashref",
      value   => $value,
    });
  }

  my @subchecks;
  for my $key ($self->rx->sort_keys ? sort keys %$value : keys %$value) {
    push @subchecks, [
      $value->{ $key },
      $self->{value_constraint},
      { data_path  => [ [$key, 'key'] ],
        check_path => [ ['values', 'key' ] ],
      },
    ];
  }

  $self->perform_subchecks(\@subchecks);

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::map - the Rx //map type

=head1 VERSION

version 0.200007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
