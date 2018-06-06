# Just the pp_subst operators
1;
__DATA__
####
# s///e
s/x/'y'/e;
s/x/$a/e;
s/x/complex_expression()/e;
####
# all the flags (s///)
s/X//m;
s/X//s;
s/X//i;
s/X//x;
s/X//p;
s/X//o;
s/X//u;
s/X//a;
s/X//l;
s/X//g;
s/X/''/e;
s/X//r;
####
# subst n modifier
# SKIP ?$] < 5.024 && "n modifier not in this Perl version"
s/X//n;
