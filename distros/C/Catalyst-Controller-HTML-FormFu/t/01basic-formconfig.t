use strict;
use warnings;

use Test::More tests => 12;

use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/basic/formconfig');

{
    # test __uri_for()__ set in config file

    like( $mech->response->content, qr{<label>[^<]+/uri_for</label>} );
}

my ($form) = $mech->forms;

ok($form);

ok( $form->find_input('basic_formconfig') );

my $uri = $form->action;

{
    $mech->post_ok( $uri, { unknown_field => 'foo' } );
    
    $mech->content_contains('<p>not submitted, render</p>');
}

{
    $mech->post_ok( $uri, { submit => 'foo' } );
    
    $mech->content_contains('<p>submitted, not valid, render</p>');
}

{
    $mech->post_ok( $uri, { basic_formconfig => '' } );
    
    $mech->content_contains('<p>submitted, not valid, render</p>');
}

{
    $mech->post_ok( $uri, { basic_formconfig => 'foo' } );
    
    $mech->content_contains('<p>submitted, valid</p>');
}
