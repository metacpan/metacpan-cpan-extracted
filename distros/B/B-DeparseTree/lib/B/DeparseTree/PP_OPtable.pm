# Copyright (c) 2018 Rocky Bernstein

# A table-driven mapping from Perl PP ops e.g pp_accept, pp_aeach,
# ... to a compact list of function names with arguments that
# implements them.

package B::DeparseTree::PP_OPtable;

use warnings; use strict;
our($VERSION, @EXPORT, @ISA);
$VERSION = '3.2.0';
@ISA = qw(Exporter);

use vars qw(%PP_MAPFNS);

use constant ASSIGN => 2; # operation OP has a =OP variant


# In the HASH below, the key is the operation name with the leading pp_ stripped.
# so "die" refers to function "pp_die". The value can be several things.
#
# If the table value is a string, then that function is called with a standard
# set of parameters. For example, consider:
#   'die' => 'listop'.
#
# The above indicates that for the pp_die operation we should call listop
# with standard parameters $self, $op, and the key value, e.g
# "die". This replaces B::Deparse equivalent:
#    sub pp_die { $self->listop($op, $cx, "die"); }
#
# If the table value is not a string, it will be an array reference, and here
# the entries may be subject to interpretation based on the function name.
#
# For the most part, when there are two entries, it is similar to the string case,
# but instead of passing the key name as a parameter, the string second parameter
# is used. For example:
#    'ghostent'   => ['baseop', "gethostent"],
# replaces the B::Deparse equivalent:
#    sub pp_ghostent { $self->listop($op, $cx, "gethostent"); }

# Precedences in binop are given by the following table

# Precedences:
# 26             [TODO] inside interpolation context ("")
# 25 left        terms and list operators (leftward)
# 24 left        ->
# 23 nonassoc    ++ --
# 22 right       **
# 21 right       ! ~ \ and unary + and -
# 20 left        =~ !~
# 19 left        * / % x
# 18 left        + - .
# 17 left        << >>
# 16 nonassoc    named unary operators
# 15 nonassoc    < > <= >= lt gt le ge
# 14 nonassoc    == != <=> eq ne cmp
# 13 left        &
# 12 left        | ^
# 11 left        &&
# 10 left        ||
#  9 nonassoc    ..  ...
#  8 right       ?:
#  7 right       = += -= *= etc.
#  6 left        , =>
#  5 nonassoc    list operators (rightward)
#  4 right       not
#  3 left        and
#  2 left        or xor
#  1             statement modifiers
#  0.5           statements, but still print scopes as do { ... }
#  0             statement level
# -1             format body


%PP_MAPFNS = (
     # 'avalues'    => ['unop', 'value'],
     # 'values'     => 'unop', # FIXME
     # 'sselect'    => 'listop',  FIXME: is used in PPfns
     # 'sockpair'   => 'listop', ""

    'accept'      => 'listop',
    'add'         => ['maybe_targmy', 'binop', '+', 18, ASSIGN],
    'aeach'       => ['unop', 'each'],
    'akeys'       => ['unop', 'keys'],
    'alarm'       => 'unop',
    'andassign'   => ['logassignop', '&&='],
    'atan2'       => ['maybe_targmy', 'listop'],

    'bind'        => 'listop',
    'binmode'     => 'listop',
    'bit_and'     => ['maybe_targmy', 'binop', "&", 13, ASSIGN],
    'bit_or'      => ['maybe_targmy', 'binop', "|", 12, ASSIGN],
    'bit_xor'     => ['maybe_targmy', 'binop', "^", 12, ASSIGN],
    'bless'       => 'listop',
    'break'       => 'unop',

    'caller'      => 'unop',
    'chdir'       => ['maybe_targmy', 'unop'], # modified below
    'chr'         => ['maybe_targmy', 'unop'],
    'chroot'      => ['maybe_targmy', 'unop'],
    'close'       => 'unop',
    'closedir'    => 'unop',
    'connect'     => 'listop',
    'concat'      => ['maybe_targmy', 'concat'],
    'continue'    => 'unop',

    'db_open'     => 'listop',
    'dbmclose'    => 'unop',
    'dbmopen'     => 'listop',
    'dbstate'     => 'cops',
    'defined'     => 'unop',
    'die'         => 'listop',
    'divide'      => ['maybe_targmy', 'binop', "/", 19, ASSIGN],
    'dorassign'   => ['logassignop', '//='],
    'dump'        => ['loopex', "CORE::dump"],

    'each'        => 'unop',
    'egrent'      => ['baseop', 'endgrent'],
    'ehostent'    => ['baseop', "endhostent"],
    'enetent'     => ['baseop', "endnetent"],
    'eof'         => 'unop',
    'eprotoent'   => ['baseop', "endprotoent"],
    'epwent'      => ['baseop', "endpwent"],
    'eservent'    => ['baseop', "endservent"],
    'exit'        => 'unop',

    'fc'          => 'unop',
    'fcntl'       => 'listop',
    'fileno'      => 'unop',
    'fork'        => 'baseop',
    'formline'    => 'listop', # see also deparse_format
    'ftatime'     => ['filetest', "-A"],
    'ftbinary'    => ['filetest', "-B"],
    'ftblk'       => ['filetest', "-b"],
    'ftchr'       => ['filetest', "-c"],
    'ftctime'     => ['filetest', "-C"],
    'ftdir'       => ['filetest', "-d"],
    'fteexec'     => ['filetest', "-x"],
    'fteowned'    => ['filetest', "-O"],
    'fteread'     => ['filetest', "-r"],
    'ftewrite'    => ['filetest', "-w"],
    'ftfile'      => ['filetest', "-f"],
    'ftis'        => ['filetest', "-e"],
    'ftlink'      => ['filetest', "-l"],
    'ftmtime'     => ['filetest', "-M"],
    'ftpipe'      => ['filetest', "-p"],
    'ftrexec'     => ['filetest', "-X"],
    'ftrowned'    => ['filetest', "-o"],
    'ftrread'     => ['filetest', '-R'],
    'ftrwrite'    => ['filetest', "-W"],
    'ftsgid'      => ['filetest', "-g"],
    'ftsize'      => ['filetest', "-s"],
    'ftsock'      => ['filetest', "-S"],
    'ftsuid'      => ['filetest', "-u"],
    'ftsvtx'      => ['filetest', "-k"],
    'fttext'      => ['filetest', "-T"],
    'fttty'       => ['filetest', "-t"],
    'ftzero'      => ['filetest', "-z"],

    'getc'        => 'unop',
    'getlogin'    => 'baseop',
    'getpeername' => 'unop',
    'getpgrp'     => ['maybe_targmy', 'unop'],
    'getsockname' => 'unop',
    'ggrent'      => ['baseop', "getgrent"],
    'ggrgid'      => ['unop',   "getgrgid"],
    'ggrnam'      => ['unop',   "getgrnam"],
    'ghbyaddr'    => ['listop', 'gethostbyaddr'],
    'ghbyname'    => ['unop',   "gethostbyname"],
    'ghostent'    => ['baseop', "gethostent"],
    'gmtime'      => 'unop',
    'gnbyaddr'    => ['listop', "getnetbyaddr"],
    'gnbyname'    => ['unop',   "getnetbyname"],
    'gnetent'     => ['baseop', "getnetent"],
    'goto'        => ['loopex', "goto"],
    'gpbyname'    => ['unop',   "getprotobyname"],
    'gpbynumber'  => ['listop', 'getprotobynumber'],
    'gprotoent'   => ['baseop', "getprotoent"],
    'gpwent'      => ['baseop', "getpwent"],
    'gpwnam'      => ['unop',   "getpwnam"],
    'gpwuid'      => ['unop',   "getpwuid"],
    'grepstart'   => ['baseop', "grep"],
    'gsbyname'    => ['listop', 'getservbyname'],
    'gsbyport'    => ['listop', 'getservbyport'],
    'gservent'    => ['baseop', "getservent"],
    'gsockopt'    => ['listop', 'getsockopt'],

    'i_add'       => ['maybe_targmy', 'binop', "+", 18, ASSIGN],
    'i_divide'    => ['maybe_targmy', 'binop', "/", 19, ASSIGN],
    'i_modulo'    => ['maybe_targmy', 'binop', "%", 19, ASSIGN],
    'i_multiply'  => ['maybe_targmy', 'binop', "*", 19, ASSIGN],
    'i_subtract'  => ['maybe_targmy', 'binop', "-", 18, ASSIGN],
    'ioctl'       => 'listop',
    'keys'        => 'unop',

    'last'        => 'loopex',
    'lc'          => 'dq_unop',
    'lcfirst'     => 'dq_unop',
    'left_shift'  => ['maybe_targmy', 'binop', "<<", 17, ASSIGN],
    'length'      => ['maybe_targmy', 'unop'],
    'listen'      => 'listop',
    'localtime'   => 'unop',
    'lock'        => 'unop',
    'lstat'       => 'filetest',

    'modulo'      => ['maybe_targmy', 'binop', "%", 19, ASSIGN],
    'msgctl'      => 'listop',
    'msgget'      => 'listop',
    'msgrcv'      => 'listop',
    'msgsnd'      => 'listop',
    'multiply'    => ['maybe_targmy', 'binop', '*', 19, ASSIGN],

    'nbit_and'    => ['maybe_targmy', 'binop', "&", 13, ASSIGN],
    'nbit_or'     => ['maybe_targmy', 'binop', "|", 12, ASSIGN],
    'nbit_xor'    => ['maybe_targmy', 'binop', "^", 12, ASSIGN],
    'next'        => 'loopex',
    'nextstate'   => 'cops',

    'ord'         => ['maybe_targmy', 'unop'],
    'open'        => 'listop',
    'orassign'    => ['logassignop', '||='],

    'padav'       => 'pp_padsv',
    'padhv'       => 'pp_padsv',
    'pack'        => 'listop',
    'pipe_op'     => ['listop', 'pipe'],
    'pop'         => 'unop',
    'pow'         => ['maybe_targmy', 'binop', "**", 22, ASSIGN],
    'prototype'   => 'unop',

    'quotemeta'   => ['maybe_targmy', 'dq_unop'],

    'read'        => 'listop',
    'readdir'     => 'unop',
    'readlink'    => 'unop',
    'recv'        => 'listop',
    'redo'        => 'loopex',
    'ref'         => 'unop',
    'repeat'      => ['maybe_targmy', 'repeat'], # modified below
    'reset'       => 'unop',
    'reverse'     => 'listop',
    'rewinddir'   => 'unop',
    'right_shift' => ['maybe_targmy', 'binop', ">>", 17, ASSIGN],
    'rmdir'       => ['maybe_targmy', 'unop'],
    'runcv'       => ['unop', '__SUB__'],

    'say'         => 'indirop',
    'seek'        => 'listop',
    'seekdir'     => 'listop',
    'select'      => 'listop',
    'semctl'      => 'listop',
    'semget'      => 'listop',
    'semop'       => 'listop',
    'send'        => 'listop',
    'setstate'    => 'nextstate',
    'sgrent'      => ['baseop', "setgrent"],
    'shift'       => 'unop',
    'shmctl'      => 'listop',
    'shmget'      => 'listop',
    'shmread'     => 'listop',
    'shmwrite'    => 'listop',
    'shostent'    => ['unop',   "sethostent"],
    'shutdown'    => 'listop',
    'sleep'       => ['maybe_targmy', 'unop'],
    'snetent'     => ['unop',   "setnetent"],
    'socket'      => 'listop',
    'sort'        => "indirop",
    'splice'      => 'listop',
    'sprotoent'   => ['unop',   "setprotoent"],
    'spwent'      => ['baseop', "setpwent"],
    'srand'       => 'unop',
    'sselect'     => ['listop', "select"],
    'sservent'    => ['unop',   "setservent"],
    'ssockopt'    => ['listop', "setsockopt"],
    'stat'        => 'filetest',
    'study'       => 'unop',
    'subtract'    => ['maybe_targmy', 'binop', "-", 18, ASSIGN],
    'syscall'     => 'listop',
    'sysopen'     => 'listop',
    'sysread'     => 'listop',
    'sysseek'     => 'listop',
    'syswrite'    => 'listop',

    'tell'        => 'unop',
    'telldir'     => 'unop',
    'tie'         => 'listop',
    'tied'        => 'unop',
    'tms'         => ['baseop', 'times'],

    'uc'          => 'dq_unop',
    'ucfirst'     => 'dq_unop',
    'umask'       => 'unop',
    'undef'       => 'unop',
    'unpack'      => 'listop',
    'untie'       => 'unop',

    'warn'        => 'listop',
    );


# Version specific modification are next...
use Config;
my $is_cperl = $Config::Config{usecperl};

if ($] >= 5.015000) {
    # FIXME is it starting in cperl 5.26+ which add this?
    $PP_MAPFNS{'srefgen'} = 'pp_refgen';
}
if ($is_cperl) {
    # FIXME reconcile differences in cperl. Maybe cperl is right?
    delete $PP_MAPFNS{'chdir'};
}

if ($] < 5.012000) {
    # Earlier than 5.12 doesn't use "targmy"?
    $PP_MAPFNS{'repeat'} = 'repeat';
}

@EXPORT = qw(%PP_MAPFNS);

1;
