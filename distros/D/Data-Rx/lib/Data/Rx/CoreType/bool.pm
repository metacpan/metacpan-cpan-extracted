use v5.12.0;
use warnings;
package Data::Rx::CoreType::bool 0.200008;
# ABSTRACT: the Rx //bool type

use parent 'Data::Rx::CoreType';

sub assert_valid {
  my ($self, $value) = @_;

  return 1 if (
    defined($value)
    and ref($value)
    and (
      eval { $value->isa('JSON::XS::Boolean') }
      or
      eval { $value->isa('JSON::PP::Boolean') }
      or
      eval { $value->isa('boolean') }
    )
  );

  $self->fail({
    error   => [ qw(type) ],
    message => "found value was not a bool",
    value   => $value,
  });
}

sub subname   { 'bool' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::bool - the Rx //bool type

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
