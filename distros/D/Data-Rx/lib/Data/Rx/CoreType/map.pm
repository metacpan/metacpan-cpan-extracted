use v5.12.0;
use warnings;
package Data::Rx::CoreType::map 0.200008;
# ABSTRACT: the Rx //map type

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

version 0.200008

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
