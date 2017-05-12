package Data::Dump::Color;

our $DATE = '2014-10-29'; # DATE
our $VERSION = '0.23'; # VERSION

use 5.010001;
use strict;
use vars qw(@EXPORT @EXPORT_OK $VERSION $DEBUG);
use subs qq(dump);

require Exporter;
*import = \&Exporter::import;
@EXPORT = qw(dd ddx);
@EXPORT_OK = qw(dump pp dumpf quote);

$DEBUG = $ENV{DEBUG};

use overload ();
use vars qw(%seen %refcnt @fixup @cfixup %require $TRY_BASE64 @FILTERS $INDENT);
use vars qw(%COLOR_THEMES %COLORS $COLOR $COLOR_THEME $COLOR_DEPTH $INDEX $LENTHRESHOLD);

use Term::ANSIColor;
require Win32::Console::ANSI if $^O =~ /Win/;
use Scalar::Util::LooksLikeNumber qw(looks_like_number);

$TRY_BASE64 = 50 unless defined $TRY_BASE64;
$INDENT = "  " unless defined $INDENT;
$INDEX = 1 unless defined $INDEX;
$LENTHRESHOLD = 500 unless defined $LENTHRESHOLD;

%COLOR_THEMES = (
    default16 => {
        colors => {
            Regexp  => 'yellow',
            undef   => 'bright_red',
            number  => 'bright_blue', # floats can have different color
            float   => 'cyan',
            string  => 'bright_yellow',
            object  => 'bright_green',
            glob    => 'bright_cyan',
            key     => 'magenta',
            comment => 'green',
            keyword => 'blue',
            symbol  => 'cyan',
            linum   => 'black on_white', # file:line number
        },
    },
    default256 => {
        color_depth => 256,
        colors => {
            Regexp  => 135,
            undef   => 124,
            number  => 27,
            float   => 51,
            string  => 226,
            object  => 10,
            glob    => 10,
            key     => 202,
            comment => 34,
            keyword => 21,
            symbol  => 51,
            linum   => 10,
        },
    },
);

$COLOR_THEME = ($ENV{TERM} // "") =~ /256/ ? 'default256' : 'default16';
$COLOR_DEPTH = $COLOR_THEMES{$COLOR_THEME}{color_depth} // 16;
%COLORS      = %{ $COLOR_THEMES{$COLOR_THEME}{colors} };

my $_colreset = color('reset');
sub _col {
    my ($col, $str) = @_;
    my $colval = $COLORS{$col};
    if ($COLOR // $ENV{COLOR} // (-t STDOUT)) {
        #say "D:col=$col, COLOR_DEPTH=$COLOR_DEPTH";
        if ($COLOR_DEPTH >= 256 && $colval =~ /^\d+$/) {
            return "\e[38;5;${colval}m" . $str . $_colreset;
        } else {
            return color($colval) . $str . $_colreset;
        }
    } else {
        return $str;
    }
}

sub dump
{
    local %seen;
    local %refcnt;
    local %require;
    local @fixup;
    local @cfixup;

    require Data::Dump::FilterContext if @FILTERS;

    my $name = "a";
    my @dump;
    my @cdump;

    for my $v (@_) {
	my ($val, $cval) = _dump($v, $name, [], tied($v));
	push(@dump , [$name,  $val]);
	push(@cdump, [$name, $cval]);
    } continue {
	$name++;
    }

    my $out  = "";
    my $cout = "";
    if (%require) {
	for (sort keys %require) {
	    $out  .= "require $_;\n";
	    $cout .= _col(keyword=>"require")." "._col(symbol=>$_).";\n";
	}
    }
    if (%refcnt) {
	# output all those with refcounts first
	for my $i (0..$#dump) {
	    my $name  = $dump[ $i][0];
	    my $cname = $cdump[$i][0];
	    if ($refcnt{$name}) {
		$out  .= "my \$$name = $dump[$i][1];\n";
		$cout .= _col(keyword=>"my")." "._col(symbol=>"\$$cname")." = $cdump[$i][1];\n";
		undef $dump[ $i][1];
		undef $cdump[$i][1];
	    }
	}
	for my $i (0..$#fixup) {
	    $out  .= "$fixup[$i];\n";
	    $cout .= "$cfixup[$i];\n";
	}
    }

    my $paren = (@dump != 1);
    $out  .= "(" if $paren;
    $cout .= "(" if $paren;
    my ($f, $cf) = format_list($paren, undef,
                               [0],
                               [map {defined($_->[1]) ? $_->[1] : "\$".$_->[0]} @dump ],
                               [map {defined($_->[1]) ? $_->[1] : "\$".$_->[0]} @cdump],
                               \@_,
                           );
    $out  .= $f;
    $cout .= $cf;
    $out  .= ")" if $paren;
    $cout .= ")" if $paren;

    if (%refcnt || %require) {
	$out  .= ";\n";
	$cout .= ";\n";
	$out  =~ s/^/$INDENT/gm;
	$cout =~ s/^/$INDENT/gm;
	$out  = "do {\n$out}";
	$cout = _col(keyword=>"do")." {\n$cout}";
    }

    print STDERR "$cout\n" unless defined wantarray;
    $cout;
}

*pp = \&dump;

sub dd {
    print dump(@_), "\n";
}

sub ddx {
    my(undef, $file, $line) = caller;
    $file =~ s,.*[\\/],,;
    my $out = _col(linum=>"$file:$line: ") . dump(@_) . "\n";
    $out =~ s/^/# /gm;
    print $out;
}

sub dumpf {
    require Data::Dump::Filtered;
    goto &Data::Dump::Filtered::dump_filtered;
}

# return two result: (uncolored dump, colored dump)
sub _dump
{
    my $ref  = ref $_[0];
    my $rval = $ref ? $_[0] : \$_[0];
    shift;

    # compared to Data::Dump, each @$idx element is also a [uncolored,colored]
    # instead of just a scalar.
    my($name, $idx, $dont_remember, $pclass, $pidx) = @_;

    my($class, $type, $id);
    my $strval = overload::StrVal($rval);
    # Parse $strval without using regexps, in order not to clobber $1, $2,...
    if ((my $i = rindex($strval, "=")) >= 0) {
	$class = substr($strval, 0, $i);
	$strval = substr($strval, $i+1);
    }
    if ((my $i = index($strval, "(0x")) >= 0) {
	$type = substr($strval, 0, $i);
	$id = substr($strval, $i + 2, -1);
    }
    else {
	die "Can't parse " . overload::StrVal($rval);
    }
    if ($] < 5.008 && $type eq "SCALAR") {
	$type = "REF" if $ref eq "REF";
    }
    warn "\$$name(@$idx) $class $type $id ($ref)" if $DEBUG;

    my $out;
    my $cout;
    my $comment;
    my $hide_keys;
    if (@FILTERS) {
	my $pself = "";
	($pself, undef) = fullname("self", [@$idx[$pidx..(@$idx - 1)]]) if $pclass;
	my $ctx = Data::Dump::FilterContext->new($rval, $class, $type, $ref, $pclass, $pidx, $idx);
	my @bless;
	for my $filter (@FILTERS) {
	    if (my $f = $filter->($ctx, $rval)) {
		if (my $v = $f->{object}) {
		    local @FILTERS;
		    ($out, $cout) = _dump($v, $name, $idx, 1);
		    $dont_remember++;
		}
		if (defined(my $c = $f->{bless})) {
		    push(@bless, $c);
		}
		if (my $c = $f->{comment}) {
		    $comment = $c;
		}
		if (defined(my $c = $f->{dump})) {
		    $out  = $c;
		    $cout = $c; # XXX where's the colored version?
		    $dont_remember++;
		}
		if (my $h = $f->{hide_keys}) {
		    if (ref($h) eq "ARRAY") {
			$hide_keys = sub {
			    for my $k (@$h) {
				return (1, 1) if $k eq $_[0]; # XXX color?
			    }
			    return (0, 0); # XXX color?
			};
		    }
		}
	    }
	}
	push(@bless, "") if defined($out) && !@bless;
	if (@bless) {
	    $class = shift(@bless);
	    warn "More than one filter callback tried to bless object" if @bless;
	}
    }

    unless ($dont_remember) {
	if (my $s = $seen{$id}) {
	    my($sname, $sidx) = @$s;
	    $refcnt{$sname}++;
	    my ($sref, $csref)  = fullname($sname, $sidx,
                                           ($ref && $type eq "SCALAR"));
	    warn "SEEN: [\$$name(@$idx)] => [\$$sname(@$sidx)] ($ref,$sref)" if $DEBUG;
	    return ($sref, $csref) unless $sname eq $name; # XXX color?
	    $refcnt{$name}++;
            my ($fn, $cfn) = fullname($name, $idx);
	    push(@fixup , "$fn = $sref");
	    push(@cfixup, "$cfn = $csref");
	    return (
                "do{my \$fix}",
                _col(keyword=>"do")."{"._col(keyword=>"my")." "._col(symbol=>"\$fix")."}",
            ) if @$idx && $idx->[-1] eq '$';
	    return (
                "'fix'",
                _col(string => "'fix'"),
            );
	}
	$seen{$id} = [$name, $idx];
    }

    if ($class) {
	$pclass = $class;
	$pidx = @$idx;
    }

    if (defined $out) {
	# keep it
    }
    elsif ($type eq "SCALAR" || $type eq "REF" || $type eq "REGEXP") {
	if ($ref) {
	    if ($class && $class eq "Regexp") {
		my $v = "$rval";

		my $mod = "";
		if ($v =~ /^\(\?\^?([msix-]*):([\x00-\xFF]*)\)\z/) {
		    $mod = $1;
		    $v = $2;
		    $mod =~ s/-.*//;
		}

		my $sep = '/';
		my $sep_count = ($v =~ tr/\///);
		if ($sep_count) {
		    # see if we can find a better one
		    for ('|', ',', ':', '#') {
			my $c = eval "\$v =~ tr/\Q$_\E//";
			#print "SEP $_ $c $sep_count\n";
			if ($c < $sep_count) {
			    $sep = $_;
			    $sep_count = $c;
			    last if $sep_count == 0;
			}
		    }
		}
		$v =~ s/\Q$sep\E/\\$sep/g;

		$out  = "qr$sep$v$sep$mod";
		$cout = _col('Regexp', $out);
		undef($class);
	    }
	    else {
		delete $seen{$id} if $type eq "SCALAR";  # will be seen again shortly
		my ($val, $cval) = _dump($$rval, $name, [@$idx, ["\$","\$"]], 0, $pclass, $pidx);
		$out  = $class ? "do{\\(my \$o = $val)}" : "\\$val";
		$cout = $class ? _col(keyword=>"do")."{\\("._col(keyword=>"my")." "._col(symbol=>"\$o")." = $cval)}" : "\\$cval";
	    }
	} else {
	    if (!defined $$rval) {
		$out  = 'undef';
		$cout = _col('undef', "undef");
	    }
	    elsif (my $ntype = looks_like_number($$rval)) {
		my $val = $ntype < 20 ? qq("$$rval") : $$rval;
                my $col = $ntype =~ /^(5|13|8704)$/ ? "float":"number";
                $out  = $val;
		$cout = _col($col => $val);
	    }
	    else {
		$out  = str($$rval);
		$cout = _col(string => $out);
	    }
	    if ($class && !@$idx) {
		# Top is an object, not a reference to one as perl needs
		$refcnt{$name}++;
		my ($obj, $cobj) = fullname($name, $idx);
		my $cl  = quote($class);
		push(@fixup , "bless \\$obj, $cl");
		push(@cfixup, _col(keyword => "bless")." \\$cobj, "._col(string=>$cl));
	    }
	}
    }
    elsif ($type eq "GLOB") {
	if ($ref) {
	    delete $seen{$id};
	    my ($val, $cval) = _dump($$rval, $name, [@$idx, ["*","*"]], 0, $pclass, $pidx);
	    $out  = "\\$val";
	    $cout = "\\$cval";
	    if ($out =~ /^\\\*Symbol::/) {
		$require{Symbol}++;
		$out  = "Symbol::gensym()";
		$cout = _col(glob => $out);
	    }
	} else {
	    my $val = "$$rval";
	    $out  = "$$rval";
	    $cout = _col(glob => $out);

	    for my $k (qw(SCALAR ARRAY HASH)) {
		my $gval = *$$rval{$k};
		next unless defined $gval;
		next if $k eq "SCALAR" && ! defined $$gval;  # always there
		my $f = scalar @fixup;
		push(@fixup, "RESERVED");  # overwritten after _dump() below
		my $cgval;
                ($gval, $cgval) = _dump($gval, $name, [@$idx, ["*{$k}", "*{"._col(string=>$k)."}"]], 0, $pclass, $pidx);
		$refcnt{$name}++;
		my ($gname, $cgname) = fullname($name, $idx);
		$fixup[ $f] = "$gname = $gval" ;  #XXX indent $gval
		$cfixup[$f] = "$gname = $cgval";  #XXX indent $gval
	    }
	}
    }
    elsif ($type eq "ARRAY") {
	my @vals;
        my @cvals;
	my $tied = tied_str(tied(@$rval));
	my $i = 0;
	for my $v (@$rval) {
	    my ($d, $cd) = _dump($v, $name, [@$idx, ["[$i]","["._col(number=>$i)."]"]], $tied, $pclass, $pidx);
            push @vals ,  $d;
            push @cvals, $cd;
	    $i++;
	}
	my ($f, $cf) = format_list(1, $tied, [scalar(@$idx)], \@vals, \@cvals, $rval);
        $out  = "[$f]";
        $cout = "[$cf]";
    }
    elsif ($type eq "HASH") {
	my(@keys, @vals, @cvals, @origk, @origv);
	my $tied = tied_str(tied(%$rval));

	# statistics to determine variation in key lengths
	my $kstat_max = 0;
	my $kstat_sum = 0;
	my $kstat_sum2 = 0;

        my @orig_keys = keys %$rval;
	if ($hide_keys) {
	    @orig_keys = grep !$hide_keys->($_), @orig_keys;
	}
	my $text_keys = 0;
	for (@orig_keys) {
	    $text_keys++, last unless /^[-+]?(?:0|[1-9]\d*)(?:\.\d+)?\z/;
	}

	if ($text_keys) {
	    @orig_keys = sort { lc($a) cmp lc($b) } @orig_keys;
	}
	else {
	    @orig_keys = sort { $a <=> $b } @orig_keys;
	}

	my $quote;
	for my $key (@orig_keys) {
	    next if $key =~ /^-?[a-zA-Z_]\w*\z/;
	    next if $key =~ /^-?[1-9]\d{0,8}\z/;
	    $quote++;
	    last;
	}

        my @lenvlastline;
        for my $key (@orig_keys) {
	    my $val = \$rval->{$key};  # capture value before we modify $key
	    push(@origk, $key);
	    $key = quote($key) if $quote;
	    $kstat_max = length($key) if length($key) > $kstat_max;
	    $kstat_sum += length($key);
	    $kstat_sum2 += length($key)*length($key);

	    push(@keys, $key);
            my ($v, $cv) = _dump($$val, $name, [@$idx, ["{$key}","{"._col(string=>$key)."}"]], $tied, $pclass, $pidx);
	    push(@vals ,  $v);
	    push(@cvals, $cv);
	    push(@origv, $$val);

            my ($vlastline) = $v =~ /(.*)\z/;
            #say "DEBUG: v=<$v>, vlastline=<$vlastline>" if $DEBUG;
            my $lenvlastline = length($vlastline);
            push @lenvlastline, $lenvlastline;
	}
        #$maxvlen += length($INDENT);
	#say "maxvlen=$maxvlen"; #TMP
        my $nl = "";
	my $klen_pad = 0;
	my $tmp = "@keys @vals";
	if (length($tmp) > 60 || $tmp =~ /\n/ || $tied) {
	    $nl = "\n";

	    # Determine what padding to add
	    if ($kstat_max < 4) {
		$klen_pad = $kstat_max;
	    }
	    elsif (@keys >= 2) {
		my $n = @keys;
		my $avg = $kstat_sum/$n;
		my $stddev = sqrt(($kstat_sum2 - $n * $avg * $avg) / ($n - 1));

		# I am not actually very happy with this heuristics
		if ($stddev / $kstat_max < 0.25) {
		    $klen_pad = $kstat_max;
		}
		if ($DEBUG) {
		    push(@keys, "__S");
		    push(@vals, sprintf("%.2f (%d/%.1f/%.1f)",
					$stddev / $kstat_max,
					$kstat_max, $avg, $stddev));
		    push(@cvals, sprintf("%.2f (%d/%.1f/%.1f)",
                                         $stddev / $kstat_max,
                                         $kstat_max, $avg, $stddev));
		}
	    }
	}

        my $maxkvlen = 0;
        for (0..$#keys) {
            my $klen = length($keys[$_]);
            $klen = $klen_pad if $klen < $klen_pad;
            my $kvlen = $klen + $lenvlastline[$_];
            $maxkvlen = $kvlen if $maxkvlen < $kvlen;
        }
        $maxkvlen = 80 if $maxkvlen > 80;

	$out  = "{$nl";
	$cout = "{$nl";
	$out  .= "$INDENT# $tied$nl" if $tied;
	$cout .= $INDENT._col(comment=>"# $tied").$nl if $tied;
	my $i = 0;
        my $idxwidth = length(~~@keys);
        while (@keys) {
	    my $key = shift(@keys);
	    my $val  = shift @vals;
	    my $cval = shift @cvals;
	    my $origk = shift @origk;
	    my $origv = shift @origv;
            my $lenvlastline = shift @lenvlastline;
	    my $vmultiline = length($val) > $lenvlastline;
            my $vpad = $INDENT . (" " x ($klen_pad ? $klen_pad + 4 : 0));
	    $val  =~ s/\n/\n$vpad/gm;
	    $cval =~ s/\n/\n$vpad/gm;
	    my $kpad = $nl ? $INDENT : " ";
	    $key .= " " x ($klen_pad - length($key)) if $nl;
            my $cpad = " " x ($maxkvlen - ($vmultiline ? -6+length($vpad) : length($key)) - $lenvlastline);
            #say "DEBUG: key=<$key>, vpad=<$vpad>, val=<$val>, lenvlastline=<$lenvlastline>, cpad=<$cpad>" if $DEBUG;
            my $visaid = "";
            $visaid .= sprintf("%s{%${idxwidth}i}", "." x @$idx, $i) if $INDEX;
            $visaid .= " klen=".length($origk) if length($origk) >= $LENTHRESHOLD;
            $visaid .= " vlen=".length($origv) if length($origv) >= $LENTHRESHOLD;
	    $out  .= "$kpad$key => $val," . ($nl && length($visaid) ? " $cpad# $visaid" : "") . $nl;
	    $cout .= $kpad._col(key=>$key)." => $cval,".($nl && length($visaid) ? " $cpad"._col(comment => "# $visaid") : "") . $nl;
            $i++;
	}
	$out  =~ s/,$/ / unless $nl;
	$cout =~ s/,$/ / unless $nl;
	$out  .= "}";
	$cout .= "}";
    }
    elsif ($type eq "CODE") {
	$out  = 'sub { ... }';
	$cout = _col(keyword=>'sub').' { ... }';
    }
    elsif ($type eq "VSTRING") {
        $out  = sprintf +($ref ? '\v%vd' : 'v%vd'), $$rval;
        $cout = _col(string => $out);
    }
    else {
	warn "Can't handle $type data";
	$out  = "'#$type#'";
	$cout = _col(comment => $out);
    }

    if ($class && $ref) {
	$cout = _col(keyword=>"bless")."($cout, " . _col(string => quote($class)) . ")";
	$out  = "bless($out, ".quote($class).")";
    }
    if ($comment) {
	$comment =~ s/^/# /gm;
	$comment .= "\n" unless $comment =~ /\n\z/;
	$comment =~ s/^#[ \t]+\n/\n/;
	$cout = _col(comment=>$comment).$out;
	$out  = "$comment$out";
    }
    return ($out, $cout);
}

sub tied_str {
    my $tied = shift;
    if ($tied) {
	if (my $tied_ref = ref($tied)) {
	    $tied = "tied $tied_ref";
	}
	else {
	    $tied = "tied";
	}
    }
    return $tied;
}

# return two result: (uncolored dump, colored dump)
sub fullname
{
    my($name, $idx, $ref) = @_;
    substr($name, 0, 0) = "\$";
    my $cname = $name;

    my @i = @$idx;  # need copy in order to not modify @$idx
    if ($ref && @i && $i[0][0] eq "\$") {
	shift(@i);  # remove one deref
	$ref = 0;
    }
    while (@i && $i[0][0] eq "\$") {
	shift @i;
	$name  = "\$$name";
	$cname = _col(symbol=>$name);
    }

    my $last_was_index;
    for my $i (@i) {
	if ($i->[0] eq "*" || $i->[0] eq "\$") {
	    $last_was_index = 0;
	    $name  = "$i->[0]\{$name}";
	    $cname = "$i->[1]\{$cname}";
	} elsif ($i->[0] =~ s/^\*//) {
	    $name  .= $i->[0];
	    $cname .= $i->[1];
	    $last_was_index++;
	} else {
	    $name  .= "->" unless $last_was_index++;
	    $cname .= "->" unless $last_was_index++;
	    $name  .= $i->[0];
	    $cname .= $i->[1];
	}
    }
    $name = "\\$name" if $ref;
    ($name, $cname);
}

# return two result: (uncolored dump, colored dump)
sub format_list
{
    my $paren = shift;
    my $comment = shift;
    my $extra = shift; # [level, ]
    my $indent_lim = $paren ? 0 : 1;
    my @vals  = @{ shift(@_) };
    my @cvals = @{ shift(@_) };
    my @orig  = @{ shift(@_) };

    if (@vals > 3) {
	# can we use range operator to shorten the list?
	my $i = 0;
	while ($i < @vals) {
	    my $j = $i + 1;
	    my $v = $vals[$i];
	    while ($j < @vals) {
		# XXX allow string increment too?
		if ($v eq "0" || $v =~ /^-?[1-9]\d{0,9}\z/) {
		    $v++;
		}
		elsif ($v =~ /^"([A-Za-z]{1,3}\d*)"\z/) {
		    $v = $1;
		    $v++;
		    $v = qq("$v");
		}
		else {
		    last;
		}
		last if $vals[$j] ne $v;
		$j++;
	    }
	    if ($j - $i > 3) {
		splice(@vals , $i, $j - $i, "$vals[$i] .. $vals[$j-1]");
		splice(@cvals, $i, $j - $i, "$cvals[$i] .. $cvals[$j-1]");
		splice(@orig , $i, $j - $i, [@orig[$i..$j-1]]);
	    }
	    $i++;
	}
    }
    my $tmp = "@vals";
    if ($comment || (@vals > $indent_lim && (length($tmp) > 60 || $tmp =~ /\n/))) {

        my $maxvlen = 0;
        for (@vals) {
            my ($vfirstline) = /\A(.*)/;
            my $lenvfirstline = length($vfirstline);
            $maxvlen = $lenvfirstline if $maxvlen < $lenvfirstline;
        }
        $maxvlen = 80 if $maxvlen > 80;
        $maxvlen += length($INDENT);

	my @res  = ("\n", $comment ? "$INDENT# $comment\n" : "");
	my @cres = ("\n", $comment ? $INDENT._col("# $comment")."\n" : "");
	my @elem  = @vals;
	my @celem = @cvals;
	for (@elem ) { s/^/$INDENT/gm; }
	for (@celem) { s/^/$INDENT/gm; }
        my $idxwidth = length(~~@elem);
        for my $i (0..$#elem) {
            my ($vlastline) = $elem[$i] =~ /(.*)\z/;
            my $cpad = " " x ($maxvlen - length($vlastline));
            my $visaid = "";
            $visaid .= sprintf("%s[%${idxwidth}i]", "." x $extra->[0], $i) if $INDEX;
            $visaid .= " len=".length($orig[$i]) if length($orig[$i]) >= $LENTHRESHOLD;
            push @res , $elem[ $i], ",", (length($visaid) ? " $cpad# $visaid" : ""), "\n";
            push @cres, $celem[$i], ",", (length($visaid) ? " $cpad"._col(comment => "# $visaid") : ""), "\n";
        }
        return (join("", @res), join("", @cres));
    } else {
	return (join(", ", @vals), join(", ", @cvals));
    }
}

sub str {
  if (length($_[0]) > 20) {
      for ($_[0]) {
      # Check for repeated string
      if (/^(.)\1\1\1/s) {
          # seems to be a repeating sequence, let's check if it really is
          # without backtracking
          unless (/[^\Q$1\E]/) {
              my $base = quote($1);
              my $repeat = length;
              return "($base x $repeat)"
          }
      }
      # Length protection because the RE engine will blow the stack [RT#33520]
      if (length($_) < 16 * 1024 && /^(.{2,5}?)\1*\z/s) {
	  my $base   = quote($1);
	  my $repeat = length($_)/length($1);
	  return "($base x $repeat)";
      }
      }
  }

  local $_ = &quote;

  if (length($_) > 40  && !/\\x\{/ && length($_) > (length($_[0]) * 2)) {
      # too much binary data, better to represent as a hex/base64 string

      # Base64 is more compact than hex when string is longer than
      # 17 bytes (not counting any require statement needed).
      # But on the other hand, hex is much more readable.
      if ($TRY_BASE64 && length($_[0]) > $TRY_BASE64 &&
	  (defined &utf8::is_utf8 && !utf8::is_utf8($_[0])) &&
	  eval { require MIME::Base64 })
      {
	  $require{"MIME::Base64"}++;
	  return "MIME::Base64::decode(\"" .
	             MIME::Base64::encode($_[0],"") .
		 "\")";
      }
      return "pack(\"H*\",\"" . unpack("H*", $_[0]) . "\")";
  }

  return $_;
}

my %esc = (
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);

# put a string value in double quotes
sub quote {
  local($_) = $_[0];
  # If there are many '"' we might want to use qq() instead
  s/([\\\"\@\$])/\\$1/g;
  return qq("$_") unless /[^\040-\176]/;  # fast exit

  s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

  # no need for 3 digits in escape for these
  s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

  s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
  s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

  return qq("$_");
}

1;
# ABSTRACT: Like Data::Dump, but with color

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dump::Color - Like Data::Dump, but with color

=head1 VERSION

This document describes version 0.23 of Data::Dump::Color (from Perl distribution Data-Dump-Color), released on 2014-10-29.

=head1 SYNOPSIS

Use it like you would Data::Dump, e.g.:

 use Data::Dump::Color; dd localtime;

=head1 DESCRIPTION

This module aims to be a drop-in replacement for L<Data::Dump>. It adds colors
to dumps. It also adds various visual aids in the comments, e.g. array/hash
index, depth indicator, and so on.

For more information, see Data::Dump. This documentation explains what's
different between this module and Data::Dump.

=for Pod::Coverage .+

=head1 RESULTS

By default Data::Dump::Color shows array index or hash pair sequence in comments
for visual aid, e.g.:

 [
   "this",      # [0]
   "is",        # [1]
   "a",         # [2]
   "5-element", # [3]
   "array",     # [4]
   {
     0  => "with",  # .{0}
     1  => "an",    # .{1}
     2  => "extra", # .{2}
     3  => "hash",  # .{3}
     4  => "at",    # .{4}
     5  => "the",   # .{5}
     16 => "end",   # .{6}
   },           # [5]
 ]

C<[]> and C<{}> brackets will indicate whether they are indexes to an array or
a hash. The dot prefixes will mark depth level.

To turn this off, set C<$INDEX> to 0:

 [
   "this",
   "is",
   "a",
   "5-element",
   "array",
   {
     0  => "with",
     1  => "an",
     2  => "extra",
     3  => "hash",
     4  => "at",
     5  => "the",
     16 => "end",
   },
 ]

=head1 VARIABLES

C<$Data::Dump::*> package variables from Data::Dump, like
C<$Data::Dump::TRY_BASE64>, etc are now in the C<Data::Dump::Color> namespace,
e.g. C<$Data::Dump::Color::TRY_BASE64>, etc.

Additional variables include:

=over

=item $COLOR => BOOL (default: undef)

Whether to force-enable or disable color. If unset, color output will be
determined from C<$ENV{COLOR}> or when in interactive terminal (when C<-t
STDOUT> is true).

=item %COLORS => HASH (default: default colors)

Define colors.

=item $INDEX => BOOL (default: 1)

Whether to add array/hash index visual aid.

=item $LENTHRESHOLD => int (default: 500)

Add string length visual aid for hash key/hash value/array element if length
is at least this value.

=back

=head1 ENVIRONMENT

=over

=item * COLOR

If set, then will force color output on or off. By default, will only output
color when in interactive terminal. This is consulted when C<$COLOR> is not set.

=back

=head1 FAQ

=head2 How do I turn off index comments?

Set C<$Data::Dump::Color::INDEX> to 0.

=head2 How do I turn off colors?

Well, colors is sort of the point of this module. But if you want to turn it
off, you can set environment COLOR to 0, or C<$Data::Dump::Color::COLOR> to 0.

=head2 How do I customize colors?

Fiddle the colors in C<%Data::Dump::Color::COLORS>. There will probably be
proper color theme support in the future (based on
L<SHARYANTO::Role::ColorTheme>.

=head1 SEE ALSO

L<Data::Dump>, L<JSON::Color>, L<YAML::Tiny::Color>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Dump-Color>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Dump-Color>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Dump-Color>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
