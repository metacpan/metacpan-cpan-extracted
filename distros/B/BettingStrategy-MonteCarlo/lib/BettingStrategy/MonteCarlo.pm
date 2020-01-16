package BettingStrategy::MonteCarlo;
use 5.008001;
use strict;
use warnings;
use version; our $VERSION = version->declare("v0.1.0");
use Moo;

has array => (
    is      => 'ro',
    default => sub { +[1, 2, 3] }
);

has magnification => (
    is      => 'ro',
    default => 2,
    isa     => sub {
        die 'invalid magnification'   unless $_[0];
        die 'magnification is 2 or 3' unless ($_[0] == 2 or $_[0] == 3);
    }
);

sub bet {
    my $self = shift;

    die 'finished' if $self->is_finished;
    return $self->array->[0] + $self->array->[-1];
}

sub lost {
    my $self = shift;

    die 'finished' if $self->is_finished;
    push @{$self->array}, $self->bet;
    return;
}

sub won {
    my $self = shift;

    die 'finished' if $self->is_finished;
    for (2 .. $self->magnification) {
        shift @{$self->array};
        pop @{$self->array};
    }
    return;
}

sub is_finished { scalar @{shift->array} <= 1 }

1;
__END__

=encoding utf-8

=head1 NAME

BettingStrategy::MonteCarlo - Monte Carlo method for gambling.

=head1 SYNOPSIS

    use BettingStrategy::MonteCarlo;
    my $strategy = BettingStrategy::MonteCarlo->new(+{magnification => 2});
    my $cash     = 100;
    while (!$strategy->is_finished) {
        my $bet = $strategy->bet;
        last if $cash < $bet;
        $cash -= $bet;
        if (rand 2 < 1) {
            $cash += $bet * 2;
            $strategy->won;
        }
        else {
            $strategy->lost;
        }
    }
    print $cash;

=head1 DESCRIPTION

Monte Carlo is one of betting strategy.

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut
