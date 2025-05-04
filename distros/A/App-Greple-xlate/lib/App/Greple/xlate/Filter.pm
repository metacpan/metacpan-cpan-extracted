package App::Greple::xlate::Filter;

use v5.26;
use warnings;
use Data::Dumper;

use Exporter 'import';
our @EXPORT = qw(lineify_colon lineify_cm);

my %RE = (
    LANG  => qr/ORIGINAL|\w\w(-\w\w)?/,
);

##
## Convert to line-by-line output if only part of a line is being translated
##
## * At this time, if a line contains more than one target area,
##   it results in being split across multiple lines.
##

sub lineify_colon {
    local $_ = do { local $/; <> };
    _colon();
    print;
}
sub _colon {
    s{
	(^|\G)
	(?<pre> (?<p>.+)?)  (?<mark> :{7,}) \s+ (?<l1> ($RE{LANG})) \n
	(?<t1>  .+)         \g{mark}            \n
	\g{mark} \s+        (?<l2> ($RE{LANG})) \n
	(?<t2>  .+)         \g{mark}            \n
	(?<post> (?(<p>) ((?!:{7}).)* | ((?!:{7}).)+ )) \n?
    }{
	<<~EOF;
	$+{mark} $+{l1}
	$+{pre}$+{t1}$+{post}
	$+{mark}
	$+{mark} $+{l2}
	$+{pre}$+{t2}$+{post}
	$+{mark}
	EOF
    }xnmge;
}

sub lineify_cm {
    local $_ = do { local $/; <> };
    _cm();
    print;
}
sub _cm {
    s{
	(^|\G)
	(?<pre> (?<p>.+)?) (?<m1> <<<<<<<) \s+ (?<l1> ($RE{LANG}))  \n
	(?<t1>  .+)        (?<m2> =======)                          \n
	(?<t2>  .+)        (?<m3> >>>>>>>) \s+ (?<l2> ($RE{LANG}))  \n
	(?<post> (?(<p>) ((?!<<<<<<<).)* | ((?!<<<<<<<).)+ )) \n?
    }{
	<<~EOF;
	$+{m1} $+{l1}
	$+{pre}$+{t1}$+{post}
	$+{m2}
	$+{pre}$+{t2}$+{post}
	$+{m3} $+{l2}
	EOF
    }xnmge;
}

1;
