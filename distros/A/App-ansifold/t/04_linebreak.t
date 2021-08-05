use v5.14;
use warnings;

use Data::Dumper;
use Test::More;

use lib '.';
use t::Util;

use List::Util qw(pairmap);

sub folded {
    my %opt = @_;
    my @option = pairmap { "--$a" => $b } @_;
    my $fold = ansifold(@option, "t/04_linebreak.txt");
    $fold->{stdout} =~ s/\n.*//sr;
}

my @option;

@option = (linebreak => 'all', runin => 2, runout => 2);
is(folded(width => 14, @option), "「吾輩は猫であ",             "normal");
is(folded(width => 16, @option), "「吾輩は猫である。",         "run-in(2)");
is(folded(width => 18, @option), "「吾輩は猫である。」",       "run-in(2)");
is(folded(width => 20, @option), "「吾輩は猫である。」",       "normal");
is(folded(width => 22, @option), "「吾輩は猫である。」",       "run-out(2)");
is(folded(width => 24, @option), "「吾輩は猫である。」「（",   "normal");
is(folded(width => 26, @option), "「吾輩は猫である。」「（名", "normal");

@option = (linebreak => 'all', runin => 4, runout => 4);
is(folded(width => 14, @option), "「吾輩は猫であ",             "[4]normal");
is(folded(width => 16, @option), "「吾輩は猫である。」",       "[4]run-in(4)");
is(folded(width => 18, @option), "「吾輩は猫である。」",       "[4]nun-in(2)");
is(folded(width => 20, @option), "「吾輩は猫である。」",       "[4]normal");
is(folded(width => 22, @option), "「吾輩は猫である。」",       "[4]run-out(2)");
is(folded(width => 24, @option), "「吾輩は猫である。」",       "[4]run-out(4)");
is(folded(width => 26, @option), "「吾輩は猫である。」「（名", "[4]normal");

done_testing;
