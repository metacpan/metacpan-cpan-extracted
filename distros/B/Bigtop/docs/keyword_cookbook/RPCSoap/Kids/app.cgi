#!/usr/bin/perl
use strict;


use CGI::Carp qw( fatalsToBrowser );

use Kids qw{
    -Engine=CGI
    -TemplateEngine=TT
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        GantryConfInstance => 'kids',

    },
    locations => {
        '/' => 'Kids',
        '/little/rascals' => 'Kids::Child',
        '/soap' => 'Kids::Soap',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
