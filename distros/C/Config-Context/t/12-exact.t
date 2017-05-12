
use strict;
use warnings;

use Test::More 'tests' => 93;
my $Per_Driver_Tests = 31;

use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<'EOF';

    <SectA bbb>
        testval_a         = 4
        testval_b         = 4
        testval_c         = 4
        testval_bbb       = 4
    </SectA bbb>

    <SectC bbb>
        testval_c         = 5
        testval_Cbbb      = 5
    </SectC bbb>

    <SectB    aaabbbccc>
        testval_a         = 3
        testval_b         = 3
        testval_c         = 3
        testval_aaabbbccc = 3
    </SectB>

    <SectB    aaa>
        testval_a   = 1
        testval_b   = 1
        testval_c   = 1
        testval_aaa = 1
    </SectB>

    <SectB    aaabbb>
        testval_a      = 2
        testval_b      = 2
        testval_c      = 2
        testval_aaabbb = 2
    </SectB>

EOF

$Config_Text{'ConfigScoped'} = <<'EOF';

    SectA bbb {
        testval_a         = 4
        testval_b         = 4
        testval_c         = 4
        testval_bbb       = 4
    }

    SectC bbb {
        testval_c         = 5
        testval_Cbbb      = 5
    }

    SectB    aaabbbccc {
        testval_a         = 3
        testval_b         = 3
        testval_c         = 3
        testval_aaabbbccc = 3
    }

    SectB    aaa {
        testval_a   = 1
        testval_b   = 1
        testval_c   = 1
        testval_aaa = 1
    }

    SectB    aaabbb {
        testval_a      = 2
        testval_b      = 2
        testval_c      = 2
        testval_aaabbb = 2
    }

EOF
$Config_Text{'XMLSimple'} = <<'EOF';
<opt>
    <SectA name="bbb">
        <testval_a>4</testval_a>
        <testval_b>4</testval_b>
        <testval_c>4</testval_c>
        <testval_bbb>4</testval_bbb>
    </SectA>

    <SectC name="bbb">
        <testval_c>5</testval_c>
        <testval_Cbbb>5</testval_Cbbb>
    </SectC>

    <SectB name="aaabbbccc">
        <testval_a>3</testval_a>
        <testval_b>3</testval_b>
        <testval_c>3</testval_c>
        <testval_aaabbbccc>3</testval_aaabbbccc>
    </SectB>

    <SectB name="aaa">
        <testval_a>1</testval_a>
        <testval_b>1</testval_b>
        <testval_c>1</testval_c>
        <testval_aaa>1</testval_aaa>
    </SectB>

    <SectB name="aaabbb">
        <testval_a>2</testval_a>
        <testval_b>2</testval_b>
        <testval_c>2</testval_c>
        <testval_aaabbb>2</testval_aaabbb>
    </SectB>
    </opt>

EOF

sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name       => 'SectA',
                match_type => 'exact',
            },
            {
                name       => 'SectB',
                match_type => 'exact',
            },
            {
                name           => 'SectC',
                match_type     => 'exact',
                merge_priority => 10,
            },
        ],
    );

    my %config;

    %config = $conf->context('wubba');

    ok (!keys %config, 'wubba: no match');

    %config = $conf->context('aaa');
    # aaa(1)
    is($config{'testval_a'},   1,        "$driver: [aaa] testval_a:    1");
    is($config{'testval_b'},   1,        "$driver: [aaa] testval_b:    1");
    is($config{'testval_c'},   1,        "$driver: [aaa] testval_c:    1");
    is($config{'testval_aaa'}, 1,        "$driver: [aaa] testval_aaa:  1");
    ok(! exists $config{'testval_bbb'},  "$driver: [aaa] testval_bbb:  not exists");
    ok(! exists $config{'testval_Cbbb'}, "$driver: [aaa] testval_Cbbb: not exists");

    %config = $conf->context('aaabbbccc');
    # aaabbbccc(3)
    is($config{'testval_a'},         3,       "$driver: [aaabbbccc] testval_a:         3");
    is($config{'testval_b'},         3,       "$driver: [aaabbbccc] testval_b:         3");
    is($config{'testval_c'},         3,       "$driver: [aaabbbccc] testval_c:         3");
    is($config{'testval_aaabbbccc'}, 3,       "$driver: [aaabbbccc] testval_aaabbbccc: 3");
    ok(! exists $config{'testval_aaa'},       "$driver: [aaabbbccc] testval_aaa:       not exists");
    ok(! exists $config{'testval_bbb'},       "$driver: [aaabbbccc] testval_bbb:       not exists");
    ok(! exists $config{'testval_Cbbb'},      "$driver: [aaabbbccc] testval_Cbbb:      not exists");
    ok(! exists $config{'testval_aaabbb'},    "$driver: [aaabbbccc] testval_aaabbb:    not exists");

    %config = $conf->context('xxxaaabbbcccxxx');
    # no match
    ok(! exists $config{'testval_a'},         "$driver: [xxxaaabbbcccxxx] testval_a:         not exists");
    ok(! exists $config{'testval_b'},         "$driver: [xxxaaabbbcccxxx] testval_b:         not exists");
    ok(! exists $config{'testval_c'},         "$driver: [xxxaaabbbcccxxx] testval_c:         not exists");
    ok(! exists $config{'testval_aaa'},       "$driver: [xxxaaabbbcccxxx] testval_aaa:       not exists");
    ok(! exists $config{'testval_bbb'},       "$driver: [xxxaaabbbcccxxx] testval_bbb:       not exists");
    ok(! exists $config{'testval_Cbbb'},      "$driver: [xxxaaabbbcccxxx] testval_Cbbb:      not exists");
    ok(! exists $config{'testval_aaabbb'},    "$driver: [xxxaaabbbcccxxx] testval_aaabbb:    not exists");
    ok(! exists $config{'testval_aaabbbccc'}, "$driver: [xxxaaabbbcccxxx] testval_aaabbbccc: not exists");

    %config = $conf->context('bbbccc');
    # no match
    ok(! exists $config{'testval_a'},         "$driver: [bbbccc] testval_a:         not exists");
    ok(! exists $config{'testval_b'},         "$driver: [bbbccc] testval_b:         not exists");
    ok(! exists $config{'testval_c'},         "$driver: [bbbccc] testval_c:         not exists");
    ok(! exists $config{'testval_aaa'},       "$driver: [bbbccc] testval_aaa:       not exists");
    ok(! exists $config{'testval_bbb'},       "$driver: [bbbccc] testval_bbb:       not exists");
    ok(! exists $config{'testval_Cbbb'},      "$driver: [bbbccc] testval_Cbbb:      not exists");
    ok(! exists $config{'testval_aaabbb'},    "$driver: [bbbccc] testval_aaabbb:    not exists");
    ok(! exists $config{'testval_aaabbbccc'}, "$driver: [bbbccc] testval_aaabbbccc: not exists");
}




SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        runtests('ConfigGeneral');
    }
    else {
        skip "Config::General not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        runtests('ConfigScoped');
    }
    else {
        skip "Config::Scoped not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        runtests('XMLSimple');
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", $Per_Driver_Tests;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}
