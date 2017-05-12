
use strict;
use warnings;

use Test::More tests => 114;
my $Per_Driver_Tests = 38;

use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<EOF;

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

$Config_Text{'ConfigScoped'} = <<EOF;

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

$Config_Text{'XMLSimple'} = <<EOF;
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

my $Raw_Config = {
    'SectA' => {
        "bbb" => {
            testval_a   => 4,
            testval_b   => 4,
            testval_c   => 4,
            testval_bbb => 4,
        },
    },
    'SectC' => {
        "bbb" => {
            testval_c    => 5,
            testval_Cbbb => 5,
        },
    },
    'SectB' => {
        "aaabbbccc" => {
            testval_a         => 3,
            testval_b         => 3,
            testval_c         => 3,
            testval_aaabbbccc => 3,
        },
        "aaa" => {
            testval_a   => 1,
            testval_b   => 1,
            testval_c   => 1,
            testval_aaa => 1,
        },
        "aaabbb" => {
            testval_a      => 2,
            testval_b      => 2,
            testval_c      => 2,
            testval_aaabbb => 2,
        },
    },

};

sub runtests {
    my $driver = shift;

    my @match_sections   = (
        {
            name       => 'SectA',
            match_type => 'substring',
        },
        {
            name       => 'SectB',
            match_type => 'substring',
        },
        {
            name           => 'SectC',
            match_type     => 'substring',
            merge_priority => 10,
        },
    );


    my $conf = Config::Context->new(
        driver           => $driver,
        string           => $Config_Text{$driver},
        match_sections   => \@match_sections,
    );

    my $raw_conf = Config::Context->new(
        config           => $Raw_Config,
        match_sections   => \@match_sections,
    );

    my %config;

    %config = $conf->context('wubba');

    is_deeply(scalar($raw_conf->raw), scalar($conf->raw), 'Config from datastructure same as config from string');
    is_deeply(scalar($raw_conf->context('wubba')), scalar($conf->context('wubba')), 'context config from datastructure same as config from string');


    ok (!keys %config, "$driver: wubba: no match");

    %config = $conf->context('aaa');
    # aaa(1)
    is($config{'testval_a'},   1,        "$driver: [aaa] testval_a:    1");
    is($config{'testval_b'},   1,        "$driver: [aaa] testval_b:    1");
    is($config{'testval_c'},   1,        "$driver: [aaa] testval_c:    1");
    is($config{'testval_aaa'}, 1,        "$driver: [aaa] testval_aaa:  1");
    ok(! exists $config{'testval_bbb'},  "$driver: [aaa] testval_bbb:  not exists");
    ok(! exists $config{'testval_Cbbb'}, "$driver: [aaa] testval_Cbbb: not exists");

    %config = $conf->context('aaabbbccc');
    # aaa(1), bbb(4), aaabbb(2), aaabbbccc(3), bbb(5)
    is($config{'testval_a'},         3, "$driver: [aaabbbccc] testval_a:         3");
    is($config{'testval_b'},         3, "$driver: [aaabbbccc] testval_b:         3");
    is($config{'testval_c'},         5, "$driver: [aaabbbccc] testval_c:         5");
    is($config{'testval_aaa'},       1, "$driver: [aaabbbccc] testval_aaa:       1");
    is($config{'testval_bbb'},       4, "$driver: [aaabbbccc] testval_bbb:       4");
    is($config{'testval_Cbbb'},      5, "$driver: [aaabbbccc] testval_Cbbb:      5");
    is($config{'testval_aaabbb'},    2, "$driver: [aaabbbccc] testval_aaabbb:    2");
    is($config{'testval_aaabbbccc'}, 3, "$driver: [aaabbbccc] testval_aaabbbccc: 3");


    %config = $conf->context('xxxaaabbbcccxxx');
    # aaa(1), bbb(4), aaabbb(2), aaabbbccc(3), bbb(5)
    is($config{'testval_a'},         3, "$driver: [xxxaaabbbcccxxx] testval_a:         3");
    is($config{'testval_b'},         3, "$driver: [xxxaaabbbcccxxx] testval_b:         3");
    is($config{'testval_c'},         5, "$driver: [xxxaaabbbcccxxx] testval_b:         5");
    is($config{'testval_aaa'},       1, "$driver: [xxxaaabbbcccxxx] testval_aaa:       1");
    is($config{'testval_bbb'},       4, "$driver: [aaabbbccc] testval_bbb:             4");
    is($config{'testval_Cbbb'},      5, "$driver: [aaabbbccc] testval_Cbbb:            5");
    is($config{'testval_aaabbb'},    2, "$driver: [xxxaaabbbcccxxx] testval_aaabbb:    2");
    is($config{'testval_aaabbbccc'}, 3, "$driver: [xxxaaabbbcccxxx] testval_aaabbbccc: 3");

    %config = $conf->context('bbbccc');
    # bbb(4), bbb(5)
    is($config{'testval_a'},         4, "$driver: [bbbccc] testval_a:         4");
    is($config{'testval_b'},         4, "$driver: [bbbccc] testval_b:         4");
    is($config{'testval_c'},         5, "$driver: [bbbccc] testval_c:         5");
    is($config{'testval_bbb'},       4, "$driver: [bbbccc] testval_c:         4");
    is($config{'testval_Cbbb'},      5, "$driver: [bbbccc] testval_c:         5");


    %config = $conf->context('cccxxxaaaxxxaaabbbxxx');
    # aaa(1), bbb(4), aaabbb(2), bbb(5)
    is($config{'testval_a'},         2,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_a:         2");
    is($config{'testval_b'},         2,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_b:         2");
    is($config{'testval_c'},         5,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_b:         5");
    is($config{'testval_aaa'},       1,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_aaa:       1");
    is($config{'testval_bbb'},       4,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_bbb:       4");
    is($config{'testval_Cbbb'},      5,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_Cbbb:      5");
    is($config{'testval_aaabbb'},    2,       "$driver: [cccxxxaaaxxxaaabbbxxx] testval_aaabbb:    2");
    ok(! exists $config{'testval_aaabbbccc'}, "$driver: [cccxxxaaaxxxaaabbbxxx] testval_aaabbbccc: not exists");

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

