
use strict;
use warnings;

use Test::More 'tests' => 93;
my $Per_Driver_Tests = 31;

use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<EOF;

    <Path /foo>
        val  = 1
        sect = foo
        foo  = 1
    </Path>

    <Location /foo/bar>
        val    = 2
        sect   = foobar
        foobar = 1
    </Location>

    <Path /foo/bar/baz>
        val       = 3
        sect      = foobarbaz
        foobarbaz = 1
    </Path>

EOF

$Config_Text{'ConfigScoped'} = <<EOF;

    Path /foo {
        val  = 1
        sect = foo
        foo  = 1
    }

    Location /foo/bar {
        val    = 2
        sect   = foobar
        foobar = 1
    }

    Path /foo/bar/baz {
        val       = 3
        sect      = foobarbaz
        foobarbaz = 1
    }

EOF

$Config_Text{'XMLSimple'} = <<EOF;
<opt>
     <Path name="/foo">
         <val>1</val>
         <sect>foo</sect>
         <foo>1</foo>
     </Path>

     <Location name="/foo/bar">
         <val>2</val>
         <sect>foobar</sect>
         <foobar>1</foobar>
     </Location>

     <Path name="/foo/bar/baz">
         <val>3</val>
         <sect>foobarbaz</sect>
         <foobarbaz>1</foobarbaz>
     </Path>
    </opt>

EOF

sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name           => 'Location',
                match_type     => 'path',
                merge_priority => 1,
            },
            {
                name           => 'Path',
                match_type     => 'path',
                merge_priority => 2,
            },
        ],
    );

    my %config;

    %config = $conf->context('/foo');
    # /foo (1)
    is($config{'sect'},       'foo',  "$driver: [/foo] sect:      foo");
    is($config{'val'},        1,      "$driver: [/foo] val:       1");
    is($config{'foo'},        1,      "$driver: [/foo] foo:       1");
    ok(!exists $config{'foobar'},     "$driver: [/foo] foobar:    not present");
    ok(!exists $config{'foobarbaz'},  "$driver: [/foo] foobarbaz: not present");

    %config = $conf->context('/foo/');
    # /foo (1)
    is($config{'sect'},       'foo',  "$driver: [/foo/] sect:      foo");
    is($config{'val'},        1,      "$driver: [/foo/] val:       1");
    is($config{'foo'},        1,      "$driver: [/foo/] foo:       1");
    ok(!exists $config{'foobar'},     "$driver: [/foo/] foobar:    not present");
    ok(!exists $config{'foobarbaz'},  "$driver: [/foo/] foobarbaz: not present");

    %config = $conf->context('/foo/bar');
    # /foo/bar (2), /foo (1)
    is($config{'sect'},       'foo',  "$driver: [/foo/bar] sect:      foo");
    is($config{'val'},        1,      "$driver: [/foo/bar] val:       1");
    is($config{'foo'},        1,      "$driver: [/foo/bar] foo:       1");
    is($config{'foobar'},     1,      "$driver: [/foo/bar] foobar:    1");
    ok(!exists $config{'foobarbaz'},  "$driver: [/foo/bar] foobarbaz: not present");

    %config = $conf->context('/foo/bar.txt');
    # /foo (1)
    is($config{'sect'},       'foo',  "$driver: [/foo/bar.txt] sect:      foo");
    is($config{'val'},        1,      "$driver: [/foo/bar.txt] val:       1");
    is($config{'foo'},        1,      "$driver: [/foo/bar.txt] foo:       1");
    ok(!exists $config{'foobar'},     "$driver: [/foo/bar.txt] foobar:    not present");
    ok(!exists $config{'foobarbaz'},  "$driver: [/foo/bar.txt] foobarbaz: not present");

    %config = $conf->context('/foo/bar/baz/boom.txt');
    # /foo/bar     (2)
    # /foo         (1)
    # /foo/bar/baz (3)
    is($config{'sect'},       'foobarbaz',  "$driver: [/foo/bar/baz/boom.txt] sect:      foobarbaz");
    is($config{'val'},        3,            "$driver: [/foo/bar/baz/boom.txt] val:       3");
    is($config{'foo'},        1,            "$driver: [/foo/bar/baz/boom.txt] foo:       1");
    is($config{'foobar'},     1,            "$driver: [/foo/bar/baz/boom.txt] foobar:    1");
    is($config{'foobarbaz'},  1,            "$driver: [/foo/bar/baz/boom.txt] foobarbaz: 1");


    # No matches
    %config = $conf->context('/foo.txt');
    ok (!keys %config, "$driver: /foo.txt: no match");

    %config = $conf->context('foo');
    ok (!keys %config, "$driver: foo: no match");

    %config = $conf->context('foo/bar');
    ok (!keys %config, "$driver: foo: no match");

    %config = $conf->context('foo.txt');
    ok (!keys %config, "$driver: foo.txt: no match");

    %config = $conf->context('/food');
    ok (!keys %config, "$driver: /food: no match");

    %config = $conf->context('/food/bar.txt');
    ok (!keys %config, "$driver: /food/bar.txt: no match");
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
