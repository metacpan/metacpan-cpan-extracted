use strict;
use warnings;
package Array::Sticky;

our $VERSION = 0.01;

sub TIEARRAY {
  my ($class, %args) = @_;

  my $self = bless +{
    head => [ @{ $args{head} || [] } ],
    body => [ @{ $args{body} || [] } ],
    tail => [ @{ $args{tail} || [] } ],
  }, $class;

  return $self;
}

sub POP { pop @{shift()->{body}} }
sub PUSH { push @{shift()->{body}}, @_ }
sub SHIFT { shift @{shift()->{body}} }
sub UNSHIFT { unshift @{shift()->{body}}, @_ }

sub CLEAR {
  my ($self) = @_;
  @{$self->{body}} = ();
}
sub EXTEND {}
sub EXISTS {
  my ($self, $index) = @_;
  my @serial = $self->serial;
  return exists $serial[$index];
}

sub serial {
  my ($self) = @_;
  return map { @{$self->{$_}} } qw(head body tail);
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->{body}[$index] = $value;
}

sub SPLICE {
  my $self = shift;
  my $offset = shift || 0;
  my $length = shift; $length = $self->FETCHSIZE if ! defined $length;

  # avoid "splice() offset past end of array"
  no warnings;

  return splice @{$self->{body}}, $offset, $length, @_;
}

sub FETCHSIZE {
  my $self = shift;

  my $size = 0;
  my %size = $self->sizes;

  foreach (values %size) {
    $size += $_;
  }

  return $size;
}

sub sizes {
  my $self = shift;
  return map { $_ => scalar @{$self->{$_}} } qw(head body tail);
}

sub FETCH {
  my $self = shift;
  my $index = shift;

  my %size = $self->sizes;

  foreach my $slot (qw(head body tail)) {
    if ($size{$slot} > $index) {
      return $self->{$slot}[$index];
    } else {
      $index -= $size{$slot};
    }
  }

  return $self->{body}[$size{body} + 1] = undef;
}

1;

__END__

=head1 NAME

Array::Sticky - make elements of an array stick in place

=head1 SYNOPSIS

    use Array::Sticky;

    my @array;

    tie @array, 'Array::Sticky', head => ['head'], body => [1..5];
    # @array = ('head', 1..5)

    unshift @array, 'shoulders';
    # @array = ('head', 'shoulders', 1..5);

    my $val = shift @array;
    # $val = 'shoulders'
    # @array = ('head', 1..5)

=head1 DESCRIPTION

On very rare occasions, you want to make sure that the first few or last few elements of an array remain
in their relative positions - stuck to the head of the array, or stuck to the tail. This module allows you
to accomplish that.

=head1 SEE ALSO

By itself this module is probably not all that interesting. See L<Sticky::Array::INC> for an actual case
where you might care about using this module.

=head1 BUGS

Please report bugs on this project's Github Issues page: L<http://github.com/belden/perl-array-sticky/issues>.

=head1 CONTRIBUTING

The repository for this software is freely available on this project's Github page:
L<http://github.com/belden/perl-array-sticky>. You may fork it there and submit pull requests in the standard
fashion.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.

