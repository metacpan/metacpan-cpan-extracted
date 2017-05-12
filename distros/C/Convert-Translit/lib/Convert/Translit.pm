#!perl
# "Translit.pm" by Genji Schmeder <genji@community.net> 4 October 1996
# creates transliteration map between character sets defined in IETF RFC 1345
# with acknowledgements to Chris Leach, author of "EBCDIC.pm"
# and to Keld Simonsen, author of RFC 1345
# Copyright (c) 1997 Genji Schmeder. All rights reserved.
# This program is free software; you can redistribute it and/or modify
#    it under the same terms as Perl itself.

package Convert::Translit;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(transliterate build_substitutes);
$VERSION = '1.03'; # dated 5 November 1997
use integer;

if ($] < 5) {die "Perl version must be at least 5.\n";}

my $here = where_module();
my $rfc_fnam    = $here."rfc1345";
my $substi_fnam = $here."substitutes";
undef &where_module;

my %nam_mne;  # hash of name keyed by mnemonic
my %mne_nam;  # hash of mnemonic keyed by name
my %aprox_mne;  # hash of substitute list keyed by mnemonic
# if new() never called, transliterate() returns unchanged arg
my @transform = (0 .. 255);
my $verbose = 0;
1;


sub where_module {
my @xx = caller;
use File::Basename;
my $yy = dirname($xx[1]);
# adjust for Macintosh and Unix different return from dirname()
if ( ($^O ne "MacOS") && ($yy =~ /[^\/]$/) ) {
	$yy .= "/";
}
return $yy;
} # end of sub where_module


sub new {
my ($bb, $cc, $dd, $ee, $gg, $ii, $jj, $kk, $line);
my ($mm, $pp, $qq, $uu, $vv, $ww, $xx, $yy, $zz);
my (@ch_tab, @thistab, @bitmap, @ff, @tt, @pp, @oo);
my (%duplcatfrom, %duplcatto);
my $this = shift;
my $class = ref($this) || $this;

%nam_mne = ();
%mne_nam = ();
%aprox_mne = ();

# syntax: new([FROM charset], TO charset, [verbose])
my @chset;
$chset[0] = ($#_ > 0) ? shift : "ascii";  # ascii is default FROM charset
$chset[1] = shift;
$verbose = shift;

# typical rfc1345 table header:
# &charset CSA_Z243.4-1985-1
# &rem source: ECMA registry
# &alias iso-ir-121
# &g0esc x2877 &g1esc x2977 &g2esc x2a77 &g3esc x2b77
# &alias ISO646-CA
# &alias csa7-1
# &alias ca
# &code 0
# NU SH SX EX ET EQ AK BL BS HT LF VT FF CR SO SI

load_dsf( $substi_fnam) or return undef;
if ($verbose) {print "Creating transliteration from \"$chset[0]\" to \"$chset[1]\"\n";}
for $ii ( 0 .. 1 ){
#traverse whole file twice for simplicity
	unless (open(RFC, $rfc_fnam)) {print "Can't open $rfc_fnam: $!.\n"; return undef;}
	while(<RFC>) { #skip to relevant section
		if (/5.\s+CHARSET TABLES/) {
			last;
		}
	}
	@thistab = ();
	while(<RFC>) { # read table lines
		$line = $_;
		chomp $line;
	 	if ($line =~ /^ACKNOWLEDGEMENTS/) { # past relevant section
			if (@thistab) { # was previous table collected?
				if (relvnt_tab($chset[$ii], \@thistab) ) {
					$ch_tab[$ii] = [ @thistab ];
				}
			}
			last;
		}
		if ($line !~ /^  [^\s]/){ # distinguish table lines by 2 leading spaces
			next;
		}
		$line =~ s/^\s*//; # trim leading spaces
		# be sure of ending a table by encountering the next
		if ($line !~ /^&charset\s/) {
			push @thistab, $line;
			next;
		}
		if (@thistab) { # was previous table collected?
			if (relvnt_tab($chset[$ii], \@thistab)) {
				$ch_tab[$ii] = [ @thistab ];
				last;
			}
		}
		@thistab = ($line); # start another table collection
	}
}
close RFC;

#examine charsets
$qq = 0;
for $ii ( 0 .. 1 ){
	if(! $ch_tab[$ii][0]){
		print STDERR "Couldn't find a character set for \"$chset[$ii]\".\n";
		$qq = 1;
	}
}
if ($qq) {return undef;}

for $ii ( 0 .. 1 ){
	for $jj ( 0 .. $#{$ch_tab[$ii]} ) {
		if($ch_tab[$ii][$jj] =~ /^&bits\b\s*(\d*)/){
			if ($1 != 0 || $1 != 8) {
				print STDERR "Can't handle $1\-bit charsets like $chset[$ii].\n";
				$qq = 1;
				last;
			}
		}
	}
}
if ($qq) {return undef;}

for $ii ( 0 .. 1 ){
	for $jj ( 0 .. $#{$ch_tab[$ii]} ) {
		if($ch_tab[$ii][$jj] =~ /^&(code2|codex|comb2)\b/){
			print STDERR "Can't handle $1 terms in charset $chset[$ii].\n";
			$qq = 1;
			last;
		}
	}
}
if ($qq) {return undef;}

#create bit maps
for $ii ( 0 .. 1 ){
	if ($verbose) {print "\nCharacter set $chset[$ii]:\n";}
	$dd = -1;  # code offset unless negative
	for $jj ( 0 .. $#{$ch_tab[$ii]} ) {
		$line = $ch_tab[$ii][$jj];
		if($line =~ /^&code\b\s*(\d)/){
			$dd = $1;
			next;
		}
		if($line =~ /^&duplicate\s+([\da-fA-F]+)\s+([^\s]+)/){
			$pp = $1; $mm = $2; # position already in base 10
			# examples: "duplicate 91 AE", "duplicate 92 O/" (position, dup mnemonic)
			# organize duplicate keeping differently for FROM and TO charsets
			if ($ii == 0) {
				if ($duplcatfrom{$pp} ) {
					# FROM keyed by position
					push @{$duplcatfrom{$pp}{Mnemonics}}, "$mm";
				} else {
					$duplcatfrom{$pp} = {Position => $pp, Mnemonics => [ "$mm" ],};
				}
#print "FROM Duplicate for position $pp: $duplcatfrom{$pp}{Mnemonics}[-1]\n";
			} else {
				$duplcatto{$mm} = $pp; # TO keyed by mnemonic
#print "TO Duplicate for position $duplcatto{$mm}: $mm\n";
			}
		}
		# flush control info (just use all defined keywords)
		if($line =~
			/^&(charset|alias|g\desc|bits|code|code2|codex|duplicate|rem|comb2)\b/) {
			$dd = -1;
			next;
		}
		if ($dd < 0) {
			if ($verbose)
				{print "Strange! You should examine the charset table: \"$line\"\n";}
			next;
		}
		@pp = split(/\s+/, $line);
		foreach $uu (@pp) {
# mnemonic "??" means position unused.
# mnemonic "__" means character set not completely defined here
			if ( $uu eq "??" || $uu eq "__" ) {
				$uu = "";
			}
			if (($uu) && (! $nam_mne{$uu})) {
				printf "Warning: position %x (hex) has invalid mnemonic \"%s\".\n",
						$dd, $uu;
				$uu = "";
			}
			$bitmap[$ii][$dd++] = $uu;
		}
#		print ($#pp, $dd, (1 + $#{$bitmap[$ii]}), "\n");
	}
	# normalize char set length
	$#{$bitmap[$ii]} += ((128 - ( (1 + $#{$bitmap[$ii]}) % 128)) % 128);
#	print ("highest index is", $#{$bitmap[$ii]}, "\n" );
	for $kk ( 0 .. $#{$bitmap[$ii]} ) {
		if ($verbose) { print (length($bitmap[$ii][$kk])?"x":"_");}
		if ( ! (($kk +1) % 16)) { if ($verbose) { print "\n";}}
	}
}

# explanation from RFC 1345:
# "&duplicate" has a special meaning indicating that a position
# is being used for more than one character. This is an ugly
# convention but it is a sad fact of life that same code in one
# coded character set can mean different characters.
# "&duplicate" takes two parameters - the first is the code to
# be duplicated, the other is the new mnemonic.
# &duplicate 91 AE
# &duplicate 92 O/ 

$#transform = $#{$bitmap[0]}; # create transliterator table
PIERWSZY: for $jj ( 0 .. $#{$bitmap[0]} ) {
	$transform[$jj] = -1;  # initialize since 0 is valid value
	@tt = ( $bitmap[0][$jj] ); # start list with one element
	if ($duplcatfrom{$jj}) { # add any duplicates in the FROM charset
		push @tt, @{$duplcatfrom{$jj}{Mnemonics}};
#print "BB $jj $#tt <<< @tt >>>\n";
	}
	@oo = ();
	for $xx ( 0 .. $#tt ) { # refine list
		if (length($tt[$xx]) > 0) {
			push @oo, $tt[$xx];
		}
	}
	if (! @oo) {
		next;
	}
	for $bb ( 0 .. $#oo ) { # match any mnemonics for this position in FROM charset
		$uu = $oo[$bb];
		for $kk ( 0 .. $#{$bitmap[1]} ) { #search TO charset
			if ($uu eq $bitmap[1][$kk]) {
				$transform[$jj] = $kk;
				next PIERWSZY;
			}
		}
		if (exists $duplcatto{$uu}) { # search TO charset duplicates
			$transform[$jj] = $duplcatto{$uu};
			next PIERWSZY;
		}
	}
}

if ($verbose) { print "\nTransliterator:\n";}
for $jj ( 0 .. $#transform ) {
	if ($verbose) { print (($transform[$jj]>=0)?"x":"_");}
	if ( ! (($jj+1) % 16)) { if ($verbose) { print "\n";}}
}

$vv = $ww = 0;
for $jj ( 0 .. $#transform ) { # try to approximate using substitute lists
	if ($transform[$jj] >= 0) {
		next;
	}
	if (! ($gg = $bitmap[0][$jj]) ) { # undefined
		next;
	}
TRZECI: foreach $pp (@{$aprox_mne{$gg}}) {
		for $cc ( 0 .. $#{$bitmap[1]} ) {
			$zz = $bitmap[1][$cc];
			if ($zz eq $pp) { # substitute must be in TO char set
				$transform[$jj] = $cc; # success
				if (!$ww) {
					$ww = 1;
					if ($verbose) {print "\nApproximate substitutes:\n";}
				}
				if ($verbose) { printf "%X==>%X\t%s==>%s\n", $jj, $cc,
								$nam_mne{ $gg}, $nam_mne{ $zz};}
				last TRZECI;
			}
		}
	}
	$vv = 1; # defined character but no substitute
}

if ($ww) {
	if ($verbose) {print "\nTransliterator with aproximate substitutions:\n";}
	for $jj ( 0 .. $#transform ) {
		if ($verbose) {print (($transform[$jj]>=0)?"x":"_");}
		if ( ! (($jj+1) % 16)) { if ($verbose) {print "\n";}}
	}
}

# non-equivalent substitutions (like "RIGHT SQUARE BRACKET" for "CENT SIGN")
if ($vv) {
	@ff = ();
	for $jj ( 0 .. $#transform ) { # list those in need in FROM charset
		if (($transform[$jj] < 0) && $bitmap[0][$jj] ) {
			push @ff, $jj;
		}
	}
	if (@ff) {
		@tt = ();
PIATY:	for $bb ( 0 .. $#{$bitmap[1]} ) { # list availables in TO charset
			# start at usual second ascii graphic (hoping to maximize graphics)
			$cc = (34 + $bb) % (1 + $#{$bitmap[1]} );
			if ($zz = $bitmap[1][$cc]) {
				for $ii ( 0 .. $#{$bitmap[0]} ) {
					if ($zz eq $bitmap[0][$ii]) {
						next PIATY;
					}
				}
				push @tt, $cc;
			}
		}
	}
	$gg = $ee = 0;
SIODMY: while ( ($#ff >= 0) && ($#tt >= 0) ) {
		for $jj ($gg .. $#ff) { # first try to match equal hex values
			$ww = $ff[$jj];
			for $kk (0 .. $#tt) {
				if ( $ww == $tt[$kk]) {
					$transform[ $ww] = $ww;
					if (!$ee) {
						$ee = 1;
						if ($verbose) {print "\nNon-equivalent substitutes:\n";}
					}
					if ($verbose)
						{printf "%X==>%X\t%s==>%s\n", $ww, $ww,
							$nam_mne{$bitmap[0][ $ww]}, $nam_mne{$bitmap[1][ $ww]};}
					splice @ff, $jj, 1;
					splice @tt, $kk, 1;
					$gg = $jj;
					next SIODMY;
				}
			}
		}
		last;
	}
	$gg = ($#ff < $#tt)? $#ff : $#tt;
	for $jj (0 .. $gg ) {
		$transform[$ff[$jj]] = $tt[$jj];
		if (!$ee) {
			$ee = 1;
			if ($verbose) {print "\nNon-equivalent substitutes:\n";}
		}
		if ($verbose)
			{printf "%X==>%X\t%s==>%s\n", $ff[$jj], $tt[$jj],
				$nam_mne{$bitmap[0][$ff[$jj]]}, $nam_mne{$bitmap[1][$tt[$jj]]};}
	}
}

$ee = $yy = 0; # anything left untranslated?
for $jj ( 0 .. $#transform ) {
	if ($transform[$jj] < 0) {
		$yy = 1;
		if ($mm = $bitmap[0][$jj]) {
			if (!$ee) {
				$ee = 1;
				if ($verbose) {print "\nNon-equivalent remnant:\n";}
			}
			if ($verbose) {printf "%X\t%s\n", $jj, $nam_mne{$mm};}
		}
	}
}

# if non-equivalent remnant, then select a hopefully unique and graphic indicator
if ($ee) {
DRUGI: for $bb ( 0 .. $#{$bitmap[1]} ) {
		$cc = (34 + $bb) % (1 + $#{$bitmap[1]} );
		if ($xx = $bitmap[1][$cc]) {
			for $dd ( 0 .. $#{$bitmap[0]} ) {
				if ( $xx eq $bitmap[0][$dd]) { # reject if in FROM charset
					next DRUGI;
				}
			}
			last; # success
		}
	}
	if ($verbose)
		{printf "\nNon-equivalence indicator: %X\t%s\n", $cc, $nam_mne{$xx}};
	for $jj ( 0 .. $#transform ) { # interpolate non-equiv character
		if (($transform[$jj] < 0) && $bitmap[0][$jj]) {
			$transform[$jj] = $cc;
		}
	}
}

# if undefined remnant, then select a possibly undefined indicator
if ($yy) {
SZOSTY: for ($cc = $#{$bitmap[1]}; $cc >= 0; --$cc ) {
		if (! ($xx = $bitmap[1][$cc]) ) {
			last;
		}
		for $dd ( 0 .. $#{$bitmap[0]} ) {
			if ($xx eq $bitmap[0][$dd] ) {
				next SZOSTY;
			}
		}
		last; # success
	}
	if ( ! ($yy = $nam_mne{$xx}) ) {$yy = "(undefined character)";}
	if ($verbose) {printf "\nUndefined indicator: %X\t%s\n", $cc, $yy};
	for $jj ( 0 .. $#transform ) { # interpolate non-equiv character
		if ($transform[$jj] < 0) {
			$transform[$jj] = $cc;
		}
	}
}

# if FROM charset length < 256, assume repeated for upper 128 chars
if ($#transform < 128) {push @transform, @transform;}
$yy = "$chset[0]".".to."."$chset[1]";
my $self = {TRN_NAM=>"$yy", TRN_ARY=>[@transform]};
bless $self, $class;
return $self;
} # end of sub new


sub relvnt_tab { # true if this is the sought char table
my ($jj, $uu, $ww, $xx, $yy, $chch, $tabref);
$chch = shift; # $chset[0 or 1]
$tabref = shift; # reference to @thistab
for $jj ( 0 .. $#{@$tabref} ){
	$ww = $$tabref[$jj];
	if ($ww  !~ /^&(charset|alias)\s+([^\s]*)/){
		next;
	}
	$xx = $1; $yy = $2;
	if ($chch =~ /^$yy$/i) {
		if ($verbose) {print "Found $xx $yy";}
		if ($xx eq "alias") {
			$uu = $$tabref[0];
			$uu =~ s/^&//;
			if ($verbose) {print " for $uu";}
		}
		if ($verbose) {print "\n";}
		return 1; # true
	}
}
return undef; # false
} # end of sub relvnt_tab


sub load_dsf { # load code definitions and approximate substitutes
my ($mm, $nn, @ww);
unless (open(DSF, "$_[0]")) {print "Can't open $_[0]: $!.\n"; return undef;}
while (<DSF>) {
	chomp;
	if (/^hash mnemonic=name/) { # first group header
		last;
	}
}
while (<DSF>) {
	chomp;
	if (/^hash mnemonic=substitute list/) { # next group header
		last;
	}
	($mm, $nn) = split(/\t/);
	$nam_mne{$mm} = "$nn";  # hash of name keyed by mnemonic
	$mne_nam{$nn} = "$mm";  # hash of mnemonic keyed by name
}
while (<DSF>) {
	chomp;
	($mm, @ww) = split(/\t/);
	$aprox_mne{$mm} = [@ww];
}
close DSF;
return 1;
} # end of sub load_dsf 


sub build_substitutes {
# creates lists of approximate substitutes
# it takes about 90 minutes to recreate the file
# there should be no need to run this since its result file never needs changing
my ($xx, $aa, $yy, $bb, $ff, $hh, $pp, $jj, $kk, $gg, $rr, $mm, $nn, $start);
my @ww;
my $this = shift;
my $class = ref($this) || $this;

#$start = time();
load_rfcdoc( $rfc_fnam);
# find approximate substitutes
# (mnemonic, hexcode, name) example:
# mnemonic:    j+-    feef    ARABIC LETTER ALEF MAKSURA ISOLATED FORM
# substitute:  j+     0649    ARABIC LETTER ALEF MAKSURA
# substitute:  a+:    e022    ARABIC LETTER ALEF FINAL FORM COMPATIBILITY (IBM868 144)

#print (time() - $start); print " delete words from right\n";
while (($xx, $aa) = each  %mne_nam) { # (name, nmemonic)
	if ($xx =~ /^DOT ABOVE\s/i) { # avoid this overly matchable character
		next;
	}
	$yy = $xx;
	while ($yy =~ /[^\s]\s+[^\s]+\s*$/) {
		$yy =~ s/^(.*[^\s])\s+[^\s]+\s*$/$1/; # delete words from right
		if ($bb = $mne_nam{$yy}) {
			push @{ $aprox_mne{$aa} }, "$bb"; # add to sub list
#print "$aa\t@{$aprox_mne{$aa}}\n";
		}
	}
}

#print (time() - $start); print " delete words from left\n";
while (($xx, $aa) = each  %mne_nam) { # (name, nmemonic)
	if ($xx =~ /^DOT ABOVE\s/i) { # avoid this overly matchable character
		next;
	}
	$yy = $xx;
	while ($yy =~ /[^\s]\s+[^\s]+\s*$/) {
		$yy =~ s/^[^\s]+\s+(.*)$/$1/; # delete words from left
		if ($yy =~ /^WITH\s/i) { # avoid matching overly broad phrases
			last;
		}
		if ($bb = $mne_nam{$yy}) {
			push @{ $aprox_mne{$aa} }, "$bb"; # add to sub list
#print "$aa\t@{$aprox_mne{$aa}}\n";
		}
	}
}

# look for (string1 inside string2) or (string2 inside string1)
# also look fcr "DIGIT ONE", "NUMBER TWO" strings
# (disabled) also equate the 2 kinds of Japanese syllabic character sets
# since subs are assigned reciprocally, algorithm avoids redundancy: for example, if
#    elements are (A, B, C, D, E), then comparisions will be E with (A, B, C, D),
#    D with (A, B, C), C with (A, B), B with (A) and A with nothing.

#print (time() - $start); print " look for string1 inside string2, number terms\n";
$ff = "DIGIT|NUMBER";
#$hh = "HIRAGANA|KATAKANA";
#$pp = "LETTER|LIGATURE|".$ff."|".$hh;
$pp = "LETTER|LIGATURE|".$ff;
$jj = scalar (keys  %mne_nam);
foreach $xx ( reverse keys %mne_nam ) {
	if ( ($kk = (--$jj)) <= 0) {
		last;
	}
	if ($xx !~ /($pp)/i) { # only certain types
		next;
	}
	if ($xx !~ /\b\w+\b\s+\b\w+/) { # at least 2 words
		next;
	}
	if ($xx =~ /\b($ff) \b(\w+)\b/i) { # digit, numeral, et al. match
		$gg = $2;
	} else {
		$gg = "";
	}
#	if ($xx =~ /(.*)\b($hh)\b(.*)/i) { # equivalent Japanese syllabic sets
#		$xx = "$1"."HIRAGANA"."$2";
#		$rr = "$1"."KATAKANA"."$2";
#	} else {
#		$rr = "";
#	}
	$aa = $mne_nam{$xx};
	foreach $yy (keys %mne_nam) {
		if ( ($kk--) <= 0) {
			last;
		}
		if ($yy !~ /($pp)/i) {
			next;
		}
		if ($yy !~ /\b\w+\b\s+\b\w+/) {
			next;
		}
		if ( (($xx =~ /\b($yy)\b/i) || ($yy =~ /\b($xx)\b/i)) ||
#			(($rr) && ($xx =~ /\b($yy)\b/i) || ($yy =~ /\b($xx)\b/i)) ||
			(($gg) && ($yy !~ /FRACTION/i) && ($yy =~ /\b($ff)\s+\b$gg\b/i)) ) {
			$bb = $mne_nam{$yy};
			push @{ $aprox_mne{ $aa} }, "$bb"; # add to sub lists repciprocally
			push @{ $aprox_mne{ $bb} }, "$aa";
#print "$aa\t@{$aprox_mne{ $aa}}\n";
#print "$bb\t@{$aprox_mne{ $bb}}\n";
		}
	}
}

#print (time() - $start); print "\n";
#print "No substitutes found for these:\n";
foreach $aa ( keys %aprox_mne ) {
	if ( $#{ $aprox_mne{$aa}} < 0) {
#		print "$aa\t$nam_mne{$aa}\n";
		delete $aprox_mne{$aa};
	}
}

#print (time() - $start); print " eliminate duplicate substitutions\n";
foreach $aa ( keys %aprox_mne ) { # eliminate duplicate substitutions
	@ww = @{$aprox_mne{$aa}};
CZWARTY: for($gg = 0;;){
		for ($jj = $#ww; $jj > 0; --$jj){
			for ($kk = ($jj -1); $kk >= 0; --$kk){
				if ("$ww[$kk]" eq "$ww[$jj]"){
					splice @ww, $jj, 1;
					$gg = 1;
					next CZWARTY;
				}
			}
		}
		last;
	}
	if ($gg) {
		$aprox_mne{$aa} = [@ww];
	}
}

#print (time() - $start); print "\n";
# for user's protection, save old file if any
$gg = "$substi_fnam".".bkp";
if (! -e $gg) {rename( $substi_fnam, "$gg")};
# contrived loop wherein second pass only when open or write failure
OSMY: for ($yy = 0; $yy == 0; $yy = 1) {
	unless (open(DSF, ">$substi_fnam")) {next OSMY};
	unless (print DSF "hash mnemonic=name\n") {next OSMY}; # header
	foreach $mm (sort keys %nam_mne ) {
	     # mnemonic tab name newline
	     unless (print DSF "$mm\t$nam_mne{$mm}\n") {next OSMY};
	}
	unless (print DSF "hash mnemonic=substitute list\n") {next OSMY}; # header
	foreach $mm (sort keys %aprox_mne ) {
	     unless (print DSF "$mm") {next OSMY};  # mnemonic
		foreach $aa (0 .. $#{$aprox_mne{$mm}}) { # each substitute
			unless (print DSF "\t$aprox_mne{$mm}[$aa]") {next OSMY};
		}
	     unless (print DSF "\n") {next OSMY}; # newline
	}
	last OSMY;
}
close DSF;
if ($yy) {
	if (! -e $substi_fnam) {rename( "$gg", $substi_fnam)};
	print "Failed to create $substi_fnam: $!\n";
	return undef;
}
return 1;
} # end of sub build_substitutes


sub load_rfcdoc { #load code definition list
my ($mm, $nn, $jj, $catch, $hh, $xx, $kk, $yy);
my $digits = \"ZERO|ONE|TWO|THREE|FOUR|FIVE|SIX|SEVEN|EIGHT|NINE";
unless (open(RFC, $_[0])) {print "Can't open $_[0]: $!\n"; return undef;}
while(<RFC>) {
	chomp;
	if (/^3.  CHARACTER MNEMONIC TABLE/) {
		last;
	}
}
$jj = 1;
while(<RFC>) {
	chomp;
	if (/^4.  CHARSETS/) {
		last;
	}
	# page head, foot, effectively empty lines
	if (/^(Simonsen|RFC 1345) / || /^.{0,3}$/) {
		next;
	}
	if (/SP\s+0020\s+SPACE/) { # first code def line
		$catch = "1";
	}
	if (! $catch) {
		next;
	}
	++$jj;
	if(/^\s*([^\s]+)\s+([\da-fA-F]{4})\s{4}\b(.+)\s*$/ ||
			/^(\s+)(e000)\s{4}\b(.+)\s*$/) {
		$mm = $1; $hh = $2; $xx = hex $2; $nn = $3;	
		# normalize unusual e000 format which indicates unfinished (Mnemonic)
		if ($hh eq "e000") {
			$mm = " "; # single space
		}
 		# correct mistake in LATIN SMALL LETTER N WITH CIRCUMFLEX BELOW
 		if ($hh eq "1e4b") {
			$mm = "n->";
		}
 		# correct mistake in LATIN SMALL LETTER S WITH DOT BELOW AND DOT ABOVE
 		if ($hh eq "1e69") {
			$mm = "s.-.";
		}
		if ($yy && ($jj != ($kk +1)) && ($xx != ($yy +1))) {
			print "Check sequence around this entry: $_\n";
		}
		$yy = $xx; $kk = $jj;
		if ($nam_mne{$mm} ne "") { # already exists
			print "Same mnemonic $mm for $nam_mne{$mm} and hex code $hh \n";
		}
		if ($mne_nam{$nn} ne "") { # already exists
			print "Same mnemonic $mne_nam{$nn} for $nn and hex code $hh \n";
		}
		# normalize for more thorough substitution
		$nn =~ s/\b(SUBSCRIPT|SUPERSCRIPT)\s+($$digits)\b/$1 DIGIT $2/;
		$nam_mne{$mm} = "$nn";  # hash of name keyed by mnemonic
		$mne_nam{$nn} = "$mm";  # hash of mnemonic keyed by name
		$aprox_mne{$mm} = [];   # list approx subs keyed by mnemonic
		next;
	}
	if (/^[ ]{16}([^\s].*)/) { # continuation line
		delete $mne_nam{$nn};
		$nn = "$nn $1";  # append to name in prev line
		$nam_mne{$mm} = "$nn";
		$mne_nam{$nn} = "$mm";
	}
}
close RFC;
return 1;
} # end of sub load_rfcdoc


sub transliterate {
	my $self  = ($#_ > 0) ? shift : 0;
	my $arref = $self ? \@{$self->{TRN_ARY}} : \@transform;
	my @xx = unpack "C*", $_[0];
	my $yy = "";
	foreach ( @xx ) {
		$yy .= pack "C", @$arref[$_];
	}
	return $yy;
} # end of sub transliterate

__END__

=head1 NAME

Convert::Translit, transliterate, build_substitutes - Perl module for string conversion among numerous character sets

=head1 SYNOPSIS

use Convert::Translit;

  $translator = new Convert::Translit($result_chset);
  $translator = new Convert::Translit($orig_chset, $result_chset);
  $translator = new Convert::Translit($orig_chset, $result_chset, $verbose);

  $result_st = $translator->transliterate($orig_st);
  $result_st = Convert::Translit::transliterate($orig_st);

  build_substitutes Convert::Translit();

  Convert::Translit::build_substitutes();

=head1 DESCRIPTION

This module converts strings among 8-bit character sets defined by IETF RFC 1345 (about 128 sets).  The RFC document is included so you can look up character set names and aliases; it's also read by the module when composing conversion maps.  Failing functions or objects return undef value.

Export_OK Functions:

=over 4

=item transliterate()

returns a string in $result_chset for an argument string in $orig_chset, transliterating by a map composed by new().

=item build_substitutes()

rebuilds the file "substitutes" containing character definitions and approximate substitutions used when a character in $orig_chset isn't defined in $result_chset.  For example, "Latin capital A" may be substituted for "Latin capital A with ogonek".  It takes a long time to rebuild this file, but you should never need to.  Its only source of information is file "rfc1345".

=back

Object methods:

=over 4

=item new()

creates a new object for converting from $orig_chset to $result_chset, these being names (or aliases) of 8-bit character sets defined in RFC 1345.  If only one argument, then $orig_chset is assumed "ascii".  If three arguments, the third is verbosity flag.  Verbose output lists approximate substitutions and other compromises.

=item transliterate()

is same as the function of that name.

=item build_substitutes()

is same as the function of that name.

=back

=head1 FILES

 Convert/Translit/rfc1345  (IETF RFC 1345, June 1992)
 Convert/Translit/substitutes

=head1 METHODOLGY

Only one-to-one character mapping is done, so characters with diacritics (like A-ogonek) are never converted to (letter character, diacritic character) pairs, rather are subject to simplification.  If no approximate substitute is available, then a unrelated substitute is chosen, preferably with the same code value.  Undefined $orig_chset characters are translated to a chosen indicator character.  Transliteration is not guaranteed commutative when substitutions were required.  An $orig_chset defined as 7-bit is assumed to be repeated to make an 8-bit set (in the style of "extended ascii"); no such adjustment is made for $result_chset.  The few mistakes in the RFC document are corrected in the module.

=head1 EXAMPLES

  Convert Russian language text from IBM to ASCII encoding:
  $xxx = new Convert::Translit("EBCDIC-Cyrillic", "Cyrillic");
  $ascii_cyr_st = $xxx->transliterate($ibm_cyr_st);

  Convert from plain ASCII (default $orig_chset) to Latin2 (Central European):
  $yyy = new Convert::Translit("Latin2");
  $cnt_eur_st = $yyy->transliterate($ascii_st);

  Since plain ASCII is subset of Latin2, nothing is lost in transliteration.
  But going the other direction requires numerous simplifications:
  $zzz = new Convert::Translit("Latin2", "ascii");
  $ascii_st = $zzz->transliterate($cnt_eur_st);

  Back to ASCII again, although substitutions probably mean ($again ne $cnt_eur_st):
  $again = $yyy->transliterate($ascii_st);

  The example.pl script converts a Polish language phrase from Latin2 to EBCDIC-US.

=head1 PORTABILITY

Requires Perl version 5.  Developed with MacPerl on Macintosh 68040 OS 7.6.1.  Tested on Sun Unix 4.1.3.

=head1 AUTHOR

Genji Schmeder E<lt>genji@community.netE<gt>

  Enjoy in good health.
  Cieszcie sie dobrym zdrowiem.
  Que gozen con salud.
  Benutze es heilsam gern!
  Genki dewa, yorokobi nasai.

=head1 COPYRIGHT

Version 1.03 dated 5 November 1997.  Copyright (c) 1997 Genji Schmeder. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

  Chris Leach, author of EBCDIC.pm
  Keld Simonsen, author of RFC 1345
