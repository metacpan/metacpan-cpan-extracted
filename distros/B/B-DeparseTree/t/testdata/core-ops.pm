# Adapted from Perl 5.26's lib/B/Deparse-core.t
1;
__DATA__
#
# format:
#   keyword args flags
#   keyword args flags  # comment
#   keyword args flags  5.022 (min perl version)
#
# args consists of:
#  * one of more digits indictating which lengths of args the function accepts,
#  * or 'B' to indiate a binary infix operator,
#  * or '@' to indicate a list function.
#
# Flags consists of the following (or '-' if no flags):
#    + : strong keyword: can't be overrriden
#    p : the args are parenthesised on deparsing;
#    1 : parenthesising of 1st arg length is inverted
#        so '234 p1' means: foo a1,a2;  foo(a1,a2,a3); foo(a1,a2,a3,a4)
#    $ : on the first argument length, there is an implicit extra
#        '$_' arg which will appear on deparsing;
#        e.g. 12p$  will be tested as: foo(a1);     foo(a1,a2);
#                     and deparsed as: foo(a1, $_); foo(a1,a2);
#
# XXX Note that we really should get this data from regen/keywords.pl
# and regen/opcodes (augmented if necessary), rather than duplicating it
# here.

__SUB__          0     -
and              B     -
cmp              B     -
# dbmopen  handled specially
# dbmclose handled specially
# delete handled specially
# do handled specially
# dump handled specially
# each handled specially
endservent       0     -
eq               B     -
eval             01    $+
evalbytes        01    $
# exists handled specially
exp              01    $
ge               B     -
# given handled specially
# glob handled specially
# goto handled specially
gt               B     -
# keys handled specially
# last handled specially
lc               01    $
lcfirst          01    $
le               B     -
local            1     p+
lstat            01    $
lt               B     -
my               123   p+ # skip with 0 args, as my() => ()
ne               B     -
# next handled specially
# not handled specially
or               B     -
our              123   p+ # skip with 0 args, as our() => ()
# push handled specially
quotemeta        01    $
# readline handled specially
# readpipe handled specially
# redo handled specially
# XXX This code prints 'Undefined subroutine &main::require called':
#   use subs (); import subs 'require';
#   eval q[no strict 'vars'; sub { () = require; }]; print $@;
# so disable for now
#require          01    $+
# return handled specially
# our setp erroneously adds $_
setgrent         0     -
# split handled specially
# splice handled specially
stat             01    $
state            123   p+ # skip with 0 args, as state() => ()
# sub handled specially
truncate         2     p
uc               01    $
ucfirst          01    $
# unshift handled specially
# values handled specially
wantarray        0     -
x                B     -
xor              B     -
