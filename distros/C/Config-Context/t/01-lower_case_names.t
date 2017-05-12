

use strict;
use warnings;
use Carp;

my $Per_Driver_Tests = 5;

use Test::More 'tests' => 10;

use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<EOF;
    <SeCTION    AAA>
        testval foo
    </SEction>
    <SECTION    AAAbbb>
        testval bar
    </section>
    <secTION    AAAbbbccc>
        testval baz
    </sECTION>
EOF

$Config_Text{'ConfigScoped'} = <<EOF;
    SeCTION AAA {
        testval = foo
    }

    SECTION AAAbbb {
        testval = bar
    }

    secTION AAAbbbccc {
        testval = baz
    }
EOF

sub runtests {
    my $driver = shift;
    my ($conf, %config);

    # Without -LowerCaseNames
    $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name       => 'SectION',
                match_type => 'substring',
            },
        ],
    );


    # Config::General and Config::Scoped handle lower case names differently:
    # Config::General: <section FOO>...</section>   => {section}{FOO}
    # Config::Scoped:  section FOO { ... }          => {section}{foo}
    # This affects match strings and the resultant data structure

    my $aaa = 'AAA';
    $aaa = 'aaa' if $driver eq 'ConfigScoped';

    %config = $conf->context('wubba');

    %config = $conf->context($aaa);
    ok(!exists $config{'testval'}, "$driver: case sensitive [aaa] testval:   not exists");


    %config = $conf->context($aaa . 'bbbccc');
    ok(!exists $config{'testval'}, "$driver: case sensitive [aaabbbccc] testval:   not exists");


    # With -LowerCaseNames
    $conf = Config::Context->new(
        driver           => $driver,
        string           => $Config_Text{$driver},
        lower_case_names => 1,
        match_sections   => [
            {
                name       => 'SectION',
                match_type => 'substring',
            },
        ],
    );


    %config = $conf->raw;
    is($config{'section'}{$aaa}{'testval'},   'foo', "$driver: case insensitive [aaa] testval:   foo");


    %config = $conf->context($aaa);
    is($config{'testval'},   'foo', "$driver: case insensitive [aaa] testval:   foo");

    %config = $conf->context($aaa . 'bbbccc');
    is($config{'testval'},   'baz', "$driver: case insensitive [aaabbbccc] testval:   baz");
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
