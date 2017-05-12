package Acme::Scurvy::Whoreson::BilgeRat::Backend::lala;

$VERSION = '1.0';

use warnings;
use strict;

use base 'Acme::Scurvy::Whoreson::BilgeRat';

=head1 NAME

Acme::Scurvy::Whoreson::BilgeRat::Backend::lala - generate insults in the style of one of London.pm's bots

=head1 SYNOPSIS

    use Acme::Scurvy::Whoreson::BilgeRat;

    my $insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new(
        language => 'lala'
    );

    print $insultgenerator; # prints a piratical insult


=head1 DESCRIPTION

The IRC channel #london.pm on the rhizomatic network used to have a bot, 
called Lala, that would insult you in her own inimitable style.

This is a backed for C<Acme::Scurvy::Whoreson::BilgeRat> that reproduces that style.

It's useless to anyone but this one particular project I'm working on. 
But since when has that stopped me?

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

based on code by

Jonathan Stowe <jns@gellyfish.com>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

http://london.pm.org

=cut



sub new {
	my $class = shift;
	
	my (@noun, @adj1, @adj2);

	my $pos = tell DATA;
    while(<DATA>) {
        chomp;
        next if /^\s*$/;


        my ($adj1,$adj2,$noun) = split;

        push @adj1, $adj1;
        push @adj2, $adj2;
        push @noun, $noun;
    }

    seek DATA, $pos,0;


	return bless { noun => \@noun, adj1 => \@adj1, adj2 => \@adj2 }, $class;
}

sub generateinsult {
	my $self  =shift;
	my @adj1  = @{$self->{adj1}};
	my @adj2  = @{$self->{adj2}};
	my @noun  = @{$self->{noun}};

  	return $adj1[rand @adj1] . " ";
           $adj2[rand @adj2] . " " .
           $noun[ rand @noun];
}
1;
__DATA__
artless          base-court           apple-john
bawdy            bat-fowling          baggage
beslubbering     beef-witted          barnacle
bootless         beetle-headed        bladder
churlish         boil-brained         boar-pig
cockered         clapper-clawed       bugbear
clouted          clay-brained         bum-bailey
craven           common-kissing       canker-blossom
currish          crook-pated          clack-dish
dankish          dismal-dreaming      clotpole
dissembling      dizzy-eyed           coxcomb
droning          doghearted           codpiece
errant           dread-bolted         death-token
fawning          earth-vexing         dewberry
fobbing          elf-skinned          flap-dragon
froward          fat-kidneyed         flax-wench
gleeking         flap-mouthed         foot-licker
goatish          fly-bitten           fustilarian
gorbellied       folly-fallen         giglet
impertinent      fool-born            gudgeon
infectious       full-gorged          haggard
jarring          guts-griping         harpy
loggerheaded     half-faced           hedge-pig
lumpish          hasty-witted         horn-beast
mammering        hedge-born           hugger-mugger
mangled          hell-hated           jolthead
mewling          idle-headed          lewdster
paunchy          ill-breeding         lout
pribbling        ill-nurtured         maggot-pie
puking           knotty-pated         malt-worm
puny             milk-livered         mammet
quailing         motley-minded        measle
rank             onion-eyed           minnow
reeky            plume-plucked        miscreant
roguish          pottle-deep          moldwarp
ruttish          pox-marked           mumble-news
saucy            reeling-ripe         nut-hook
spleeny          rough-hewn           pigeon-egg
spongy           rude-growing         pignut
surly            rump-fed             puttock
tottering        shard-borne          pumpion
unmuzzled        sheep-biting         ratsbane
vain             spur-galled          scut
venomed          swag-bellied         skainsmate
villainous       tardy-gaited         strumpet
warped           tickle-brained       varlet
wayward          toad-spotted         vassal
weedy            urchin-snouted       whey-face
yeasty           weather-bitten       wagtail
