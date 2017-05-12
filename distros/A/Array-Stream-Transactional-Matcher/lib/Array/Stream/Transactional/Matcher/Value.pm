# $Id: Value.pm,v 1.6 2004/06/11 21:50:53 claes Exp $

use strict;

our $VERSION = "1.00";
my $number = qr/^-?\d+(?:\.\d+)$/;

package Array::Stream::Transactional::Matcher::Value;
our @ISA = qw(Array::Stream::Transactional::Matcher::Rule);

sub new {
  my ($class, @args) = @_;
  $class = ref $class || $class;
  my $self = bless [@args], $class;  
  return $self;
}

sub match { 1; }

package Array::Stream::Transactional::Matcher::Value::eq;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return $compare == $self->[0] if($compare =~ $number && $self->[1]);
  return $compare eq $self->[0];
}

package Array::Stream::Transactional::Matcher::Value::ne;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return $compare != $self->[0] if($compare =~ $number && $self->[1]);
  return $compare ne $self->[0];
}

package Array::Stream::Transactional::Matcher::Value::gt;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return $compare > $self->[0] if($compare =~ $number && $self->[1]);
  return $compare gt $self->[0];
}

package Array::Stream::Transactional::Matcher::Value::lt;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return $compare < $self->[0] if($compare =~ $number && $self->[1]);
  return $compare lt $self->[0];
}

package Array::Stream::Transactional::Matcher::Value::ge;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return $compare >= $self->[0] if($compare =~ $number && $self->[1]);
  return $compare ge $self->[0];
}

package Array::Stream::Transactional::Matcher::Value::le;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return $compare <= $self->[0] if($compare =~ $number && $self->[1]);
  return $compare le $self->[0];
}

package Array::Stream::Transactional::Matcher::Value::isa;
our @ISA = qw(Array::Stream::Transactional::Matcher::Value);

sub match {
  my ($self, $stream) = @_;
  my $compare = $stream->current;
  return 0 unless(ref $compare);
  return UNIVERSAL::isa($compare, $self->[0]);
}

1;
__END__
=head1 NAME

Array::Stream::Transactional::Matcher::Value - Rules implementing value checks

=head1 DESCRIPTION

Array::Stream::Transactional::Matcher::Value implements the standard comparision operators eq, ne, gt, lt, ge, le and isa.

=head1 RULES

=head2 Array::Stream::Transactional::Matcher::Value::eq

Does B<==> if it looks like a number, otherwise it does an B<eq>

=over 4

=item new ( $VALUE )

Creates a new EQ rule where the value must be equal to the value of $VALUE.

=back

=head2 Array::Stream::Transactional::Matcher::Value::ne

Does B<!=> if it looks like a number, otherwise it does an B<ne>

=over 4

=item new ( $VALUE )

Creates a new NE rule where the value must not be equal to the value of $VALUE.

=back

=head2 Array::Stream::Transactional::Matcher::Value::gt

Does B<E<gt>> if it looks like a number, otherwise it does an B<gt>

=over 4

=item new ( $VALUE )

Creates a new GT rule where the value must be greater than the value of $VALUE.

=back

=head2 Array::Stream::Transactional::Matcher::Value::lt

Does B<E<lt>> if it looks like a number, otherwise it does an B<lt>

=over 4

=item new ( $VALUE )

Creates a new LT rule where the value must be less than the value of $VALUE.

=back

=head2 Array::Stream::Transactional::Matcher::Value::ge

Does B<E<gt>=> if it looks like a number, otherwise it does an B<le>

=over 4

=item new ( $VALUE )

Creates a new GE rule where the value must be greater than or equal to the value of $VALUE.

=back

=head2 Array::Stream::Transactional::Matcher::Value::le

Does B<E<lt>=> if it looks like a number, otherwise it does an B<le>

=over 4

=item new ( $VALUE )

Creates a new LE rule where the value must be less than or equal tothe value of $VALUE.

=back

=head2 Array::Stream::Transactional::Matcher::Value::isa

Checks if the value is an object and of a specific class or one of its subclasses.

=over 4

=item new ( $VALUE )

Creates a new ISA rule where the value must be an object and belongs to the class specified in $VALUE or one of its subclasses.

=back

=head1 EXPORT

None by default.

=head1 AUTHOR

Claes Jacobsson, E<lt>claesjac@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Claes Jacobsson

This library is free software; you can redistribute it and/or modify it 
under the same license terms as Perl itself.

=cut




