# Acme::GuessNumber - Number guessing game robot

# Copyright (c) 2007-2008 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.
# First written: 2007-05-19

package Acme::GuessNumber;
use strict;
use warnings;
use base qw(Exporter);
use vars qw($VERSION @EXPORT @EXPORT_OK);
$VERSION = 0.04;
@EXPORT = qw(guess_number HURRY_UP);
@EXPORT_OK = @EXPORT;
# Prototype declaration
sub guess_number($;$);

use vars qw(@GUESSMSGS @RESTMSGS);
@GUESSMSGS = split /\n/, << "EOT";
%d?
Is it %d?
It must be %d!
EOT
@RESTMSGS = split /\n/, << "EOT";
Any cigarette?
I'm feeling lucky tonight
I'm getting a little tired
It's killing me
I'm gonna faint
EOT

# HURRY_UP: Speed up the game
use constant HURRY_UP => 1;

# guess_number: Play the game
sub guess_number($;$) {
    local ($_, %_);
    my ($max, $hurry, $to_rest);
    ($max, $hurry) = @_;
    $hurry = 0 if @_ < 2;
    
    # Play the game
    $to_rest = 5 + int rand 7 unless $hurry;
    while (1) {
        my ($num, $guess);
        # Generate the number
        $num = 1 + int rand $max;
        # Generate the guess
        $guess = 1 + int rand $max;
        # Output our guess
        $_ = sprintf $GUESSMSGS[int rand scalar @GUESSMSGS], $guess;
        printf "%-40s", "<Player>: $_";
        # Hit?
        if ($guess == $num) {
            print "<Banker>: Jackpot!\n";
            last;
        }
        print "<Banker>: Sorry, it's $num.\n";
        # We are in a hurry
        next if $hurry;
        # Take a little rest
        if (--$to_rest == 0) {
            my ($flush, $rest);
            $flush = $|;
            $| = 1;
            # Yell something
            print "  *" . $RESTMSGS[int rand scalar @RESTMSGS] . "* ";
            $rest = 3 + int rand 4;
            while ($rest-- > 0) {
                print ".";
                sleep 1;
            }
            print "\n";
            $| = $flush;
            # Reset the rest counter
            $to_rest = 5 + int rand 7;
        # Take a breath
        } else {
            sleep 1;
        }
    }
    
    return;
}

return 1;

__END__

=head1 NAME

Acme::GuessNumber - An automatic number guessing game robot

=head1 SYNOPSIS

  use Acme::GuessNumber;
  guess_number(25);
  # If you are in a hurry
  guess_number(25, HURRY_UP);

=head1 DESCRIPTION

Many people have this experience:  You sit before a gambling table.  You
keep placing the bet.  You know the Goddess will finally smile at you.
You just don't know when.  You have only to wait.  As the time goes by,
the bets in your hand become fewer and fewer.  You feel the time goes
slower and slower.  This lengthy waiting process become painfully long,
like a train running straightforwardly into hell.  You start feeling
your whole life is a misery, as the jackpot never comes...

But, hey, why so painfully waiting?  The Goddess will finally smile at
you, right?  So, why not put this painly waiting process to a computer
program?  Yes.  That is the whole idea, the greatest invention in the
century:  An automatic gambler!  There is no secret.  It is simple
brute-force.  It never-endingly runs toward your final jackpot.  You can
go for your life: sleep, eat, work.  When you finally came back you
win.  With it, the hell of gambling is history!

Remember, that the computer is never affected by emotions, luck,
everything.  It never feel anxious or depressed.  It simply, faithfully,
determinedly runs the probability until the jackpot.  As you know,
the anxiety and depression are the enemy of the games, while a
simple, faithful, and determined mind is the only path to the jackpot.
This makes a computer a perfect gambler than an ordinary human being.

=head1 FUNCTIONS

=over

=item guess_number($max, $hurry)

Start playing.  Give it a maximum range of the numbers, and the program
will play the number guessing game for you.  If you are in a hurry, you
can also speed it up by setting $hurry = 1, or use the exported symbol
HURRY_UP.

=back

=head1 NOTES

=head2 It's so funny!  May I join the game?

No.  That's the whole point of acme.  Human beings are never acme.  Only
machines are acme.  So, in order for everything to be acme, no human
being is allowed.  This ensures that when guessing, the player
is never bothered by all kinds of feelings: anxiety, depression,
anything.  It just guesses, precisely.  Nothing more.

=head1 BUGS

No.  This can't possiblely be wrong.  This is brute-force.  It will try
until it succeeds.  Nothing can stop it from success.  You always win!
You will always win!  The Goddess will always smile at you!

=head1 SEE ALSO

None.

=head1 AUTHOR

imacat <imacat@mail.imacat.idv.tw>

=head1 COPYRIGHT

Copyright (c) 2007-2008 imacat. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
