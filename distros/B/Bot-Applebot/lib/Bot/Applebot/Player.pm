package Bot::Applebot::Player;
use Moose;
use MooseX::AttributeHelpers;
use List::MoreUtils 'firstidx';

use overload q{""} => sub { shift->name };

has name => (
    is  => 'ro',
    isa => 'Str',
);

has _noun_cards => (
    metaclass => 'Collection::Array',
    writer    => 'set_noun_cards',
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },
    provides  => {
        push     => 'add_noun_card',
        elements => 'noun_cards',
    },
);

has adjective_cards => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    default   => sub { [] },
    provides  => {
        push => 'add_adjective_card',
    },
);

has played_noun_card => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'clear_played_noun_card',
);

has prefers_notices => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

sub card_index {
    my $self = shift;
    my $name = shift;

    # Do they have the exact card?
    my $idx = 1 + firstidx { $_ eq $name } $self->noun_cards;
    return $idx if $idx;

    return 0 if Bot::Applebot::forbid('floating_adjectives');

    # You get only one use of <adj>
    return 0 if $name =~ /<adj>.*<adj>/;

    # Don't make it too easy to inject an obnoxious amount of space
    return 0 if $name =~ /\s\s/;

    # "Visionary" Bumper Stickers
    $name =~ s/"<adj>"/<adj>/g;

    # You get to put one <adj> wherever you want
    $name =~ s/<adj>//;

    my @name = split ' ', $name;

    my $i = 0;
    CARD: for my $card ($self->noun_cards) {
        ++$i;

        # Builtin cards can have <adj> in them
        $card =~ s/<adj>//g;

        my @card = split ' ', $card;

        next CARD if @name != @card;

        # Make sure they didn't change any words
        for (my $j = 0; $j < @name; ++$j) {
            no warnings 'uninitialized';
            next CARD if $name[$j] ne $card[$j];
        }

        return $i;
    }

    return 0;
}

sub cards {
    my $self = shift;
    my $i = 0;
    my @cards = map { ++$i . ": $_" } $self->noun_cards;
    return join ', ', @cards;
}

sub score {
    my $self = shift;
    return scalar @{ $self->adjective_cards };
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

