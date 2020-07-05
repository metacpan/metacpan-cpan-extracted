package Const::Introspect::C::Constant;

use 5.020;
use Moo;
use experimental qw( signatures );

# ABSTRACT: Class representing a C/C++ constant
our $VERSION = '0.01'; # VERSION


has c => (
  is       => 'ro',
  required => 1,
);


has name => (
  is       => 'ro',
  required => 1,
);


has raw_value => (
  is => 'ro',
);


has value => (
  is      => 'ro',
  lazy    => 1,
  default => sub ($self) {
    my $type = $self->type;
    $type eq 'other'
      ? undef
      : do {
        local $@ = '';
        my $value = eval { $self->c->compute_expression_value($type, $self->name) };
        # TODO: diagnostic on `fail`
        $@ ? undef : $value;
      };
  },
);


has type => (
  is       => 'ro',
  isa      => sub {
    die "type should be one of: string, int, long, pointer, float, double or other"
      unless $_[0] =~ /^(string|int|long|pointer|float|double|other)$/;
  },
  lazy     => 1,
  default  => sub ($self) {
    local $@ = '';
    my $type = eval { $self->c->compute_expression_type($self->name) };
    # TODO: diagnostic on `other`
    $@ ? 'other' : $type;
  },
);

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Const::Introspect::C::Constant - Class representing a C/C++ constant

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This class represents a single C/C++ constant.  See L<Const::Introspect::C> for the
interface for getting a list of these constants from a header file.

=head1 PROPERTIES

=head2 c

The L<Const::Introspect::C> instance.

=head2 name

The name of the constant.

=head2 raw_value

The value of the constant as seen in the header file.  This may be an expression
and thus unusable as a constant value, but it may also be useful for diagnostics.

If the raw value is unknown this will be C<undef>.

=head2 value

The value of the constant.  The representation may depend on the C<type>, or for
C<other> type (typically for code macros), there is no sensible value,
and this will be C<undef>.

=head2 type

The constant type.  This will be one of: C<string>, C<int>, C<long>, C<pointer>, C<float>,
C<double> or C<other>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
