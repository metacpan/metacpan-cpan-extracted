# Adapted from Perl 5.26's lib/B/Deparse-core.t
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
accept           2     p
alarm            01    $
and              B     -
atan2            2     p
bind             2     p
binmode          12    p
bless            1     p
break            0     -
caller           0     -
chdir            01    -
chmod            @     p1
chomp            @     $
chop             @     $
chown            @     p1
chr              01    $
chroot           01    $
close            01    -
closedir         1     -
cmp              B     -
connect          2     p
continue         0     -
cos              01    $
crypt            2     p
# dbmopen  handled specially
# dbmclose handled specially
defined          01    $+
# delete handled specially
die              @     p1
# do handled specially
# dump handled specially
# each handled specially
endgrent         0     -
endhostent       0     -
endnetent        0     -
endprotoent      0     -
endpwent         0     -
endservent       0     -
eof              01    - # also tested specially
eq               B     -
eval             01    $+
evalbytes        01    $
exec             @     p1 # also tested specially
# exists handled specially
exit             01    -
exp              01    $
fc               01    $
fcntl            3     p
fileno           1     -
flock            2     p
fork             0     -
formline         2     p
ge               B     -
getc             01    -
getgrent         0     -
getgrgid         1     -
getgrnam         1     -
gethostbyaddr    2     p
gethostbyname    1     -
gethostent       0     -
getlogin         0     -
getnetbyaddr     2     p
getnetbyname     1     -
getnetent        0     -
getpeername      1     -
getpgrp          1     -
getppid          0     -
getpriority      2     p
getprotobyname   1     -
getprotobynumber 1     p
getprotoent      0     -
getpwent         0     -
getpwnam         1     -
getpwuid         1     -
getservbyname    2     p
getservbyport    2     p
getservent       0     -
getsockname      1     -
getsockopt       3     p
# given handled specially
# grep             123   p+ # also tested specially
# glob handled specially
# goto handled specially
gmtime           01    -
gt               B     -
hex              01    $
index            23    p
int              01    $
ioctl            3     p
join             13    p
# keys handled specially
kill             123   p
# last handled specially
lc               01    $
lcfirst          01    $
le               B     -
length           01    $
link             2     p
listen           2     p
local            1     p+
localtime        01    -
lock             1     -
log              01    $
lstat            01    $
lt               B     -
# map              123   p+ # also tested specially
mkdir            @     p$
msgctl           3     p
msgget           2     p
msgrcv           5     p
msgsnd           3     p
my               123   p+ # skip with 0 args, as my() => ()
ne               B     -
# next handled specially
# not handled specially
oct              01    $
open             12345 p
opendir          2     p
or               B     -
ord              01    $
our              123   p+ # skip with 0 args, as our() => ()
pack             123   p
pipe             2     p
pop              0     1 # also tested specially
pos              01    $+
# print            @     p$+
# printf           @     p$+
prototype        1     +
# push handled specially
quotemeta        01    $
rand             01    -
read             34    p
readdir          1     -
# readline handled specially
readlink         01    $
# readpipe handled specially
recv             4     p
# redo handled specially
ref              01    $
rename           2     p
# XXX This code prints 'Undefined subroutine &main::require called':
#   use subs (); import subs 'require';
#   eval q[no strict 'vars'; sub { () = require; }]; print $@;
# so disable for now
#require          01    $+
reset            01    -
# return handled specially
reverse          @     p1 # also tested specially
rewinddir        1     -
rindex           23    p
rmdir            01    $
# our setp erroneously adds $_
# say              @     p$+
scalar           1     +
seek             3     p
seekdir          2     p
select           014   p1
semctl           4     p
semget           3     p
semop            2     p
send             34    p
setgrent         0     -
sethostent       1     -
setnetent        1     -
setpgrp          2     p
setpriority      3     p
setprotoent      1     -
setpwent         0     -
setservent       1     -
setsockopt       4     p
shift            0     1 # also tested specially
shmctl           3     p
shmget           3     p
shmread          4     p
shmwrite         4     p
shutdown         2     p
sin              01    $
sleep            01    -
socket           4     p
socketpair       5     p
# sort             @     p1+
# split handled specially
# splice handled specially
sprintf          123   p
sqrt             01    $
srand            01    -
stat             01    $
state            123   p+ # skip with 0 args, as state() => ()
study            01    $+
# sub handled specially
substr           234   p
symlink          2     p
syscall          2     p
sysopen          34    p
sysread          34    p
sysseek          3     p
system           @     p1 # also tested specially
syswrite         234   p
tell             01    -
telldir          1     -
tie              234   p
tied             1     -
time             0     -
times            0     -
truncate         2     p
uc               01    $
ucfirst          01    $
umask            01    -
undef            01    +
unlink           @     p$
unpack           12    p$
# unshift handled specially
untie            1     -
utime            @     p1
# values handled specially
vec              3     p
wait             0     -
waitpid          2     p
wantarray        0     -
warn             @     p1
write            01    -
x                B     -
xor              B     -
