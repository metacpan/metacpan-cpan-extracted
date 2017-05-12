package Lingua::EN::Hyphenate;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

@EXPORT_OK = qw( hyphenate syllables def_syl def_hyph );

$VERSION = '0.01';

sub debug {  print @_ if $::debug }

my @diphthong = qw { ao ia io ii iu oe uo ue };
my @diphthong1 = map { substr($_,0,1)."(?=".substr($_,1,1).")" } @diphthong;
my $diphthong = "(" . join('|', @diphthong1) . ")(.)";

my $vowels = '(?:[aeiou]+y?|y)';

my $precons = '( str
		 |sch
		 |sph
		 |squ
		 |thr
	         |b[r]
	         |d[rw]
	         |f[lr]
	         |g[nr]
	         |k[n]
	         |p[nr]
	         |r[h]
	         |s[lmnw]
	         |t[w]
		 |qu
		 )';

my $ppcons1 = '(  b[l]
	         |c[hlr]
	         |g[hl]
	         |m[n]
	         |p[l]
	         |t[h](?!r)
	         |s[chpt](?!r)
	         |s[k]
	         |tr
		 )';

my $ppcons2 = '((?=[a-z])[^aeiouy])';

my $postcons = '( ght
		 |nst
		 |rst
		 |tch
		 |rth
		 |bb
	         |c[ckt]
	         |d[dlz]
		 |f[ft]
	         |g[gt]
	         |l[bcdfgklmnptv]
	         |m[mp]
	         |n[cdgknstx]
		 |pp
	         |r[bcdfgklmnprtv]
		 |ss
		 |t[tz]
		 |vv
		 |wn
	         |x[tx]
		 )';

my @paircons = qw { ph tl n't };
my $paircons = "(" . join('|', @paircons) . ")";

my @dblcons = qw { c~tr n~th n~c[th] n~s[th] ns~d l~pr s~tl
		   n~c n~s c~t r~t };
my @dblcons1 = map { /(.+)~(.+)/; "$1(?=$2)" } @dblcons;
my @dblcons2 = map { /(.+)~(.+)/; "$2" } @dblcons;
my $dblcons = "(" . join('|', @dblcons1) . ")(" . join('|', @dblcons2) . ")";

my @repcons = map { "$_(?=$_)" } qw { b c g h j k m n p q r t v w x z };
my $repcons = "(" . join('|', @repcons) . ")";

my $pprecons = "($ppcons1|$precons|$ppcons2)";
my $ppostcons = "($ppcons1|$postcons|$ppcons2)";

sub abstract
{
	no strict;
	sub C_  { debug "C_($_[0])\n"; return { type => 'C_',  val => $_[0] } }
	sub _C  { debug "_C($_[0])\n"; return { type => '_C',  val => $_[0] } }
	sub _S  { debug "_S($_[0])\n"; return { type => '_S',  val => $_[0] } }
	sub _C_ { debug "_C_($_[0])\n"; return { type => '_C_', val => $_[0] } }
	sub V   { debug "V($_[0])\n"; return { type => 'V',   val => $_[0] } }
	sub E   { debug "E($_[0])\n"; return { type => 'E',   val => $_[0] } }

	local $_ = shift;
	local @head = (); sub app  { push @head, @_ if defined $_[0]; '' }
	local @tail = (); sub prep { unshift @tail, @_ if defined $_[0]; '' }

	#debug "\A${pprecons}${diphthong}${postcons}\Z\n";

	s/\A${pprecons}${diphthong}${ppostcons}\Z/app C_($1),V("$5$6"),_C($7)/eix;

	s/\Ay/app C_("y")/ei
		or s/\Aex/app V("e"),_C("x")/ei
		or s/\Ai([nmg])/app V("i"),_C($1)/ei
		or s/\A([eu])([nm])/app V($1),_C($2)/ei
		or s/\Airr/app V("i"),_C("r"),C_("r")/ei
		or s/\Aill/app V("i"),_C("l"),C_("l")/ei
		or s/\Acon/app C_("c"), V("o"), _C("n")/ei
		or s/\Aant([ie])/app V("a"),_C("n"),C_("t"),V($1),_C('')/ei
		or s/\A(w[hr])/app C_("$1")/ei
		or s/\Amay/app C_("m"), V("a"), _C("y")/ei
		;

	s/([bd])le\Z/prep C_($1), V(''), _C("le")/ei
		or s/sm\Z/prep C_("s"), V(''), _C("m")/ei
		or s/${repcons}\1e\Z/do{prep _C("$1$1e")}/eix
		or s/(?=..e)${dblcons}e\Z/do{prep _C("$1$2e")}/eix
		or s/(${vowels})${ppcons2}es\Z/do{prep _C("$2es");$1}/eix
		or s/(${vowels})(ples?)\Z/do{prep C_($2);$1}/eix
		or s/([td])ed\Z/prep C_($1),V("e"), _C("d")/eix
		or s/([^aeiou])\1ed\Z/prep _C("$1$1ed")/eix
		or s/${pprecons}ed\Z/prep _C("$1ed")/eix
		or s/${ppostcons}ed\Z/prep _C("$1ed")/eix
		or s/([aeou])ic(s?)\Z/prep V($1), V("i"),_C("c$2")/ei
		or s/([sct])ion(s?)\Z/prep _C_($1),V("io"),_C("n$2")/ei
		or s/([cts])ia([nl]s?)\Z/prep _C_($1),V("ia"),_C($2)/ei
		or s/([ts])ia(s?)\Z/prep _C_($1),V("ia$2")/ei
		or s/t(i?ou)s\Z/prep _C_("t"),V($1),_C("s")/ei
		or s/cious\Z/prep _C_("c"),V("iou"),_C("s")/ei
		or s/${ppostcons}(e?s)\Z/prep _C("$1$5")/eix
		;

	1 while s/${dblcons}\Z/do{prep _C("$1$2")}/eix;

	while (/[a-z]/i)
	{
		debug "=====[$_]=====\n";
		s/\A(s'|'s)\Z/app _S($1)/eix	 		and next;
		s/\A${dblcons}/app _C($1),C_($2)/eix		and next;
		s/\A${dblcons}/app _C($1),C_($2)/eix		and next;
		s/\A${repcons}/app _C($1)/eix			and next;
		s/\A${paircons}/app _C($1)/eix			and next;
		s/\A${ppcons1}e(?![aeiouy])/app _C_($1),E("e")/eix
								and next;
		s/\A${precons}e(?![aeiouy])/app C_($1),E("e")/eix
								and next;
		s/\A${postcons}e(?![aeiouy])/app _C($1),E("e")/eix
								and next;
		s/\A${ppcons2}e(?![aeiouy])/app _C_($1),E("e")/eix
								and next;
		s/\A${postcons}?([sct])ion/app C_(($1||'').$2),V("io"),_C("n")/eix
								and next;
		s/\A${postcons}?tial/app C_(($1||'')."t"),V("ia"),_C("l")/eix
								and next;
		s/\A${postcons}?([ct])ia([nl])/app C_(($1||'').$2),V("ia"),_C($3)/eix
								and next;
		s/\A${postcons}?t(i?ou)s/app C_(($1||'')."t"),V($1),_C("s")/eix
								and next;
		s/\Aience/app V("i"),V("e"),_C("nc"),E('e')/eix
								and next;
		s/\Acious/app C_(($1||'')."c"),V("iou"),_C("s")/eix
								and next;
		s/\A$diphthong/app V($1),V($2)/ei		and next;
		s/\A$ppcons1/app _C_($1)/eix			and next;
		s/\A$precons/app C_($1)/eix			and next;
		s/\A$postcons/app _C($1)/eix			and next;
		s/\A$ppcons2/app _C_($1)/eix			and next;
		s/\A($vowels)/app V($1)/ei			and next;
	}
	return (@head, @tail);
}

sub partition
{
	no strict;
	local @list = @_;
	local @syls = ();

	sub is_S  { @list > 1 && $list[$#list]->{val} =~ /'?s'?/  }
	sub isR   { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type}=~'C'
						  && $list[$i]->{val} eq 'r'  }
	sub isC   { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type}=~'C' }
	sub is_C  { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type}=~'_C' }
	sub isC_  { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type}=~'C_' }
	sub isV   { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type}=~/V|E/ }
	sub isVnE { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type} eq 'V'
						  && $list[$i]->{val} !~ /\Ae/
						  }
	sub isE   { my $i = $#list+$_[0]; $i >= 0 && $list[$i]->{type} eq 'E' }

	sub syl { my $syl = "";
		  for (1..$_[0]) { $syl = pop(@list)->{val}.$syl }
		  unshift @syls, $syl;
		  1}

	is_S(0) && do { my $val = pop @list; $list[$#list]->{val} .= $val->{val} };

	while (@list)
	{
		print "\t[@syls]\n" if $::debug;
		isE(-2) && isR(-1) && isVnE(0) 		   && syl(1) && next;
		isC(-1) && is_C(0)			   && syl(1) && next;
		isC_(-3) && isV(-2) && isC(-1) && isE(0)   && syl(4) && next;
		isC_(-2) && isV(-1) && is_C(0)		   && syl(3) && next;
		isV(-2) && isC(-1) && isE(0) 		   && syl(3) && next;
		isC_(-1) && isV(0)			   && syl(2) && next;
		isV(-1) && is_C(0)			   && syl(2) && next;
		isC(0)					   && syl(1) && next;
		isV(0)					   && syl(1) && next;
	}
	return @syls;
}

my %user_def_syl = ();
my %user_def_hyph = ();

sub def_syl($)
{
	my $word = $_[0];
	$word =~ tr/~//d;
	$user_def_syl{$word} = [split /\~/, $_[0]];
}

sub def_hyph($)
{
	my $word = $_[0];
	$word =~ tr/~//d;
	$user_def_hyph{$word} = [split /\~/, $_[0]];
}

sub syllables($)  # ($word)
{
	return ($_[0]) unless $_[0] =~ /[A-Za-z]/;
	my $word = $_[0];
	$word =~ s/\A([^a-zA-Z]+)//;
	my $leader = $1||'';
	$word =~ s/([^a-zA-Z]+)\Z//;
	my $trailer = $1||'';
	my @syls = @{$user_def_syl{$word}||[]};
	unless (@syls)
	{
		my @part = split /((?:\s|'(?![ts]\b)|'[^A-Za-z]|[^A-Za-z'])+)/, $word;
		for (my $p = 0; $p < @part; $p++)
		{
			if ($p & 1) { $syls[$#syls] .= $part[$p] }
			else        { push @syls, partition(abstract($part[$p])) }
		}
	}
	$syls[0] = $leader . $syls[0];
	$syls[$#syls] .= $trailer;
	return @syls if wantarray;
	return join '~', @syls;
}


sub hyphenate($$;$)  # ($word, $width; $hyphen)
{
	my $word = shift;
	my @syls = @{$user_def_hyph{$word}||[]};
	@syls = syllables($word) unless @syls;
	my ($width, $hyphen) = (@_,'-');
	my $hlen = length $hyphen;
	my $first = '';
	while (@syls)
	{
		if ($#syls) { last if length($first) + length($syls[0]) + $hlen > $width }
		else { last if length($first) + length($syls[0]) > $width }
		$first .= shift @syls;
	}
	$first .= $hyphen if $first && @syls && $first !~ /$hyphen\Z/;
	return ("$first",join '',@syls);
}

1;
__END__

=head1 NAME

Lingua::En::Hyphenate - Perl extension for syllable-based hyphenation

=head1 SYNOPSIS

  use Lingua::En::Hyphenate;

=head1 DESCRIPTION

=head1 AUTHOR

=cut
