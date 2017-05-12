#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get basic template, no Metadata
$mech->get_ok('/helloworld', 'Get Hello World page');
is($mech->ct, 'text/html', 'Hello World page content type');
$mech->content_contains('Hello, World!', 'Hello World page content');

$mech->content_lacks('http://extjs.cachefly.net/',
    "pages are using local ExtJS links");

# warn $mech->content;
__END__
