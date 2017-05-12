use strict;
use warnings;

package Acme::Zalgo;
$Acme::Zalgo::VERSION = '0.002';
# ABSTRACT: Speak the forbidden tongue, or just screw up your terminal

use Exporter qw(import);

our @EXPORT = qw(zalgo);

# spaces are zalgofied by default, but not other whitespace
our $ZALGO_REGEX = qr/([[:alnum:] ])/;

my $chars = <<"HE_COMES";
# up
	\x{030d}\x{030e}\x{0304}\x{0305}
	\x{033f}\x{0311}\x{0306}\x{0310}
	\x{0352}\x{0357}\x{0351}\x{0307}
	\x{0308}\x{030a}\x{0342}\x{0343}
	\x{0344}\x{034a}\x{034b}\x{034c}
	\x{0303}\x{0302}\x{030c}\x{0350}
	\x{0300}\x{0301}\x{030b}\x{030f}
	\x{0312}\x{0313}\x{0314}\x{033d}
	\x{0309}\x{0363}\x{0364}\x{0365}
	\x{0366}\x{0367}\x{0368}\x{0369}
	\x{036a}\x{036b}\x{036c}\x{036d}
	\x{036e}\x{036f}\x{033e}\x{035b}
	\x{0346}\x{031a}
# middle
	\x{0315}\x{031b}\x{0340}\x{0341}
	\x{0358}\x{0321}\x{0322}\x{0327}
	\x{0328}\x{0334}\x{0335}\x{0336}
	\x{034f}\x{035c}\x{035d}\x{035e}
	\x{035f}\x{0360}\x{0362}\x{0338}
	\x{0337}\x{0361}\x{0489}
# down
	\x{0316}\x{0317}\x{0318}\x{0319}
	\x{031c}\x{031d}\x{031e}\x{031f}
	\x{0320}\x{0324}\x{0325}\x{0326}
	\x{0329}\x{032a}\x{032b}\x{032c}
	\x{032d}\x{032e}\x{032f}\x{0330}
	\x{0331}\x{0332}\x{0333}\x{0339}
	\x{033a}\x{033b}\x{033c}\x{0345}
	\x{0347}\x{0348}\x{0349}\x{034d}
	\x{034e}\x{0353}\x{0354}\x{0355}
	\x{0356}\x{0359}\x{035a}\x{0323}
HE_COMES

our @ZALGO = map { my $s = $_; $s =~ s/\s+//g; $s } grep {$_} split qr/^#.*?$/ms, $chars;

use Carp;

sub randint { 
	my ($min, $max) = @_;
	if (not defined $max) {
		$max = $min;
		$min = 0;
	}
	return int(rand($max - $min)) + $min; 
}

sub rand_char {
	my ($s) = @_;
	return substr($s, randint(length $s), 1);
}

sub zalgo_char {
	my ($c, $upmin, $upmax, $midmin, $midmax, $downmin, $downmax) = @_;
	for my $i (1..randint($upmin, $upmax)) {
		$c .= rand_char($ZALGO[0]);
	}
	for my $i (1..randint($midmin, $midmax)) {
		$c .= rand_char($ZALGO[1]);
	}
	for my $i (1..randint($downmin, $downmax)) {
		$c .= rand_char($ZALGO[2]);
	}
	return $c;
}

sub zalgo {
	if (not @_) {
		@_ = ("HE COMES");
	}
	if (@_ == 1) {
		push @_, (0,5, 0,5, 0,5);
	} elsif (@_ == 2) {
		my ($s, $max) = @_;
		@_ = ($s, 0, $max, 0, $max, 0, $max);
	}
	my ($str, $minup, $maxup, $minmid, $maxmid, $mindown, $maxdown) = @_;
	$str =~ s/$ZALGO_REGEX/zalgo_char($1,$minup,$maxup+1,$minmid,$maxmid+1,$mindown,$maxdown+1)/ge;
	return $str;
}	

package 
	COMES;  # hide from cpan

sub HE {
	my $pkg = shift;
	Acme::Zalgo::zalgo(@_);
}

1;	
__END__

=head1 NAME

Acme::Zalgo - The Nezperdian hive-mind of chaos. 

=head1 SYNOPSIS

    use Acme::Zalgo;

    binmode STDOUT, ':utf8';

    print zalgo("Hello world\n");

    # alternate syntax.  NO COMMAS, THEY ARE FORBIDDEN
    print HE COMES "Tony The Pony\n";

=head1 DESCRIPTION

T͇̟̺o̩̭̖͡ ͚̯̕i̤̜͜n̮̹͕͕v̛̬̬̭̙͖̲̺o̳̪̘̻͔̺ͅk͕̪̟̙͓͘e҉̜̹̟̞ͅ ̪̜̥̯͍th̗̩̠̜̱e̝̰͖̤͓͜ͅ ͈̩̰͎̙̙̮h̴̥i҉͇͙͉̮v̜̣̗̖̭ẹ͞-̱͔͙m͔i̲̪̙͜n̩̲̳̝̮̯͈d̟̫̟̦̖̯̗́ ҉̹͓̰͓͕̲̻r͙͙̯̘͕̞̝͠é͖̠͙̪p͉̱̙̰͠r̖̗͓e͏̱̟ṣ͚͞e̯̮̝̙̩n͖͍̬̜̝ͅͅt̥̠͔̪̳͢i̵͍n̬g͖͇ ̷͉̱̺̲̰̤c̨͔̜̪͎h̢a̷o̹̲̻̥̖͓s̫͜.̷̟̣̯̩
̜͓͍͖́Iń̰̯̬̤̹v̼̬̠ͅo̠̜k̦̠͚̞i͚͉͜ṇ̯͎g̛̥ ̣̹̜̟͇̬t̲̞̫̪he̜͕̮̲ ͖̞͍̱̖ͅf҉͙͙͓̱̦̰e̺̞̯̩̩e̸l̸͙͔i̼̠̲͍͎͓͜ń̻̻̘͔̳̝͍g̝̼̹͕͖ ̨̩o̰̤̻f̻̝̯͉̪͇͟ ̦̱̱͜c҉̝̜͓̮̰̞̦h̸̬͍̖̳͔̤à̞̥̤̙̦o̰̲͉s̬.̝̲͍͕̣̬̘
̫̖̝̬̪̣ͅW̭̮͇̼̼i͍̙̘͎̩̤t̘̩̝̥̭h̘̻̟̠ ̘̮͔ou̙͕̗͡t ̲o̴̠̟̣̮͖̱̞r̞̞d̷͕̰͉̟̣e͕͇͕̗̲̖ͅr̗̥̪̪̘͠.͉̟̲̺̻͓͔͞
̘̥Ţ̜͙̞̖he҉ Ṉ̶͓̭̼ḛ̴̥͓̳̲z̤̜ͅp͔̩̱e͏͎r̜̙̪͚d҉͓̹͉͉̪̱i̹̹̻̣a͙͢n̼̞͉ ̖͔ḫ̨̝͈̹͓̺͚i͍̘͎̬̖v̩̫̻̭̤̺͍è̥̯̯̝-̯͚͕͟m̮͍͝i̲n͎̤͇͙̰͉d̜͍̝̭͇ ̲͟o̵͙͍̱̤f̲͕̪̟ ̥͎c͏̤̤̦̪h̠͙̮a̰o̟̤̻s̲̯͍̦̞ͅ.̺̭̼̦̻̤͜ ̭͉̮Z̠̣̱͚͚͕á̱l̰ͅg̡o̮.̣̞̯̳̜
̠ͅH̵̪̥̠̼e̗͚̻̗̭̩̮ ͍͟w̷͙̭͙̙̝͙h̡̩͇̝̯o͏͉̱͉̲ͅ ̘͉͡W̠̲͙̰̹͡a͞i͍̼̝t̯̻̻̰̮̱̹s̗̭̖̦̠̺̥ ̙B̝͖̤͜e̘̫͍̤̩͇h̹i̖̦̼͓̠n̸͉̲d̨͚͓͎ͅ ͈͇̞̻̲̮̹͝T̸̝̜̠̜̞̤̜h̨̖̖è͈̞ͅ ̮W҉̞̹͈a̬̻̜͕͚̼̤l͓͕̹͔̹̬l͖̦̟̼͈͡.͕̤͚͙̤
̤̝̦̠̬Z̤̺͉̦A̖͝L͍̱G̶̰̺̲̗̥̖̮O̩͈̠!̤̝̗
    	    
[credit to and shamelessly stolen from http://eemo.net] 

=head1 SEE ALSO

http://eeemo.net/ - Zalgo Text Generator

=head1 AUTHOR

Chuck Adams <cja987@gmail.com>

=head1 LICENSE

This module is Copyright 2014 Chuck Adams.

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
