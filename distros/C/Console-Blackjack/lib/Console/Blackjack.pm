package Console::Blackjack;

use v5.20;
use strict;
use warnings FATAL => 'all';
use experimental qw(signatures);

use utf8;
use open ':std', ':encoding(UTF-8)';
use Storable qw(dclone);

=head1 NAME

Console::Blackjack - A console-based implementation of Blackjack

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module lets you play Blackjack in your console.

    console-blackjack.pl

=cut

=head1 AUTHOR

Greg Donald, C<< <gdonald at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests at https://github.com/gdonald/console-blackjack-perl/issues.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Console::Blackjack

You can also look for information at:

=over 4

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Console-Blackjack>

=item * Search CPAN

L<https://metacpan.org/release/Console-Blackjack>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Greg Donald.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use constant {
    SAVE_FILE        => 'bj.txt',
    CARDS_IN_DECK    => 52,
    MAX_DECKS        => 8,
    MAX_PLAYER_HANDS => 7,
    MIN_BET          => 500,
    MAX_BET          => 10000000,
    HARD             => 0,
    SOFT             => 1,
    WON              => 2,
    LOST             => 3,
    PUSH             => 4,
    PLAYER           => 0,
    DEALER           => 1
};

sub is_ace ($card) {
    !$card->{value};
}

sub is_ten ($card) {
    $card->{value} > 8;
}

sub hand_value ( $hand, $method, $owner ) {
    my $total = 0;

    for my $i ( 0 .. scalar( @{ $hand->{cards} } ) - 1 ) {
        next if $owner == DEALER && $i == 1 && $hand->{hide_down_card};

        my $tmp_v = @{ $hand->{cards} }[$i]->{value} + 1;
        my $v     = $tmp_v > 9 ? 10 : $tmp_v;

        $v = 11 if $method eq SOFT && $v == 1 && $total < 11;
        $total += $v;
    }

    return hand_value( $hand, HARD, $owner ) if $method eq SOFT && $total > 21;

    $total;
}

sub player_is_busted ($player_hand) {
    hand_value( $player_hand, SOFT, PLAYER ) > 21 ? 1 : 0;
}

sub is_blackjack ($cards) {
    return 0 if scalar( @{$cards} ) != 2;
    return 1 if is_ace( @$cards[0] ) && is_ten( @$cards[1] );

    is_ace( @$cards[1] ) && is_ten( @$cards[0] ) ? 1 : 0;
}

sub player_can_hit ($player_hand) {
    (        $player_hand->{played}
          || $player_hand->{stood}
          || 21 == hand_value( $player_hand, HARD, PLAYER )
          || is_blackjack( $player_hand->{cards} )
          || player_is_busted($player_hand) ) ? 0 : 1;
}

sub player_can_stand ($player_hand) {
    (        $player_hand->{stood}
          || player_is_busted($player_hand)
          || is_blackjack( $player_hand->{cards} ) ) ? 0 : 1;
}

sub all_bets ($game) {
    my $bets = 0;

    for ( @{ $game->{player_hands} } ) {
        $bets += $_->{bet};
    }

    $bets;
}

sub shuffle ($shoe) {
    for ( my $i = @{ ${$shoe} } ; --$i ; ) {
        my $j = int rand( $i + 1 );
        @{ ${$shoe} }[ $i, $j ] = @{ ${$shoe} }[ $j, $i ];
    }
}

sub new_shoe ( $game, $values ) {
    my $total_cards = $game->{num_decks} * CARDS_IN_DECK;

    $game->{shoe} = [];

    while ( scalar( @{ $game->{shoe} } ) < $total_cards ) {
        for ( my $suit = 0 ; $suit < 4 ; ++$suit ) {
            last if scalar( @{ $game->{shoe} } ) >= $total_cards;

            for ( @{$values} ) {
                my %c = ( suit => $suit, value => $_ );
                push @{ $game->{shoe} }, \%c;
            }
        }
    }

    shuffle( \$game->{shoe} );
}

sub new_regular ($game) {
    new_shoe( $game, [ 0 .. 12 ] );
}

sub new_aces ($game) {
    new_shoe( $game, [0] );
}

sub new_jacks ($game) {
    new_shoe( $game, [10] );
}

sub new_aces_jacks ($game) {
    new_shoe( $game, [ 0, 10 ] );
}

sub new_sevens ($game) {
    new_shoe( $game, [6] );
}

sub new_eights ($game) {
    new_shoe( $game, [7] );
}

sub need_to_shuffle ($game) {
    my $num_cards    = $game->{num_decks} * CARDS_IN_DECK;
    my $current_card = $num_cards - scalar( @{ $game->{shoe} } );
    my $used         = ( $current_card / $num_cards ) * 100.0;

    for ( my $x = 0 ; $x < MAX_DECKS ; ++$x ) {
        my $spec = $game->{shuffle_specs}[$x];
        return 1 if ( $game->{num_decks} == @$spec[1] && $used > @$spec[0] );
    }

    0;
}

sub deal_card ( $shoe, $cards ) {
    my $card = pop( @{$shoe} );
    push @{$cards}, $card;
}

sub dealer_upcard_is_ace ($dealer_hand) {
    is_ace( $dealer_hand->{cards}[0] );
}

sub clear {
    system('export TERM=linux; clear');
}

sub card_face ( $game, $value, $suit ) {
    return $game->{faces2}[$value][$suit] if ( $game->{face_type} == 2 );

    $game->{faces}[$value][$suit];
}

sub draw_dealer_hand ($game) {
    my $dealer_hand = $game->{dealer_hand};

    print(' ');

    for ( my $i = 0 ; $i < scalar( @{ $dealer_hand->{cards} } ) ; ++$i ) {
        if ( $i == 1 && $dealer_hand->{hide_down_card} ) {
            printf( '%s ', card_face( $game, 13, 0 ) );
        }
        else {
            my $card = $dealer_hand->{cards}[$i];
            printf( '%s ', card_face( $game, $card->{value}, $card->{suit} ) );
        }
    }

    printf( ' ⇒  %u', hand_value( $dealer_hand, SOFT, DEALER ) );
}

sub draw_player_hand ( $game, $index ) {
    my $player_hand = $game->{player_hands}[$index];

    print(' ');

    for ( my $i = 0 ; $i < scalar( @{ $player_hand->{cards} } ) ; ++$i ) {
        my $card = $player_hand->{cards}[$i];
        printf( '%s ', card_face( $game, $card->{value}, $card->{suit} ) );
    }

    printf( ' ⇒  %u  ', hand_value( $player_hand, SOFT, PLAYER ) );

    if ( $player_hand->{status} == LOST ) {
        print('-');
    }
    elsif ( $player_hand->{status} == WON ) {
        print('+');
    }

    printf( '$%.2f', $player_hand->{bet} / 100.0 );
    print(' ⇐')
      if ( !$player_hand->{played} && $index == $game->{current_player_hand} );
    print('  ');

    if ( $player_hand->{status} == LOST ) {
        print( player_is_busted($player_hand) ? 'Busted!' : 'Lose!' );
    }
    elsif ( $player_hand->{status} == WON ) {
        print( is_blackjack( $player_hand->{cards} ) ? 'Blackjack!' : 'Won!' );
    }
    elsif ( $player_hand->{status} == PUSH ) {
        print('Push');
    }

    print("\n\n");
}

sub draw_hands ($game) {
    clear();
    print("\n Dealer: \n");
    draw_dealer_hand($game);
    printf( "\n\n Player \$%.2f:\n", $game->{money} / 100.0 );

    for ( my $x = 0 ; $x < scalar( @{ $game->{player_hands} } ) ; $x++ ) {
        draw_player_hand( $game, $x );
    }
}

sub read_one_char ($matcher) {
    open( TTY, "+</dev/tty" ) or die "no tty: $!";
    system 'stty raw -echo min 1 time 1';

    my $c;
    while (1) {
        $c = getc(TTY);
        last if $c =~ $matcher;
    }

    system 'stty sane';
    $c;
}

sub need_to_play_dealer_hand ($game) {
    for ( my $x = 0 ; $x < scalar( @{ $game->{player_hands} } ) ; ++$x ) {
        my $player_hand = $game->{player_hands}[$x];
        return 1
          if !(player_is_busted($player_hand)
            || is_blackjack( $player_hand->{cards} ) );
    }

    0;
}

sub play_dealer_hand ($game) {
    my $dealer_hand = $game->{dealer_hand};
    $dealer_hand->{hide_down_card} = 0
      if ( is_blackjack( $dealer_hand->{cards} ) );

    if ( !need_to_play_dealer_hand($game) ) {
        pay_hands($game);
        return;
    }

    $dealer_hand->{hide_down_card} = 0;

    my $soft_count = hand_value( $dealer_hand, SOFT, DEALER );
    my $hard_count = hand_value( $dealer_hand, HARD, DEALER );

    while ( $soft_count < 18 && $hard_count < 17 ) {
        deal_card( $game->{shoe}, $dealer_hand->{cards} );
        $soft_count = hand_value( $dealer_hand, SOFT, DEALER );
        $hard_count = hand_value( $dealer_hand, HARD, DEALER );
    }

    pay_hands($game);
}

sub no_insurance ($game) {
    if ( is_blackjack( $game->{dealer_hand}->{cards} ) ) {
        $game->{dealer_hand}->{hide_down_card} = 0;

        pay_hands($game);
        draw_hands($game);
        bet_options($game);
        return;
    }

    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];

    if ( player_is_done( $game, $player_hand ) ) {
        play_dealer_hand($game);
        draw_hands($game);
        bet_options($game);
        return;
    }

    draw_hands($game);
    player_get_action($game);
}

sub insure_hand ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];

    $player_hand->{bet} /= 2;
    $player_hand->{played} = 1;
    $player_hand->{payed}  = 1;
    $player_hand->{status} = LOST;
    $game->{money} -= $player_hand->{bet};

    draw_hands($game);
    bet_options($game);
}

sub player_is_done ( $game, $player_hand ) {
    if (   $player_hand->{played}
        || $player_hand->{stood}
        || is_blackjack( $player_hand->{cards} )
        || player_is_busted($player_hand)
        || 21 == hand_value( $player_hand, SOFT, PLAYER )
        || 21 == hand_value( $player_hand, HARD, PLAYER ) )
    {

        $player_hand->{played} = 1;

        if ( !$player_hand->{payed} && player_is_busted($player_hand) ) {
            $player_hand->{payed}  = 1;
            $player_hand->{status} = LOST;
            $game->{money} -= $player_hand->{bet};
        }

        return 1;
    }

    0;
}

sub normalize_bet ($game) {
    $game->{current_bet} = MIN_BET if $game->{current_bet} < MIN_BET;
    $game->{current_bet} = MAX_BET if $game->{current_bet} > MAX_BET;

    $game->{current_bet} = $game->{money}
      if $game->{current_bet} > $game->{money};
}

sub dealer_is_busted ($dealer_hand) {
    hand_value( $dealer_hand, SOFT, DEALER ) > 21 ? 1 : 0;
}

sub pay_hands ($game) {
    my $dealer_hand = $game->{dealer_hand};
    my $dhv         = hand_value( $dealer_hand, SOFT, DEALER );
    my $dhb         = dealer_is_busted($dealer_hand);

    for ( my $x = 0 ; $x < scalar( @{ $game->{player_hands} } ) ; ++$x ) {
        my $player_hand = $game->{player_hands}[$x];

        next if ( $player_hand->{payed} );
        $player_hand->{payed} = 1;

        my $phv = hand_value( $player_hand, SOFT, PLAYER );

        if ( $dhb || $phv > $dhv ) {
            $player_hand->{bet} *= 1.5
              if ( is_blackjack( $player_hand->{cards} ) );
            $game->{money} += $player_hand->{bet};
            $player_hand->{status} = WON;
        }
        elsif ( $phv < $dhv ) {
            $game->{money} -= $player_hand->{bet};
            $player_hand->{status} = LOST;
        }
        else {
            $player_hand->{status} = PUSH;
        }
    }

    normalize_bet($game);
    save_game($game);
}

sub get_new_bet ($game) {
    clear();
    draw_hands($game);

    printf( '  Current Bet: $%u  Enter New Bet: $',
        ( $game->{current_bet} / 100 ) );

    my $tmp = <STDIN>;
    chomp $tmp;

    $game->{current_bet} = $tmp * 100;
    normalize_bet($game);
    deal_new_hand($game);
}

sub get_new_num_decks ($game) {
    clear();
    draw_hands($game);

    printf( '  Number Of Decks: %u  Enter New Number Of Decks (1-8): ',
        ( $game->{num_decks} ) );

    my $tmp = <STDIN>;

    $tmp               = 1 if ( $tmp < 1 );
    $tmp               = 8 if ( $tmp > 8 );
    $game->{num_decks} = $tmp;

    game_options($game);
}

sub get_new_deck_type ($game) {
    clear();
    draw_hands($game);
    print(
" (1) Regular  (2) Aces  (3) Jacks  (4) Aces & Jacks  (5) Sevens  (6) Eights\n"
    );

    my $c = read_one_char(qr/[1-6]/);
    $game->{deck_type} = $c;
    $game->{deck_types}->{ $game->{deck_type} }->($game);

    save_game($game);
    draw_hands($game);
    bet_options($game);
}

sub get_new_face_type ($game) {
    clear();
    draw_hands($game);
    print(" (1) A♠  (2) 🂡\n");

    my $c = read_one_char(qr/[1-2]/);
    $game->{face_type} = $c;

    save_game($game);
    draw_hands($game);
    bet_options($game);
}

sub game_options ($game) {
    clear();
    draw_hands($game);
    print(" (N) Number of Decks  (T) Deck Type  (F) Face Type  (B) Back\n");

    my $c = read_one_char(qr/[ntfb]/);

    if ( $c eq 'n' ) {
        get_new_num_decks($game);
    }
    elsif ( $c eq 't' ) {
        get_new_deck_type($game);
    }
    elsif ( $c eq 'f' ) {
        get_new_face_type($game);
    }
    elsif ( $c eq 'b' ) {
        clear();
        draw_hands($game);
        bet_options($game);
    }
}

sub bet_options ($game) {
    print(" (D) Deal Hand  (B) Change Bet  (O) Options  (Q) Quit\n");

    my $c = read_one_char(qr/[dboq]/);

    return if $c eq 'd';

    if ( $c eq 'b' ) {
        get_new_bet($game);
    }
    elsif ( $c eq 'o' ) {
        game_options($game);
    }
    elsif ( $c eq 'q' ) {
        $game->{quitting} = 1;
        clear();
    }
}

sub player_can_split ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];

    return 0
      if ( $player_hand->{stood}
        || scalar( @{ $game->{player_hands} } ) >= MAX_PLAYER_HANDS );
    return 0 if ( $game->{money} < all_bets($game) + $player_hand->{bet} );

    my $cards = $player_hand->{cards};
    @$cards == 2 && @$cards[0]->{value} == @$cards[1]->{value} ? 1 : 0;
}

sub player_can_dbl ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];

    return 0 if ( $game->{money} < all_bets($game) + $player_hand->{bet} );

    $player_hand->{stood}
      || scalar( @{ $player_hand->{cards} } ) != 2
      || player_is_busted($player_hand)
      || is_blackjack( $player_hand->{cards} ) ? 0 : 1;
}

sub process ($game) {
    if ( more_hands_to_play($game) ) {
        play_more_hands($game);
        return;
    }

    play_dealer_hand($game);
    draw_hands($game);
    bet_options($game);
}

sub more_hands_to_play ($game) {
    $game->{current_player_hand} < scalar( @{ $game->{player_hands} } ) - 1;
}

sub play_more_hands ($game) {
    my $player_hand =
      $game->{player_hands}[ ++( $game->{current_player_hand} ) ];
    deal_card( $game->{shoe}, $player_hand->{cards} );

    if ( player_is_done( $game, $player_hand ) ) {
        process($game);
        return;
    }

    draw_hands($game);
    player_get_action($game);
}

sub player_hit ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];
    deal_card( $game->{shoe}, $player_hand->{cards} );

    if ( player_is_done( $game, $player_hand ) ) {
        process($game);
        return;
    }

    draw_hands($game);
    player_get_action($game);
}

sub player_stand ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];

    $player_hand->{stood}  = 1;
    $player_hand->{played} = 1;

    if ( more_hands_to_play($game) ) {
        play_more_hands($game);
        return;
    }

    play_dealer_hand($game);
    draw_hands($game);
    bet_options($game);
}

sub player_split ($game) {
    if ( !player_can_split($game) ) {
        draw_hands($game);
        player_get_action($game);
        return;
    }

    my %new_hand = (
        cards  => [],
        bet    => $game->{current_bet},
        stood  => 0,
        played => 0,
        payed  => 0,
        status => 0
    );
    my $hand_count = scalar( @{ $game->{player_hands} } );

    $game->{player_hands}[$hand_count] = \%new_hand;

    while ( $hand_count > $game->{current_player_hand} ) {
        my $ph = dclone( $game->{player_hands}[ $hand_count - 1 ] );
        $game->{player_hands}[$hand_count] = $ph;
        --$hand_count;
    }

    my $this_hand  = $game->{player_hands}[ $game->{current_player_hand} ];
    my $split_hand = $game->{player_hands}[ $game->{current_player_hand} + 1 ];

    $split_hand->{cards} = [ dclone( $this_hand->{cards}[1] ) ];
    $this_hand->{cards}  = [ dclone( $this_hand->{cards}[0] ) ];

    deal_card( $game->{shoe}, $this_hand->{cards} );

    if ( player_is_done( $game, $this_hand ) ) {
        process($game);
        return;
    }

    draw_hands($game);
    player_get_action($game);
}

sub player_dbl ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];

    deal_card( $game->{shoe}, $player_hand->{cards} );
    $player_hand->{played} = 1;
    $player_hand->{bet} *= 2;

    process($game) if ( player_is_done( $game, $player_hand ) );
}

sub player_get_action ($game) {
    my $player_hand = $game->{player_hands}[ $game->{current_player_hand} ];
    print(' ');

    if ( player_can_hit($player_hand) )   { print('(H) Hit  '); }
    if ( player_can_stand($player_hand) ) { print('(S) Stand  '); }
    if ( player_can_split($game) )        { print('(P) Split  '); }
    if ( player_can_dbl($game) )          { print('(D) Double  '); }

    print("\n");

    my $c = read_one_char(qr/[hspd]/);

    if ( $c eq 'h' ) {
        player_hit($game);
    }
    elsif ( $c eq 's' ) {
        player_stand($game);
    }
    elsif ( $c eq 'p' ) {
        player_split($game);
    }
    elsif ( $c eq 'd' ) {
        player_dbl($game);
    }
}

sub ask_insurance ($game) {
    print(" Insurance?  (Y) Yes  (N) No\n");

    my $c = read_one_char(qr/[yn]/);

    if ( $c eq 'y' ) {
        insure_hand($game);
    }
    elsif ( $c eq 'n' ) {
        no_insurance($game);
    }
}

sub deal_new_hand ($game) {
    $game->{deck_types}->{ $game->{deck_type} }->($game)
      if ( need_to_shuffle($game) );

    my %player_hand = (
        cards  => [],
        bet    => $game->{current_bet},
        stood  => 0,
        played => 0,
        payed  => 0,
        status => 0
    );
    my %dealer_hand = ( cards => [], hide_down_card => 1 );

    deal_card( $game->{shoe}, ( \%player_hand )->{cards} );
    deal_card( $game->{shoe}, ( \%dealer_hand )->{cards} );
    deal_card( $game->{shoe}, ( \%player_hand )->{cards} );
    deal_card( $game->{shoe}, ( \%dealer_hand )->{cards} );

    $game->{player_hands}        = [ \%player_hand ];
    $game->{current_player_hand} = 0;
    $game->{dealer_hand}         = \%dealer_hand;

    draw_hands($game);

    if ( dealer_upcard_is_ace( \%dealer_hand )
        && !is_blackjack( ( \%player_hand )->{cards} ) )
    {
        draw_hands($game);
        ask_insurance($game);
        return;
    }

    if ( player_is_done( $game, \%player_hand ) ) {
        $dealer_hand{hide_down_card} = 0;
        pay_hands($game);
        draw_hands($game);
        bet_options($game);
        return;
    }

    draw_hands($game);
    player_get_action($game);
    save_game($game);
}

sub save_game ($game) {
    open( my $fh, '>:encoding(UTF-8)', SAVE_FILE ) or die $!;
    printf( $fh "%u\n%u\n%u\n%u\n%u\n",
        $game->{num_decks}, $game->{money}, $game->{current_bet},
        $game->{deck_type}, $game->{face_type}
    );
    close($fh);
}

sub load_game ($game) {
    if ( open( my $fh, '<:encoding(UTF-8)', SAVE_FILE ) ) {
        my $line = <$fh>;
        chomp $line;
        $game->{num_decks} = int($line);

        $line = <$fh>;
        chomp $line;
        $game->{money} = int($line);

        $line = <$fh>;
        chomp $line;
        $game->{current_bet} = int($line);

        $line = <$fh>;
        chomp $line;
        $game->{deck_type} = int($line);

        $line = <$fh>;
        chomp $line;
        $game->{face_type} = int($line);

        close($fh);
    }
}

sub run {
    my %game = (
        quitting            => 0,
        shoe                => [],
        dealer_hand         => {},
        player_hands        => [],
        num_decks           => 8,
        deck_type           => 1,
        face_type           => 1,
        money               => 10000,
        current_bet         => 500,
        current_player_hand => 0,
        shuffle_specs       => [
            [ 95, 8 ], [ 92, 7 ], [ 89, 6 ], [ 86, 5 ],
            [ 84, 4 ], [ 82, 3 ], [ 81, 2 ], [ 80, 1 ]
        ],
        faces => [
            [ 'A♠', 'A♥', 'A♣', 'A♦' ],
            [ '2♠', '2♥', '2♣', '2♦' ],
            [ '3♠', '3♥', '3♣', '3♦' ],
            [ '4♠', '4♥', '4♣', '4♦' ],
            [ '5♠', '5♥', '5♣', '5♦' ],
            [ '6♠', '6♥', '6♣', '6♦' ],
            [ '7♠', '7♥', '7♣', '7♦' ],
            [ '8♠', '8♥', '8♣', '8♦' ],
            [ '9♠', '9♥', '9♣', '9♦' ],
            [ 'T♠', 'T♥', 'T♣', 'T♦' ],
            [ 'J♠', 'J♥', 'J♣', 'J♦' ],
            [ 'Q♠', 'Q♥', 'Q♣', 'Q♦' ],
            [ 'K♠', 'K♥', 'K♣', 'K♦' ],
            ['??']
        ],
        faces2 => [
            [ '🂡', '🂱', '🃁', '🃑' ],
            [ '🂢', '🂲', '🃂', '🃒' ],
            [ '🂣', '🂳', '🃃', '🃓' ],
            [ '🂤', '🂴', '🃄', '🃔' ],
            [ '🂥', '🂵', '🃅', '🃕' ],
            [ '🂦', '🂶', '🃆', '🃖' ],
            [ '🂧', '🂷', '🃇', '🃗' ],
            [ '🂨', '🂸', '🃈', '🃘' ],
            [ '🂩', '🂹', '🃉', '🃙' ],
            [ '🂪', '🂺', '🃊', '🃚' ],
            [ '🂫', '🂻', '🃋', '🃛' ],
            [ '🂭', '🂽', '🃍', '🃝' ],
            [ '🂮', '🂾', '🃎', '🃞' ],
            ['🂠']
        ],
        deck_types => {
            1 => \&new_regular,
            2 => \&new_aces,
            3 => \&new_jacks,
            4 => \&new_aces_jacks,
            5 => \&new_sevens,
            6 => \&new_eights
        }
    );

    load_game( \%game );

    while (1) {
        deal_new_hand( \%game );
        last if $game{quitting};
    }
}

1; # End of Console::Blackjack
