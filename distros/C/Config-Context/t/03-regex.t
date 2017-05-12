
use strict;
use warnings;

use Test::More 'tests' => 90;

my $Per_Driver_Tests = 30;

use Config::Context;

my %Config_Text;
$Config_Text{'ConfigGeneral'} = <<EOF;

    <FooMatch  a.*>
        sect  = a
        val1  = 1
        secta = 1
    </FooMatch>
    <BarMatch  b.*>
        sect  = b
        val1  = 2
        sectb = 1
    </BarMatch>
    <FooMatch  c.*>
        sect  = c
        val1  = 3
        sectc = 1
    </FooMatch>
    <BarMatch  d.*>
        sect  = d
        val1  = 4
        sectd = 1
    </BarMatch>
    <FooMatch  e.*>
        sect  = e
        val1  = 5
        secte = 1
    </FooMatch>
    <FooMatch  F.*>
        sect   = F(a)
        val1   = 6
        sectFa = 1
    </FooMatch>
    <FooMatch  (?i:F.*)>
        sect   = F(b)
        val1   = 7
        sectFb = 1
    </FooMatch>

EOF

$Config_Text{'ConfigScoped'} = <<EOF;

    FooMatch  'a.*' {
        sect  = a
        val1  = 1
        secta = 1
    }
    BarMatch  'b.*' {
        sect  = b
        val1  = 2
        sectb = 1
    }
    FooMatch  'c.*' {
        sect  = c
        val1  = 3
        sectc = 1
    }
    BarMatch  'd.*' {
        sect  = d
        val1  = 4
        sectd = 1
    }
    FooMatch  'e.*' {
        sect  = e
        val1  = 5
        secte = 1
    }
    FooMatch  'F.*' {
        sect   = 'F(a)'
        val1   = 6
        sectFa = 1
    }
    FooMatch  '(?i:F.*)' {
        sect   = 'F(b)'
        val1   = 7
        sectFb = 1
    }

EOF

$Config_Text{'XMLSimple'} = <<EOF;
<opt>
     <FooMatch name="a.*">
         <sect>a</sect>
         <val1>1</val1>
         <secta>1</secta>
     </FooMatch>
     <BarMatch name="b.*">
         <sect>b</sect>
         <val1>2</val1>
         <sectb>1</sectb>
     </BarMatch>
     <FooMatch name="c.*">
         <sect>c</sect>
         <val1>3</val1>
         <sectc>1</sectc>
     </FooMatch>
     <BarMatch name="d.*">
         <sect>d</sect>
         <val1>4</val1>
         <sectd>1</sectd>
     </BarMatch>
     <FooMatch name="e.*">
         <sect>e</sect>
         <val1>5</val1>
         <secte>1</secte>
     </FooMatch>
     <FooMatch name="F.*">
         <sect>F(a)</sect>
         <val1>6</val1>
         <sectFa>1</sectFa>
     </FooMatch>
     <FooMatch name="(?i:F.*)">
         <sect>F(b)</sect>
         <val1>7</val1>
         <sectFb>1</sectFb>
     </FooMatch>
    </opt>

EOF

sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name           => 'FooMatch',
                match_type     => 'regex',
                merge_priority => 1,
            },
            {
                name           => 'BarMatch',
                match_type     => 'regex',
                merge_priority => 2,
            },
        ],
    );

    my %config;

    %config = $conf->context('abcd');
    # [Section] match (chars): value
    # [Foo] c(2): 3
    # [Foo] a(4): 1
    # [Bar] d(1): 4
    # [Bar] b(3): 2

    is($config{'sect'},    'b',         "$driver: [abcd] sect:    b");
    is($config{'val1'},    2,           "$driver: [abcd] val1:    2");
    is($config{'secta'},   1,           "$driver: [abcd] secta:   1");
    is($config{'sectb'},   1,           "$driver: [abcd] sectb:   1");
    is($config{'sectc'},   1,           "$driver: [abcd] sectc:   1");
    is($config{'sectd'},   1,           "$driver: [abcd] sectd:   1");
    ok(!exists $config{'secte'},        "$driver: [abcd] secte:   not present");

    %config = $conf->context('a');
    # [Section] match (chars): value
    # [Foo] a(1): 1
    #
    is($config{'sect'},    'a',         "$driver: [a] sect:    a");
    is($config{'val1'},    1,           "$driver: [a] val1:    1");
    is($config{'secta'},   1,           "$driver: [a] secta:   1");
    ok(!exists $config{'sectb'},        "$driver: [a] sectb:   not present");
    ok(!exists $config{'sectc'},        "$driver: [a] sectc:   not present");
    ok(!exists $config{'sectd'},        "$driver: [a] sectd:   not present");
    ok(!exists $config{'secte'},        "$driver: [a] secte:   not present");

    %config = $conf->context('cad');
    # [Section] match (chars): value
    # [Foo] a(2): 1
    # [Foo] c(3): 3
    # [Bar] d(1): 4
    is($config{'sect'},    'd',         "$driver: [cad] sect:    d");
    is($config{'val1'},    4,           "$driver: [cad] val1:    4");
    is($config{'secta'},   1,           "$driver: [cad] secta:   1");
    ok(!exists $config{'sectb'},        "$driver: [cad] sectb:   not present");
    is($config{'sectc'},   1,           "$driver: [cad] sectc:   1");
    is($config{'sectd'},   1,           "$driver: [cad] sectd:   1");
    ok(!exists $config{'secte'},        "$driver: [cad] secte:   not present");


    %config = $conf->context('foo');
    # Case insensitive matching
    # [Section] match (chars): value
    # [Foo] f(3): 7
    is($config{'sect'},    'F(b)',      "$driver: [foo] sect:      F(b)");
    is($config{'val1'},    7,           "$driver: [foo] val1:      7");
    ok(!exists $config{'secta'},        "$driver: [foo] secta:     not present");
    ok(!exists $config{'sectb'},        "$driver: [foo] sectb:     not present");
    ok(!exists $config{'sectc'},        "$driver: [foo] sectc:     not present");
    ok(!exists $config{'sectd'},        "$driver: [foo] sectd:     not present");
    ok(!exists $config{'secte'},        "$driver: [foo] secte:     not present");
    ok(!exists $config{'sectFa'},       "$driver: [foo] sectFa:    not present");
    is($config{'sectFb'},   1,          "$driver: [foo] sectFb:    1");
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

