#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN {
    use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp"
}
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get basic template, no Metadata
$mech->get_ok('/', 'Get home page');
$mech->content_contains(q{content="text/html; charset=utf-8"}, 'default charset');

# warn $mech->content;
__END__
