package Bot::Applebot;
use 5.008001;
use Moose;
use Moose::Util::TypeConstraints 'enum';
use MooseX::AttributeHelpers;
use List::Util 'shuffle';
use List::MoreUtils 'uniq';
use IO::All;
use String::IRC;
use Lingua::EN::Inflect 'AN';
use Roman qw/roman arabic isroman/;
use File::ShareDir 'dist_file';
use YAML 'LoadFile';

use Bot::Applebot::Player;

extends 'Bot::BasicBot';

our $VERSION = '0.02';

do {
    my $conf;
    sub conf {
        if (!$conf) {
            $conf = LoadFile($ENV{APPLEBOT} || "$ENV{HOME}/.applebotrc");
        }

        return $conf->{$_[0]} if @_;

        return wantarray ? %$conf : $conf;
    }
};

sub forbid {
    my $forbid = conf->{forbid} or return 0;
    return grep { conf->{forbid}{$_} } @_;
}

has wait_announce => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    lazy    => 1,
    clearer => 'reset_wait_announce',
);

has end_score => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => 10,
);

has game_state => (
    is      => 'rw',
    isa     => (enum ['initializing', 'playing', 'judging']),
    default => 'initializing',
    lazy    => 1,
    trigger => sub {
        my $self  = shift;
        my $state = shift;

        if ($state eq 'playing') {
            $self->round_is_beginning(1);
        }
        elsif ($state eq 'initializing') {
            $self->announce("Say !join to join the game of Apples to Apples!");
            for ($self->meta->get_all_attributes) {
                my $clearer = $_->clearer
                    or next;
                $self->$clearer;
            }
        }
    },
);

has round_is_beginning => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    lazy    => 1,
);

has played_cards => (
    metaclass  => 'Collection::List',
    is         => 'rw',
    isa        => 'ArrayRef',
    default    => sub { [] },
    clearer    => 'clear_played_cards',
    lazy       => 1,
    auto_deref => 1,
    provides   => {
        count => 'played_cards_count',
    },
);

has _players => (
    metaclass => 'Collection::Hash',
    is        => 'rw',
    isa       => 'HashRef[Bot::Applebot::Player]',
    default   => sub { {} },
    lazy      => 1,
    clearer   => 'clear_players',
    provides  => {
        exists  => 'has_player',
        set     => 'add_player',
        get     => 'player',
        keys    => 'player_names',
        values  => 'players',
        delete  => 'delete_player',
    },
);

has shuffled_players => (
    is         => 'rw',
    isa        => 'ArrayRef',
    auto_deref => 1,
    clearer    => 'clear_shuffled_players',
    lazy       => 1,
    default    => sub { [ shuffle shift->players ] },
);

has deferred_players => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef',
    lazy      => 1,
    auto_deref => 1,
    default   => sub { [] },
    clearer   => 'clear_deferred_players',
    provides  => {
        push  => 'add_deferred_player',
    },
);

has inactive_players => (
    metaclass => 'Collection::Hash',
    is        => 'rw',
    isa       => 'HashRef[Bot::Applebot::Player]',
    default   => sub { {} },
    lazy      => 1,
    clearer   => 'clear_inactive_players',
    provides  => {
        get    => 'get_inactive_player',
        set    => 'set_inactive_player',
        delete => 'delete_inactive_player',
    },
);

has judge => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_judge',
    clearer   => 'clear_judge',
);

has noun_cards => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    clearer   => 'reshuffle_noun_cards',
    provides  => {
        shift => 'draw_noun_card',
        empty => 'has_noun_cards',
    },
    default => sub { [ grep { /\S/ } shuffle(
        io(dist_file('Bot-Applebot', 'nouns.txt'))->chomp->slurp,
        eval { io(conf->{aux}{nouns})->chomp->slurp },
    )]},
    lazy    => 1,
);

has adjective_cards => (
    metaclass => 'Collection::Array',
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    clearer   => 'reshuffle_adjective_cards',
    provides  => {
        shift => 'draw_adjective_card',
        empty => 'has_adjective_cards',
    },
    default => sub { [ grep { /\S/ } shuffle(
        io(dist_file('Bot-Applebot', 'adjectives.txt'))->chomp->slurp,
        eval { io(conf->{aux}{adjectives})->chomp->slurp },
    )]},
    lazy    => 1,
);

has adjective_card => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { shift->draw_adjective_card },
    lazy    => 1,
    clearer => 'clear_adjective_card',
);

has streak_winner => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'clear_streak_winner',
);

has streak_score => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
    clearer => 'reset_streak_score',
);

sub channel { (shift->channels)[0] }

sub color {
    my ($string, $color) = @_;
    Carp::cluck("Too many arguments") if @_ > 2;
    return $string if forbid("color");
    return eval { String::IRC->new($string)->$color } || $string;
}

sub adj { color($_[0], 'light_green') }

around draw_adjective_card => sub {
    my $orig = shift;
    my $self = shift;
    my $forbid_special = shift;

    unless ($forbid_special) {
        if (!forbid('secret_adjectives') && rand(50) < 1) {
            return '(a secret)';
        }

        if (!forbid('blank_adjectives') && rand(50) < 1) {
            return 'BLANK';
        }
    }

    $self->reshuffle_adjective_cards unless $self->has_adjective_cards;

    my $adjective = $orig->($self, @_);

    if ($adjective eq 'Bold') {
        $adjective = color($adjective, 'bold');
    }

    $adjective =~ s{<player>}{(shuffle $self->player_names)[0]}eg;
    $adjective =~ s{<judge>}{$self->judge}eg;

    return "$adjective";
};

around draw_noun_card => sub {
    my $orig = shift;
    my $self = shift;
    my $forbid_special = shift;

    unless ($forbid_special) {
        if (!forbid('blank_nouns') && rand(100) < 1) {
            return 'BLANK';
        }
    }

    $self->reshuffle_noun_cards unless $self->has_noun_cards;
    return $orig->($self, @_);
};

sub said {
    my $self = shift;
    my $args = shift;

    my $nick = $args->{who};
    my $text = $args->{body};
    my $chan = $args->{channel};

    if ($nick eq conf->{owner} && $text =~ /^!eval (.+)/) {
        my $ret = eval $1;
        return $@ if $@;
        return $ret;
    }

    if ($self->game_state eq 'initializing') {
        return $self->init_said($nick, $text, $chan);
    }
    else {
        return $self->play_said($nick, $text, $chan);
    }
}

sub init_said {
    my $self = shift;
    my $nick = shift;
    my $text = shift;
    my $chan = shift;

    if ($text =~ /^!(j(oin)?|play)\b/i) {
        return "$nick is already playing." if $self->has_player($nick);
        my $player = $self->add_player($nick => Bot::Applebot::Player->new(name => $nick));
        $self->give_cards($player);

        $self->announce("$nick is now playing! Current players: " . join(', ', $self->player_names) . ". Type !join to play." . ($self->players > 2 ? " Type !begin [score] to start." : ""));
    }

    if ($text =~ /^!players?\b/i) {
        return "There are currently no players. Type !join to play." if $self->players == 0;
        return "Current players: " . join(', ', $self->player_names) . ". Type !join to play.";
    }

    if ($text =~ /^!(?:start|begin|commence)\s*(\d+)?/i) {
        my $end_score = $1;

        return "You're not even playing! Type !join to play." unless $self->has_player($nick);
        return "We need at least three players to be able to start." if $self->players < 3;

        $self->end_score($end_score) if $end_score;
        $self->game_state('playing');
        return $self->announce("Apples to Apples is starting! Players: " . join(', ', $self->player_names) . ". Playing until " . $self->end_score . " points.");
    }

    return;
}

sub play_said {
    my $self = shift;
    my $nick = shift;
    my $text = shift;
    my $chan = shift;

    if (!$self->has_player($nick)) {
        if ($text =~ /^!(join|play)\b/i) {
            unless (grep { $_ eq $nick } $self->deferred_players) {
                $self->add_deferred_player($nick);
                return $self->announce("I'll add $nick to the game once this round is over.");
            }
        }

        if ($text =~ /^!(quit|part|leave|stop)\b/i) {
            my @before = $self->deferred_players;
            $self->deferred_players([grep { $_ ne $nick } @before]);
            my @after = $self->deferred_players;
            if (@before != @after) {
                return $self->announce("$nick has been removed from the game.");
            }
        }

        return;
    }

    my $player = $self->player($nick);

    if ($text =~ /^!scores?\b/i) {
        return $self->announce_scores;
    }

    if ($text =~ /^!pms?\b/i) {
        $player->prefers_notices(0);
        return;
    }

    if ($text =~ /^!notices?\b/i) {
        $player->prefers_notices(1);
        return;
    }

    if ($text =~ /^!(quit|part|leave|stop)\b/i) {
        return $self->deactivate_player($player);
    }

    if (conf->{roman} && conf->{roman}{$nick} && isroman($text)) {
        $text = arabic($text);
    }

    if ($text =~ /^!judge\s+#?(.*)$/i || ($text =~ /^#?(\d+)(\s+(#|-- |\/\/|\/\*).*)?$/ && $self->is_judge($player) && $self->game_state eq 'judging')) {
        my $choice = $1;
        my $count = $self->played_cards_count;

        return $self->judge . " is the judge!" unless $self->is_judge($player);

        return "Quit channeling AnacondaRifle and wait your turn." unless $self->game_state eq 'judging';

        return "I don't understand what '$1' means. Give me a number between 1 and $count." if $choice < 1 || $choice > $count;

        $self->decide_winner($choice - 1);
        return;
    }

    $text = "!play $text" if ($chan eq 'msg' || $text =~ /^#?\d+$/)
                          && $text !~ /^!/;

    if ($text =~ /^!blank\s+(.+)\s*$/i) {
        my $value = $1;

        if ($self->is_judge($player)) {
            return if $self->adjective_card ne 'BLANK';
            return "That's stupid. You're stupid. Pick a real adjective." if uc($1) eq 'BLANK';

            $self->adjective_card($1);
            $self->wait_announce(-1 * $self->players);
            return $self->announce("The green card has been chosen and it's... " . adj($1) . "!");
        }
        else {
            return unless $self->game_state eq 'playing';
            return $self->pm($nick => "You can't play a card as judge.") if $self->is_judge($player);
            return $self->pm($nick => "You don't have any BLANK cards.") if $player->card_index('BLANK') == 0;

            $player->played_noun_card($value);

            return $self->pm($nick => "It's kind of silly to play a card before the BLANK adjective has been chosen. You can choose again if you want, or not.") if $self->adjective_card eq 'BLANK';
        }

        return;
    }

    if ($text =~ /^!(?:play|use)\s+(.*)\s*$/i) {
        my $card = $1;
        if ($card =~ /^#?([1-7])$/) {
            $card = ($player->noun_cards)[$1-1];
        }

        if ($card eq 'BLANK') {
            return $self->pm($nick => "No no, tell me what you want the BLANK to be. PM me !blank Whatever");
        }

        return unless $self->game_state eq 'playing';
        return $self->pm($nick => "You can't play a card as judge.") if $self->is_judge($player);

        if ($player->card_index($card) == 0) {
            my $blank = $player->card_index('BLANK') ? '. To play your BLANK card, PM me !blank Whatever' : '';
            return $self->pm($nick => "You don't have that card. Your cards are: " . $player->cards . $blank);
        }

        $player->played_noun_card($card);
    }

    return;
}

sub announce_scores {
    my $self = shift;
    my @players = sort { $b->score <=> $a->score } $self->players;
    $self->announce("Scores: " . join(', ', map { $_->name . ':' . $_->score } @players) . ". Playing until " . $self->end_score . " points. ");
}

sub tick {
    my $self = shift;

    if ($self->round_is_beginning) {
        $self->begin_round;
    }
    elsif ($self->game_state eq 'playing') {
        # is everyone done playing cards?
        my @waiting_on = $self->waiting_on;
        if (@waiting_on == 0) {
            $self->begin_judging;
        }
        else {
            $self->wait_announce($self->wait_announce + 1);
            if ($self->wait_announce > 0 && $self->wait_announce % 30 == 29) {
                if ($self->wait_announce > 80) {
                    if ($self->adjective_card eq 'BLANK') {
                        $self->adjective_card($self->draw_adjective_card(1));
                        $self->announce("Okay " . $self->judge . ", time's up. The blank green card has been wasted. I'm giving you... " . adj($self->adjective_card) . "!");
                        $self->reset_wait_announce;
                    }
                    else {
                        $self->deactivate_player($_) for @waiting_on;
                    }
                }
                else {
                    my @waiting_on = $self->waiting_on(sub { color($_, 'yellow') });
                    my $waiting_on = $self->waiting_on(sub { color($_, 'yellow') });
                    my $singular = @waiting_on == 1;

                    my $an = lc AN($self->adjective_card);
                    $an =~ s/ .*//; # strip adjective

                    $self->announce(
                        "Still waiting on "
                        . ($singular ? "$an " : "")
                        . adj($self->adjective_card)
                        . " card"
                        . ($singular ? "" : "s")
                        . " from: "
                        . $waiting_on);
                }
            }
        }
    }
    elsif ($self->game_state eq 'judging') {
        $self->wait_announce($self->wait_announce + 1);
        if ($self->wait_announce > 0 && $self->wait_announce % 30 == 29) {
            if ($self->wait_announce > 80) {
                $self->deactivate_player($self->judge);
            }
            else {
                $self->announce(
                    "Still waiting on a judgment from "
                    . color($self->judge, 'yellow')
                    . "."
                );
            }
        }
    }

    return 2; # seconds til next tick
}

sub begin_round {
    my $self = shift;
    $self->round_is_beginning(0);

    for my $name (uniq $self->deferred_players) {
        my $player = $self->delete_inactive_player($name) || Bot::Applebot::Player->new(name => $name);
        $self->add_player($name => $player);
        $self->give_cards($player);
        push @{ $self->shuffled_players }, $player;
    }
    $self->clear_deferred_players;

    $self->choose_judge;
    $self->clear_adjective_card;
    $self->clear_played_cards;

    $self->reset_wait_announce;

    $self->announce("The judge is now " . color($self->judge, 'yellow') . "! Now hold on for a minute while I tell everyone their cards.");

    for my $player ($self->players) {
        next if $self->is_judge($player);
        my $cards = $player->cards;
        my $blank = $cards =~ /BLANK/ ? "To play your BLANK, PM me !blank Whatever" : '';
        $self->pm($player->name => "Your cards are: $cards. $blank");
    }

    $self->announce($self->judge . " draws a green card and it's... " . adj($self->adjective_card) . "!");
    $self->announce("The actual adjective will be revealed when judging begins.") if $self->adjective_card eq '(a secret)';
    $self->announce($self->judge . ": You may select the adjective by saying !blank ADJECTIVE. For example, !blank " . $self->draw_adjective_card(1)) if $self->adjective_card eq 'BLANK';

     return;
}

sub choose_judge {
    my $self = shift;

    my @players = ($self->shuffled_players) x 2;
    while (defined(my $player = shift @players)) {
        next unless $self->is_judge($player);
        return $self->judge((shift @players)->name);
    }

    return $self->judge( ($self->shuffled_players)[0]->name );
}

sub pm {
    my $self = shift;
    my $nick = shift;
    my $text = shift;

    my $player = $self->player($nick);

    if ($player && $player->prefers_notices) {
        $self->notice($nick => $text);
    }
    else {
        $self->say(
            who     => $nick,
            channel => 'msg',
            body    => $text,
        );
    }

    return;
}

sub announce {
    my $self = shift;
    my $text = shift;

    $self->say(
        channel => $self->channel,
        body    => $text,
    );

    return;
}

sub is_judge {
    my $self = shift;
    my $name = shift;

    $name = $name->name if blessed $name; # passed a player object

    return unless $self->has_judge;
    return $self->judge eq $name;
}

sub judge_player {
    my $self = shift;
    return (grep { $self->is_judge($_) } $self->players)[0];
}

sub waiting_on {
    my $self = shift;
    my $transform = shift;

    my @players;

    if ($self->adjective_card eq 'BLANK') {
        @players = $self->judge_player;
    }
    else {
        @players = grep { !$self->is_judge($_) }
                   grep { !$_->played_noun_card }
                   $self->players;
    }

    if (wantarray) {
        @players = map { $transform->($_) } @players if $transform;
        return @players;
    }

    @players = map { $_->name } @players;
    @players = map { $transform->($_) } @players if $transform;
    return join ', ', @players;
}

sub give_card {
    my $self   = shift;
    my $player = shift;

    my $card;

    my @players = sort { $b->score <=> $a->score } $self->players;

    if ($players[-1] eq $player
     && $player->card_index("BLANK") == 0
     && $players[-1]->score < $players[-2]->score # not tied for last
     && rand(15) < 1) {
        $self->pm($player->name => "Psst.. here's a blank card. ;)");
        $card = "BLANK";
    }
    else {
        $card = $self->draw_noun_card;
    }

    $player->add_noun_card($card);
    return $card;
}

sub begin_judging {
    my $self = shift;

    $self->game_state('judging');
    $self->reset_wait_announce;

    my $judge = $self->judge;

    if ($self->adjective_card eq '(a secret)') {
        $self->adjective_card($self->draw_adjective_card(1));
    }

    my $adjective = $self->adjective_card;

    $self->finalize_played_cards;

    $self->announce("Everyone is done playing. $judge, it's time to judge some ".adj($adjective)." cards.");

    my $i = 0;
    for ($self->played_cards) {
        my ($card, $player) = @$_;

        $card = $self->format_card($adjective, $card);

        ++$i;

        if (conf->{roman} && conf->{roman}{$judge}) {
            $self->announce(uc(roman($i)) . ": $card");
        }
        else {
            $self->announce($i . ": $card");
        }
    }

    $self->announce("$judge: Type the number of the best entry.");
}

sub finalize_played_cards {
    my $self = shift;
    my @cards;

    for my $player ($self->players) {
        next if $self->is_judge($player);
        my $card = $player->played_noun_card;
        push @cards, [$card, $player];

        my @player_cards = $player->noun_cards;
        my $i = $player->card_index($card);

        # blank?
        if (!$i) {
            $i = $player->card_index('BLANK');
        }

        # error?
        if (!$i) {
            warn "Unable to find '$card' in ${player}'s cards: " . join(', ', @player_cards);
        }

        splice @player_cards, $i - 1, 1;

        $player->set_noun_cards(\@player_cards);

        # now fill their hand back up
        $self->give_cards($player);
        $player->clear_played_noun_card;
    }

    $self->played_cards([shuffle @cards]);
}

sub give_cards {
    my $self = shift;
    my $player = shift;

    $player->add_noun_card($self->draw_noun_card) while $player->noun_cards < 7;
}

sub announce_results {
    my $self = shift;
    for my $name ($self->player_names) {
        my @cards = @{ $self->player($name)->adjective_cards };
        my $adjectives;

        if (@cards == 0) {
            $adjectives = 'not very creative';
        }
        elsif (@cards == 1) {
            $adjectives = $cards[0];
        }
        elsif (@cards == 2) {
            $adjectives = join ' and ', @cards;
        }
        else {
            $adjectives = join(', ', @cards[0 .. $#cards-1]) . ", and $cards[-1]";
        }

        $self->announce("$name is: $adjectives.");
    }
}

sub format_card {
    my $self = shift;
    my $adj = shift;
    my $noun = shift;

    if ($noun !~ /<adj>/i) {
        $noun = "<adj> $noun";
        $noun =~ s/^<adj> (A|An|The|My|\d+)\b/$1 <adj>/i;
    }

    # inflect!
    $noun =~ s/\bAn? <adj>/ucfirst AN($adj)/egi;

    $noun =~ s/<adj>/$adj/gi;

    return $noun;
}

sub deactivate_player {
    my $self = shift;
    my $player = shift;

    $player = $self->player($player) if !blessed($player);

    $self->delete_player($player->name);
    $self->set_inactive_player($player->name => $player);

    $self->shuffled_players([grep { $_->name ne $player->name } $self->shuffled_players]);

    if ($self->players <= 2) {
        $self->announce($player->name . " has been removed from the game.");
        return $self->end_game;
    }

    if ($self->is_judge($player)) {
        if ($self->state eq 'judging') {
            $self->announce($player->name . " is a jerk for abandoning the game while judging. Guess I'll roll a die...");
            $self->judge($self->nick);
            $self->decide_winner(int rand @{ $self->played_cards });
        }
        else {
            $self->announce($player->name . " is a jerk for abandoning the game while judging. Let's just start a new round...");
            $self->clear_played_cards;
            $self->clear_judge;
            $self->choose_judge;
            $self->game_state('playing');
        }
    }
    else {
        $self->announce($player->name . " has been removed from the game.");
    }

    return;
}

sub decide_winner {
    my $self  = shift;
    my $choice = shift;

    my ($card, $winner) = @{ $self->played_cards->[$choice] };

    $card = $self->format_card($self->adjective_card, $card);

    my $decree = sprintf q{%s has chosen %s's "%s"!},
        $self->judge,
        color($winner->name, 'red'),
        color($card, 'cyan');

    $self->announce($decree);

    do {
        no warnings 'uninitialized';
        if ($self->streak_winner eq "$winner") {
            $self->streak_score($self->streak_score + 1);
            $self->announce("That's " . color($self->streak_score, "red") . " in a row for $winner!");
        }
        else {
            $self->streak_score(1);
            $self->streak_winner("$winner");
        }
    }

    $winner->add_adjective_card($self->adjective_card);
    if ($winner->score >= $self->end_score) {
        $self->tweet("Game winner: $card [by $winner]");
        return $self->end_game($winner);
    }
    else {
        $self->announce_scores;

        $self->tweet("$card [by $winner]");

        $self->game_state('playing');
    }
}

sub end_game {
    my $self = shift;
    my $winner = shift;

    if ($winner) {
        $self->announce("This Apples to Apples game is over! $winner has won!");
    }
    else {
        $self->announce("This Apples to Apples game is over!");
    }

    $self->announce_results;

    $self->game_state("initializing");
    return;
}

sub chanpart {
    my $self = shift;
    my $stats = shift;

    my $player = $self->player($stats->{who}) or return;
    $self->deactivate_player($player);
}

sub notice {
    my $self = shift;
    $self->SUPER::notice(@_);
}

my $tweet_warned = 0;
sub tweet {
    my $self = shift;
    my $tweet = shift;

    if (conf->{twitter}) {
        require Net::Twitter;

        my $twitter = Net::Twitter->new(
            username => conf->{twitter}{username},
            password => conf->{twitter}{password},
            useragent_args => {
                timeout => 5,
            },
        );

        my $result = eval { $twitter->update($tweet) };

        if (!defined($result)) {
            use Data::Dumper;
            warn $@ ? $@ : Dumper($twitter->get_error);
        }
    }
}

# I don't use make_immutable or no Moose here because I like adding stuff at
# runtime with !eval

1;

__END__

=head1 NAME

Bot::Applebot - Arbiter of the word card-based game Apples to Apples

=head1 SYNOPSIS

    1. Edit ~/.applebotrc (it's YAML)

    ---
    server:   irc.foo.net
    port:     6667
    channels: ["#apples2apples"]
    nick:     Applebot

    # additional word files for you and yours, one per line
    aux:
        adjectives: /home/you/.applebot/adjectives-ex.txt
        nouns: /home/home/.applebot/nouns-ex.txt

    # turn off features you don't like
    forbid:
        color: 0
        secret_adjectives: 0
        blank_adjectives: 0
        blank_nouns: 0
        floating_adjectives: 0

    2. Run `applebot`

    3. Pick good words

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

