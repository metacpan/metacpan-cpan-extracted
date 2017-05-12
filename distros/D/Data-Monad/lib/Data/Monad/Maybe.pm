package Data::Monad::Maybe;
use strict;
use warnings;
use parent qw/Data::Monad::Base::MonadZero/;
use Carp ();
use Scalar::Util qw/reftype/;
use Exporter qw/import/;

our @EXPORT = qw/just nothing/;

sub just { bless [@_], __PACKAGE__ }
sub nothing() { bless \(my $d = undef), __PACKAGE__ }

sub unit {
    my $class = shift;
    just @_;
}

sub zero {
    my $class = shift;
    nothing;
}

sub flat_map {
    my ($self, $f) = @_;
    $self->is_nothing ? $self : $f->($self->value);
}

sub is_nothing { reftype $_[0] ne 'ARRAY' }

sub value {
    my ($self) = @_;
    if ($self->is_nothing) {
        Carp::carp "nothing has no values";
        ();
    } else {
        wantarray ? @$self : $self->[0];
    }
}

1;

__END__

=head1 NAME

Data::Monad::Maybe - The Maybe monad.

=head1 SYNOPSIS

  use Data::Monad::Maybe;
  sub div {
      my ($n, $m) = @_;
      $m == 0 ? nothing : just($n / $m);
  }

  # answer: 1.5
  print just(3, 2)->flat_map(\&div)
                  ->map(sub { "answer: $_[0]" })
                  ->value, "\n";

  # nothing
  print "nothing\n" if just(3, 0)->flat_map(\&div)
                                 ->map(sub { "answer: $_[0]" })
                                 ->is_nothing;

=head1 DESCRIPTION

Data::Monad::Maybe represents optional values.

This module is marked B<EXPERIMENTAL>. API could be changed without any notice.

=head1 METHODS

=over 4

=item $maybe = just(@values)

=item $maybe = nothing()

Is the constructors of this class.

=item unit

=item flat_map

Overrides methods of L<Data::Monad::Base::Monad>.

=item zero

Overrides methods of L<Data::Monad::Base::MonadZero>.

=item $maybe->is_nothing

Checks if C<$maybe> contains any values.

=item @values = $maybe->value

Returns a list of values which is contained by C<$maybe>.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

