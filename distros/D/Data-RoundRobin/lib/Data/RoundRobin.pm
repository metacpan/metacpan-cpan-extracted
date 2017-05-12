package Data::RoundRobin;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.03';

use overload
    'eq' => \&next,
    'ne' => \&next,
    "cmp" => \&next,
    "<=>" => \&next,
    '+' => \&numerify,
    '==' => \&numerify,
    '""' => \&next;

sub new {
    my ($class, @arr) = @_;
    my $self = {
        array => \@arr,
        current => 0,
        total => scalar(@arr),
    };
    return bless $self;
}

sub next {
    my $self = shift;
    my $r    = $self->{array}->[$self->{current}];
    $self->{current}++;
    $self->{current} %= $self->{total};
    return $r;
}

sub numerify {
    my $self   = shift;
    my $other  = shift || 0;
    my $value  = $self->next;
    $value =~ s/^(\d*).*$/$1/;
    $value ||= 0;
    return $value + $other;
}

1;

__END__

=head1 NAME

Data::RoundRobin - Serve data in a round robin manner.

=head1 SYNOPSIS

  my @array = qw(a b);
  # OO Interface
  my $rr = Data::RoundRobin->new(@array);

  print $rr->next; # a
  print $rr->next; # b
  print $rr->next; # a
  print $rr->next; # b
  ...

  # Infinite Loop
  while(my $elem = $rr->next) {
     ...
  }

  # Operator overloading
  my $rr = Data::RoundRobin->new(qw(a b));
  print $rr; # a
  print $rr; # b
  print $rr; # a

=head1 DESCRIPTION

This module provides a round roubin object implementation.  It is similar to
an iterator, only the internal counter is reset to the begining whenever it
reaches the end. It might also be considered as a circular iterator.

=head1 METHODS

=over 4

=item new

Constructor, a list should be given to construct a C<Data::RoundRobin> object.

=item next

Retrieve next value of this instance.

=item numerify

Retrieve next numerifed value of this instance. Invoked by Perl's
operator overloadding mechanism.

=back

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

