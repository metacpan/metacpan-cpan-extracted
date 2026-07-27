######################################################################
#
# 0031-set-positional.t  set [--] ARG ... sets $1..$9 / $@ / $# (v0.09)
#
# BACKGROUND
#   Until v0.09 the "set" builtin understood only its option letters
#   (-e -u -x, -o NAME) and silently ignored every operand, so the
#   standard way of feeding an argument list to a script fragment
#
#       set -- -f value
#       while getopts f: opt ; do ... done
#
#   saw an empty argument list: getopts falls back to the positional
#   parameters, and those were never set.  "set" now implements the POSIX
#   operand rules -- "set -- [ARG ...]" replaces the positional
#   parameters (clearing them when no ARG follows), and so does a first
#   operand that is not an option, as in "set a b c".  The parameters are
#   kept in the interpreter's existing %1..%9 / %* representation, the
#   one a function call and "shift" already use, so $1..$9, $@, $*, $#,
#   shift and getopts all see them.
#
# THIS TEST
#   SP01-SP02  set -- ARG ... sets $1..$3, $# and $@.
#   SP03       Quoting is respected: set -- "a b" c sets two parameters.
#   SP04       set -- with no operand clears the parameters.
#   SP05       set a b (no --) sets them too (POSIX operand rule).
#   SP06       Options and operands combine: set -e -- p q.
#   SP07       An option-only "set" leaves existing parameters alone.
#   SP08       shift works on parameters set this way.
#   SP09       getopts parses them (the case from the BACKGROUND note).
#   SP10       A full getopts loop plus shift $((OPTIND - 1)).
#   SP11       A value containing a backslash survives (v0.09 literals).
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

sub _capture {
    my ($code) = @_;
    my $out = '';
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    my $tmp = "$FindBin::Bin/_sp_cap_$$.tmp";
    close(STDOUT);
    open(STDOUT, "> $tmp")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    eval { $code->() };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    local *RF;
    if (open(RF, $tmp)) { local $/; $out = <RF>; close(RF) }
    unlink($tmp);
    $out = '' unless defined $out;
    warn $err if $err;
    $out =~ s/\r//g;
    $out =~ s/\s+\z//;
    return $out;
}

sub _run {
    my ($script) = @_;
    BATsh::Env::init();
    return _capture(sub { BATsh->run_string($script) });
}

my @tests = (

    sub {
        _ok(_run('set -- a b c; echo [$1] [$2] [$3]') eq '[a] [b] [c]',
            'SP01: set -- ARG ... sets $1..$3');
    },

    sub {
        _ok(_run('set -- a b c; echo [$#] [$@] [$*]') eq '[3] [a b c] [a b c]',
            'SP02: $# and $@ / $* follow the new parameter list');
    },

    sub {
        _ok(_run('set -- "a b" c; echo [$1] [$2] [$#]') eq '[a b] [c] [2]',
            'SP03: a quoted operand stays one parameter');
    },

    sub {
        _ok(_run('set -- a b; set --; echo [$1] [$#]') eq '[] [0]',
            'SP04: set -- with no operand clears the parameters');
    },

    sub {
        _ok(_run('set x y; echo [$1] [$2]') eq '[x] [y]',
            'SP05: a first operand that is not an option sets them too');
    },

    sub {
        _ok(_run('set -e -- p q; echo [$1] [$2]') eq '[p] [q]',
            'SP06: options and operands combine');
    },

    sub {
        _ok(_run('set -- a b; set +x; echo [$1] [$2]') eq '[a] [b]',
            'SP07: an option-only set leaves the parameters alone');
    },

    sub {
        _ok(_run('set -- a b c; shift; echo [$1] [$#]') eq '[b] [2]',
            'SP08: shift works on parameters set by set --');
    },

    sub {
        my $out = _run('set -- -f val; getopts f: o; echo [$o] [$OPTARG]');
        _ok($out eq '[f] [val]', 'SP09: getopts parses them');
    },

    sub {
        my $out = _run(join("\n",
            'set -- -a -b bval rest',
            'while getopts ab: opt; do',
            '    echo "opt=$opt arg=$OPTARG"',
            'done',
            'shift $((OPTIND - 1))',
            'echo "left=$1"',
        ));
        $out =~ s/\n/ /g;
        _ok($out eq 'opt=a arg= opt=b arg=bval left=rest',
            'SP10: a getopts loop plus shift $((OPTIND - 1))');
    },

    sub {
        _ok(_run("set -- 'C:\\x' d; echo [\$1] [\$2]") eq '[C:\x] [d]',
            'SP11: a parameter keeps a backslash in its value');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { $? = 1 if $fail }
