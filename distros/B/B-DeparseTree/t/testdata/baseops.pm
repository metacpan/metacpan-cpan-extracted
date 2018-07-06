# Adapted from Perl 5.26's lib/B/Deparse-core.t
1;
__DATA__
#
# format:
#   keyword args flags
#   keyword args flags  # comment
#   keyword args flags  5.022 (min perl version)

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

endgrent         0     -
endhostent       0     -
endnetent        0     -
endprotoent      0     -
endpwent         0     -
fork             0     -
gethostent       0     -
getlogin         0     -
getppid          0     -
getgrent         0     -
getnetent        0     -
getprotoent      0     -
getpwent         0     -
getservent       0     -
setpwent         0     -
time             0     -
times            0     -
wait             0     -
