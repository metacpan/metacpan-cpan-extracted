#!perl -T

use 5.006;

use strict;
use warnings;

use Test::More tests => 1;
use HTTP::Request::Common;

{
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::Tail;

    get '/' => sub {'OK'};
}

my $app = MyApp->to_app;
isa_ok( $app, 'CODE' );

diag( "Testing Dancer2::Plugin::Tail $Dancer2::Plugin::Tail::VERSION, Perl $], $^X" );

