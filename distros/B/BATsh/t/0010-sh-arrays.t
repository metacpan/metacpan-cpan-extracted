######################################################################
#
# 0010-sh-arrays.t  BATsh::SH indexed and associative array tests
#
# Tests array support added in v0.06.  All tests run via BATsh::SH
# directly (no external shell, no system() calls needed).
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
use File::Spec ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Capture STDOUT produced by a list of SH lines into a single string.
sub _run_capture {
    my (@lines) = @_;
    BATsh::Env::init();
    %BATsh::SH::_SH_ARRAY      = ();
    %BATsh::SH::_SH_ARRAY_TYPE = ();
    my $out = '';
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $FindBin::Bin/_arr_capture_$$.tmp")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    BATsh::SH->exec_block([@lines]);
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    my $tmp = "$FindBin::Bin/_arr_capture_$$.tmp";
    local *RF;
    if (open(RF, $tmp)) {
        local $/;
        $out = <RF>;
        close(RF);
    }
    unlink($tmp);
    $out = '' unless defined $out;
    return $out;
}

my @tests = (

    # AR1: simple indexed array literal + ${arr[@]}
    sub {
        my $o = _run_capture('arr=(a b c)', 'echo "${arr[@]}"');
        _ok($o eq "a b c\n", 'AR1: arr=(a b c) ${arr[@]}');
    },

    # AR2: element count ${#arr[@]}
    sub {
        my $o = _run_capture('arr=(a b c d)', 'echo ${#arr[@]}');
        _ok($o eq "4\n", 'AR2: ${#arr[@]} element count');
    },

    # AR3: element access by index
    sub {
        my $o = _run_capture('arr=(x y z)', 'echo ${arr[0]} ${arr[2]}');
        _ok($o eq "x z\n", 'AR3: ${arr[i]} element access');
    },

    # AR4: $arr is shorthand for ${arr[0]}
    sub {
        my $o = _run_capture('arr=(first second)', 'echo $arr');
        _ok($o eq "first\n", 'AR4: $arr == ${arr[0]}');
    },

    # AR5: negative index -> last element
    sub {
        my $o = _run_capture('arr=(p q r)', 'echo ${arr[-1]}');
        _ok($o eq "r\n", 'AR5: ${arr[-1]} negative index');
    },

    # AR6: element assignment arr[i]=v
    sub {
        my $o = _run_capture('arr=(a b c)', 'arr[1]=B', 'echo "${arr[@]}"');
        _ok($o eq "a B c\n", 'AR6: arr[i]=v element assignment');
    },

    # AR7: append arr+=(...)
    sub {
        my $o = _run_capture('arr=(a b)', 'arr+=(c d)',
                             'echo "${arr[@]}" ${#arr[@]}');
        _ok($o eq "a b c d 4\n", 'AR7: arr+=(...) append');
    },

    # AR8: append to a single element arr[i]+=x
    sub {
        my $o = _run_capture('arr=(foo bar)', 'arr[0]+=BAZ', 'echo ${arr[0]}');
        _ok($o eq "fooBAZ\n", 'AR8: arr[i]+=x element append');
    },

    # AR9: ${!arr[@]} indices
    sub {
        my $o = _run_capture('arr=(a b c)', 'echo "${!arr[@]}"');
        _ok($o eq "0 1 2\n", 'AR9: ${!arr[@]} indices');
    },

    # AR10: ${#arr[i]} length of one element
    sub {
        my $o = _run_capture('arr=(hello hi)', 'echo ${#arr[0]} ${#arr[1]}');
        _ok($o eq "5 2\n", 'AR10: ${#arr[i]} element length');
    },

    # AR11: explicit subscripts in a literal create a sparse array
    sub {
        my $o = _run_capture('arr=([2]=two [5]=five)',
                             'echo "${!arr[@]}" / "${arr[@]}" / ${#arr[@]}');
        _ok($o eq "2 5 / two five / 2\n", 'AR11: sparse indexed array literal');
    },

    # AR12: for over "${arr[@]}" word-splits one item per element
    sub {
        my $o = _run_capture('arr=(one two three)',
                             'for x in "${arr[@]}"; do echo "item:$x"; done');
        _ok($o eq "item:one\nitem:two\nitem:three\n",
            'AR12: for x in "${arr[@]}"');
    },

    # AR13: array element values containing spaces survive "${arr[@]}"
    sub {
        my $o = _run_capture('arr=("a b" "c d")',
                             'echo ${#arr[@]}',
                             'for x in "${arr[@]}"; do echo "[$x]"; done');
        _ok($o eq "2\n[a b]\n[c d]\n", 'AR13: quoted elements with spaces');
    },

    # AR14: subscript may be a variable -- ${arr[$i]}
    sub {
        my $o = _run_capture('arr=(a b c)', 'i=2', 'echo ${arr[$i]}');
        _ok($o eq "c\n", 'AR14: ${arr[$i]} variable subscript');
    },

    # AR15: subscript arithmetic -- ${arr[i+1]}
    sub {
        my $o = _run_capture('arr=(a b c d)', 'i=1', 'echo ${arr[i+1]}');
        _ok($o eq "c\n", 'AR15: ${arr[i+1]} arithmetic subscript');
    },

    # AR16: unset whole array
    sub {
        my $o = _run_capture('arr=(a b c)', 'unset arr', 'echo "[${#arr[@]}]"');
        _ok($o eq "[0]\n", 'AR16: unset arr removes whole array');
    },

    # AR17: unset single element
    sub {
        my $o = _run_capture('arr=(a b c)', 'unset arr[1]',
                             'echo "${!arr[@]}" "${arr[@]}"');
        _ok($o eq "0 2 a c\n", 'AR17: unset arr[i] removes one element');
    },

    # AR18: declare -A then element assignment
    sub {
        my $o = _run_capture('declare -A m', 'm[red]=FF', 'm[grn]=00',
                             'echo ${m[red]} ${m[grn]} ${#m[@]}');
        _ok($o eq "FF 00 2\n", 'AR18: declare -A + element assignment');
    },

    # AR19: associative literal map=([k]=v ...)
    sub {
        my $o = _run_capture('declare -A m',
                             'm=([a]=1 [b]=2 [c]=3)',
                             'echo ${m[b]} ${#m[@]}');
        _ok($o eq "2 3\n", 'AR19: associative literal assignment');
    },

    # AR20: associative keys ${!m[@]} (sorted, deterministic)
    sub {
        my $o = _run_capture('declare -A m', 'm[zebra]=1', 'm[apple]=2',
                             'echo "${!m[@]}"');
        _ok($o eq "apple zebra\n", 'AR20: ${!m[@]} sorted keys');
    },

    # AR21: associative subscript is a literal string (not arithmetic)
    sub {
        my $o = _run_capture('declare -A m', 'm[10+1]=here',
                             'echo "${m[10+1]}"');
        _ok($o eq "here\n", 'AR21: associative key is literal string');
    },

    # AR22: declare -A inline initialiser
    sub {
        my $o = _run_capture('declare -A m=([x]=9 [y]=8)',
                             'echo ${m[x]}${m[y]} ${#m[@]}');
        _ok($o eq "98 2\n", 'AR22: declare -A m=([..]=..) inline init');
    },

    # AR23: iterate associative array by key
    sub {
        my $o = _run_capture('declare -A m=([a]=1 [b]=2)',
                             'for k in "${!m[@]}"; do echo "$k=${m[$k]}"; done');
        _ok($o eq "a=1\nb=2\n", 'AR23: for k in "${!m[@]}" with ${m[$k]}');
    },

    # AR24: typeset -A behaves like declare -A
    sub {
        my $o = _run_capture('typeset -A m', 'm[k]=v', 'echo ${m[k]}');
        _ok($o eq "v\n", 'AR24: typeset -A alias');
    },

    # AR25: whole-array reassignment resets prior contents
    sub {
        my $o = _run_capture('arr=(a b c d e)', 'arr=(x y)',
                             'echo "${arr[@]}" ${#arr[@]}');
        _ok($o eq "x y 2\n", 'AR25: arr=(...) resets the array');
    },

    # AR26: unset element then append continues past the highest index
    sub {
        my $o = _run_capture('arr=(a b c)', 'unset arr[1]', 'arr+=(d)',
                             'echo "${!arr[@]}" "${arr[@]}"');
        _ok($o eq "0 2 3 a c d\n", 'AR26: append after sparse unset');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { exit 1 if $fail }
