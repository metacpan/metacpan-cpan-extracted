#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/html_charset.conf';
    use_ok "Test::WWW::Mechanize::Catalyst" => "TestAppCustomConfig"
}
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get basic template, no Metadata
$mech->get_ok('/autocrud', 'Get home page');
$mech->content_contains(q{content="text/html; charset=iso-8859-1"}, 'custom charset');

# warn $mech->content;
__END__
