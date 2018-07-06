#!./perl
# Adapted from Perl's lib/B/Deparse-core.t
#
# Test the core keywords.
#
# Initially this test file just checked that CORE::foo got correctly
# deparsed as CORE::foo, hence the name. It's since been expanded
# to fully test both CORE:: versus none, plus that any arguments
# are correctly deparsed. It also cross-checks against regen/keywords.pl
# to make sure we've tested all keywords, and with the correct strength.
#
# A keyword can be either weak or strong. Strong keywords can never be
# overridden, while weak ones can. So deparsing of weak keywords depends
# on whether a sub of that name has been created:
#
# for both:         keyword(..) deparsed as keyword(..)
# for weak:   CORE::keyword(..) deparsed as CORE::keyword(..)
# for strong: CORE::keyword(..) deparsed as keyword(..)
#
# Three permutations of lex/nonlex args are checked for:
#
#   foo($a,$b,$c,...)
#   foo(my $a,$b,$c,...)
#   my ($a,$b,$c,...); foo($a,$b,$c,...)
#
# Note that tests for prefixing feature.pm-enabled keywords with CORE:: when
# feature.pm is not enabled are in deparse.t, as they fit that format better.

use rlib '.';
use helper;

BEGIN {
    if ($] < 5.016 || $] > 5.0289) {
	plan skip_all => 'Customized to the Perl 5.16 - 5.26 interpreters';
    }
    require Config;
    my $is_cperl = $Config::Config{usecperl};
    plan skip_all => 'Customized to Perl (not CPerl) interpreter' if $is_cperl;
}

use strict;
use English;


use feature (sprintf(":%vd", $^V)); # to avoid relying on the feature
                                    # logic to add CORE::

my $filename = 'core-ops.pm';
test_ops('core-ops.pm');

# Special cases

# testit dbmopen  => 'CORE::dbmopen(%foo, $bar, $baz);';
# testit dbmclose => 'CORE::dbmclose %foo;', 0

testit delete   => 'CORE::delete $h{\'foo\'};', 'delete $h{\'foo\'};';
# testit delete   => 'CORE::delete $h{\'foo\'};', undef, 1;
#testit delete   => 'CORE::delete @h{\'foo\'};', undef, 1;
#testit delete   => 'CORE::delete $h[0];', undef, 1;
# testit delete   => 'CORE::delete @h[0];', undef, 1;
# testit delete   => 'delete $h{\'foo\'};',       'delete $h{\'foo\'};';

# do is listed as strong, but only do { block } is strong;
# do $file is weak,  so test it separately here
## testit do       => 'CORE::do $a;';
## testit do       => 'do $a;',                     'do($a);';
## testit do       => 'CORE::do { 1 }',
##		   "do {\n        1\n    };";
##testit do       => 'do { 1 };',
		   "do {\n        1\n    };";

testit 'each', 'CORE::each %bar;', 'CORE::each %bar;';
testit 'each', 'CORE::each @foo;', 'CORE::each %bar;';

testit 'eof', 'CORE::eof();', 'CORE::eof();';

testit exists   => 'CORE::exists $h{\'foo\'};', 'exists $h{\'foo\'};';
# testit exists   => 'CORE::exists $h{\'foo\'};', undef, 1;
# testit exists   => 'CORE::exists &foo;', undef, 1;
# testit exists   => 'CORE::exists $h[0];', undef, 1;
# testit exists   => 'exists $h{\'foo\'};',       'exists $h{\'foo\'};';

# testit exec     => 'CORE::exec($foo $bar);';

# testit glob     => 'glob;',                       'glob($_);';
# testit glob     => 'CORE::glob;',                 'CORE::glob($_);';
# testit glob     => 'glob $a;',                    'glob($a);';
# testit glob     => 'CORE::glob $a;',              'CORE::glob($a);';

# testit grep     => 'CORE::grep { $a } $b, $c',    'grep({$a;} $b, $c);';

testit 'keys', 'CORE::keys %bar;', 'CORE::keys %bar;';
testit 'keys', 'CORE::keys @bar;', 'CORE::keys @bar;';

# testit map      => 'CORE::map { $a } $b, $c',    'map({$a;} $b, $c);';

testit 'not', '3 unless CORE::not $a && $b;', '3 unless CORE::not $a && $b;';

testit 'pop', 'CORE::pop @foo;', 'CORE::pop @foo;';

testit push     => 'CORE::push @foo;',           'CORE::push(@foo);';
testit push     => 'CORE::push @foo, 1;',        'CORE::push(@foo, 1);';
testit push     => 'CORE::push @foo, 1, 2;',     'CORE::push(@foo, 1, 2);';

testit 'readline', 'CORE::readline $a . $b;', 'CORE::readline $a . $b;';
testit 'readpipe', 'CORE::readpipe $a + $b;', 'CORE::readpipe $a + $b;';
# testit 'reverse', 'CORE::reverse sort(@foo);', 'CORE::reverse sort(@foo);';
testit 'shift', 'CORE::shift @foo;', 'CORE::shift @foo;';

testit splice   => q{CORE::splice @foo;},                 q{CORE::splice(@foo);};
testit splice   => q{CORE::splice @foo, 0;},              q{CORE::splice(@foo, 0);};
testit splice   => q{CORE::splice @foo, 0, 1;},           q{CORE::splice(@foo, 0, 1);};
# testit splice   => q{CORE::splice @foo, 0, 1, 'a';},      q{CORE::splice(@foo, 0, 1, 'a');};
# testit splice   => q{CORE::splice @foo, 0, 1, 'a', 'b';}, q{CORE::splice(@foo, 0, 1, 'a', 'b');};

# note that the test does '() = split...' which is why the
# limit is optimised to 1

# testit split    => 'split;',                     q{split(/ /, $_, 1);};
# testit split    => 'CORE::split;',               q{split(/ /, $_, 1);};
# testit split    => 'split $a;',                  q{split(/$a/, $_, 1);};
# testit split    => 'CORE::split $a;',            q{split(/$a/, $_, 1);};
## FIXME
#testit split    => 'split $a, $b;',              q{split(/$a/u, $b, 1);};
#testit split    => 'CORE::split $a, $b;',        q{split(/$a/u, $b, 1);};
#testit split    => 'split $a, $b, $c;',          q{split(/$a/u, $b, $c);};
#testit split    => 'CORE::split $a, $b, $c;',    q{split(/$a/u, $b, $c);};

# testit sub      => 'CORE::sub { $a, $b }',
#			"sub {\n        \$a, \$b;\n    }\n    ;";

# testit system   => 'CORE::system($foo $bar);';

testit unshift  => 'CORE::unshift @foo;',        'CORE::unshift(@foo);';
testit unshift  => 'CORE::unshift @foo, 1;',     'CORE::unshift(@foo, 1);';
testit unshift  => 'CORE::unshift @foo, 1, 2;',  'CORE::unshift(@foo, 1, 2);';

# testit values   => 'CORE::values %bar;';
# testit values   => 'CORE::values @foo;';


# XXX These are deparsed wrapped in parens.
# whether they should be, I don't know!

# testit dump     => '(CORE::dump);';
# testit dump     => '(CORE::dump FOO);';
# testit goto     => '(CORE::goto);',     '(goto);';
# testit goto     => '(CORE::goto FOO);', '(goto FOO);';
# testit last     => '(CORE::last);',     '(last);';
# testit last     => '(CORE::last FOO);', '(last FOO);';
# testit next     => '(CORE::next);',     '(next);';
# testit next     => '(CORE::next FOO);', '(next FOO);';
# testit redo     => '(CORE::redo);',     '(redo);';
# testit redo     => '(CORE::redo FOO);', '(redo FOO);';
# testit redo     => '(CORE::redo);',     '(redo);';
# testit redo     => '(CORE::redo FOO);', '(redo FOO);';

# FIXME: used to work...
# testit return   => '(return);',         '(return);';
# testit return   => '(CORE::return);',   '(return);';

# these are the keywords I couldn't think how to test within this framework

my %not_tested = map { $_ => 1} qw(
    __DATA__
    __END__
    __FILE__
    __LINE__
    __PACKAGE__
    AUTOLOAD
    BEGIN
    CHECK
    CORE
    DESTROY
    END
    INIT
    UNITCHECK
    default
    else
    elsif
    for
    foreach
    format
    given
    if
    m
    no
    package
    q
    qq
    qr
    qw
    qx
    require
    s
    tr
    unless
    until
    use
    when
    while
    y
);



# Sanity check against keyword data:
# make sure we haven't missed any keywords,
# and that we got the strength right.

SKIP:
{
    skip "sanity checks when not PERL_CORE", 1 unless defined $ENV{PERL_CORE};
    my $count = 0;
    my $file = '../regen/keywords.pl';
    my $pass = 1;
    if (open my $fh, '<', $file) {
	while (<$fh>) {
	    last if /^__END__$/;
	}
	while (<$fh>) {
	    next unless /^([+\-])(\w+)$/;
	    my ($strength, $key) = ($1, $2);
	    $strength = ($strength eq '+') ? 1 : 0;
	    $count++;
	    if (!$SEEN{$key} && !$not_tested{$key}) {
		diag("keyword '$key' seen in $file, but not tested here!!");
		$pass = 0;
	    }
	    if (exists $SEEN_STRENGTH{$key} and $SEEN_STRENGTH{$key} != $strength) {
		diag("keyword '$key' strengh as seen in $file doen't match here!!");
		$pass = 0;
	    }
	}
    }
    else {
	diag("Can't open $file: $!");
	$pass = 0;
    }
    # insanity check
    if ($count < 200) {
	diag("Saw $count keywords: less than 200!");
	$pass = 0;
    }
    ok($pass, "sanity checks");
}


done_testing();
