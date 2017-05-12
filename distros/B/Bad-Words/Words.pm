package Bad::Words;

use strict;

use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 0.09 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head1 NAME

Bad::Words - a list of bad words

=head1 KEYWORDS

abuse bad dirty words vulgar swear slang drugs sex profane
abusive profanity vulgarity swearing sexual slurs

=head1 SYNOPSIS

  require Bad::Words;

  my $wordref = once Bad::Words qw(add words);
  my $wordref = new Bad::Words qw(add more words);
  my $wordref = newthrd Bad::Words qw(add words);
  my $updated = $wordref->remove(qw( words to remove ));
  my $numberOfWords = $updated->count;

=head1 DESCRIPTION

This module returns an array REF to an alphabetically sorted list of LOWER CASE B<bad words>.
You can add more words during initiliazation with B<once>, B<new>, and B<newthrd>.

The list contains American dirty words, swear words, etc...

=head1 WORD SOURCES

The words are taken from the public domain, internet sites and the
imagination of contributors.
 
	=========================================

  http://fffff.at/googles-official-list-of-bad-words/

The contents of the site are all in the public domain. You may enjoy, use,
modify, snipe about and republish all F.A.T. media and technologies as you
see fit.
 
	=========================================

=cut

#
#easterEgg.BadWorder.list={

my @google = (qw(
4r5e
5h1t
5hit
a55
anal
anus
ar5e
arrse
arse
ass
ass-fucker
asses
assfucker
assfukka
asshole
assholes
asswhole
a_s_s
b!tch
b00bs
b17ch
b1tch
ballbag
balls
ballsack
bastard
beastial
beastiality
bellend
bestial
bestiality
bi+ch
biatch
bitch
bitcher
bitchers
bitches
bitchin
bitching
bloody),
'blow job', qw(
blowjob
blowjobs
boiolas
bollock
bollok
boner
boob
boobs
booobs
boooobs
booooobs
booooooobs
breasts
buceta
bugger
bum),
'bunny fucker', qw(
butt
butthole
buttmuch
buttplug
c0ck
c0cksucker),
'carpet muncher', qw(
cawk
chink
cipa
cl1t
clit
clitoris
clits
cnut
cock
cock-sucker
cockface
cockhead
cockmunch
cockmuncher
cocks
cocksuck
cocksucked
cocksucker
cocksucking
cocksucks
cocksuka
cocksukka
cok
cokmuncher
coksucka
coon
cox
crap
cum
cummer
cumming
cums
cumshot
cunilingus
cunillingus
cunnilingus
cunt
cuntlick
cuntlicker
cuntlicking
cunts
cyalis
cyberfuc
cyberfuck
cyberfucked
cyberfucker
cyberfuckers
cyberfucking
d1ck
damn
dick
dickhead
dildo
dildos
dink
dinks
dirsa
dlck
dog-fucker
doggin
dogging
donkeyribber
doosh
duche
dyke
ejaculate
ejaculated
ejaculates
ejaculating
ejaculatings
ejaculation
ejakulate),
'f u c k',
'f u c k e r', qw(
f4nny
fag
fagging
faggitt
faggot
faggs
fagot
fagots
fags
fanny
fannyflaps
fannyfucker
fanyy
fatass
fcuk
fcuker
fcuking
feck
fecker
felching
fellate
fellatio
fingerfuck
fingerfucked
fingerfucker
fingerfuckers
fingerfucking
fingerfucks
fistfuck
fistfucked
fistfucker
fistfuckers
fistfucking
fistfuckings
fistfucks
flange
fook
fooker
fuck
fucka
fucked
fucker
fuckers
fuckhead
fuckheads
fuckin
fucking
fuckings
fuckingshitmotherfucker
fuckme
fucks
fuckwhit
fuckwit
fudge packer
fudgepacker
fuk
fuker
fukker
fukkin
fuks
fukwhit
fukwit
fux
fux0r
f_u_c_k
gangbang
gangbanged
gangbangs
gaylord
gaysex
goatse
God
god-dam
god-damned
goddamn
goddamned
hardcoresex
hell
heshe
hoar
hoare
hoer
homo
hore
horniest
horny
hotsex
jack-off
jackoff
jap
jerk-off
jism
jiz
jizm
jizz
kawk
knob
knobead
knobed
knobend
knobhead
knobjocky
knobjokey
kock
kondum
kondums
kum
kummer
kumming
kums
kunilingus
l3i+ch
l3itch
labia
lmfao
lust
lusting
m0f0
m0fo
m45terbate
ma5terb8
ma5terbate
masochist
master-bate
masterb8
masterbat
masterbat3
masterbate
masterbation
masterbations
masturbate
mo-fo
mof0
mofo
mothafuck
mothafucka
mothafuckas
mothafuckaz
mothafucked
mothafucker
mothafuckers
mothafuckin
mothafucking
mothafuckings
mothafucks),
'mother fucker', qw(
motherfuck
motherfucked
motherfucker
motherfuckers
motherfuckin
motherfucking
motherfuckings
motherfuckka
motherfucks
muff
mutha
muthafecker
muthafuckker
muther
mutherfucker
n1gga
n1gger
nazi
nigg3r
nigg4h
nigga
niggah
niggas
niggaz
nigger
niggers
nob),
'nob jokey', qw(
nobhead
nobjocky
nobjokey
numbnuts
nutsack
orgasim
orgasims
orgasm
orgasms
p0rn
pawn
pecker
penis
penisfucker
phonesex
phuck
phuk
phuked
phuking
phukked
phukking
phuks
phuq
pigfucker
pimpis
piss
pissed
pisser
pissers
pisses
pissflaps
pissin
pissing
pissoff
poop
porn
porno
pornography
pornos
prick
pricks
pron
pube
pusse
pussi
pussies
pussy
pussys
rectum
retard
rimjaw
rimming),
's hit', qw(
s.o.b.
sadist
schlong
screwing
scroat
scrote
scrotum
semen
sex
sh!+
sh!t
sh1t
shag
shagger
shaggin
shagging
shemale
shi+
shit
shitdick
shite
shited
shitey
shitfuck
shitfull
shithead
shiting
shitings
shits
shitted
shitter
shitters
shitting
shittings
shitty
skank
slut
sluts
smegma
smut
snatch
son-of-a-bitch
spac
spunk
s_h_i_t
t1tt1e5
t1tties
teets
teez
testical
testicle
tit
titfuck
tits
titt
tittie5
tittiefucker
titties
tittyfuck
tittywank
titwank
tosser
turd
tw4t
twat
twathead
twatty
twunt
twunter
v14gra
v1gra
vagina
viagra
vulva
w00se
wang
wank
wanker
wanky
whoar
whore
willies
willy
xrated
xxx
));

=pod

  http://urbanoalvarez.es/blog/2008/04/04/bad-words-list/

A public forum

	=========================================

=cut

my @urbanos = (qw(
ahole
anus
ash0le
ash0les
asholes
ass),
'Ass Monkey', qw(
Assface
assh0le
assh0lez
asshole
assholes
assholz
asswipe
azzhole
bassterds
bastard
bastards
bastardz
basterds
basterdz
Biatch
bitch
bitches
Blow Job
boffing
butthole
buttwipe
c0ck
c0cks
c0k),
'Carpet Muncher', qw(
cawk
cawks
Clit
cnts
cntz
cock
cockhead
cock-head
cocks
CockSucker
cock-sucker
crap
cum
cunt
cunts
cuntz
dick
dild0
dild0s
dildo
dildos
dilld0
dilld0s
dominatricks
dominatrics
dominatrix
dyke
enema),
'f u c k',
'f u c k e r', qw(
fag
fag1t
faget
fagg1t
faggit
faggot
fagit
fags
fagz
faig
faigs
fart),
'flipping the bird', qw(
fuck
fucker
fuckin
fucking
fucks),
'Fudge Packer', qw(
fuk
Fukah
Fuken
fuker
Fukin
Fukk
Fukkah
Fukken
Fukker
Fukkin
g00k
gay
gayboy
gaygirl
gays
gayz
God-damned
h00r
h0ar
h0re
hells
hoar
hoor
hoore
jackoff
jap
japs
jerk-off
jisim
jiss
jizm
jizz
knob
knobs
knobz
kunt
kunts
kuntz
Lesbian
Lezzian
Lipshits
Lipshitz
masochist
masokist
massterbait
masstrbait
masstrbate
masterbaiter
masterbate
masterbates),
'Motha Fucker',
'Motha Fuker',
'Motha Fukkah',
'Motha Fukker',
'Mother Fucker',
'Mother Fukah',
'Mother Fuker',
'Mother Fukkah',
'Mother Fukker',
'mother-fucker',
'Mutha Fucker',
'Mutha Fukah',
'Mutha Fuker',
'Mutha Fukkah',
'Mutha Fukker', qw(
n1gr
nastt
nigger
nigur
niiger
niigr;
orafis
orgasim;
orgasm
orgasum
oriface
orifice
orifiss
packi
packie
packy
paki
pakie
paky
pecker
peeenus
peeenusss
peenus
peinus
pen1s
penas
penis
penis-breath
penus
penuus
Phuc
Phuck
Phuk
Phuker
Phukker
polac
polack
polak
Poonani
pr1c
pr1ck
pr1k
pusse
pussee
pussy
puuke
puuker
queer
queers
queerz
qweers
qweerz
qweir
recktum
rectum
retard
sadist
scank
schlong
screwing
semen
sex
sexy
Sh!t
sh1t
sh1ter
sh1ts
sh1tter
sh1tz
shit
shits
shitter
Shitty
Shity
shitz
Shyt
Shyte
Shytty
Shyty
skanck
skank
skankee
skankey
skanks
Skanky
slut
sluts
Slutty
slutz
son-of-a-bitch
tit
turd
va1jina
vag1na
vagiina
vagina
vaj1na
vajina
vullva
vulva
w0p
wh00r
wh0re
whore
xrated
xxx
b!+ch
bitch
blowjob
clit
arschloch
fuck
shit
ass
asshole
b!tch
b17ch
b1tch
bastard
bi+ch
boiolas
buceta
c0ck
cawk
chink
cipa
clits
cock
cum
cunt
dildo
dirsa
ejakulate
fatass
fcuk
fuk
fux0r
hoer
hore
jism
kawk
l3itch
l3i+ch
lesbian
masturbate
masterbat
masterbat3
motherfucker
s.o.b.
mofo
nazi
nigga
nigger
nutsack
phuck
pimpis
pusse
pussy
scrotum
sh!t
shemale
shi+
sh!+
slut
smut
teets
tits
boobs
b00bs
teez
testical
testicle
titt
w00se
jackoff
wank
whoar
whore
damn
dyke
fuck
shit
amcik
andskota
arse
assrammer
ayir
bi7ch
bitch
bollock
breasts
butt-pirate
cabron
cazzo
chraa
chuj
Cock
cunt
d4mn
daygo
dego
dick
dike
dupa
dziwka
ejackulate
Ekrem
Ekto
enculer
faen
fag
fanculo
fanny
feces
feg
Felcher
ficken
fitt
Flikker
foreskin
Fotze),
'Fu\(',		# HERE mark
'@$$', qw(
fuk
futkretzn
gay
gook
guiena
h0r
h4x0r
hell
helvete
hoer
honkey
Huevon
hui
injun
jizz
kanker
kike
klootzak
kraut
knulle
kuk
kuksuger
Kurac
kurwa
kusi
kyrpa
lesbo
mamhoon
masturbat
merd
mibun
monkleigh
mouliewop
muie
mulkku
muschi
nazis
nepesaurio
nigger
orospu
paska
perse
picka
pierdol
pillu
pimmel
piss
pizda
poontsee
poop
porn
p0rn
pr0n
preteen
pula
pule
puta
puto
qahbeh
queef
rautenberg
schaffer
scheiss
schlampe
schmuck
screw
sh!t
sharmuta
sharmute
shipal
shiz
skribz
skurwysyn
sphencter
spic
spierdalaj
splooge
suka
b00b
testicle
titt
twat
vittu
wank
wetback
wichser
wop
yed
zabourah
));

=pod

  http://wordpress.org/support/topic/plugin-wp-content-filter-list-of-swear-words
  posted to http://www.ourchangingglobe.com/misc/badwords-comma.txt

  GPL2V2

	=========================================

=cut

my @changing = ('ahole','anus','ash0le','ash0les','asholes','ass','Ass Monkey','Assface',
'assh0le','assh0lez','asshole','assholes','assholz','asswipe','azzhole','bassterds','bastard',
'bastards','bastardz','basterds','basterdz','Biatch','bitch','bitches','Blow Job','boffing',
'butthole','buttwipe','c0ck','c0cks','c0k','Carpet Muncher','cawk','cawks','Clit','cnts','cntz',
'cock','cockhead','cock-head','cocks','CockSucker','cock-sucker','crap','cum','cunt','cunts',
'cuntz','dick','dild0','dild0s','dildo','dildos','dilld0','dilld0s','dominatricks','dominatrics',
'dominatrix','dyke','enema','f u c k','f u c k e r','fag','fag1t','faget','fagg1t','faggit',
'faggot','fagit','fags','fagz','faig','faigs','fart','flipping the bird','fuck','fucker',
'fuckin','fucking','fucks','Fudge Packer','fuk','Fukah','Fuken','fuker','Fukin','Fukk','Fukkah',
'Fukken','Fukker','Fukkin','g00k','gay','gayboy','gaygirl','gays','gayz','God-damned','h00r',
'h0ar','h0re','hells','hoar','hoor','hoore','jackoff','jap','japs','jerk-off','jisim','jiss','jizm',
'jizz','knob','knobs','knobz','kunt','kunts','kuntz','Lesbian','Lezzian','Lipshits','Lipshitz',
'masochist','masokist','massterbait','masstrbait','masstrbate','masterbaiter','masterbate',
'masterbates','Motha Fucker','Motha Fuker','Motha Fukkah','Motha Fukker','Mother Fucker',
'Mother Fukah','Mother Fuker','Mother Fukkah','Mother Fukker','mother-fucker','Mutha Fucker',
'Mutha Fukah','Mutha Fuker','Mutha Fukkah','Mutha Fukker','n1gr','nastt','nigger','nigur','niiger',
'niigr','orafis','orgasim','orgasm','orgasum','oriface','orifice','orifiss','packi','packie',
'packy','paki','pakie','paky','pecker','peeenus','peeenusss','peenus','peinus','pen1s','penas',
'penis','penis-breath','penus','penuus','Phuc','Phuck','Phuk','Phuker','Phukker','polac','polack',
'polak','Poonani','pr1c','pr1ck','pr1k','pusse','pussee','pussy','puuke','puuker','queer','queers',
'queerz','qweers','qweerz','qweir','recktum','rectum','retard','sadist','scank','schlong','screwing',
'semen','sex','sexy','Sh!t','sh1t','sh1ter','sh1ts','sh1tter','sh1tz','shit','shits','shitter',
'Shitty','Shity','shitz','Shyt','Shyte','Shytty','Shyty','skanck','skank','skankee','skankey',
'skanks','Skanky','slut','sluts','Slutty','slutz','son-of-a-bitch','tit','turd','va1jina','vag1na',
'vagiina','vagina','vaj1na','vajina','vullva','vulva','w0p','wh00r','wh0re','whore','xrated','xxx');

#################
#
# assorted additional words

my @assorted = (
'batty man', qw(
bender
bollocks
bumboy
cracker
cumsucker
douchebag
fucktwat
ho
honky
jackass),
'joey semen',
'joey deacon', qw(
knobcheese
minge
minger
mong
munter
pickle
rimmer
spakka
spaz
taint
tool
));

my $ref;	# not thread safe

sub once {
  return $ref if $ref;
  &new;
}

sub new {
  $ref = &newthrd;
}

sub newthrd {
  my $proto = shift;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $wr = ref($_[0]) ? $_[0] : [@_];
  my @add = grep { defined $_ && $_ ne '' } @$wr;	# strip empty and undefined entries
  my %uniq = map { lc($_) => 1 } (@google,@urbanos,@changing,@assorted,@add);
  my @list = sort keys %uniq;
  bless \@list, $class;
}

my $passes;
sub remove {
  my $wr = shift;
  my $x = ref($_[0]) ? $_[0] : [@_];
  return $wr unless @$x;	# empty or missing list
  my @list = sort grep { defined $_ && $_ ne '' && ($_ = lc $_) }@$x;
# attempt to remove words in a single pass
# this will fail if the 'remove' word in not
# in the bad list. Hence the while loop
  $passes = 0;			# for debug
LIST:
  while (defined (my $s = shift @list)) {
    $passes++;
    for (my $i=0;$i< @$wr;) {
      if ($s eq $wr->[$i]) {
	splice @$wr,$i,1;
	last LIST unless defined ($s = shift @list);	# end of list?
      } else {
	$i++;
      }
    }
  }
  $wr;
}

sub _passes { return $passes };

sub noregex {
  my($wr,$regex) = @_;
  return $wr unless defined $regex;
  for (my $i=0;$i< @$wr;) {
    if ($wr->[$i] =~ /$regex/) {
      splice @$wr,$i,1;
      next;
    }
    $i++;
  }
  $wr;
}

sub count {
  return scalar @{$_[0]};
}

1;
__END__

=head1 USAGE

  my $wordref = new Bad::Words qw( new swear words );
  my $updated = $wordref->remove(qw( these words ));

  my $badwords = join '|' @$updated;

  my $paragraph= 'a bunch of text...';

  if ($paragraph =~ /($badwords)/oi) {
      print "paragraph contains badword '$1'\n";
  }

The above regex is aggressive and will find "tit" in title. To be less
agressive, try:

  if ($paragraph =~ /\b($badwords)\b/oi {
      print "paragraph contains badword '$1'\n";
  }

=head1 DESCRIPTION

WARNING: B<once> and B<new> store the list reference in a lexical variable
within the module. B<newthrd> does not do this. B<once> returns this stored variable
if it is already initialized. This is suitable for use in web servers where
each httpd child has its own non-thread environment. If you intend to use
Bad::Words in a threaded environment, do not use B<once> and B<new>, use
B<newthrd> instead.

=over 4

=item * $wordref = new Bad::Words qw(optional list of more words);

This method converts all words in the combined lists to lower case, make the
list unique, sorts it and returns a blessed reference.

  input:	a reference to or a list of
		optional additional bad words
  return:	reference to word list

=item * $wordref = once Bad::Words qw(optional list of more words);

This method performs the B<new> operation B<once> and on subsequent calls,
it just returns the pre-computed reference.

  input:	a reference to or a list of
		optional additional bad words
  return:	reference to word list

=item * $wordref = newthrd Bad::Words qw(optional list of words);

This method recalculates the bad word list on every call.

  input:	a reference to or a list of
		optional additional bad words
  return:	reference to word list

=item * $updated = $wordref->remove list;

This method removes words from the bad word list.

  input:	a reference to or a list of
		words to remove from bad word list
  return:	updated reference

=item * $updated = $wordref->noregex('regex string');

This method removes all words from the list 
that match the 'regex string'. The regular expression will be used on each
word in the list as follows:

	my $regex = shift;
	foreach(@word) {
	  remove word if $_ =~ /$regex/;
	}

  input:	'a regular expression string'
  return:	updated reference

=item * $numberOfWords = $wordref->count;

This method returns the number of unique words in the bad word list.

  input:	none
  return:	number of words

=back

=head1 AUTHOR

Michael Robinton E<lt>michael@bizsystems.comE<gt>

=head1 COPYRIGHT  

    Copyright 2013-2014, Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2.

You should also have received a copy of the GNU General Public License
along with this program in the file named "GPL". If not, write to the 

        Free Software Foundation, Inc.
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA

or visit their web page on the internet at:

        http://www.gnu.org/copyleft/gpl.html.

=cut
