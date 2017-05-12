#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;
use Path::Tiny;

use_ok "App::CatalystStarter::Bloated", ":test";

use lib 't/lib';
use TestUtils;

local %ARGV = test_argv;

goto_test_dir;

if ( system_has_catalyst ) {
    App::CatalystStarter::Bloated::_mk_app();
}
else {
    fake_mk_app;
}

App::CatalystStarter::Bloated::_create_TT();

test_dir( cat_name(), "lib", cat_name(), "Controller", "Foo.pm" )->touch;
test_dir( cat_name(), "lib", cat_name(), "Controller", "Bar.pm" )->touch;
test_dir( cat_name(), "lib", cat_name(), "View", "Bar.pm" )->touch;
test_dir( cat_name(), "lib", cat_name(), "View", "Baz.pm" )->touch;
test_dir( cat_name(), "lib", cat_name(), "Model", "Baz.pm" )->touch;
test_dir( cat_name(), "lib", cat_name(), "Model", "Foo.pm" )->touch;

is(
    App::CatalystStarter::Bloated::_catalyst_path( "scripts" )->relative( proj_dir ),
    test_dir( cat_name(), "scripts" )->relative( proj_dir ),
    "path to scripts"
);

# scripts dir
is(
    App::CatalystStarter::Bloated::_catalyst_path( "scripts" )->relative( proj_dir ),
    test_dir( cat_name(), "scripts" )->relative( proj_dir ),
    "path to scripts"
);

subtest "path to controller" => sub {

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "C", "Foo.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "Controller", "Foo.pm")->relative( proj_dir ),
        "path to Foo.pm controller"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "C", "Bar.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "Controller", "Bar.pm")->relative( proj_dir ),
        "Bar.pm controller"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "C", "Root.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "Controller", "Root.pm")->relative( proj_dir ),
        "Root.pm controller"
    );

};

subtest "path to model" => sub {

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "M", "Baz.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "Model", "Baz.pm")->relative( proj_dir ),
        "path to Baz.pm model"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "M", "Foo.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "Model", "Foo.pm")->relative( proj_dir ),
        "Foo.pm model"
    );

};

subtest "path to view" => sub {

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "V", "HTML.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "HTML.pm")->relative( proj_dir ),
        "path to HTML.pm view"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "V", "Bar.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "Bar.pm")->relative( proj_dir ),
        "path to Bar.pm view"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "V", "Bar.pm" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "Bar.pm")->relative( proj_dir ),
        "Bar.pm view"
    );

};

$ARGV{"--TT"} = "Bar";

subtest "path to TT" => sub {

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "TT" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "Bar.pm")->relative( proj_dir ),
        "path to Bar.pm view using TT"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "TT", "gar", "bage" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "Bar.pm")->relative( proj_dir ),
        "path to TT, trailing garbage removed"
    );

};

$ARGV{"--JSON"} = "Baz";

subtest "path to JSON" => sub {

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "JSON" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "Baz.pm")->relative( proj_dir ),
        "path to Baz.pm view using JSON"
    );

    is(
        App::CatalystStarter::Bloated::_catalyst_path
              ( "JSON", "gar", "bage" )->relative( proj_dir ),
        test_dir(cat_name(), "lib", cat_name(),
                 "View", "Baz.pm")->relative( proj_dir ),
        "path to JSON, trailing garbage removed"
    );

};

clean_cat_dir;

done_testing;
