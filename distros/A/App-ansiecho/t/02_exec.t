use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Test::More;
use Data::Dumper;

use lib '.';
use t::Util;

use Getopt::EX::Colormap ':all';

is(ansiecho(qw(a b c))->{stdout}, "a b c\n", 'a b c');
is(ansiecho(qw(-n a b c))->{stdout}, "a b c", '-n a b c');
is(ansiecho(qw(-j a b c))->{stdout}, "abc\n", '-j a b c');
is(ansiecho(qw(-nj a b c))->{stdout}, "abc", '-nj a b c');
is(ansiecho(qw(--separate=: a b c))->{stdout}, "a:b:c\n", '--seprate=: a b c');

SKIP: {

my $smiley =
    sub { eval sprintf q("\\N{%s}"), $_[0] }->("WHITE SMILING FACE")
    or skip "Unicode charname is not supported.";

is(ansiecho('--no-escape', '\N{WHITE SMILING FACE}')->{stdout},
   '\N{WHITE SMILING FACE}'."\n",
   '\N{WHITE SMILING FACE}');

is(ansiecho('\N{WHITE SMILING FACE}')->{stdout},
   "$smiley\n",
   '-e \N{WHITE SMILING FACE}');

is(ansiecho('--escape', '\N{WHITE SMILING FACE}')->{stdout},
   "$smiley\n",
   '-e \N{WHITE SMILING FACE}');

}

for my $fg ('RGBCMYKW' =~ /./g) {
    no strict 'refs';
    *{$fg} = sub { colorize($fg, @_) };
    for my $bg ('RGBCMYKW' =~ /./g) {
	*{"${fg}on${bg}"} = sub { colorize("${fg}/${bg}", @_) };
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
is(ansiecho(qw(-c R RED))->{stdout}, R("RED")."\n", '-c R RED');
is(ansiecho(qw(-cR RED)) ->{stdout}, R("RED")."\n", '-cR RED');
is(ansiecho(qw(-cR -cG RED))->{stdout}, R(G("RED"))."\n", '-cR -cG RED');

# -n
is(ansiecho(qw(-n -c R RED))->{stdout}, R("RED"), '-n');

# -j
is(ansiecho(qw(-j -cR R -cG G -cB B))->{stdout},
   join("",R("R"),G("G"),B("B"))."\n",
   '-j -cR R -cG G -cB B');

# -f
is(ansiecho(qw(-f %s abc))      ->{stdout}, "abc\n", "-f %s abc");
is(ansiecho(qw(-f %%))          ->{stdout}, "%\n", "-f %%");
is(ansiecho(qw(-f %%%s%% abc))  ->{stdout}, "%abc%\n", "-f %%%s%% abc");
is(ansiecho(qw(-f %5s abc))     ->{stdout}, "  abc\n", "-f %5s abc");
is(ansiecho(qw(-f %5s -c R abc))->{stdout},
   sprintf("  %s\n", R("abc")),
   "-f %5s -c R abc");
is(ansiecho(qw(-f %-5s -c R abc))->{stdout},
   sprintf("%s  \n", R("abc")),
   "-f %-5s -c R abc");

is(ansiecho(qw(-f %d 123))       ->{stdout}, "123\n", "-f %d 123");
is(ansiecho(qw(-f %d -123))      ->{stdout}, "-123\n", "-f %d -123");
is(ansiecho(qw(-f %5d 123))      ->{stdout}, "  123\n", "-f %5d 123");
is(ansiecho(qw(-f %05d 123))     ->{stdout}, "00123\n", "-f %05d 123");
is(ansiecho(qw(-f %-5d 123))     ->{stdout}, "123  \n", "-f %-5d 123");
is(ansiecho(qw(-f %+5d  123))    ->{stdout}, " +123\n", "-f %+5d 123");
is(ansiecho(qw(-f %+5d -123))    ->{stdout}, " -123\n", "-f %+5d -123");
is(ansiecho('-f', '% 5d',  '123')->{stdout}, "  123\n", "-f '% 5d' 123");
is(ansiecho('-f', '% 5d', '-123')->{stdout}, " -123\n", "-f '% 5d' -123");
is(ansiecho('-f', '%o', '123')   ->{stdout},  "173\n", "-f %o 123");
is(ansiecho('-f', '%#o', '123')   ->{stdout}, "0173\n", "-f %#o 123");

# width parameter: *
is(ansiecho(qw(-f %*s 5 abc))->{stdout},
   "  abc\n", "-f %*s 5 abc");
is(ansiecho(qw(-f %*.*s 5 5 abc))->{stdout},
   "  abc\n", "-f %*.*s 5 5 abc");
is(ansiecho(qw(-f %*.*s 5 5 abcdefg))->{stdout},
   "abcde\n", "-f %*.*s 5 5 abcdefg");

is(ansiecho(qw(-f %%%*s%% 5 abc))->{stdout},
   "%  abc%\n", "-f %%%*s%% 5 abc");
is(ansiecho(qw(-f %0*d 5 123))->{stdout},
   "00123\n", "-f %0*d 5 123");
is(ansiecho(qw(-f %-*d 5 123))->{stdout},
   "123  \n", "-f %-*d 5 123");
is(ansiecho(qw(-f %-*d 5 -123))->{stdout},
   "-123 \n", "-f %-*d 5 -123");
is(ansiecho(qw(-f %0*.*d 5 5 123))->{stdout},
   "00123\n", "-f %0*.*d 5 5 123");
is(ansiecho(qw(-f %-*.*d 5 5 123))->{stdout},
   "00123\n", "-f %-*.*d 5 5 123");
is(ansiecho(qw(-f %-*.*d 5 5 -123))->{stdout},
   "-00123\n", "-f %-*.*d 5 5 -123");

# recurtion
is(ansiecho(qw(-f %5s -c -f %s/%s W R abc))->{stdout},
   sprintf("  %s\n", WonR("abc")),
   "-f %5s -c -f %s/%s W R abc");
is(ansiecho(qw(-f %5s -c -f %s/%s -f %s W -f %s R abc))->{stdout},
   sprintf("  %s\n", WonR("abc")),
   "-f %5s -c -f %s/%s -f %s W -f %s R abc");

# recursion
is(ansiecho(qw(-f -f %%%ds 5 -c R abc))->{stdout},
   sprintf("  %s\n", R("abc")), "-f -f %%%ds 5 -c R abc");

# -s, -z, -r
is(ansiecho(qw(-r 0 ))      ->{stdout}, "0\n", '-r 0');
is(ansiecho(qw(-r0 ))       ->{stdout}, "0\n", '-r0');
is(ansiecho(qw(-r -c ))     ->{stdout}, "-c\n", '-r -c');
is(ansiecho(qw(-r -c -r -f))->{stdout}, "-c-f\n", '-r -c -r -f');

is(ansiecho(qw(-s R RED -z ZE))->{stdout},
   R("RED")."\n",
   '-s R RED -z ZE');

is(ansiecho(qw(-s R RED -r \e[m\e[K))->{stdout},
   R("RED")."\n",
   '-s R RED -r \\e[m\\e[K');

is(ansiecho(qw(-s R RED -z ZE -s G GREEN -z ZE))->{stdout},
   sprintf("%s %s\n",
	   R("RED"),
	   G("GREEN"),
   ),
   '-s R RED -z ZE -s G GREEN -z ZE');

is(ansiecho(qw(-s R RED -s G GREEN -z ZE))->{stdout},
   sprintf("%s %s\n",
	   ansi_code("R")."RED",
	   G("GREEN"),
   ),
   '-s R RED -s G GREEN -z ZE');

is(ansiecho(qw(-s R RED -s G GREEN -z ZE))->{stdout},
   sprintf("%s %s\n",
	   ansi_code("R")."RED",
	   G("GREEN"),
   ),
   '-s R RED -s G GREEN -z ZE');

is(ansiecho(qw(-s R R -s U RU -s I RUI -s S RUIS -s F RUISF -z Z))->{stdout},
   join(' ',
	ansi_code("R")."R",
	ansi_code("U")."RU",
	ansi_code("I")."RUI",
	ansi_code("S")."RUIS",
	ansi_code("F")."RUISF".ansi_code("Z")."\n",
   ),
   '-s R R -s U RU -s I RUI -s S RUIS -s F RUISF -z Z');

# -C, -F, -E

is(ansiecho(qw(-C R a b c))->{stdout},
   join(' ', R('a'), R('b'), R('c'))."\n",
   '-C R a b c');

is(ansiecho(qw(-CR a b c))->{stdout},
   join(' ', R('a'), R('b'), R('c'))."\n",
   '-CR a b c');

is(ansiecho(qw(-C R a b -E c))->{stdout},
   join(' ', R('a'), R('b'), 'c')."\n",
   '-C R a b -E c');

is(ansiecho(qw(-F -%s- a b c))->{stdout},
   join(' ', '-a-', '-b-', '-c-')."\n",
   '-F -%s- a b c');

is(ansiecho(qw(-F -%s- a b -E c))->{stdout},
   join(' ', '-a-', '-b-', 'c')."\n",
   '-F -%s- a b c');

is(ansiecho(qw(-F -%%%s- a b c))->{stdout},
   join(' ', '-%a-', '-%b-', '-%c-')."\n",
   '-F -%%%s- a b c');

is(ansiecho(qw(-CR -F -%s- a b c))->{stdout},
   join(' ', R('-a-'), R('-b-'), R('-c-'))."\n",
   '-CR -F -%s- a b c');

is(ansiecho(qw(-CR -F -%s- a b -E c))->{stdout},
   join(' ', R('-a-'), R('-b-'), 'c')."\n",
   '-CR -F -%s- a b -E c');

is(ansiecho(qw(-CR -F-%s- a b c))->{stdout},
   join(' ', R('-a-'), R('-b-'), R('-c-'))."\n",
   '-CR -F-%s- a b c');

is(ansiecho(qw(-F -%s- -CR a b c))->{stdout},
   join(' ', '-'.R('a').'-', '-'.R('b').'-', '-'.R('c').'-')."\n",
   '-F -%s- -CR a b c');

is(ansiecho(qw(-F [%s] -F -%s- -CR a b c))->{stdout},
   join(' ', '[-'.R('a').'-]', '[-'.R('b').'-]', '[-'.R('c').'-]')."\n",
   '-F [%s] -F -%s- -CR a b c');

done_testing;
