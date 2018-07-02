use warnings;
no warnings "syntax";
no warnings "void";
use strict;

BEGIN {
	if("$]" < 5.013008) {
		require Test::More;
		Test::More::plan(skip_all =>
			"parse_*expr not available on this Perl");
	}
}

use Test::More tests => 3 + 12*4*5 + 7*5;
use t::LoadXS ();
use t::WriteHeader ();

t::WriteHeader::write_header("callparser1", "t", "stdargs");
ok 1;
require_ok "Devel::CallParser";
t::LoadXS::load_xs("stdargs", "t", [Devel::CallParser::callparser_linkable()]);
ok 1;

my @three = qw(a b c);
my @five = qw(a b c d e);

sub par_() { [@_] }
sub par_s($) { [@_] }
sub par_ss($$) { [@_] }
sub par_l(@) { [@_] }
t::stdargs::cv_set_call_parser_parenthesised(\&par_);
t::stdargs::cv_set_call_parser_parenthesised(\&par_s);
t::stdargs::cv_set_call_parser_parenthesised(\&par_ss);
t::stdargs::cv_set_call_parser_parenthesised(\&par_l);

is_deeply scalar(eval(q{par_()})), [];
is_deeply scalar(eval(q{par_(1)})), undef;
is_deeply scalar(eval(q{par_(@three)})), undef;
is_deeply scalar(eval(q{par_(@three, @five)})), undef;
is_deeply scalar(eval(q{par_((9,8,7))})), undef;
is_deeply scalar(eval(q{par_((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{par_})), undef;
is_deeply scalar(eval(q{par_ 1})), undef;
is_deeply scalar(eval(q{[ par_ 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ par_ @three, @five ]})), undef;
is_deeply scalar(eval(q{[ par_ +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ par_ +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{par_s()})), undef;
is_deeply scalar(eval(q{par_s(1)})), [1];
is_deeply scalar(eval(q{par_s(@three)})), [3];
is_deeply scalar(eval(q{par_s(@three, @five)})), undef;
is_deeply scalar(eval(q{par_s((9,8,7))})), [7];
is_deeply scalar(eval(q{par_s((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{par_s})), undef;
is_deeply scalar(eval(q{par_s 1})), undef;
is_deeply scalar(eval(q{[ par_s 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ par_s @three, @five ]})), undef;
is_deeply scalar(eval(q{[ par_s +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ par_s +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{par_ss()})), undef;
is_deeply scalar(eval(q{par_ss(1)})), undef;
is_deeply scalar(eval(q{par_ss(@three)})), undef;
is_deeply scalar(eval(q{par_ss(@three, @five)})), [3,5];
is_deeply scalar(eval(q{par_ss((9,8,7))})), undef;
is_deeply scalar(eval(q{par_ss((9,8,7), (6,5,4))})), [7,4];
is_deeply scalar(eval(q{par_ss})), undef;
is_deeply scalar(eval(q{par_ss 1})), undef;
is_deeply scalar(eval(q{[ par_ss 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ par_ss @three, @five ]})), undef;
is_deeply scalar(eval(q{[ par_ss +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ par_ss +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{par_l()})), [];
is_deeply scalar(eval(q{par_l(1)})), [1];
is_deeply scalar(eval(q{par_l(@three)})), [qw(a b c)];
is_deeply scalar(eval(q{par_l(@three, @five)})), [qw(a b c a b c d e)];
is_deeply scalar(eval(q{par_l((9,8,7))})), [9,8,7];
is_deeply scalar(eval(q{par_l((9,8,7), (6,5,4))})), [9,8,7,6,5,4];
is_deeply scalar(eval(q{par_l})), undef;
is_deeply scalar(eval(q{par_l 1})), undef;
is_deeply scalar(eval(q{[ par_l 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ par_l @three, @five ]})), undef;
is_deeply scalar(eval(q{[ par_l +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ par_l +(9,8,7), (6,5,4) ]})), undef;

sub nul_() { [@_] }
sub nul_s($) { [@_] }
sub nul_ss($$) { [@_] }
sub nul_l(@) { [@_] }
t::stdargs::cv_set_call_parser_nullary(\&nul_);
t::stdargs::cv_set_call_parser_nullary(\&nul_s);
t::stdargs::cv_set_call_parser_nullary(\&nul_ss);
t::stdargs::cv_set_call_parser_nullary(\&nul_l);

is_deeply scalar(eval(q{nul_()})), [];
is_deeply scalar(eval(q{nul_(1)})), undef;
is_deeply scalar(eval(q{nul_(@three)})), undef;
is_deeply scalar(eval(q{nul_(@three, @five)})), undef;
is_deeply scalar(eval(q{nul_((9,8,7))})), undef;
is_deeply scalar(eval(q{nul_((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{nul_})), [];
is_deeply scalar(eval(q{nul_ 1})), undef;
is_deeply scalar(eval(q{[ nul_ 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ nul_ @three, @five ]})), undef;
is_deeply scalar(eval(q{[ nul_ !(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ nul_ !(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{nul_s()})), undef;
is_deeply scalar(eval(q{nul_s(1)})), [1];
is_deeply scalar(eval(q{nul_s(@three)})), [3];
is_deeply scalar(eval(q{nul_s(@three, @five)})), undef;
is_deeply scalar(eval(q{nul_s((9,8,7))})), [7];
is_deeply scalar(eval(q{nul_s((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{nul_s})), undef;
is_deeply scalar(eval(q{nul_s 1})), undef;
is_deeply scalar(eval(q{[ nul_s 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ nul_s @three, @five ]})), undef;
is_deeply scalar(eval(q{[ nul_s !(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ nul_s !(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{nul_ss()})), undef;
is_deeply scalar(eval(q{nul_ss(1)})), undef;
is_deeply scalar(eval(q{nul_ss(@three)})), undef;
is_deeply scalar(eval(q{nul_ss(@three, @five)})), [3,5];
is_deeply scalar(eval(q{nul_ss((9,8,7))})), undef;
is_deeply scalar(eval(q{nul_ss((9,8,7), (6,5,4))})), [7,4];
is_deeply scalar(eval(q{nul_ss})), undef;
is_deeply scalar(eval(q{nul_ss 1})), undef;
is_deeply scalar(eval(q{[ nul_ss 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ nul_ss @three, @five ]})), undef;
is_deeply scalar(eval(q{[ nul_ss !(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ nul_ss !(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{nul_l()})), [];
is_deeply scalar(eval(q{nul_l(1)})), [1];
is_deeply scalar(eval(q{nul_l(@three)})), [qw(a b c)];
is_deeply scalar(eval(q{nul_l(@three, @five)})), [qw(a b c a b c d e)];
is_deeply scalar(eval(q{nul_l((9,8,7))})), [9,8,7];
is_deeply scalar(eval(q{nul_l((9,8,7), (6,5,4))})), [9,8,7,6,5,4];
is_deeply scalar(eval(q{nul_l})), [];
is_deeply scalar(eval(q{nul_l 1})), undef;
is_deeply scalar(eval(q{[ nul_l 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ nul_l @three, @five ]})), undef;
is_deeply scalar(eval(q{[ nul_l !(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ nul_l !(9,8,7), (6,5,4) ]})), undef;

sub una_() { [@_] }
sub una_s($) { [@_] }
sub una_ss($$) { [@_] }
sub una_l(@) { [@_] }
t::stdargs::cv_set_call_parser_unary(\&una_);
t::stdargs::cv_set_call_parser_unary(\&una_s);
t::stdargs::cv_set_call_parser_unary(\&una_ss);
t::stdargs::cv_set_call_parser_unary(\&una_l);

is_deeply scalar(eval(q{una_()})), [];
is_deeply scalar(eval(q{una_(1)})), undef;
is_deeply scalar(eval(q{una_(@three)})), undef;
is_deeply scalar(eval(q{una_(@three, @five)})), undef;
is_deeply scalar(eval(q{una_((9,8,7))})), undef;
is_deeply scalar(eval(q{una_((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{una_})), [];
is_deeply scalar(eval(q{una_ 1})), undef;
is_deeply scalar(eval(q{[ una_ 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ una_ @three, @five ]})), undef;
is_deeply scalar(eval(q{[ una_ +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ una_ +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{una_s()})), undef;
is_deeply scalar(eval(q{una_s(1)})), [1];
is_deeply scalar(eval(q{una_s(@three)})), [3];
is_deeply scalar(eval(q{una_s(@three, @five)})), undef;
is_deeply scalar(eval(q{una_s((9,8,7))})), [7];
is_deeply scalar(eval(q{una_s((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{una_s})), undef;
is_deeply scalar(eval(q{una_s 1})), [1];
is_deeply scalar(eval(q{[ una_s 1, 2 ]})), [[1],2];
is_deeply scalar(eval(q{[ una_s @three, @five ]})), [[3],qw(a b c d e)];
is_deeply scalar(eval(q{[ una_s +(9,8,7) ]})), [[7]];
is_deeply scalar(eval(q{[ una_s +(9,8,7), (6,5,4) ]})), [[7],6,5,4];

is_deeply scalar(eval(q{una_ss()})), undef;
is_deeply scalar(eval(q{una_ss(1)})), undef;
is_deeply scalar(eval(q{una_ss(@three)})), undef;
is_deeply scalar(eval(q{una_ss(@three, @five)})), [3,5];
is_deeply scalar(eval(q{una_ss((9,8,7))})), undef;
is_deeply scalar(eval(q{una_ss((9,8,7), (6,5,4))})), [7,4];
is_deeply scalar(eval(q{una_ss})), undef;
is_deeply scalar(eval(q{una_ss 1})), undef;
is_deeply scalar(eval(q{[ una_ss 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ una_ss @three, @five ]})), undef;
is_deeply scalar(eval(q{[ una_ss +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ una_ss +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{una_l()})), [];
is_deeply scalar(eval(q{una_l(1)})), [1];
is_deeply scalar(eval(q{una_l(@three)})), [qw(a b c)];
is_deeply scalar(eval(q{una_l(@three, @five)})), [qw(a b c a b c d e)];
is_deeply scalar(eval(q{una_l((9,8,7))})), [9,8,7];
is_deeply scalar(eval(q{una_l((9,8,7), (6,5,4))})), [9,8,7,6,5,4];
is_deeply scalar(eval(q{una_l})), [];
is_deeply scalar(eval(q{una_l 1})), [1];
is_deeply scalar(eval(q{[ una_l 1, 2 ]})), [[1],2];
is_deeply scalar(eval(q{[ una_l @three, @five ]})), [[qw(a b c)],qw(a b c d e)];
is_deeply scalar(eval(q{[ una_l +(9,8,7) ]})), [[9,8,7]];
is_deeply scalar(eval(q{[ una_l +(9,8,7), (6,5,4) ]})), [[9,8,7],6,5,4];

sub lis_() { [@_] }
sub lis_s($) { [@_] }
sub lis_ss($$) { [@_] }
sub lis_l(@) { [@_] }
t::stdargs::cv_set_call_parser_list(\&lis_);
t::stdargs::cv_set_call_parser_list(\&lis_s);
t::stdargs::cv_set_call_parser_list(\&lis_ss);
t::stdargs::cv_set_call_parser_list(\&lis_l);

is_deeply scalar(eval(q{lis_()})), [];
is_deeply scalar(eval(q{lis_(1)})), undef;
is_deeply scalar(eval(q{lis_(@three)})), undef;
is_deeply scalar(eval(q{lis_(@three, @five)})), undef;
is_deeply scalar(eval(q{lis_((9,8,7))})), undef;
is_deeply scalar(eval(q{lis_((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{lis_})), [];
is_deeply scalar(eval(q{lis_ 1})), undef;
is_deeply scalar(eval(q{[ lis_ 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ lis_ @three, @five ]})), undef;
is_deeply scalar(eval(q{[ lis_ +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ lis_ +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{lis_s()})), undef;
is_deeply scalar(eval(q{lis_s(1)})), [1];
is_deeply scalar(eval(q{lis_s(@three)})), [3];
is_deeply scalar(eval(q{lis_s(@three, @five)})), undef;
is_deeply scalar(eval(q{lis_s((9,8,7))})), [7];
is_deeply scalar(eval(q{lis_s((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{lis_s})), undef;
is_deeply scalar(eval(q{lis_s 1})), [1];
is_deeply scalar(eval(q{[ lis_s 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ lis_s @three, @five ]})), undef;
is_deeply scalar(eval(q{[ lis_s +(9,8,7) ]})), [[7]];
is_deeply scalar(eval(q{[ lis_s +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{lis_ss()})), undef;
is_deeply scalar(eval(q{lis_ss(1)})), undef;
is_deeply scalar(eval(q{lis_ss(@three)})), undef;
is_deeply scalar(eval(q{lis_ss(@three, @five)})), [3,5];
is_deeply scalar(eval(q{lis_ss((9,8,7))})), undef;
is_deeply scalar(eval(q{lis_ss((9,8,7), (6,5,4))})), [7,4];
is_deeply scalar(eval(q{lis_ss})), undef;
is_deeply scalar(eval(q{lis_ss 1})), undef;
is_deeply scalar(eval(q{[ lis_ss 1, 2 ]})), [[1,2]];
is_deeply scalar(eval(q{[ lis_ss @three, @five ]})), [[3,5]];
is_deeply scalar(eval(q{[ lis_ss +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ lis_ss +(9,8,7), (6,5,4) ]})), [[7,4]];

is_deeply scalar(eval(q{lis_l()})), [];
is_deeply scalar(eval(q{lis_l(1)})), [1];
is_deeply scalar(eval(q{lis_l(@three)})), [qw(a b c)];
is_deeply scalar(eval(q{lis_l(@three, @five)})), [qw(a b c a b c d e)];
is_deeply scalar(eval(q{lis_l((9,8,7))})), [9,8,7];
is_deeply scalar(eval(q{lis_l((9,8,7), (6,5,4))})), [9,8,7,6,5,4];
is_deeply scalar(eval(q{lis_l})), [];
is_deeply scalar(eval(q{lis_l 1})), [1];
is_deeply scalar(eval(q{[ lis_l 1, 2 ]})), [[1,2]];
is_deeply scalar(eval(q{[ lis_l @three, @five ]})), [[qw(a b c),qw(a b c d e)]];
is_deeply scalar(eval(q{[ lis_l +(9,8,7) ]})), [[9,8,7]];
is_deeply scalar(eval(q{[ lis_l +(9,8,7), (6,5,4) ]})), [[9,8,7,6,5,4]];

sub blo_() { [@_] }
sub blo_s($) { [@_] }
sub blo_ss($$) { [@_] }
sub blo_l(@) { [@_] }
t::stdargs::cv_set_call_parser_block_list(\&blo_);
t::stdargs::cv_set_call_parser_block_list(\&blo_s);
t::stdargs::cv_set_call_parser_block_list(\&blo_ss);
t::stdargs::cv_set_call_parser_block_list(\&blo_l);

is_deeply scalar(eval(q{blo_()})), [];
is_deeply scalar(eval(q{blo_(1)})), undef;
is_deeply scalar(eval(q{blo_(@three)})), undef;
is_deeply scalar(eval(q{blo_(@three, @five)})), undef;
is_deeply scalar(eval(q{blo_((9,8,7))})), undef;
is_deeply scalar(eval(q{blo_((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{blo_})), [];
is_deeply scalar(eval(q{blo_ 1})), undef;
is_deeply scalar(eval(q{[ blo_ 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ blo_ @three, @five ]})), undef;
is_deeply scalar(eval(q{[ blo_ +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ blo_ +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{blo_s()})), undef;
is_deeply scalar(eval(q{blo_s(1)})), [1];
is_deeply scalar(eval(q{blo_s(@three)})), [3];
is_deeply scalar(eval(q{blo_s(@three, @five)})), undef;
is_deeply scalar(eval(q{blo_s((9,8,7))})), [7];
is_deeply scalar(eval(q{blo_s((9,8,7), (6,5,4))})), undef;
is_deeply scalar(eval(q{blo_s})), undef;
is_deeply scalar(eval(q{blo_s 1})), [1];
is_deeply scalar(eval(q{[ blo_s 1, 2 ]})), undef;
is_deeply scalar(eval(q{[ blo_s @three, @five ]})), undef;
is_deeply scalar(eval(q{[ blo_s +(9,8,7) ]})), [[7]];
is_deeply scalar(eval(q{[ blo_s +(9,8,7), (6,5,4) ]})), undef;

is_deeply scalar(eval(q{blo_ss()})), undef;
is_deeply scalar(eval(q{blo_ss(1)})), undef;
is_deeply scalar(eval(q{blo_ss(@three)})), undef;
is_deeply scalar(eval(q{blo_ss(@three, @five)})), [3,5];
is_deeply scalar(eval(q{blo_ss((9,8,7))})), undef;
is_deeply scalar(eval(q{blo_ss((9,8,7), (6,5,4))})), [7,4];
is_deeply scalar(eval(q{blo_ss})), undef;
is_deeply scalar(eval(q{blo_ss 1})), undef;
is_deeply scalar(eval(q{[ blo_ss 1, 2 ]})), [[1,2]];
is_deeply scalar(eval(q{[ blo_ss @three, @five ]})), [[3,5]];
is_deeply scalar(eval(q{[ blo_ss +(9,8,7) ]})), undef;
is_deeply scalar(eval(q{[ blo_ss +(9,8,7), (6,5,4) ]})), [[7,4]];

is_deeply scalar(eval(q{blo_l()})), [];
is_deeply scalar(eval(q{blo_l(1)})), [1];
is_deeply scalar(eval(q{blo_l(@three)})), [qw(a b c)];
is_deeply scalar(eval(q{blo_l(@three, @five)})), [qw(a b c a b c d e)];
is_deeply scalar(eval(q{blo_l((9,8,7))})), [9,8,7];
is_deeply scalar(eval(q{blo_l((9,8,7), (6,5,4))})), [9,8,7,6,5,4];
is_deeply scalar(eval(q{blo_l})), [];
is_deeply scalar(eval(q{blo_l 1})), [1];
is_deeply scalar(eval(q{[ blo_l 1, 2 ]})), [[1,2]];
is_deeply scalar(eval(q{[ blo_l @three, @five ]})), [[qw(a b c),qw(a b c d e)]];
is_deeply scalar(eval(q{[ blo_l +(9,8,7) ]})), [[9,8,7]];
is_deeply scalar(eval(q{[ blo_l +(9,8,7), (6,5,4) ]})), [[9,8,7,6,5,4]];

sub par_r { [ map { ref } @_ ] }
sub nul_r { [ map { ref } @_ ] }
sub una_r { [ map { ref } @_ ] }
sub lis_r { [ map { ref } @_ ] }
sub blo_r { [ map { ref } @_ ] }
t::stdargs::cv_set_call_parser_parenthesised(\&par_r);
t::stdargs::cv_set_call_parser_nullary(\&nul_r);
t::stdargs::cv_set_call_parser_unary(\&una_r);
t::stdargs::cv_set_call_parser_list(\&lis_r);
t::stdargs::cv_set_call_parser_block_list(\&blo_r);

is_deeply scalar(eval(q{par_r({})})), ["HASH"];
is_deeply scalar(eval(q{par_r(sub{})})), ["CODE"];
is_deeply scalar(eval(q{par_r {}})), undef;
is_deeply scalar(eval(q{par_r {} 1})), undef;
is_deeply scalar(eval(q{par_r {} 1, 2})), undef;
is_deeply scalar(eval(q{[ par_r {}, 1 ]})), undef;
is_deeply scalar(eval(q{[ par_r {}, 1, 2 ]})), undef;

is_deeply scalar(eval(q{nul_r({})})), ["HASH"];
is_deeply scalar(eval(q{nul_r(sub{})})), ["CODE"];
is_deeply scalar(eval(q{nul_r {}})), undef;
is_deeply scalar(eval(q{nul_r {} 1})), undef;
is_deeply scalar(eval(q{nul_r {} 1, 2})), undef;
is_deeply scalar(eval(q{[ nul_r {}, 1 ]})), undef;
is_deeply scalar(eval(q{[ nul_r {}, 1, 2 ]})), undef;

is_deeply scalar(eval(q{una_r({})})), ["HASH"];
is_deeply scalar(eval(q{una_r(sub{})})), ["CODE"];
is_deeply scalar(eval(q{una_r {}})), ["HASH"];
is_deeply scalar(eval(q{una_r {} 1})), undef;
is_deeply scalar(eval(q{una_r {} 1, 2})), undef;
is_deeply scalar(eval(q{[ una_r {}, 1 ]})), [["HASH"],1];
is_deeply scalar(eval(q{[ una_r {}, 1, 2 ]})), [["HASH"],1,2];

is_deeply scalar(eval(q{lis_r({})})), ["HASH"];
is_deeply scalar(eval(q{lis_r(sub{})})), ["CODE"];
is_deeply scalar(eval(q{lis_r {}})), ["HASH"];
is_deeply scalar(eval(q{lis_r {} 1})), undef;
is_deeply scalar(eval(q{lis_r {} 1, 2})), undef;
is_deeply scalar(eval(q{[ lis_r {}, 1 ]})), [["HASH",""]];
is_deeply scalar(eval(q{[ lis_r {}, 1, 2 ]})), [["HASH","",""]];

is_deeply scalar(eval(q{blo_r({})})), ["HASH"];
is_deeply scalar(eval(q{blo_r(sub{})})), ["CODE"];
is_deeply scalar(eval(q{blo_r {}})), ["CODE"];
is_deeply scalar(eval(q{blo_r {} 1})), ["CODE",""];
is_deeply scalar(eval(q{blo_r {} 1, 2})), ["CODE","",""];
is_deeply scalar(eval(q{[ blo_r {}, 1 ]})), undef;
is_deeply scalar(eval(q{[ blo_r {}, 1, 2 ]})), undef;

1;
