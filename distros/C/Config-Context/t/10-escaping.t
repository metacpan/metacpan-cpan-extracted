

use strict;
use warnings;

use Test::More 'tests' => 6;
my $Per_Driver_Tests = 2;


use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<'EOF';
    Module = 0
    <Match \.pm$>
        Module = 1
    </Match>

EOF

$Config_Text{'ConfigScoped'} = <<'EOF';
    Module = 0
    Match '\.pm$' {
        Module = 1
    }

EOF

$Config_Text{'XMLSimple'} = <<'EOF';
<opt>
    <Module>0</Module>
    <Match name="\.pm$">
        <Module>1</Module>
    </Match>
   </opt>

EOF

sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name         => 'Match',
                match_type   => 'regex',
                section_type => 'match',
            },
        ],

    );

    my %config;
    %config = $conf->context(
        match   => 'Simple.pm',
    );

    is($config{'Module'},      1, "$driver: [match: Simple.pm] Perl_Module:       1");

    %config = $conf->context(
        match   => 'Simplexpm',
    );
    ok(!$config{'Module'},        "$driver: [match: Simplexpm] Perl_Module:       0");
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
