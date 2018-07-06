# Adapted from Perl 5.26's lib/B/Deparse-core.t
# restricted just to unary ops
1;
__DATA__
#
# format:
#   keyword args flags
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
abs              01    $
alarm            01    $
break            0     -
caller           0     -
chdir            01    -
chmod            @     p1
chomp            @     $ 5.020
chop             @     $ 5.020
chr              01    $
chroot           01    $
close            01    -
closedir         1     -
continue         0     -
cos              01    $
defined          01    $+
eof              01    - # also tested specially
exec             @     p1 # also tested specially
exit             01    -
fc               01    $
fileno           1     -
getc             01    -
getgrgid         1     -
getgrnam         1     -
gethostbyname    1     -
getnetbyname     1     -
getpeername      1     -
getpgrp          1     -
getprotobyname   1     -
getpwnam         1     -
getpwuid         1     -
getsockname      1     -
gmtime           01    -
hex              01    $
int              01    $
length           01    $
localtime        01    -
lock             1     -
log              01    $
oct              01    $
ord              01    $
pop              0     1 # also tested specially
pos              01    $+
prototype        1     +
rand             01    -
readdir          1     -
readlink         01    $
ref              01    $
reset            01    -
rewinddir        1     -
rmdir            01    $
scalar           1     +
sethostent       1     -
setnetent        1     -
setprotoent      1     -
setservent       1     -
shift            0     1 # also tested specially
sin              01    $
sleep            01    -
sqrt             01    $
srand            01    -
study            01    $+
tell             01    -
telldir          1     -
tied             1     -
umask            01    -
undef            01    +
untie            1     -
write            01    -
