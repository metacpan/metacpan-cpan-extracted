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

accept           2     p
atan2            2     p
bind             2     p
binmode          12    p
bless            1     p
chown            @     p1
connect          2     p
crypt            2     p
die              @     p1
fcntl            3     p
flock            2     p
formline         2     p
gethostbyaddr    2     p
getnetbyaddr     2     p
getpriority      2     p
getprotobynumber 1     p
getservbyname    2     p
getservbyport    2     p
getsockopt       3     p
index            23    p
ioctl            3     p
join             13    p
kill             123   p
link             2     p
listen           2     p
mkdir            @     p$
msgctl           3     p
msgget           2     p
msgrcv           5     p
msgsnd           3     p
open             12345 p
opendir          2     p
pack             123   p
pipe             2     p
read             34    p
recv             4     p
rename           2     p
reverse          @     p1 # also tested specially
rindex           23    p
seek             3     p
seekdir          2     p
select           014   p1
semctl           4     p
semget           3     p
semop            2     p
send             34    p
setpgrp          2     p
setpriority      3     p
setsockopt       4     p
shmctl           3     p
shmget           3     p
shmread          4     p
shmwrite         4     p
shutdown         2     p
socket           4     p
socketpair       5     p
sprintf          123   p
substr           234   p
symlink          2     p
syscall          2     p
sysopen          34    p
sysread          34    p
sysseek          3     p
system           @     p1 # also tested specially
syswrite         234   p
tie              234   p
unlink           @     p$
unpack           12    p$
utime            @     p1
vec              3     p
waitpid          2     p
warn             @     p1
