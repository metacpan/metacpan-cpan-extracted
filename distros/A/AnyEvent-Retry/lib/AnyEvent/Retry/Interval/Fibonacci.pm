package AnyEvent::Retry::Interval::Fibonacci;
BEGIN {
  $AnyEvent::Retry::Interval::Fibonacci::VERSION = '0.03';
}
# ABSTRACT: fibonacci back-off
use Moose;
use MooseX::Types::Common::Numeric qw(PositiveNum);

use Math::Fibonacci qw(term);

use true;
use namespace::autoclean;

with 'AnyEvent::Retry::Interval';

has 'scale' => (
    is      => 'ro',
    isa     => PositiveNum,
    default => 1.0,
);

sub reset {}

sub next {
    my ($self, $i) = @_;
    return $self->scale * term($i);
}

__PACKAGE__->meta->make_immutable;



=pod

=head1 NAME

AnyEvent::Retry::Interval::Fibonacci - fibonacci back-off

=head1 VERSION

version 0.03

=head1 SYNOPSIS

C<AnyEvent::Retry::Interval> that waits longer and longer after each
failed attempt.

=head1 INITARGS

=head2 scale

A number greater than 0 that the fibonacci number is multiplied by
before being returned.  For example, to wait 1 millisecond, then 1
millisecond, then 2 milliseconds, then 3 ..., pass C<scale => 1/1000>.

=head1 NOTES

The fibonacci number is computed with L<Math::Fibonacci>.  This may yield
slightly different results from the iterative C<F(n) = F(n-2) + F(n-1)>
method.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

