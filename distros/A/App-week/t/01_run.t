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
        September         $
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
    }

    my $week = Script->new([qw(--cm *= -C0 1752/9/2)])->run;
    compare $week->result, $result{"175209_re"}, "1752/9/2";
}

done_testing;
