#!/usr/bin/perl -w

use Test::More tests => 2;

use B qw(svref_2object);
BEGIN { use_ok 'B::Generate'; }

CHECK {
    my ($x,$prev,$new);

    # Add new scope around op "add $a + $b"
    for ($x = B::main_start; $x->type != B::opnumber("add"); $x=$x->next){ # Find "add"
        $prev = $x;  # op before "add"
    };

    $new = $x->scope;     # Create new scope op
    $new->next($x);       # Link scope->next to add
    $prev->next($new);    # Link prev padsv => scope
    #$new->targ($x->targ);
}

# ori
# $ pb -MO=Concise,-exec t/scope.t
# 1  <0> enter
# 2  <;> nextstate(main 1293 scope.t:22) v:{
# 3  <0> padsv[$b:1293,1295] vM/LVINTRO
# 4  <;> nextstate(main 1294 scope.t:23) v:{
# 5  <$> const(IV 17) s
# 6  <$> gvsv(*a) s
# 7  <2> sassign vKS/2
# 8  <;> nextstate(main 1294 scope.t:24) v:{
# 9  <$> const(IV 15) s
# a  <0> padsv[$b:1293,1295] sRM*
# b  <2> sassign vKS/2
# c  <;> nextstate(main 1294 scope.t:26) v:{
# d  <$> gvsv(*a) s
# e  <0> padsv[$b:1293,1295] s

# f  <2> add[t3] sK/2

# g  <0> padsv[$sum:1294,1295] sRM*/LVINTRO
# h  <2> sassign vKS/2
# i  <;> nextstate(main 1295 scope.t:27) v:{
# j  <0> pushmark s
# k  <0> padsv[$sum:1294,1295] s
# l  <$> const(IV 32) s
# m  <2> eq sKM/2
# n  <$> const(PV "scope") sM
# o  <$> gv(*ok) s
# p  <1> entersub[t4] vKS/TARG,1
# q  <@> leave[1 ref] vKP/REFC

# =>
#
# 1  <0> enter
# 2  <;> nextstate(main 1310 scope.t:56) v:{
# 3  <0> padsv[$b:1310,1312] vM/LVINTRO
# 4  <;> nextstate(main 1311 scope.t:57) v:{
# 5  <$> const(IV 17) s
# 6  <$> gvsv(*a) s
# 7  <2> sassign vKS/2
# 8  <;> nextstate(main 1311 scope.t:58) v:{
# 9  <$> const(IV 15) s
# a  <0> padsv[$b:1310,1312] sRM*
# b  <2> sassign vKS/2
# c  <;> nextstate(main 1311 scope.t:61) v:{
# d  <$> gvsv(*a) s
# e  <0> padsv[$b:1310,1312] s

# -  <@> scope K
# f  <2> add[t3] sK/2

# g  <0> padsv[$sum:1311,1312] sRM*/LVINTRO
# h  <2> sassign vKS/2
# i  <;> nextstate(main 1312 scope.t:63) v:{
# j  <0> pushmark s
# k  <0> padsv[$sum:1311,1312] s
# l  <$> const(IV 32) s
# m  <2> eq sKM/2
# n  <$> const(PV "scope") sM
# o  <$> gv(*ok) s
# p  <1> entersub[t4] vKS/TARG,1
# q  <@> leave[1 ref] vKP/REFC

my $b; 	 # lex
$a = 17; # global
$b = 15;

# scope this op as my $sum = { $a + $b }
my $sum = $a + $b;

ok $sum == 32, "scope";

