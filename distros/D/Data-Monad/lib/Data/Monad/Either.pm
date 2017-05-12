package Data::Monad::Either;
use strict;
use warnings;
use parent qw/Data::Monad::Base::Monad/;
use Exporter qw/import/;

our @EXPORT = qw/left right/;

sub left {
    return bless [@_], __PACKAGE__ . '::Left';
}

sub right {
    return bless [@_], __PACKAGE__ . '::Right';
}

# from Data::Monad::Base::Monad

sub unit {
    my ($class, @v) = @_;
    return right(@v);
}

sub flat_map {
    my ($self, $f) = @_;
    return $self->is_left ? $self : $f->($self->value);
}

# instance methods

sub is_left {
    my ($self) = @_;
    return ref($self) eq __PACKAGE__ . '::Left';
}

sub is_right {
    my ($self) = @_;
    return ref($self) eq __PACKAGE__ . '::Right';
}

sub value {
    my ($self) = @_;
    return wantarray ? @$self : $self->[0];
}

sub fold {
    my ($self, $left_accum, $right_accum) = @_;
    my $accum = $self->is_right ? $right_accum : $left_accum;
    return $accum->($self->value);
}

sub or_else {
    my ($self, $else) = @_;
    return $self->fold(
      sub { return $else },
      sub { return right(@_) },
    );
}

sub get_or_else {
    my ($self, @else) = @_;
    return $self->value_or(sub { wantarray ? @else : $else[0] });
}

sub value_or {
    my ($self, $or) = @_;
    return $self->fold(
      $or,
      sub { return wantarray ? @_ : $_[0] },
    );
}

sub swap {
    my ($self) = @_;
    return $self->fold(
      sub { return right(@_) },
      sub { return left(@_) },
    )
}

sub left_map {
    my ($self, $f) = @_;
    return $self->fold(
      sub { return left($f->(@_)) },
      sub { return right(@_) },
    );
}

package Data::Monad::Either::Left;
use parent -norequire, 'Data::Monad::Either';

package Data::Monad::Either::Right;
use parent -norequire, 'Data::Monad::Either';

1;

__END__

=head1 NAME

Data::Monad::Either - The Either monad

=head1 SYNOPSIS

  use Data::Monad::Either qw/left right/;
  sub get_key {
    my ($key) = @_;
    return sub {
      my ($data) = @_;
      return left('value is not a hash') unless ref($data) eq 'HASH';
      return exists($data->{$key}) ? right($data->{$key}) : left("data has no values for key:$key");
    };
  }

  my $commit_data = { commit => { author => 'Larry' } };
  my $right = right($data)->flat_map(get_key('commit'))->flat_map(get_key('author'));
  $right->value; # => 'Larry'

  my $not_hash = right(['Larry'])->flat_map(get_key('commit'))->flat_map(get_key('author'));
  $not_hash->value; # => 'value is not a hash'

  my $not_exists_key = right($data)->flat_map(get_key('parent_commit'))->flat_map(get_key('author'));
  $not_exists_key->value; # => 'data has no values for key:parent_commit'

=head1 DESCRIPTION

Data::Monad::Either represents values with 2 possibilities.

=head1 METHODS

=over 4

=item $right = right(@values)

=item $left = left(@values)

The constructors of this class.

=item $bool = $either->is_right

=item $bool = $either->is_left

Checks if C<$either> is right (correct) or left (failure)

=item $either->unit(@values)

=item $either->flat_map(sub { })

Overrides methods of L<Data::Monad::Base::Monad>

=item @values = $either->value

Returns a list of values which is contained by C<$either>

=item $folded = $either->fold(sub { ... }, sub { ... });

Run the first function if left, or the second.

These given functions take a value contained by C<$either>.

=item $either_or = $either->or_else($else);

Returns this Either monad if it is right, or returns the given value.

=item $get_or_else = $either->get_or_else(@value_else);

Returns the values contains by this, or returns the given default value.

=item $value_or = $either->value_or(sub { ... });

Returns the values contains by this, or runs the given default function on the left value.

=item $swapped = $either->swap;

Flip the left right values.

=item $either = $either->left_map(sub { ... });

Run the given function on the left value.

=back

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=head1 SEE ALSO

L<Data::Monad::Base::Monad>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
