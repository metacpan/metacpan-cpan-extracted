package Bot::Backbone::Service::OFun::Dice;
$Bot::Backbone::Service::OFun::Dice::VERSION = '0.142230';
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
);

use List::MoreUtils qw( any );
use List::Util qw( shuffle );
use Readonly;

Readonly my $DICE_NOTATION => qr/(?<count>\d+)?d(?<sides>\d+)(?<modifier>[+-]\d+)?/i;
Readonly my @COIN_SIDES => qw( heads tails );

# ABSTRACT: Tools for rolling dice, flipping coins, choosing, and shuffling



service_dispatcher as {
    command '!roll' => given_parameters {
        parameter 'dice' => (
            match   => $DICE_NOTATION,
            default => 'd6',
        );
    } respond_by_method 'roll_dice';

    command '!flip' => given_parameters {
        parameter 'count' => ( match => qr/\d+/, default => 1 );
    } respond_by_method 'flip_coin';

    command '!choose' => given_parameters {
        parameter 'count' => ( match => qr/\d+/ );
    } respond_by_method 'choose_n';

    command '!choose' => respond_by_method 'choose_n';

    command '!shuffle' => respond_by_method 'choose_all';
};


sub roll_dice {
    my ($self, $message) = @_;

    my $dice = $message->parameters->{dice} // 'd6';
    my $success = $dice =~ $DICE_NOTATION;
    return "I don't understand those dice." unless $success;

    my $count    = $+{count} // 1;
    my $sides    = $+{sides} // 6;
    my $modifier = $+{modifier} // 0;

    my @messages;

    return "Not sure what to do with a $sides-sided die."
        unless $sides >= 2;

    if ($count > 100) {
        my $verbing = $sides == 2 ? 'flipping' : 'rolling';
        return "You can't be serious. I'm not $verbing $count times."
    }

    unless (any { $sides == $_ } (2, 4, 6, 8, 10, 12, 20, 100)) {
        push @messages, "You have INTERESTING dice.";
    }

    if ($sides eq 2) {
        my @flips;
        for (1 .. $count) {
            push @flips, $COIN_SIDES[ int($sides * rand()) ];
        }

        push @messages, "Flipped $count times: ".join(', ', @flips);
    }

    else {
        my $sum = 0;
        for (1 .. $count) {
            $sum += int($sides * rand()) + 1;
        }
        $sum += $modifier;

        push @messages, "Rolled $sum";
    }

    return @messages;
}


sub flip_coin {
    my ($self, $message) = @_;

    my $count = $message->parameters->{count};
    $message->parameters->{dice} = $count . 'd2';
    return $self->roll_dice($message);
}


sub _items {
    my ($self, $message) = @_;
    return shuffle grep /\S/, map { s/^\s+//; s/\s+$//; $_ } map { $_->original } $message->all_args;
}

sub choose_n {
    my ($self, $message) = @_;

    my $count = $message->parameters->{count} // 1;
    my @items = $self->_items($message);
    my $n     = scalar @items;

    return "Wise-guy, eh? There's only $n items in that set, I can't pick $count items from it."
        if $count > $n;

    return "I choose " . join(', ', @items[ 0 .. $count-1 ]);
}


sub choose_all {
    my ($self, $message) = @_;

    my @items = $self->_items($message);

    $message->parameters->{count} = scalar @items;

    return $self->choose_n($message);
}

sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::OFun::Dice - Tools for rolling dice, flipping coins, choosing, and shuffling

=head1 VERSION

version 0.142230

=head1 SYNOPSIS

    # in your bot config
    service dice => (
        service => 'OFun::Dice',
    );

    dispatcher chatroom => as {
        redispatch_to 'dice';
    };

    # in chat
    alice> !roll
    bot> Rolled 4
    alice> !roll 2d4+3
    bot> Rolled 7
    alice> !flip
    bot> Flipped 1 times: heads
    alice> !flip 4
    bot> Flipped 4 times: tails, tails, tails, heads
    alice> !choose 2 alice bob chuck dick ed
    bot> I choose ed, chuck
    alice> !choose alice bob chuck dick ed
    bot> I choose dick
    alice> !shuffle alice bob chuck dick ed
    bot> I choose bob, alice, ed, dick, chuck

=head1 DESCRIPTION

This service provides a number of tools related to randomly generating numbers, coin flips, choosing items, etc.

=head1 DISPATCHER

=head2 !roll

    !roll
    !roll 2d6
    !roll 4d20+12

Generates a dice roll. If no arguments are given, it's the same as rolling a
single 6-sided die. If you specify dice notation, it will roll the dice
specified.

=head2 !flip

    !flip
    !flip 5

Flips a coin or several. If no arguments are given, it will flip a single coin
and report the outcome. If a number is given, it will flip that many coins.

=head2 !choose

    !choose 3 a b c d e
    !choose a b c d e

Choose 1 or more items from a list. If the first argument is a number, it
will choose that many items from the list. If the first argument is not a
number, it will choose a single item.

=head2 !shuffle

    !shuffle a b c d e

This is identical to:

    !choose 5 a b c d e

It choose all items, but shuffles them in the process.

=head1 METHODS

=head2 roll_dice

Implements the C<!roll> and C<!flip> commands.

=head2 flip_coin

Implements the C<!flip> command by passing "d2" as the dice notation to L</roll_dice>.

=head2 choose_n

Implements the C<!choose> and C<!shuffle> commands.

=head2 choose_all

Implements the C<!shuffle> command by counting the number of arguments
and asking L</choose_n> to pick that many items.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
