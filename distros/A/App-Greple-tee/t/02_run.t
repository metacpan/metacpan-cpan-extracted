use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib './t';
use Util;

use Text::ParseWords qw(shellwords);
use Getopt::Long 'Configure';
Configure qw(bundling no_getopt_compat no_ignore_case);
GetOptions(\my %opt,
           'data-section',	# produce data section
           'example',		# show command execution example
           'show',		# show test
           'number|n=i',	# select test number
) or die;

use File::Spec;
$ENV{HOME} = File::Spec->rel2abs('t/home');
$ENV{NO_COLOR} = '1';

use Data::Section::Simple qw(get_data_section);
my $expected = get_data_section;

use File::Slurper 'read_lines';
my $sh = $0 =~ s/\.t/.sh/r;
my @command = read_lines $sh or die;

if ($opt{show}) {
    for (keys @command) {
	printf "%4d: %s\n", $_, $command[$_];
    }
    exit;
}

if (defined(my $n = $opt{number})) {
    die "$n: invalid number\n" if $n > $#command;
    @command = $command[$n];
}

for (@command) {
    my @command = shellwords $_;
    shift @command if $command[0] eq 'greple';
    my $result = run(@command)->stdout;
    if ($opt{example}) {
	printf "\$ %s\n", $_;
	print $result;
    }
    elsif ($opt{'data-section'}) {
	printf "\@\@ %s\n", $_;
	print $result;
    }
    else {
	is($result, $expected->{$_}, $_);
    }
}

exit if %opt;

done_testing;

__DATA__

@@ greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
     1	The quick brown fox
     2	jumps over the lazy dog.
     3	1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

     4	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     5	Sylvia wagt quick den Jux bei Pforzheim.

     6	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     7	Le cœur déçu mais l'âme plutôt naïve,
     8	Louÿs rêva de crapaüter en canoë au delà des îles,
     9	près du mälströn où brûlent les novæ.

    10	El veloz murciélago hindú comía feliz cardillo y kiwi.
    11	La cigüeña tocaba el saxofón detrás del palenque de paja.
@@ greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
     1	The quick brown fox
     2	jumps over the lazy dog.
     3	1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

     1	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     1	Sylvia wagt quick den Jux bei Pforzheim.

     1	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     1	Le cœur déçu mais l'âme plutôt naïve,
     2	Louÿs rêva de crapaüter en canoë au delà des îles,
     3	près du mälströn où brûlent les novæ.

     1	El veloz murciélago hindú comía feliz cardillo y kiwi.
     2	La cigüeña tocaba el saxofón detrás del palenque de paja.
@@ greple -Mtee perl -CSAD -pE '$_="($.)$_"' -- '\S+' t/SAMPLE.txt --all
(1)The (2)quick (3)brown (4)fox
(5)jumps (6)over (7)the (8)lazy (9)dog.
(10)1234567890

(11)いろはにほへとちりぬるを
(12)わかよたれそつねならむ
(13)うゐのおくやまけふこえて
(14)あさきゆめみしゑひもせすん

(15)色は匂へど散りぬるを
(16)我が世誰そ常ならむ
(17)有為の奥山今日越えて
(18)浅き夢見じ酔ひもせず.

(19)Ma (20)la (21)volpe (22)col (23)suo (24)balzo (25)ha (26)raggiunto (27)il (28)quieto (29)Fido.

(30)Sylvia (31)wagt (32)quick (33)den (34)Jux (35)bei (36)Pforzheim.

(37)Victor (38)jagt (39)zwölf (40)Boxkämpfer (41)quer (42)über (43)den (44)großen (45)Sylter (46)Deich.

(47)Le (48)cœur (49)déçu (50)mais (51)l'âme (52)plutôt (53)naïve,
(54)Louÿs (55)rêva (56)de (57)crapaüter (58)en (59)canoë (60)au (61)delà (62)des (63)îles,
(64)près (65)du (66)mälströn (67)où (68)brûlent (69)les (70)novæ.

(71)El (72)veloz (73)murciélago (74)hindú (75)comía (76)feliz (77)cardillo (78)y (79)kiwi.
(80)La (81)cigüeña (82)tocaba (83)el (84)saxofón (85)detrás (86)del (87)palenque (88)de (89)paja.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
THE QUICK BROWN FOX
JUMPS OVER THE LAZY DOG.
1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE,
LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES,
PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI.
LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
THE QUICK BROWN FOX
JUMPS OVER THE LAZY DOG.
1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE,
LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES,
PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI.
LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. 1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE, LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES, PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI. LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup --discrete
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. 1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE, LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES, PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI. LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup
     1	The quick brown fox jumps over the lazy dog. 1234567890

     2	いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせすん

     3	色は匂へど散りぬるを我が世誰そ常ならむ有為の奥山今日越えて浅き夢見じ酔ひもせず.

     4	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     5	Sylvia wagt quick den Jux bei Pforzheim.

     6	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     7	Le cœur déçu mais l'âme plutôt naïve, Louÿs rêva de crapaüter en canoë au delà des îles, près du mälströn où brûlent les novæ.

     8	El veloz murciélago hindú comía feliz cardillo y kiwi. La cigüeña tocaba el saxofón detrás del palenque de paja.
@@ greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup --discrete
     1	The quick brown fox jumps over the lazy dog. 1234567890

     1	いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせすん

     1	色は匂へど散りぬるを我が世誰そ常ならむ有為の奥山今日越えて浅き夢見じ酔ひもせず.

     1	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     1	Sylvia wagt quick den Jux bei Pforzheim.

     1	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     1	Le cœur déçu mais l'âme plutôt naïve, Louÿs rêva de crapaüter en canoë au delà des îles, près du mälströn où brûlent les novæ.

     1	El veloz murciélago hindú comía feliz cardillo y kiwi. La cigüeña tocaba el saxofón detrás del palenque de paja.
