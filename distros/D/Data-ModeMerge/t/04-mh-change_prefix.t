#!perl

use strict;
use warnings;
use Test::More tests => 5;

use lib './t';
do 'testlib.pm';

# just making sure that we indeed *CAN* use suffix, infix, or whatever
# instead of just prefix

use Data::ModeMerge;
my $mm = Data::ModeMerge->new;
my ($mha, $mhc);
for ($mm->modes->{ADD}) {
    $mha = $_;
    $_->prefix_re(qr/-ADD$/);
    $_->add_prefix_sub(sub {$_[0]."-ADD"});
    $_->remove_prefix_sub(sub {$_[0] =~ s/-ADD$//; $_[0]});
}
for ($mm->modes->{CONCAT}) {
    $mhc = $_;
    $_->prefix_re(qr/-CONCAT$/);
    $_->add_prefix_sub(sub {$_[0]."-CONCAT"});
    $_->remove_prefix_sub(sub {$_[0] =~ s/-CONCAT$//; $_[0]});
}
is($mha->add_prefix("a"), "a-ADD", "add 1");
is($mhc->add_prefix("a"), "a-CONCAT", "concat 1");
merge_is({a=>1, c=>1}, {"a-ADD"=>2, "c-CONCAT"=>2, "+a"=>20, ".c"=>20}, {a=>3, c=>12, "+a"=>20, ".c"=>20}, "merge 1", $mm);
merge_is({}, {"a-ADD"=>2, "c-CONCAT"=>2}, {"a-ADD"=>2, "c-CONCAT"=>2}, "merge 2", $mm);
merge_is({a=>1,       h=>{a=>10,        ""=>{set_prefix=>{ADD=>"plus-"}}}},
         {"a-ADD"=>2, h=>{"plus-a"=>20}},
         {a=>3, h=>{a=>30}}, "merge+ok 1", $mm);
