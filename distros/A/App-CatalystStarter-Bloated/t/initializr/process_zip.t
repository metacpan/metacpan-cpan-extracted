#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Test::Most;
use Test::FailWarnings;

use lib 't/lib';
use TestUtils;

use_ok "App::CatalystStarter::Bloated::Initializr";

*az = *App::CatalystStarter::Bloated::Initializr::_az;

## some basic functions for control and setup

note( "zip setup and safely check tests" );

is( az(), undef, "az undef before init" );

throws_ok { App::CatalystStarter::Bloated::Initializr::_require_az() }
    qr/^\Qaz object not initialized/, "az check dies as expected before init";

isa_ok(
    App::CatalystStarter::Bloated::Initializr::_set_az_from_cache(),
    "Archive::Zip"
);

isa_ok( az(), "Archive::Zip",
        "az after init" );

lives_ok { App::CatalystStarter::Bloated::Initializr::_require_az() }
    "az check lives after init";

note( "zip accessor tests" );

## search one

*search_one = *App::CatalystStarter::Bloated::Initializr::_safely_search_one_member;

throws_ok { search_one(qr/./) }
    qr/^\QFound 0 or more than one zip member match for/,
    "safe search dies on > 1 matches";

throws_ok { search_one(qr/THIS SHOULD NOT BE IN ANY OF THE ZIP MEMBERS/) }
    qr/^\QFound 0 or more than one zip member match for/,
    "a non matching qr also dies";

lives_ok { search_one(qr/THIS SHOULD NOT BE IN ANY OF THE ZIP MEMBERS/, 1) }
    "a non matching qr lives when allowed to";

isa_ok( search_one( qr(^initializr/index\.html$) ), "Archive::Zip::Member",
        "index.html" );

## content related

note( "zipped content handling" );

*content = *App::CatalystStarter::Bloated::Initializr::_zip_content;

like( my $c0 = content( qr(/main.css$) ), qr/Author's custom styles/, "content check" );

is( $c0, content( qr(/main.css$)), "content not changed with no 2nd argument" );

lives_ok {content( qr(/main.css$), "/* new css file content /*\n" )}
    "zip member content can beupdated";

is( content( qr(/main.css$)), "/* new css file content /*\n",
    "new content reflected in zip" );

lives_ok {content( qr(/main.css$), $c0 )} "original content can inserted";

is( content( qr(/main.css$)), $c0, "original reflected in zip" );

## accessor related functions

note( "zip member particulars" );

# isa_ok( my $index = App::CatalystStarter::Bloated::Initializr::_index_dom(),
#         "Mojo::DOM" );

## higher level function

note( "HIGH LEVEL FUNCTIONS" );


## setup index
note( "mangle index.html into wrapper.tt2" );

lives_ok {App::CatalystStarter::Bloated::Initializr::_setup_index()}
    "index process complets alive";

## check that index.html doesn't exist
## (should be renamed to wrapper.tt2 by now)
is( search_one( qr/index\.html$/, 1), undef, "index.html not in archive" );

ok( search_one( qr/wrapper\.tt2$/ ), "wrapper.tt2 *is* in archive" );

## sanity checks on wrapper

my $w = content( qr/wrapper\.tt2$/ );

like( $w, qr(<!DOCTYPE html>), "wrapper contains doctype html" );
like( $w, qr([% content %]), "wrapper contains content tt var" );
like( $w, qr([% jumbotron %]), "wrapper contains jumbotron tt var" );

unlike( $w, qr{"js/}, "no attributes that start with js/ in the html" );
unlike( $w, qr{"css/}, "no attributes that start with css/ in the html" );
unlike( $w, qr{"(?:img|images)/}, "no attributes that start with img/ or images/ in the html" );

## check that img/ is now images/

note( "moves img/ members to static/images/" );

lives_ok {App::CatalystStarter::Bloated::Initializr::_move_images()}
    "changing img/ to images/ lives";

is( search_one( qr(^/img/), 1 ), undef, "no img/ members found in zip" );

## might be just an empty dir, so ">="
cmp_ok( az()->membersMatching( qr{/static/images/} ), ">=", 1,
    "several */static/images/ found in archive" );

## change css and js to /static/(css|js)/ , and also fonts

note( "moves js/, css/ and fonts/ members to static/*" );

lives_ok {App::CatalystStarter::Bloated::Initializr::_move_css_js_fonts()}
    "putting js and css and fonts under static/ lives";

## we know for sure that there should be more than just an empty dir, so '>'
cmp_ok( az()->membersMatching( qr{/static/css/} ), ">", 1,
    "several */static/css members found in archive" );
cmp_ok( az()->membersMatching( qr{/static/js/} ), ">", 1,
    "several */static/js members found in archive" );
cmp_ok( az()->membersMatching( qr{/static/fonts/} ), ">", 1,
    "several */static/fonts members found in archive" );

done_testing;
