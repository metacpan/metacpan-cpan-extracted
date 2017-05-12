use strict;
use warnings;
package Data::Rx::CoreType::int;
# ABSTRACT: the Rx //int type
$Data::Rx::CoreType::int::VERSION = '0.200007';
use parent 'Data::Rx::CoreType::num';

sub subname   { 'int' }

sub __type_fail {
  my ($self, $value) = @_;
  $self->fail({
    error   => [ qw(type) ],
    message => "value is not an integer",
    value   => $value,
  });
}

sub _value_is_of_type {
  my ($self, $value) = @_;

  return unless $self->SUPER::_value_is_of_type($value);
  return ($value == int $value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::int - the Rx //int type

=head1 VERSION

version 0.200007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
