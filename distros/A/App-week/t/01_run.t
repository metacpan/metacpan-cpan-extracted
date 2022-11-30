use v5.14;
use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use Data::Dumper;

use lib '.';
use t::Util;
$Script::lib    = File::Spec->rel2abs('lib');
$Script::script = File::Spec->rel2abs('script/week');

my %result = (

'175209' => <<END,
                          \
        September         \
   Su Mo Tu We Th Fr Sa   \
          1  2 14 15 16   \
   17 18 19 20 21 22 23   \
   24 25 26 27 28 29 30   \
                          \
                          \
                          \
                          \
END

'175209_re' => qr{(?x:\A
)                          $
(?x: \s+ Sep(tember)? \s+ )$
(?x:
(?-x:   Su Mo Tu We Th Fr Sa   ) |
(?-x:    S  M Tu  W Th  F  S   ) )$
          1  2 14 15 16   $
   17 18 19 20 21 22 23   $
   24 25 26 27 28 29 30   $
                          $
                          $
                          $
                          $
\z}m,

'175209W_re' => qr{(?x:\A
)                             $
(?x: \s+ Sep(tember)? \s+ )   $
(?x:
(?-x:   Su Mo Tu We Th Fr Sa CW   ) |
(?-x:    S  M Tu  W Th  F  S CW   ) )$
          1  2 14 15 16 36   $
   17 18 19 20 21 22 23 37   $
   24 25 26 27 28 29 30 38   $
                             $
                             $
                             $
                             $
\z}m,

);

sub compare {
    my($result, $compare, $comment) = @_;
    if (ref $compare eq 'Regexp'){
	like $result, $compare, $comment;
    } else {
	is   $result, $compare, $comment;
    }
}

SKIP: {
    local %ENV = %ENV;
    $ENV{LANG} = $ENV{LC_ALL} = 'C';

    local $_ = `cal`;
    if ($? != 0) {
	skip "cal command execution error.", 1;
    } else {
	s/((?=.)[\000-\037])/sprintf("^%c", ord($1)+0100)/ge;
	warn $_;
	$_ = `cal 1752`;
	s/((?=.)[\000-\037])/sprintf("^%c", ord($1)+0100)/ge;
	warn $_;
    }

    my @default = qw(--cm *= -C0p0 1752/9/2);

    my $week = Script->new([ @default ])->run;
    compare $week->result, $result{"175209_re"}, "1752/9/2";

    my $netbsd =
	Script->new([qw(--config netbsd=1), @default ])->run;
    compare $netbsd->result, $result{"175209_re"}, "netbsd emulation";

    my $crashspace =
	Script->new([qw(--config crashspace=1), @default])->run;
    compare $crashspace->result, $result{"175209_re"}, "crashspace emulation";

    my $tabify =
	Script->new([qw(--config tabify=1), @default])->run;
    compare $tabify->result, $result{"175209_re"}, "solaris tabify emulation";

    my $sm =
    	Script->new([qw(--config shortmonth=1), @default])->run;
    compare $sm->result, $result{"175209_re"}, "solaris short month emulation";

    my $sm =
    	Script->new([qw(--weeknumber), @default])->run;
    compare $sm->result, $result{"175209W_re"}, "--weeknumber";
}

done_testing;
