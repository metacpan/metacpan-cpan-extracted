package CEDict::Pinyin;
# Copyright (c) 2009 Christopher Davaz. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
use strict;
use warnings;
use vars qw($VERSION);
use base qw(Class::Light);
use Carp;
use Encode;

$VERSION = '0.02004';

=encoding utf8

=head1 NAME

CEDict::Pinyin - Validates pinyin strings

=head1 SYNOPSIS

    # This is from the test case provided with this module:

    use CEDict::Pinyin;

    my @good = ("ji2 - rui4 cheng2", "xi'an", "dian4 nao3, yuyan2", "kongzi");
    my @bad  = ("123", "not pinyin", "gu1 gu1 fsck4 fu3");
    my $py   = CEDict::Pinyin->new;

    for (@good) {
      $py->setSource($_);
      ok($py->isPinyin, "correctly validated good pinyin");
      print "pinyin: " . $py->getSource . "\n";
      print "parts: " . join(', ', @{$py->getParts}) . "\n";
    }

    for (@bad) {
      $py->setSource($_);
      ok(!$py->isPinyin, "correctly invalidated bad pinyin");
      print "pinyin: " . $py->getSource . "\n";
      print "parts: " . join(', ', @{$py->getParts}) . "\n";
    }

=head1 DESCRIPTION

This class helps you validate and parse pinyin. Currently the pinyin must follow
some rules about how it is formatted before being considered "valid" by this
class's validation method. All valid pinyin syllables are expressed by characters
within the 7-bit ASCII range. That means the validation method will fail on a
string like "nán nǚ lǎo shào". The pinyin should instead contain numbers after
the letter to represent tones. Instead of the string above we should use
"nan2 nv lao3 shao4". Being able to accept a string with accented characters
that represent the tone of the syllable is a feature I hope to add to a future
version of this module. The parser first takes a look at the entires string
you pass it to see if it is even worth parsing. The regular expression used
is shown below.

C<< /^[A-Za-z]+[A-Za-z1-5,'\- ]*$/ >>

If the pinyin doesn't match this regex, then isPinyin returns false and stops
parsing the string. All this means is that if you want to use this module to
validate your pinyin but your pinyin is not exactly in the same format as
just described then you need cleanup your pinyin strings a little bit first.

Again, hopefully future versions of this class will be more flexible in what
is accepted as valid pinyin. However we want to be sure that what we are looking
at is really pinyin and not some English words as this module was originally
written in part to distinguish between a pinyin string and English. I would
also like to keep this idea in future versions, so if you update the class
with your own code, please keep that in mind.

=cut

# Class Data defined here
my %ValidPinyin;
$ValidPinyin{$_} = chomp $_ while <DATA>;
close DATA;

# Characters containing the diacritic marks used in pinyin. The array is ordered
# by tone number (however since arrays are 0-indexed the first-tone diacritic
# information is at $Tones[0]).
my @Tones = (
{a=>"\x{0101}",e=>"\x{0113}",i=>"\x{012B}",o=>"\x{014D}",u=>"\x{016B}",v=>"\x{01D6}"},
{a=>"\x{00E1}",e=>"\x{00E9}",i=>"\x{00ED}",o=>"\x{00F3}",u=>"\x{00FA}",v=>"\x{01D8}"},
{a=>"\x{01CE}",e=>"\x{0115}",i=>"\x{01D0}",o=>"\x{01D2}",u=>"\x{01D4}",v=>"\x{01DA}"},
{a=>"\x{00E0}",e=>"\x{00E8}",i=>"\x{00EC}",o=>"\x{00F2}",u=>"\x{00F9}",v=>"\x{01DC}"}
);

sub getValidPinyin {
	return \%ValidPinyin;
}

=head2 Methods

=over 4

=item C<< CEDict::Pinyin->new( >>I<SCALAR>C<)>

Creates a new CEDict::Pinyin object. I<SCALAR> should be a string containing
the pinyin you want to work with. If I<SCALAR> is ommited it can be set later
using the C<setSource> method.

=cut

sub _init {
	my $self   = shift;
	my $source = shift || '';
	$self->{source} = $source;
  $self->{parts}  = [];
}

=item C<< $obj->setSource( >>I<SCALAR>C<)>

Sets the source string to work with. Currently only the C<isPinyin> method accesses
this attribute. Returns the previously set pinyin string.

=cut

sub setSource {
  my $self = shift;
  my $new  = shift;
  my $old  = $self->{source};

  $self->{source} = $new; 
  $self->{parts}  = [];

  return $old;
}

=item C<< $obj->diacritic >>

Returns the string of pinyin using diacritic marks instead of numbers to represent
tone information. For example, if the source pinyin is "nan2 nv lao3 shao4" then
C<< $obj->diacritic >> will return "nán nǚ lǎo shào".

=cut

# See http://www.pinyin.info/rules/where.html for a description of the
# rules regarding where tone marks go. These rules are copied here:
#
# * a and e trump all other vowels and always take the tone mark.
#   There are no Mandarin syllables in Hanyu Pinyin that contain
#   both a and e.
# * In the combination ou, o takes the mark.
# * In all other cases, the final vowel takes the mark.
#
sub diacritic {
	my $self   = shift;
	my $source = $self->{source};
	my $parts  = [];
	return unless $self->isPinyin($parts);
	my @parts  = @$parts;
	return unless @parts;
	my @string;

	for my $part (@parts) {
		$part =~ s/(.*)([1-5])/$1/;
		my $tone = ($2 ? $2 : 5) - 1;
		if ($tone < 4) {
			if ($part =~ /([ae])/) {
				my $vowel = $1;
				$part =~ s/$vowel/$Tones[$tone]{$vowel}/;
			} elsif ($part =~ /ou/) {
				$part =~ s/o/$Tones[$tone]{o}/;
			} elsif ($part =~ /v/) {
				$part =~ s/v/$Tones[$tone]{v}/;
			} elsif (reverse $part =~ /([aeiou])/) {
				my $vowel = $1;
				$part =~ s/$vowel/$Tones[$tone]{$vowel}/;
			}
		}
		push @string, $part;
	}

	return encode('UTF-8', join (' ', @string));
}

=item C<< $obj->getParts >>

Returns the individually parsed elements of the pinyin source string.

=cut

# defined by Class::Light

=item C<< $obj->getSource >>

Returns the pinyin source string that was supplied earlier either via the
constructor or C<< $obj->setSource >>.

=cut

# defined by Class::Light

=item C<< $obj->isPinyin >> I<or> C<< $obj>->isPinyin( >>I<ARRAYREF>C<)>

Validates the pinyin supplied to the constructor or to C<< $obj->setSource(SCALAR) >>.
If an I<ARRAYREF> is supplied as an argument, adds each syllable of the parsed pinyin
to the array. If a syllable is considered invalid then the method stops parsing and
immediately returns false. Returns true otherwise.

=cut

sub isPinyin {
	my $self   = shift;
	my $parts  = shift || $self->{parts};
	my $source = $self->{source};
	return unless $source;
	$source = lc $source;
	return 0 unless $source =~ /^[a-z]+[a-z1-5,'\- ]*$/;
	# Find all the alphabetic characters before a syllable boundary ([1-5,'\- ]).
	# The matched group may still consist of many syllables (for example, the
	# string "shenjingbing"). So we still need to split this string into its
	# constituent syllables.
	my @result = $source =~ /([a-z]+[1-5]?)/g;
	for my $validSubstring (@result) {
		my $lastValidSubstring;
		my $tone;

		$tone = $1 if $validSubstring =~ /([1-5])/;
		$validSubstring =~ s/[1-5]//;

		while (1) {
			$lastValidSubstring = $validSubstring;
			$validSubstring = _getValidSubstring($validSubstring);
			unless ($validSubstring) {
				push @$parts, $lastValidSubstring . ($tone ? $tone : "");
				last;
			}
			push @$parts, substr(
				$lastValidSubstring,
				0,
				length($lastValidSubstring) - length($validSubstring)
			);
		}
		return 0 unless defined $validSubstring;
	}
	return 1;
}

=item C<< CEDict::Pinyin->buildRegex( >>I<SCALAR>C<)>

Takes a string containing pinyin and returns a regular expression that can be used with
the MySQL database (so far only tested against the 5.1 series). Accepts an asterisk ("*")
as a wildcard. Note that the C<isPinyin> method will return false when validating such
a string, so if you plan on first validating the pinyin then generating the regex, make
sure you are validating the string without the asterisks C<($string =~ s/\*//g)>.

=back

=cut

sub buildRegex {
	my $self    = shift;
	my $source  = shift or return;
	$source =~ s/\*+/\*/g; # Collapse redundant wildcards into one
	my @reParts = ($source =~ /(\*|[^*]+)/g);
	my $regex   = '^';

	for (my $h = 0; $h < @reParts; $h++) {
		$_ = $reParts[$h];
		if ($_ eq '*') {
			$regex .= '.*';
			next;
		}
		my $pinyin = __PACKAGE__->new($_);
		my $parts  = []; $pinyin->isPinyin($parts);
		my @parts  = @$parts;
		return unless @parts;

		# Check if last part is a valid pinyin substring
		return unless _isValidInitialSubstring($parts[$#parts]);

		# Use parts to construct a MySQL regular expression
		for (my $i = 0; $i < @parts; $i++) {
			$regex .= $parts[$i];
			$regex .= '[1-5]?' unless $parts[$i] =~ /[1-5]/;
			unless (
				($h == $#reParts
					|| ($h == ($#reParts - 1) && $reParts[$#reParts] eq '*'))
				&& $i == $#parts) {
				$regex .=  "[,' -]";
			}
		}
	}

	$regex .= '$';
	return $regex;
}

# Private Static Method _isValidInitialSubstring
#
# Checks if $startsWith is the beginning of a valid pinyin string
sub _isValidInitialSubstring {
	my $startsWith = shift;
	$startsWith =~ s/[1-5]//;
	for (keys %ValidPinyin) {
		return 1 if /^$startsWith/;
	}
	return 0;
}

# Private Static Method _getValidSubstring
#
# _getValidSubstring returns the empty string if the entire $syllable matches
# a valid pinyin syllable. If only a portion of the string (starting from the
# beginning of the string) matches, then the rest of the string that didn't
# match is returned. If a match can't be found undef is returned.
sub _getValidSubstring {
	my $syllable = shift;
	my $part     = undef;
	my $valid    = 0;
	my $max      = length($syllable) < 6 ? length($syllable) + 1 : 7;

	# Do a quick lookup to see if the whole $syllable matches
	return "" if exists $ValidPinyin{$syllable};

	# Find the longest valid syllable
	for (my $i = 1; $i < $max; $i++) {
		$part = substr $syllable, 0, $i;
		$valid = $i if exists $ValidPinyin{$part};
	}

	# $syllable is invalid so return undef
	return undef unless $valid;

	# Get only the valid part of $syllable
	$part = substr $syllable, 0, $valid;

	return substr $syllable, length($part), length($syllable);
}

1;

=head1 AUTHOR

Christopher Davaz         www.chrisdavaz.com          cdavaz@gmail.com

=head1 VERSION

Version 0.02004 (Mar 01 2010)

=head1 COPYRIGHT

Copyright (c) 2009 Christopher Davaz. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

__DATA__
a
o
e
ai
ei
ao
ou
an
en
ang
eng
er
yo
yi
ya
ye
yao
you
yan
yin
yang
ying
wu
wa
wo
wai
wei
wan
wen
wang
weng
yu
yue
yuan
yun
yong
bi
ba
bo
bai
bei
bao
ban
ben
bang
beng
bie
biao
bian
bin
bing
bu
pi
pa
po
pai
pei
pao
pou
pan
pen
pang
peng
pie
piao
pian
pin
ping
pu
mi
ma
mo
me
mai
mei
mao
mou
man
men
mang
meng
mie
miao
miu
mian
min
ming
mu
fa
fo
fei
fou
fan
fen
fang
feng
fu
di
da
de
dai
dei
dao
dou
dan
dang
deng
die
diao
diu
dian
ding
du
duo
dui
duan
dun
dong
ti
ta
te
tai
tao
tou
tan
tang
teng
tie
tiao
tian
ting
tu
tuo
tui
tuan
tun
tong
ni
na
ne
nai
nei
nao
nou
nan
nen
nang
neng
nie
niao
niu
nian
nin
niang
ning
nu
nuo
nuan
nong
nv
nue
li
la
lo
le
lai
lei
lao
lou
lan
lang
leng
lia
lie
liao
liu
lian
lin
liang
ling
lu
luo
luan
lun
long
lv
lue
ga
ge
gai
gei
gao
gou
gan
gen
gang
geng
gu
gua
guo
guai
gui
guan
gun
guang
gong
ka
ke
kai
kei
kao
kou
kan
ken
kang
keng
ku
kua
kuo
kuai
kui
kuan
kun
kuang
kong
ha
he
hai
hei
hao
hou
han
hen
hang
heng
hu
hua
huo
huai
hui
huan
hun
huang
hong
ji
jia
jie
jiao
jiu
jian
jin
jiang
jing
ju
juan
jun
jue
jiong
qi
qia
qie
qiao
qiu
qian
qin
qiang
qing
qu
quan
qun
que
qiong
xi
xia
xie
xiao
xiu
xian
xin
xiang
xing
xu
xuan
xun
xue
xiong
zhi
zha
zhe
zhai
zhei
zhao
zhou
zhan
zhen
zhang
zheng
zhu
zhua
zhuo
zhuai
zhui
zhuan
zhun
zhuang
zhong
chi
cha
che
chai
chao
chou
chan
chen
chang
cheng
chu
chua
chuo
chuai
chui
chuan
chun
chuang
chong
shi
sha
she
shai
shei
shao
shou
shan
shen
shang
sheng
shu
shua
shuo
shuai
shui
shuan
shun
shuang
ri
re
rao
rou
ran
ren
rang
reng
ru
ruo
rui
ruan
run
rong
zi
za
ze
zai
zei
zao
zou
zan
zen
zang
zeng
zu
zuo
zui
zuan
zun
zong
ci
ca
ce
cai
cao
cou
can
cen
cang
ceng
cu
cuo
cui
cuan
cun
cong
si
sa
se
sai
sao
sou
san
sen
sang
seng
su
suo
sui
suan
sun
song
