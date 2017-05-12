#!/usr/bin/perl

use strict;
use warnings;

BEGIN { eval "use threads; use threads::shared;" }

use Scalar::Util    qw/blessed reftype tainted/;
use Test::More;
use B               qw/SVf_ROK/;
use File::Temp      qw/tempfile/;
use Taint::Runtime  qw/taint_start taint_stop taint/;
use Clone::Closure  qw/clone/;

# Test::Builder has some too-clever-by-half fakery to detect if the test
# actually dies; however, under 5.6.1 it gets confused by eval {} :(

# It turns out [rt.cpan.org#12359] that this is caused by my use of $^P,
# and is fixed by perl@24291 (went into 5.8.7).

if ($] < 5.008007) {
    my $die = $SIG{__DIE__};
    $SIG{__DIE__} = sub {
        ($^S and defined $^S) or $die->();
    };
}

defined &B::SV::ROK or
    *B::SV::ROK = sub { $_[0]->FLAGS & B::SVf_ROK };

BEGIN { *b = \&B::svref_2object }

my $RVc = blessed b \\1;

use constant        SVp_SCREAM => 0x08000000;

sub mg {
    my %mg;
    my $mg = eval { b($_[0])->MAGIC };

    while ($mg and $$mg) {
        $mg{ $mg->TYPE } = $mg;
        $mg = $mg->MOREMAGIC;
    }

    return \%mg;
}

sub _test_mg {
    my ($invert, $ref, $how, $name) = @_;

    my $mg  = mg $ref;
    my $got = join '', keys %$mg;

    my ($ok, $no) = ($mg->{$how}, '');

    if ($invert) {
        $ok = !$ok;
        $no = 'no ';
    }

    local $Test::Builder::Level = $Test::Builder::Level + 2;
    return ok($ok, $name) || diag(<<DIAG);
Got magic of types
    '$got',
expected ${no}magic of type
    '$how'.
DIAG
}

sub has_mg   { _test_mg 0, @_; }
sub hasnt_mg { _test_mg 1, @_; }

sub is_prop {
    my (%got, %exp, $comp, $sub, $meth, $name);
    ($got{ref}, $comp, $exp{ref}, $name) = @_;

    my @comp = split '/', $comp;
    $meth = pop @comp;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return ok(
        eval {
            my $sub = {
                b  => sub { b($_[0]) },
                mg => sub { mg($_[0])->{$comp[1]} },
            }->{$comp[0]}
                or die "unknown property '$comp'";

            for my $o (\%got, \%exp) {
                $o->{obj} = $sub->($o->{ref})
                    or die "$comp[0]($$o{ref}) failed";

                $o->{res} = $o->{obj}->$meth;
            }

            my $ok;

            if (not defined $got{res}) {
                $ok = not defined $exp{res};
            }
            else {
                $ok = defined $exp{res}
                    && $got{res} eq $exp{res};
            }

            $_ = defined($_) ? "'$_'" : 'undef'
                for $got{res}, $exp{res};

            $ok or die <<DIE
$comp[0]()->$meth was
    $got{res},
expected
    $exp{res}.
DIE
        },
        $name,
    ) || diag($@);
}

sub _test_flag {
    my ($invert, $ref, $flag, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;

    my $ok = b($ref)->FLAGS & $flag;
    my $no = '';

    if ($invert) {
        $ok = !$ok;
        $no = 'no ';
    }

    return ok($ok, $name);
}

sub is_flag   { return _test_flag 0, @_; }
sub isnt_flag { return _test_flag 1, @_; }

sub oneliner {
    my ($perl) = @_;
    my ($SCRIPT, $script) = tempfile('XXXXXXXX', UNLINK => 1);
    print $SCRIPT $perl;
    my $val = qx/$^X $script/;
    $? and $val = "Perl script\n$perl\nfailed with \$? = $?";
    return $val;
}

my $tests;

# Types of magic (from perl.h)

#define PERL_MAGIC_sv		  '\0' /* Special scalar variable */
{
    BEGIN { $tests += 3 }

    my $mg = clone $0;

    has_mg      \$0,        "\0",           '(sanity check)';
    hasnt_mg    \$mg,       "\0",           '$0 loses magic';
    is          $mg,        $0,             '...but keeps value';
}

#define PERL_MAGIC_overload	  'A' /* %OVERLOAD hash */
#define PERL_MAGIC_overload_elem  'a' /* %OVERLOAD hash element */
#define PERL_MAGIC_overload_table 'c' /* Holds overload table (AMT) on stash */

#define PERL_MAGIC_bm		  'B' /* Boyer-Moore (fast string search) */
SKIP: {
    BEGIN { $tests += 8 }
    $] == 5.010000 
        and skip "5.10.0 has serious bugs in PVBM handling", 8;

    use constant PVBM => 'foo';

    my $dummy  = index 'foo', PVBM;
    # blead (5.9) doesn't have PVBM, and uses PVGV instead
    my $type   = blessed b(\PVBM);
    my $pvbm   = clone \PVBM;

    isa_ok  b($pvbm),       $type,      'PVBM cloned';
    isnt    $pvbm,          \PVBM,      '...not a copy';
    has_mg  \PVBM,          'B',        '(sanity check)';
    has_mg  $pvbm,          'B',        '...with magic';
    is      $$pvbm,         'foo',      '...and value';

    SKIP: {
        skip 'B doesn\'t support PVBM methods', 2
            unless eval { b(\PVBM)->RARE; 1; };
        is_prop $pvbm, 'b/RARE',    \PVBM,  '...and RARE';
        is_prop $pvbm, 'b/TABLE',   \PVBM,  '...and TABLE';
    }

    is      index('foo', $$pvbm),   0,  '...and still works';
}

#define PERL_MAGIC_regdata	  'D' /* Regex match position data
#					(@+ and @- vars) */
#define PERL_MAGIC_regdatum	  'd' /* Regex match position data element */
{
    BEGIN { $tests += 7 }

    "foo" =~ /foo/;
    my $Dmg = clone \@+;
    my $dmg = clone \$+[0];

    has_mg      \@+,        'D',        '(sanity check)';
    hasnt_mg    $Dmg,       'D',        '@+ loses magic';
    is_deeply   $Dmg,       \@+,        '...but keeps value';
    isnt        \$Dmg->[0], \$+[0],     '...not copied';

    has_mg      \$+[0],     'd',        '(sanity check)';
    hasnt_mg    $dmg,       'd',        '$+[0] loses magic';
    is          $$dmg,      $+[0],      '...but keeps value';
}

#define PERL_MAGIC_env		  'E' /* %ENV hash */
#define PERL_MAGIC_envelem	  'e' /* %ENV hash element */
{
    BEGIN { $tests += 6 }

    $ENV{FOO} = 'BAR';
    $ENV{BAR} = 'BAZ';
    my $Emg   = clone \%ENV;
    my $emg   = clone \$ENV{FOO};

    sub real_getenv { oneliner "print \$ENV{'$_[0]'}" }

    has_mg      \%ENV,      'E',        '(sanity check)';
    hasnt_mg    $Emg,       'E',        '%ENV loses magic';
    is_deeply   $Emg,       \%ENV,      '...but keeps value';

    has_mg      \$ENV{FOO}, 'e',        '(sanity check)';
    hasnt_mg    $emg,       'e',        '$ENV{FOO} loses magic';
    is          $$emg,      'BAR',      '...but keeps value';

    BEGIN { $tests += 2 }

    $Emg->{BAR} = 'QUUX';
    $$emg       = 'ZPORK';

    is      real_getenv('BAR'), 'BAZ',  '%ENV preserved';
    is      real_getenv('FOO'), 'BAR',  '$ENV{FOO} preserved';
}

#define PERL_MAGIC_fm		  'f' /* Formline ('compiled' format) */

#define PERL_MAGIC_regex_global	  'g' /* m//g target / study()ed string */
{
    BEGIN { $tests += 4 }

    my $str = 'foo';
    study $str;
    my $mg  = clone $str;

    has_mg      \$str,      'g',        '(sanity check)';
    hasnt_mg    \$mg,       'g',        'studied string loses magic';
    isnt_flag   \$mg,       SVp_SCREAM, '...and SCREAM';
    is          $mg,        $str,       '...but keeps value';
}

#define PERL_MAGIC_isa		  'I' /* @ISA array */
#define PERL_MAGIC_isaelem	  'i' /* @ISA array element */
{
    BEGIN { $tests += 6 }

    use vars qw/@ISA/;

    local @ISA;
    push @ISA, 't';

    my $Img = clone \@ISA;
    my $img = clone \$ISA[0];

    has_mg      \@ISA,      'I',        '(sanity check)';
    hasnt_mg    $Img,       'I',        '@ISA loses magic';
    is_deeply   $Img,       \@ISA,      '...but keeps value';

    has_mg      \$ISA[0],   'i',        '(sanity check)';
    hasnt_mg    $img,       'i',        '$ISA[0] loses magic';
    is          $$img,      $ISA[0],    '...but keeps value';
}

#define PERL_MAGIC_nkeys	  'k' /* scalar(keys()) lvalue */
# it is apparently impossible to create a scalar with a value in it that
# has 'k' magic... it only exists on the LHS of an assignment.

#define PERL_MAGIC_dbfile	  'L' /* Debugger %_<filename */
#define PERL_MAGIC_dbline	  'l' /* Debugger %_<filename element */
{
    BEGIN { $tests += 6 }

    no strict 'refs';

    {
        local $^P = $^P | 0x02;
        require t::Foo;
    }

    my $pm  = '_<' . $INC{'t/Foo.pm'};
    ${$pm}{foo} = 'bar';
    my $Lmg = clone \%$pm;
    my $lmg = clone \${$pm}{foo};

    has_mg      \%$pm,      'L',        '(sanity check)';
    hasnt_mg    $Lmg,       'L',        '%_<file loses magic';
    is_deeply   $Lmg,       \%$pm,      '...but keeps value';

    has_mg      \${$pm}{foo}, 'l',      '(sanity check)';
    hasnt_mg    $lmg,       'l',        '$_<file{} loses magic';
    is          $$lmg,      'bar',      '...but keeps value';
}

#define PERL_MAGIC_mutex	  'm' /* for lock op */

#define PERL_MAGIC_shared	  'N' /* Shared between threads */
#define PERL_MAGIC_shared_scalar  'n' /* Shared between threads */
SKIP: {
    my $skip;
    skip "no threads", $skip unless defined &share;

    {
        BEGIN { $skip += 5 }

        my $shr;
        share($shr);
        $shr   = 'foo';
        my $mg = clone \$shr;

        has_mg  \$shr,              'n',    '(sanity check)';
        has_mg  $mg,                'n',    'shared scalars clone';
        is      $$mg,               $shr,   '...with value';

        threads->create(sub { $$mg = 'bar' })->join;

        is      $$mg,               'bar',  '...and still work';
        is      $shr,               'foo',  'original preserved';
    }

    {
        BEGIN { $skip += 5 }

        my @shr;
        share(@shr);
        @shr   = qw/foo bar/;

        my $mg = clone \@shr;

        has_mg      \@shr,          'P',    '(sanity check)';
        has_mg      $mg,            'P',    'shared arrays clone';
        is_deeply   $mg,            \@shr,  '...with value';

        threads->create(sub { $mg->[0] = 'baz' })->join;

        is          $mg->[0],       'baz',  '...and still work';
        is          $shr[0],        'foo',  'original preserved';
    }

    BEGIN { $tests += $skip }
}

#define PERL_MAGIC_collxfrm	  'o' /* Locale transformation */

#define PERL_MAGIC_tied		  'P' /* Tied array or hash */
#define PERL_MAGIC_tiedelem	  'p' /* Tied array or hash element */
{
    BEGIN { $tests += 11 }

    use Tie::Array;

    tie my @ary, 'Tie::StdArray';
    @ary = qw/a b c/;
    my $Pmg = clone \@ary;
    my $pmg = clone \$ary[2];

    isa_ok      b($Pmg),            'B::AV',    'tied array cloned';
    has_mg      \@ary,              'P',        '(sanity check)';
    has_mg      $Pmg,               'P',        '...with magic';
    ok          tied(@$Pmg),                    '...still tied';
    isnt        tied(@$Pmg),        tied(@ary), '...not copied';
    is          $Pmg->[0],          'a',        '...correctly';

    $Pmg->[0] = 'd';

    is          $Pmg->[0],          'd',        '(sanity check)';
    is          $ary[0],            'a',        '...tied array preserved';

    has_mg      \$ary[2],           'p',        '(sanity check)';
    hasnt_mg    $pmg,               'p',        '$tied[2] loses magic';
    is          $$pmg,              'c',        '...but keeps value';
}
{
    BEGIN { $tests += 11 }

    use Tie::Hash;

    tie my %hsh, 'Tie::StdHash';
    %hsh = qw/a b c d/;
    my $Pmg = clone \%hsh;
    my $pmg = clone \$hsh{c};

    isa_ok      b($Pmg),            'B::HV',    'tied hash cloned';
    has_mg      \%hsh,              'P',        '(sanity check)';
    has_mg      $Pmg,               'P',        '...with magic';
    ok          tied(%$Pmg),                    '...still tied';
    isnt        tied(%$Pmg),        tied(%hsh), '...not copied';
    is          $Pmg->{a},          'b',        '...correctly';

    $Pmg->{a} = 'e';

    is          $Pmg->{a},          'e',        '(sanity check)';
    is          $hsh{a},            'b',        '...tied hash preserved';

    has_mg      \$hsh{c},           'p',        '(sanity check)';
    hasnt_mg    $pmg,               'p',        '$tied{c} loses magic';
    is          $$pmg,              'd',        '...but keeps value';
}

#define PERL_MAGIC_tiedscalar	  'q' /* Tied scalar or handle */
{
    BEGIN { $tests += 8 }

    use Tie::Scalar;

    tie my $sv, 'Tie::StdScalar';
    $sv = 'foo';
    my $mg = clone \$sv;

    isa_ok      b($mg),             'B::SV',    'tied scalar cloned';
    has_mg      \$sv,               'q',        '(sanity check)';
    has_mg      $mg,                'q',        '...with magic';
    ok          tied($$mg),                     '...still tied';
    isnt        tied($$mg),         tied($sv),  '...not copied';
    is          $$mg,               'foo',      '...correctly';

    $$mg = 'bar';

    is          $$mg,               'bar',      '(sanity check)';
    is          $sv,                'foo',      'tied scalar preserved';
}

#define PERL_MAGIC_qr		  'r' /* precompiled qr// regex */
SKIP: {
    my $skip;
    skip "qrs aren't magic in this version of perl", $skip
        if $] > 5.010;

    my $qr = qr/foo/;
    my $mg = clone $qr;

    BEGIN { $skip += 3 }

    # qr//s are already refs

    has_mg      $qr,                'r',        '(sanity check)';
    has_mg      $mg,                'r',        'qr// clones';
    isa_ok      $mg,                'Regexp',   '...and';

    BEGIN { $skip += 2 }

    SKIP: {
        skip "no B::MAGIC->REGEX", 2 unless B::MAGIC->can('REGEX');
        is_prop     $mg, 'mg/r/REGEX',     $qr,     '...and REGEX';
        is_prop     $mg, 'mg/r/precomp',   $qr,     '...and precomp';
    }

    BEGIN { $skip += 2 }

    is          $mg,                   $qr,     '...and value';
    ok          +('barfoobaz' =~ $mg),          '...and still works';

    my $segv = oneliner <<PERL;
BEGIN { unshift \@INC, qw,inc blib/lib blib/arch,; }
use Clone::Closure qw/clone/;

clone qr/foo/;
PERL
   
    BEGIN { $skip += 1 }

    is          $segv,              '',         '...and doesn\'t segfault';

    BEGIN { $tests += $skip }
}

BEGIN { $tests += 3 }

# see [perl #20683]
SKIP: {
    $] < 5.008 and skip "(??{}) buggy under 5.6", 3;

    my $p = 1;
    "x" =~ /(??{$p})/;
    my $mg = clone \$p;
    
    has_mg      \$p,            'r',        '(sanity check)'; 

    for (1..4) { $p++ if /(??{$p})/ }

    is          $p,             5,          '(??{}) works after cloning';
    hasnt_mg    $mg,            'r',        '...and clone isn\'t magic';
}

#define PERL_MAGIC_sig		  'S' /* %SIG hash */
#define PERL_MAGIC_sigelem	  's' /* %SIG hash element */
{
    no warnings 'signal';
    my $HAS_USR1 = exists $SIG{USR1};

    my $count;
    $SIG{USR1} = sub { $count++ };
    my $Smg    = clone \%SIG;
    my $smg    = \clone $SIG{USR1};

    BEGIN { $tests += 5 }

    my $usr1 = $Smg->{USR1};
    $count = 0;

    has_mg      \%SIG,      'S',        '(sanity check)';
    hasnt_mg    $Smg,       'S',        '%SIG loses magic';
    is      reftype($usr1), 'CODE',     '...but value is cloned'
        and $usr1->();
    isnt    $Smg->{USR1},   $SIG{USR1}, '...not copied';
    is          $count,     1,          '...correctly';

    BEGIN { $tests += 5 }

    $count = 0;

    has_mg      \$SIG{USR1}, 's',       '(sanity check)';
    hasnt_mg    $smg,       's',        '$SIG{USR1} loses magic';
    is      reftype($$smg), 'CODE',     '...but value is cloned'
        and ($$smg)->();
    isnt        $$smg,      $SIG{USR1}, '...not copied';
    is          $count,     1,          '...correctly';

    SKIP: {
        my $skip;
        skip 'no SIGUSR1', $skip unless $HAS_USR1;
        skip 'signals don\'t work with threads', $skip 
            if defined &share;

        BEGIN { $skip += 3 }

        $count = 0;
        kill USR1 => $$;

        is      $count,     1,          '(sanity check)';

        $Smg->{USR1} = sub { 1; };
        $count = 0;
        kill USR1 => $$;

        is      $count,     1,          '%SIG preserved';

        $$smg = sub { 1; };
        $count = 0;
        kill USR1 => $$;

        is      $count,     1,          '$SIG{USR1} preserved';

        BEGIN { $tests += $skip }
    }
}

#define PERL_MAGIC_taint	  't' /* Taintedness */
{
    BEGIN { $tests += 3 }

    taint_start;

    my $t  = "foo";
    taint \$t;
    my $mg = clone $t;

    ok      tainted($t),                '(sanity check)';
    ok      tainted($mg),               'taintedness clones';
    has_mg  \$mg,               't',    '...with magic';

    taint_stop;
}

#define PERL_MAGIC_uvar		  'U' /* Available for use by extensions */
#define PERL_MAGIC_uvar_elem	  'u' /* Reserved for use by extensions */

#define PERL_MAGIC_vstring	  'V' /* SV was vstring literal */
SKIP: {
    my $skip;

    my $vs = v1.2.3;

    skip "no vstrings", $skip unless mg(\$vs)->{V};

    BEGIN { $skip += 3 }

    my $mg = clone $vs;

    has_mg  \$mg,           'V',        'vstring keeps magic';
    is      $mg,            $vs,        '...and value';
    is_prop \$mg, 'mg/V/PTR', \$vs,     '...correctly';

    BEGIN { $tests += $skip }
}

#define PERL_MAGIC_vec		  'v' /* vec() lvalue */
{
    BEGIN { $tests += 4 }

    my $str = 'aaa';
    my $mg  = clone \vec $str, 1, 8;

    has_mg      \vec($str, 1, 8), 'v',  '(sanity check)';
    hasnt_mg    $mg,        'v',        'vec() loses magic';
    is          $$mg,       ord('a'),   '...but keeps value';

    $$mg = ord('b');

    is          $str,       'aaa',      'vec() preserved';
}

#define PERL_MAGIC_utf8		  'w' /* Cached UTF-8 information */
SKIP: {
    my $skip;

    {
        BEGIN { $skip += 4 }

        my $str = "\x{fff}a";
        my $dummy = index $str, 'a';
        
        mg(\$str)->{w} or skip 'no utf8 cache', $skip;

        my $mg = clone \$str;

        has_mg  \$str,          'w',        '(sanity check)';
        has_mg  $mg,            'w',        'utf8 cache is cloned';
        is      $$mg,           $str,       '...with value';
        is_prop $mg, 'mg/w/PTR', \$str,     '...correctly';
    }
    {
        BEGIN { $skip += 4 }

        my $str   = "foo";
        utf8::upgrade($str);
        my $tmp   = substr $str, 2, 1;
        my $mg    = clone \$str;

        has_mg  \$str,          'w',        '(sanity check)';
        has_mg  $mg,            'w',        'utf8 cache is cloned';
        is      $$mg,           $str,       '...with value';
        is_prop $mg, 'mg/w/PTR', \$str,     '...correctly';
    }
    
    BEGIN { $tests += $skip }
}

#define PERL_MAGIC_substr	  'x' /* substr() lvalue */
{
    BEGIN { $tests += 4 }

    my $str = 'aabbc';
    my $mg  = clone \substr $str, 2, 2;

    has_mg      \substr($str, 3, 2), 'x',   '(sanity check)';
    hasnt_mg    $mg,        'x',            'substr() loses magic';
    is          $$mg,       'bb',           '...but keeps value';

    $$mg = 'dd';

    is          $str,       'aabbc',        'substr() preserved';
}

#define PERL_MAGIC_defelem	  'y' /* Shadow "foreach" iterator variable /
#					smart parameter vivification */
{
    BEGIN { $tests += 3 }

    my %hash;

    sub {
        # can't test with has_mg, as taking a ref destroys the magic

        ok !defined(clone $_[0]),       'cloned autoviv is still undef';
        ok !exists($hash{a}),           '(sanity check)';

        my $dummy = \clone($_[0]);

        ok !exists($hash{a}),           'autoviv preserved';
    }->($hash{a});
}

#define PERL_MAGIC_glob		  '*' /* GV (typeglob) */
{
    BEGIN { $tests += 5 }

    my $glob = *bar;
    my $gv   = clone *bar;

    my $has_mg = exists mg(\*bar)->{'*'};

    isa_ok  b(\$gv),        'B::GV',        'GV cloned';

    SKIP: {
        skip 'globs have no magic', 2 unless $has_mg;
        has_mg  \*bar,          '*',            '(sanity check)';
        has_mg  \$gv,           '*',            '...with magic';
    }

    SKIP: {
        skip 'can\'t test globs', 2
            unless eval { b(\*STDOUT)->GP; 1 };

        is_prop \$glob, 'b/GP', \*bar,      '(sanity check)';
        is_prop \$gv,   'b/GP', \*bar,      '...and is the same glob';
    }

    BEGIN { $tests += 5 }

    my $rv = clone \*foo;

    isa_ok  b(\$rv),        $RVc,           'ref to GV cloned';
    ok      b(\$rv)->ROK,                   '...and is ROK';
    isa_ok  b($rv),         'B::GV',        'GV cloned';
    is      $rv,            \*foo,          '...and is copied';

    SKIP: {
        skip 'globs have no magic', 1 unless $has_mg;
        has_mg  $rv,            '*',            '...with magic';
    }
}

#define PERL_MAGIC_arylen	  '#' /* Array length ($#ary) */
{
    BEGIN { $tests += 4 }

    my @ary = qw/a b c/;
    my $mg  = clone \$#ary;

    has_mg      \$#ary,     '#',            '(sanity check)';
    hasnt_mg    $mg,        '#',            '$#ary loses magic';
    is          $$mg,       $#ary,          '...but keeps value';

    $$mg = 5;

    is          $#ary,      2,              '$#ary preserved';
}

#define PERL_MAGIC_pos		  '.' /* pos() lvalue */
{
    BEGIN { $tests += 4 }

    my $str = 'fffgh';
    $str =~ /f*/g;
    my $mg  = clone \pos($str);

    has_mg      \pos($str), '.',            '(sanity check)';
    hasnt_mg    $mg,        '.',            'pos() loses magic';
    is          $$mg,       pos($str),      '...but keeps value';

    $$mg = 0;

    is          pos($str),  3,              'pos() preserved';
}

#define PERL_MAGIC_backref	  '<' /* for weak ref data */
SKIP: {
    my $skip;
    eval 'use Scalar::Util qw/weaken isweak/; 1'
        or skip 'no weakrefs', $skip;

    {
        BEGIN { $skip += 5 }
        
        # we need to have a real ref to the referent in the cloned
        # structure, otherwise it destructs.

        my $sv    = 5;
        my $weak  = [\$sv, \$sv];
        weaken($weak->[0]);
        my $type  = blessed b \$weak->[0];
        my $rv   = clone $weak;

        isa_ok  b(\$rv->[0]),   $type,      'weakref cloned';
        ok      b(\$rv->[0])->ROK,          '...and a reference';
        ok      isweak($rv->[0]),           '...preserving isweak';
        isnt    $rv->[0],       \$sv,       '...not copied';
        is      ${$rv->[0]},    5,          '...correctly';
    }

    {
        BEGIN { $skip += 6 }

        my $weak = [5, undef];
        $weak->[1] = \$weak->[0];
        weaken($weak->[1]);

        my $type = blessed b \$weak->[0];
        my $rv   = clone $weak;

        isa_ok  b(\$rv->[0]),   $type,      'weak referent cloned';
        isnt    \$rv->[0],      \$weak->[0],    '...not copied';
        ok      isweak($rv->[1]),           '...preserving isweak';
        has_mg  \$weak->[0],    '<',        '(sanity check)';
        has_mg  \$rv->[0],      '<',        '...with magic';
        is      $rv->[0],       5,          '...correctly';
    }

    {
        BEGIN { $skip += 8 }

        my $circ;
        $circ    = \$circ;
        weaken($circ);
        my $type = blessed b \$circ;
        my $rv   = clone \$circ;

        isa_ok  b($rv),         $type,      'weak circular ref cloned';
        ok      b(\$rv)->ROK,               '...and a reference';
        ok      b($rv)->ROK,                '...to a reference';
        has_mg  \$circ,         '<',        '(sanity check)';
        has_mg  $rv,            '<',        '...with magic';
        ok      isweak($$rv),               '...preserving isweak';
        isnt    $$rv,           \$circ,     '...not copied';
        is      $$$rv,          $$rv,       '...correctly';
    }

    BEGIN { $tests += $skip }
}

#define PERL_MAGIC_ext		  '~' /* Available for use by extensions */

BEGIN { plan tests => $tests }
