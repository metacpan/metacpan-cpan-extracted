package Data::Monad::Base::MonadZero;
use strict;
use warnings;
use parent qw/Data::Monad::Base::Monad/;

sub zero {
    my $class = shift;
    die "You should override this method.";
}

sub filter {
    my ($self, $predicate) = @_;
    $self->flat_map(sub {
        $predicate->(@_) ? (ref $self)->unit(@_) : (ref $self)->zero;
    });
}

1;


__END__

=head1 NAME

Data::Monad::Base::MonadZero - The base class of monads which have the zero.

=head1 SYNOPSIS

  package YourMonadClass;
  use base qw/Data::Monad::Base::MonadZero/;

  sub unit {
      my ($class, @v) = @_;
      ...
  }

  sub flat_map {
      my ($self, $f) = @_;
      ...
  }

  sub zero {
      my $class = shift;
      ...
  }

=head1 DESCRIPTION

Data::Monad::Base::MonadZero has the zero element which will not be changed
by any monadic operations.

You must implement zero() according to some of monadplus laws.

=head1 METHODS

=over 4

=item $m = YourMonad->zero;

Represents the zero value.

=item $m2 = $m1->filter(sub { ... });

Filters values by predicates. If the predicate returns false, filter will
use the zero value.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

