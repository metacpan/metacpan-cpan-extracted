#!/alternate/bin/perl
use strict;


use CGI::Carp qw( fatalsToBrowser );

use AddressBook qw{
    -Engine=CGI
    -TemplateEngine=TT
};

use Gantry::Engine::CGI;

my $cgi = Gantry::Engine::CGI->new( {
    config => {
        GantryConfInstance => 'addressbook_CGI',
        GantryConfFile => 'docs/app.gantry.conf',
    },
    locations => {
        '/' => 'AddressBook',
        '/family' => 'AddressBook::Family',
        '/child' => 'AddressBook::Child',
    },
} );

$cgi->dispatch();

if ( $cgi->{config}{debug} ) {
    foreach ( sort { $a cmp $b } keys %ENV ) {
        print "$_ $ENV{$_}<br />\n";
    }
}
