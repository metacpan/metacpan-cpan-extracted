#!/usr/bin/perl -w
# spamscan.pl  by Alex Gough, 2001, (alex@rcon.org)
# This is a quick illustration of the Regexgene pseudo- module which
# is itself an illustration of the AI::Gene::Sequence module.
#
# It will run for ever, printing out dots or regular expressions
# which are quite good at spotting spam.

use strict;
use warnings;
use Regexgene;

my $num_mutates = 3;

# read in our passes and failures.
my (@wanted, @spam);
while (<DATA>) {
  if (1../^$/) { push @wanted, $_;}
  else         { push @spam, $_}
}
print "Best score possible is: ", scalar(@spam), "\n";

my $regex = seed_match(); # start off with something quite good
my $best_yet = 0;
my $temp = 1;
while (1) {
  my $child = $regex->clone;           # copy the parent
  $child->mutate($num_mutates);        # change it slightly
  my $rex = $child->regex;
  $rex = qr/$rex/;
  my $score = 0;                       # see if the kid is better
  $score += grep {$_ =~ $rex} @spam;   # we don't want spam
  $score -= grep {$_ =~ $rex} @wanted; # but we do want our mail
  if ($score > $best_yet) {
    $regex = $child;                   # and so progress is made
    $best_yet = $score;
    print "\n* $best_yet ", $regex->regex, "\n";
  }
  print '.' unless ($temp++ % 80);
}

sub seed_match {
  my $regex;
 TWIDDLE: while (1) {
    $regex = Regexgene->new(5);
    my $rg = $regex->regex;
    last TWIDDLE if $spam[rand@spam] =~ $rg;
  }
  return $regex;
}

# Stuff from my mailbox (Don't ask) and my spam trap
__DATA__;
Stats since whenever
Hello
Bit of Fun
Money 
oxford
The sound of one hand clapping
Silly Americans
Saturday
Mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm!
I've just written 4000 words with twenty diagrams in six hours.
Mmmmmm
Guiness
Who the Man!
The owls are not what they seem
It's that rich b*stard again
Irish Virus
What Alex Did Next
Stuff
Go Jerry, Go Jerry!!
Change of e-mail
Petrol
Groovy.
You know you aren't working when:
The saga continues...
At last, the cycle is complete
Phone works again
Warm, glowy feeling.
Mmmmm Free Time
Hmmm.
broken
Pedantry and the feminine perspective since 1840...
E-mail addresses
The domain
Disarming Baptists
Stats for, er, a while...
End-of-year party...
Nasty
The Joy of Work
Sild in tomato sauce
Someone I admire and deeply love
I am Mike, he is Bob
Windows 95 CD
Lather, Rinse, Repeat
Resistance is futile.

cum!!
Your complimentary market consultation.                         6861
Domain Registration
Finance Available on Attractive Terms
Free Dish Network Satellite & Free Install - Limited time offer! _____________________
An Internet Opportunity that really works!
Urgent message for Help!!!
RE: i need reload the scripts
Ink Jet Cartridges and Paper!  Lowest Prices w/ Guarantees
MORE$$$ 
Information IS Power!
Lenders COMPETE for mortgage LOANS!                         7080
Improve Your Sex Life With VIAGRA!!                         32358
BEST DEAL ON NEW CARS AND TRUCKS!!
E-Mail Services
The Net Detective. Snoop on Anyone....
Re:  Your Business
Re:  Your Business
Lenders COMPETE for your MORTAGE Loan!!! -rnqyxoyj
A LITTLE MONEY CAN GO A LONG WAYS
Detective software
Click Here and get a Brand New Free Satellite ...
Eliminate BAD c r e d i t! 
FWD:FWD:Target your market with search engine traffic for $0.25 -hoxrgck
** It is fun, it is legal and it works***
|||- - Professional Direct Email Marketers Club - -|||				kljh	
"A dream come true offering major bank credit cards at 5.9% interest!!
 ..//..pres./ We have foreigners who want to buy or finance your business/speak to them right now... 
Make Money For The Holidays Now!!                         30231
Make Money While You Sleep!!!!
Make Money While You Sleep!!!!
Untold Real Estate Info.
Pirate SOFTWARE
You Decide:  Is Age-Reversal Possible?                         29348
Open Letter Matthias Rath
90 % of the people in your city and state need this service,,become a credit card....
Get Out of Line...                         23048
=?big5?B?d29ya6FJoUk=?=
=?big5?B?d29ya6FJoUk=?=
 sixdegrees does entertainment
>I made my cool color business card online for FREE!
Lenders COMPETE for your MORTAGE Loan! -ihjvxhrmxxw
"you will be a dream come true,90% of the people in your city need this service!!
Your Long Distance Bill Is Incorrect.....
Are you looking for a "better way" to make money?                         17269
FRE
