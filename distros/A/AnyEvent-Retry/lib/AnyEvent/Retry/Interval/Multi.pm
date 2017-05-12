package AnyEvent::Retry::Interval::Multi;
BEGIN {
  $AnyEvent::Retry::Interval::Multi::VERSION = '0.03';
}
# ABSTRACT: combine multiple interval objects into one interval
use Moose;
use AnyEvent::Retry::Types qw(Interval);

use true;
use namespace::autoclean;

with 'AnyEvent::Retry::Interval';

has [qw/first then/] => (
    is       => 'ro',
    isa      => Interval,
    required => 1,
    coerce   => 1,
);

has '_source' => (
    accessor => '_source',
    isa      => 'Str',
    lazy     => 1,
    default  => 'first',
    clearer  => '_reset_source',
);

has 'after' => (
    is       => 'ro',
    isa      => 'Num|CodeRef',
    required => 1,
);

sub reset {
    my $self = shift;
    $self->_reset_source;
    $self->first->reset;
    $self->then->reset;
}

sub next {
    my ($self, $i) = @_;
    my $source = $self->_source;
    return $self->then->next if $self->_source eq 'then';

    my $next = $self->first->next;
    my $switch = $self->check_condition($i, $next);
    return $next if !$switch;

    $self->_source('then');
    return $self->then->next;
}

sub check_condition {
    my ($self, $i, $next) = @_;
    my $cond = $self->after;
    my $switch = 0;
    if(ref $cond){
        $switch = $cond->($i, $next) ? 1 : 0;
    }
    elsif($cond < 0){
        $switch = 1 if $i > abs($cond);
    }
    else {
        $switch = 1 if $next > $cond;
    }

    return $switch;
}

__PACKAGE__->meta->make_immutable;



=pod

=head1 NAME

AnyEvent::Retry::Interval::Multi - combine multiple interval objects into one interval

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $m = AnyEvent::Retry::Interval::Multi->new(
        first => { Constant => { interval => .5 } },
        after => -2,
        then  => { Multi => {
            first => 'Fibonacci',
            after => 10,
            then  => { Multi => {
                first => { Constant => { interval => 10 } },
                after => -6,
                then  => { Constant => { interval => 60 } },
            }},
        }},
    );

C<$m> waits for .5 seconds twice, then it waits for 1 second, 1
second, 2 seconds, 3 seconds, 5 seconds, 8 seconds, then 10 seconds 6
times, then 60 seconds forever.

=head1 DESCRIPTION

See the code and tests for more detail.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

