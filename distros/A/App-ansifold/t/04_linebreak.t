use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Data::Dumper;
use Test::More;

use lib '.';
use t::Util;

sub folded {
    my @option = @_;
    my $fold = ansifold(@option, "t/04_linebreak.txt");
    $fold->run->{stdout} =~ s/\n$//r;
}

my @option;

@option = qw (--boundary=space --linebreak=all --runin=2 --runout=2);
is(folded("-w15," , @option), "「吾輩は猫で あ",             "normal");
is(folded("-w17," , @option), "「吾輩は猫で ある。",         "run-in(2)");
is(folded("-w19," , @option), "「吾輩は猫で ある。」",       "run-in(2)");
is(folded("-w21," , @option), "「吾輩は猫で ある。」",       "normal");
is(folded("-w23," , @option), "「吾輩は猫で ある。」",       "run-out(2)");
is(folded("-w25," , @option), "「吾輩は猫で ある。」「（",   "normal");
is(folded("-w27," , @option), "「吾輩は猫で ある。」「（名", "normal");

@option = qw (--boundary=space --linebreak=all --runin=4 --runout=4);
is(folded("-w15," , @option), "「吾輩は猫で あ",             "[4]normal");
is(folded("-w17," , @option), "「吾輩は猫で ある。」",       "[4]run-in(4)");
is(folded("-w19," , @option), "「吾輩は猫で ある。」",       "[4]nun-in(2)");
is(folded("-w21," , @option), "「吾輩は猫で ある。」",       "[4]normal");
is(folded("-w23," , @option), "「吾輩は猫で ある。」",       "[4]run-out(2)");
is(folded("-w25," , @option), "「吾輩は猫で ある。」",       "[4]run-out(4)");
is(folded("-w27," , @option), "「吾輩は猫で ある。」「（名", "[4]normal");

done_testing;
