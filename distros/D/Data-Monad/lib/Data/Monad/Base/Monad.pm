package Data::Monad::Base::Monad;
use strict;
use warnings;
use Scalar::Util ();
use Data::Monad::Base::Sugar;
use Data::Monad::Base::Util qw(list);

sub unit {
    my ($class, @v) = @_;
    die "You should override this method.";
}

sub flat_map_multi {
    my ($class, $f, @ms) = @_;

    Data::Monad::Base::Sugar::for {
        my @args;
        for my $i (0 .. $#ms) {
            # capture each value in each slot of @args
            pick +(my $slot = []) => sub { $ms[$i] };
            push @args, $slot;
        }
        pick sub { $f->(map { @$_ } @args) };
    };
}

sub map_multi {
    my ($class, $f, @ms) = @_;

    $class->flat_map_multi(sub { $class->unit($f->(@_)) }, @ms)
}

sub sequence {
    my $class = shift;
    $class->map_multi(sub { list @_ } => @_);
}

sub _welldefined_check {
    my $self = shift;
    \&flat_map != $self->can('flat_map') and return;
    \&map != $self->can('map') and \&flatten != $self->can('flatten')
                                                                    and return;

    die "You must implement flat_map(), or map() and flatten().";
}

sub flat_map {
    my ($self, $f) = @_;

    $self->_welldefined_check;

    no strict qw/refs/;
    *{(ref $self) . "::flat_map"} = sub {
        my ($self, $f) = @_;
        $self->map($f)->flatten;
    };

    $self->flat_map($f);
}

sub map {
    my ($self, $f) = @_;

    $self->_welldefined_check;

    no strict qw/refs/;
    *{(ref $self) . "::map"} = sub {
        my ($self, $f) = @_;
        $self->flat_map(sub { (ref $self)->unit($f->(@_)) });
    };

    $self->map($f);
}

sub flatten {
    my $self_duplexed = shift;

    $self_duplexed->_welldefined_check;

    no strict qw/refs/;
    *{(ref $self_duplexed) . "::flatten"} = sub {
        my $self_duplexed = shift;
        $self_duplexed->flat_map(sub { list @_ });
    };

    $self_duplexed->flatten;
}

sub ap { (ref $_[0])->map_multi(sub { my $c = shift; $c->(@_) } => @_) }

sub while {
    my ($self, $predicate, $f) = @_;

    my $weaken_loop;
    my $loop = sub {
        my @v = @_;
        $predicate->(@v) ? $f->(@v)->flat_map($weaken_loop)
                         : (ref $self)->unit(@v);
    };
    Scalar::Util::weaken($weaken_loop = $loop);

    $self->flat_map($loop);
}

1;

__END__

=head1 NAME

Data::Monad::Base::Monad - The base class of any monads.

=head1 SYNOPSIS

  package YourMonadClass;
  use base qw/Data::Monad::Base::Monad/;

  sub unit {
      my ($class, @v) = @_;
      ...
  }

  sub flat_map {
      my ($self, $f) = @_;
      ...
  }

=head1 DESCRIPTION

Data::Monad::Base::Monad provides some useful functions for any monads.

You must implement unit() and flat_map() according to monad laws.
Or you may implement flatten() and map() instead of flat_map().

This module is marked B<EXPERIMENTAL>. API could be changed without any notice.
I'll drop many useless stuffs in the future.

=head1 METHODS

=over 4

=item $m = SomeMonad->unit(@vs);

A natural transformation, which is known as "return" in Haskell.

You must implement this method in sub classes.

=item $f = SomeMonad->flat_map_multi(sub { ... }, $m1, $m2, ...);

Changes the type of function from (v1, v2, ...) -> m(v0)
to (m(v1), m(v2), ...) -> m(v0), and apply it to $m1, $m2, ...

=item $f = SomeMonad->map_multi(sub { ... }, $m1, $m2, ...);

Changes the type of function from (v1, v2, ...) -> v0
to (m(v1), m(v2), ...) -> m(v0), and apply it to $m1, $m2, ...

=item $m = SomeMonad->sequence($m1, $m2, $m3, ...);

Packs monads into the new monad.

=item $m2 = $m1->flat_map(sub { ... });

The composition of Kleisli category, which known as ">>=" in Haskell.

You must implement this method in sub classes.

=item $m2 = $m1->map(sub { ... });

The morphism map of the monad, which is known as "fmap" in Haskell.

=item $m = $mm->flatten;

A natural transformation, which is known as "join" in Haskell.

=item $m = $mf->ap($m1, $m2,...);

Executes the function which wrapped by the monad.

=item $m = $m->while(\&predicate, \&f);

C<flat_map(\&f)> while C<\&predicate> is true.

=back

=head1 AUTHOR

hiratara E<lt>hiratara {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::MonadZero>, L<Data::Monad::Base::Sugar>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

