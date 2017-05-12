package Acme::Scurvy::Whoreson::BilgeRat::Backend::insultserver;

$VERSION = '1.0';

use warnings;
use strict;

use base 'Acme::Scurvy::Whoreson::BilgeRat';


=head1 NAME

Acme::Scurvy::Whoreson::BilgeRat::Backend::insultserver - generate insults in the style of the old colarado.edu Insult Server

=head1 SYNOPSIS

	use Acme::Scurvy::Whoreson::BilgeRat;
  
	my $insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new(
		language => 'insultserver'
	);
  
	print $insultgenerator; # prints an insult


=head1 DESCRIPTION

We used to have the Insult Server at http://insulthost.colorado.edu 
which you could telnet to on port 1695 to get a random insult. And Lo! 
it was fun. 

Useless, but fun.

Sadly, it's down now. This is a reimplementation in Perl.

=head1 BUGS

Should be able to specify another config file, possibly though environment variables.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

based on code by 

James Garnett <garnett@colorado.edu>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

http://insulthost.colorado.edu/

=cut


sub new {
	my $class = shift;
	
	my $self = {};

	my $pos = tell DATA;
    while(<DATA>) {
        chomp;
        next if /^\s*$/;
		next if /^\s*#/;
		next unless s!^\s*(adj|amt|noun)\s+!!i;
		my $what = $1;
		# turn the '|' character into a space
		push @{$self->{$what}}, map { s!\|! !g; $_ } split ' ', $_;	
    }

    seek DATA, $pos,0;


	return bless $self, $class;
}

sub generateinsult {
	my $self  =shift;

	my @adj  = @{$self->{adj}};
	my @noun = @{$self->{noun}};
	my @amt  = @{$self->{amt}}; 

	my $adj1   = rand @{$self->{adj}};
	my $adj2   = $adj1;
	do { $adj2 = rand @{$self->{adj}} } while ($adj1 == $adj2);

	$adj1      = $adj[$adj1];
	$adj2      = $adj[$adj2];

	my $amt    = $amt[rand @amt];
	my $noun   = $noun[rand @noun];


	my $return  = "You are nothing but a";
	$return    .= 'n' if substr($adj1,0,1) =~ m![aeiou]!;
	$return    .= sprintf(" %s %s of %s %s.", $adj1, $amt, $adj2, $noun);

	return $return;

}
1;
__DATA__
#
# configuration file for colorado insult server
#
# Use the '|' character to include a space in the middle of a noun, adjective
# or amount (it'll get transmogrified into a space.  No, really!).
#
# Mon Mar 16 10:49:53 MST 1992 garnett added more colorful insults
# Fri Dec  6 10:48:43 MST 1991 garnett
#

##
# Adjectives
##
adj acidic antique contemptible culturally-unsound despicable evil fermented
adj festering foul fulminating humid impure inept inferior industrial
adj left-over low-quality malodorous off-color penguin-molesting
adj petrified pointy-nosed salty sausage-snorfling tastless tempestuous
adj tepid tofu-nibbling unintelligent unoriginal uninspiring weasel-smelling
adj wretched spam-sucking egg-sucking decayed halfbaked infected squishy
adj porous pickled coughed-up thick vapid hacked-up
adj unmuzzled bawdy vain lumpish churlish fobbing rank craven puking
adj jarring fly-bitten pox-marked fen-sucked spongy droning gleeking warped
adj currish milk-livered surly mammering ill-borne beef-witted tickle-brained
adj half-faced headless wayward rump-fed onion-eyed beslubbering villainous
adj lewd-minded cockered full-gorged rude-snouted crook-pated pribbling
adj dread-bolted fool-born puny fawning sheep-biting dankish goatish
adj weather-bitten knotty-pated malt-wormy saucyspleened motley-mind
adj it-fowling vassal-willed loggerheaded clapper-clawed frothy ruttish
adj clouted common-kissing pignutted folly-fallen plume-plucked flap-mouthed
adj swag-bellied dizzy-eyed gorbellied weedy reeky measled spur-galled mangled
adj impertinent bootless toad-spotted hasty-witted horn-beat yeasty
adj imp-bladdereddle-headed boil-brained tottering hedge-born hugger-muggered 
adj elf-skinned

##
# Amounts 
##
amt accumulation bucket coagulation enema-bucketful gob half-mouthful
amt heap mass mound petrification pile puddle stack thimbleful tongueful
amt ooze quart bag plate ass-full assload 

##
# Objects
##
noun bat|toenails bug|spit cat|hair chicken|piss dog|vomit dung
noun fat-woman's|stomach-bile fish|heads guano gunk pond|scum rat|retch
noun red|dye|number-9 Sun|IPC|manuals waffle-house|grits yoo-hoo
noun dog|balls seagull|puke cat|bladders pus urine|samples
noun squirrel|guts snake|assholes snake|bait buzzard|gizzards
noun cat-hair-balls rat-farts pods armadillo|snouts entrails
noun snake|snot eel|ooze slurpee-backwash toxic|waste Stimpy-drool
noun poopy poop craptacular|carpet|droppings jizzum cold|sores anal|warts

