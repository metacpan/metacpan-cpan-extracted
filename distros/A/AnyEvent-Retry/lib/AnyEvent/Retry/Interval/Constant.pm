package AnyEvent::Retry::Interval::Constant;
BEGIN {
  $AnyEvent::Retry::Interval::Constant::VERSION = '0.03';
}
# ABSTRACT: a constant interval
use Moose;
use MooseX::Types::Common::Numeric qw(PositiveNum);
use true;
use namespace::autoclean;

with 'AnyEvent::Retry::Interval';

has 'interval' => (
    is      => 'ro',
    isa     => PositiveNum,
    default => 1,
);

sub reset {}

sub next {
    my ($self, $try) = @_;
    return $self->interval;
}

__PACKAGE__->meta->make_immutable;



=pod

=head1 NAME

AnyEvent::Retry::Interval::Constant - a constant interval

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Always wait 42 seconds:

    my $i = AnyEvent::Retry::Interval::Constant->new( interval => 42 );

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

