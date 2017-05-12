#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN {
    $ENV{AUTOCRUD_DEBUG} = 1;
    use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp"
}
my $mech = Test::WWW::Mechanize::Catalyst->new;

# these are tests for plugging AutoCRUD into applications with
# their own TT and RenderView installations, other controller actions.

# get test page from TestApp TT View
$mech->get_ok('/testpage', 'Get Test page');
is($mech->ct, 'text/html', 'Test page content type');
$mech->content_contains('This is a test', 'Test Page content');

# can stil get hello world from AutoCRUD TT View
$mech->get_ok('/helloworld', 'Get Hello World page');
is($mech->ct, 'text/html', 'Hello World page content type');
$mech->content_contains('Hello, World!', 'Hello World (View TT) page content');

# can still use AutoCRUD JSON View
$mech->get_ok('/site/default/schema/dbic/source/album/dumpmeta', 'AJAX (View JSON) also works');
is( $mech->ct, 'application/json', 'Metadata content type' );
# $mech->content_contains('"model":"AutoCRUD::DBIC::Album","table_info":', 'AJAX data content');

#warn $mech->content;
__END__
