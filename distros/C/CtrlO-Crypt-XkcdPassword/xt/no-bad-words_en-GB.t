#!/usr/bin/perl
use Test::More;
use strict;
use warnings;
use lib 'lib';

use Data::Handle;
use Bad::Words;
use CtrlO::Crypt::XkcdPassword::Wordlist::en_gb;

my $handle = eval { Data::Handle->new('CtrlO::Crypt::XkcdPassword::Wordlist::en_gb') };
my %list = map { s/\n//g; chomp; $_ => 1 } $handle->getlines;

my $badwords = Bad::Words->newthrd; # what a strange API
push(@$badwords,map { chomp; $_ } <DATA>); # add some words we already removed from the list

foreach my $bad (@$badwords) {
    ok(!$list{$bad}, "questionable word not in list: $bad");
}

done_testing();

__DATA__
abortion
abuse
abuser
asexual
assault
assaulter
bareback
bastard
bible
biblical
bigamist
bigamy
bitch
bludgeon
bondage
booby
bosom
breast
bugger
bummer
buttock
cleavage
cocaine
communion
condom
devil
drugstore
ejaculate
erection
erotic
faggot
fiddle
fiddler
foreplay
foreskin
genital
genocide
girdle
holocaust
kidnap
kidnapper
killer
knife
lesbian
machete
mallet
marijuana
massacre
menopause
menstrual
orgasm
rapist
rectum
sadism
sadist
sadistic
satanic
semen
sexism
sexist
sexual
sexuality
sexually
slash
slaughter
sodomy
sorcerer
sorcery
sperm
spunk
stillborn
vagina
vaginae
vaginal
virgin
virginity
