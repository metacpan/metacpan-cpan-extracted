package Catalyst::View::EmbeddedPerl::PerRequest::EachInfo;

sub new {
  my ($class, $current_count, $length) = @_;
  return bless { current_count => $current_count, length => $length }, $class;
}

sub current { shift->{current_count} }

sub total { shift->{length} }  

sub last_index { shift->{length} - 1 }

sub first_index { 0 }

sub is_first { shift->{current_count} == 0 }

sub is_not_first { shift->{current_count} != 0 }

sub is_last { shift->{current_count} == shift->{length} - 1 }

sub is_not_last { shift->{current_count} != shift->{length} - 1 }

sub is_even { shift->{current_count} % 2 == 0 }

sub is_odd { shift->{current_count} % 2 == 1 }

sub if_even {
  my ($self, $cb) = @_;
  return $self->is_even ? $cb->() : '';
}

sub if_odd {
  my ($self, $cb) = @_;
  return $self->is_odd ? $cb->() : '';
}

sub if_first {
  my ($self, $cb) = @_;
  return $self->current == 0 ? $cb->() : '';
}

sub if_last {
  my ($self, $cb) = @_;
  return $self->current == $self->last_index ? $cb->() : '';
}

sub if_not_first {
  my ($self, $cb) = @_;
  return $self->current != 0 ? $cb->() : '';
}

sub if_not_last {
  my ($self, $cb) = @_;
  return $self->current != $self->last_index ? $cb->() : '';
}

1;

=head1 NAME

Catalyst::View::EmbeddedPerl::PerRequest::EachInfo - Helper class for iteration metadata

=head1 SYNOPSIS

  use Catalyst::View::EmbeddedPerl::PerRequest::EachInfo;

  my $info = Catalyst::View::EmbeddedPerl::PerRequest::EachInfo->new($current_index, $total_count);

  # Access current index and total length
  my $current = $info->current;
  my $total   = $info->total;

  # Conditional checks
  if ($info->is_first) { ... }
  if ($info->is_last)  { ... }
  if ($info->is_even)  { ... }

  # Callback-based conditionals
  $info->if_first(sub { print "First element!\n" });
  $info->if_even(sub { print "Even index!\n" });

=head1 DESCRIPTION

This class provides metadata and utility methods for managing information
about the current index and total length in a loop or iterable context.

=head1 METHODS

=head2 new

  my $info = Catalyst::View::EmbeddedPerl::PerRequest::EachInfo->new($current_index, $total_count);

Constructor. Creates a new instance of the class. Accepts two arguments:

=over

=item * C<$current_index> - The current index in the iteration.

=item * C<$total_count> - The total number of items in the iteration.

=back

=head2 current

  my $current = $info->current;

Returns the current index.

=head2 total

  my $total = $info->total;

Returns the total number of items.

=head2 first_index

  my $first = $info->first_index;

Returns the first index (always 0).

=head2 last_index

  my $last = $info->last_index;

Returns the last index (C<total - 1>).

=head2 is_first

  if ($info->is_first) { ... }

Returns true if the current index is the first index.

=head2 is_not_first

  if ($info->is_not_first) { ... }

Returns true if the current index is not the first index.

=head2 is_last

  if ($info->is_last) { ... }

Returns true if the current index is the last index.

=head2 is_not_last

  if ($info->is_not_last) { ... }

Returns true if the current index is not the last index.

=head2 is_even

  if ($info->is_even) { ... }

Returns true if the current index is even.

=head2 is_odd

  if ($info->is_odd) { ... }

Returns true if the current index is odd.

=head2 if_even

  $info->if_even(sub { print "Even index!\n" });

Executes the provided callback if the current index is even. Returns the result
of the callback if executed, otherwise an empty string.

=head2 if_odd

  $info->if_odd(sub { print "Odd index!\n" });

Executes the provided callback if the current index is odd. Returns the result
of the callback if executed, otherwise an empty string.

=head2 if_first

  $info->if_first(sub { print "This is the first element!\n" });

Executes the provided callback if the current index is the first index.
Returns the result of the callback if executed, otherwise an empty string.

=head2 if_last

  $info->if_last(sub { print "This is the last element!\n" });

Executes the provided callback if the current index is the last index.
Returns the result of the callback if executed, otherwise an empty string.

=head2 if_not_first

  $info->if_not_first(sub { print "Not the first element!\n" });

Executes the provided callback if the current index is not the first index.
Returns the result of the callback if executed, otherwise an empty string.

=head2 if_not_last

  $info->if_not_last(sub { print "Not the last element!\n" });

Executes the provided callback if the current index is not the last index.
Returns the result of the callback if executed, otherwise an empty string.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
