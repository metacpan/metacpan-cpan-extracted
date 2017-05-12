#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use HTML::TreeBuilder;

eval('require Catalyst::Test' );
if ( $@ ) {
    plan 'skip_all' => 'No Catalyst::Test' ;
    exit;
}
else {
    plan 'tests' => 5;
}


use_ok( 'TestApp', 'Can use basic test app' );

eval(qq{ use Catalyst::Test 'TestApp'; } );


# Make a request to analyse:
request( 'index.html' );
my $index_html = get( 'index.html' );

# did that at least render some HTML?
ok( $index_html, 'Basic test app produced some HTML' );

my $tree = HTML::TreeBuilder->new_from_content( $index_html );

# Check that the heading from the skeleton is present:
ok( scalar $tree->look_down( _tag => 'h1'), 'Got the heading from skeleton' );

# Check that something from the meat is present:
ok( scalar $tree->look_down( id => 'name'), 'Got the name from meat' );

# Check that we processed the meat by replacing "name"
is( $tree->look_down( id => 'name' )->as_text, 'REPLACED',
   'We replaced text in the meat' );
