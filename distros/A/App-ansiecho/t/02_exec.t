use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

use Term::ANSIColor::Concise qw(ansi_color ansi_code);

sub test {
    my $answer = pop @_;
    my $comment = join(' ', map { / / ? "'$_'" : $_ } @_);
    is(ansiecho(@_)->{stdout},
       $answer,
       $comment);
}

test(qw(a b c), "a b c\n");
test(qw(-n a b c), "a b c");
test(qw(-j a b c), "abc\n");
test(qw(-nj a b c), "abc");
test(qw(--separate=: a b c), "a:b:c\n");
test(qw(--separate=\N{COLON} a b c), "a:b:c\n");

test(qw(\\-c), "-c\n");
test(qw(\\55c), "\55c\n");
test(qw(\\055c), "\055c\n");
test(qw(\\o{55}c), "\o{55}c\n");
test(qw(\\o{055}c), "\o{055}c\n");
test(qw(\\x2dc), "\x2dc\n");
test(qw(\\N{U+002D}c), "\N{U+002D}c\n");

SKIP: {

my $smiley =
    sub { eval sprintf q("\\N{%s}"), $_[0] }->("WHITE SMILING FACE")
    or skip "Unicode charname is not supported.", 3;

is(ansiecho('--no-escape', '\N{WHITE SMILING FACE}')->{stdout},
   '\N{WHITE SMILING FACE}'."\n",
   '\N{WHITE SMILING FACE}');

is(ansiecho('\N{WHITE SMILING FACE}')->{stdout},
   "$smiley\n",
   '-e \N{WHITE SMILING FACE}');

is(ansiecho('--escape', '\N{WHITE SMILING FACE}')->{stdout},
   "$smiley\n",
   '--escape \N{WHITE SMILING FACE}');

}

for my $fg ('RGBCMYKW' =~ /./g) {
    no strict 'refs';
    *{$fg} = sub { ansi_color($fg, @_) };
    for my $bg ('RGBCMYKW' =~ /./g) {
	*{"${fg}on${bg}"} = sub { ansi_color("${fg}/${bg}", @_) };
    }
}

# error
{ local $@;
  like(do { ansiecho(qw(-c)); $@ }, qr/Not enough/, '-c (error)'); }
{ local $@;
  like(do { ansiecho(qw(-f)); $@ }, qr/Not enough/, '-f (error)'); }
{ local $@;
  like(do { ansiecho(qw(-f %s)); $@ }, qr/Not enough/, '-f %s (error)'); }
{ local $@;
  like(do { ansiecho(qw(-f %s%s a)); $@ }, qr/Not enough/, '-f %s%s a (error)'); }

# -c
test(qw(-c R RED),    R("RED")."\n");
test(qw(-cR RED),     R("RED")."\n");
test(qw(-cR -cG RED), R(G("RED"))."\n");

# -n
test(qw(-n -c R RED), R("RED"));

# -j
test(qw(-j -cR R -cG G -cB B),
     join("", R("R"), G("G"), B("B")) . "\n"
    );

# -f
test(qw(-f %s abc),     "abc\n");
test(qw(-f %%),         "%\n");
test(qw(-f %%%s%% abc), "%abc%\n");
test(qw(-f %5s abc),    "  abc\n");
test(qw(-f %5s -c R abc),  sprintf("  %s\n", R("abc")));
test(qw(-f %-5s -c R abc), sprintf("%s  \n", R("abc")));

test(qw(-f %d 123),        "123\n"  );
test(qw(-f %d -123),       "-123\n" );
test(qw(-f %5d 123),       "  123\n");
test(qw(-f %05d 123),      "00123\n");
test(qw(-f %-5d 123),      "123  \n");
test(qw(-f %+5d  123),     " +123\n");
test(qw(-f %+5d -123),     " -123\n");
test('-f', '% 5d',  '123', "  123\n");
test('-f', '% 5d', '-123', " -123\n");
test('-f', '%o', '123',    "173\n");
test('-f', '%#o', '123',   "0173\n");

# positional parameters
test('-f', '%2$d %d',    '12', '34',       "34 12\n");
test('-f', '%2$d %d %d', '12', '34',       "34 12 34\n");
test('-f', '%3$d %d %d', '12', '34', '56', "56 12 34\n");

sub RED   { R('RED') };
sub GREEN { G('GREEN') };
sub BLUE  { B('BLUE') };
test(qw(-f %2$s-%1$s -cR RED -cG GREEN),
     sprintf("%s-%s\n", G('GREEN'), RED));
test(qw(-f %3$s-%2$s-%1$s -cR RED -cG GREEN -cB BLUE),
     sprintf("%s-%s-%s\n", BLUE, GREEN, RED));
TODO: {
local $TODO = "ansi_fold removes trailing Erase Line code.";
test(qw(-f %3$.1s-%2$.1s-%1$.1s -cR RED -cG GREEN -cB BLUE),
     sprintf("%s-%s-%s\n", B('B'), G('G'), R('R')));
}

# reordered precision arguments
SKIP: {
    skip "reordered precision arguments was supported by v5.24", 7
	if $] < 5.024;
    test('-f', '%2$*3$d %d', '12', '34', '3',  " 34 12\n") ;
    test(qw(-f %*1$.*f 4 5 10), "5.0000 10\n") ;
    test(qw(-f %.*f        3 1.2345  ), "1.234\n");
    test(qw(-f %*3$.*f     3 1.2345 6), " 1.234\n");
    test(qw(-f %*2$.*3$f   1.2345 6 3), " 1.234\n");
    test(qw(-f %*3$.*2$f   1.2345 3 6), " 1.234\n");
    test(qw(-f %1$*3$.*2$f 1.2345 3 6), " 1.234\n");
}

# width parameter: *
test(qw(-f %*s 5 abc),         "  abc\n");
test(qw(-f %*.*s 5 5 abc),     "  abc\n");
test(qw(-f %*.*s 5 5 abcdefg), "abcde\n");

test(qw(-f %%%*s%% 5 abc),   "%  abc%\n");
test(qw(-f %0*d 5 123),      "00123\n");
test(qw(-f %-*d 5 123),      "123  \n");
test(qw(-f %-*d 5 -123),     "-123 \n");
test(qw(-f %0*.*d 5 5 123),  "00123\n");
test(qw(-f %-*.*d 5 5 123),  "00123\n");
test(qw(-f %-*.*d 5 5 -123), "-00123\n");

# recurtion
test(qw(-f %5s -c -f %s/%s W R abc),
   sprintf("  %s\n", WonR("abc")));
test(qw(-f %5s -c -f %s/%s -f %s W -f %s R abc),
   sprintf("  %s\n", WonR("abc")));

# recursion
test(qw(-f -f %%%ds 5 -c R abc),
   sprintf("  %s\n", R("abc")));

# -i, -a

test(qw(-i R RED -a ZE),
   R("RED")."\n");

test(qw(-i R RED -a ZE -i G GREEN -a ZE),
   sprintf("%s %s\n",
	   R("RED"),
	   G("GREEN")));

test(qw(-i R RED -i G GREEN -a ZE),
   sprintf("%s %s\n",
	   ansi_code("R")."RED",
	   G("GREEN")));

test(qw(-i R RED -i G GREEN -a ZE),
   sprintf("%s %s\n",
	   ansi_code("R")."RED",
	   G("GREEN")));

test(qw(-i R R -i U RU -i I RUI -i S RUIS -i F RUISF -a Z),
   join(' ',
	ansi_code("R")."R",
	ansi_code("U")."RU",
	ansi_code("I")."RUI",
	ansi_code("S")."RUIS",
	ansi_code("F")."RUISF".ansi_code("Z")."\n"));

# -C, -F, -E

test(qw(-C R a b c),
   join(' ', R('a'), R('b'), R('c'))."\n");

test(qw(-CR a b c),
   join(' ', R('a'), R('b'), R('c'))."\n");

test(qw(-C R a b -E c),
   join(' ', R('a'), R('b'), 'c')."\n");

test(qw(-F -%s- a b c),
   join(' ', '-a-', '-b-', '-c-')."\n");

test(qw(-F -%s- a b -E c),
   join(' ', '-a-', '-b-', 'c')."\n");

test(qw(-F -%%%s- a b c),
   join(' ', '-%a-', '-%b-', '-%c-')."\n");

test(qw(-CR -F -%s- a b c),
   join(' ', R('-a-'), R('-b-'), R('-c-'))."\n");

test(qw(-CR -F -%s- a b -E c),
   join(' ', R('-a-'), R('-b-'), 'c')."\n");

test(qw(-CR -F-%s- a b c),
   join(' ', R('-a-'), R('-b-'), R('-c-'))."\n");

test(qw(-F -%s- -CR a b c),
   join(' ', '-'.R('a').'-', '-'.R('b').'-', '-'.R('c').'-')."\n");

test(qw(-F [%s] -F -%s- -CR a b c),
   join(' ', '[-'.R('a').'-]', '[-'.R('b').'-]', '[-'.R('c').'-]')."\n");

# -S

test(qw(-S R),
   ansi_code('R')."\n");

test(qw(-S R R R),
   join(' ', ((ansi_code('R')) x 3)) . "\n");

test(qw(-S R R R -E H),
   join(' ', ((ansi_code('R')) x 3)) . " H\n");

test(qw(-j -S R R R -E H),
   join('', ((ansi_code('R')) x 3)) . "H\n");

done_testing;
