#!/usr/bin/perl
use strict;


use CGI::Carp qw( fatalsToBrowser );

use Bigtop::Example::Billing qw{ -Engine=CGI -TemplateEngine=TT };

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        dbconn => 'dbi:SLQite:dbname=app.db',
        template_wrapper => 'genwrapper.tt',
        root => 'html',
    },
    locations => {
        '/' => 'Billing',
        '/status' => 'Bigtop::Example::Billing::Status',
        '/company' => 'Bigtop::Example::Billing::Company',
        '/customer' => 'Bigtop::Example::Billing::Customer',
        '/lineitem' => 'Bigtop::Example::Billing::LineItem',
        '/invoice' => 'Bigtop::Example::Billing::Invoice',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
