
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 11;

use Class::DBI::FormBuilder::DBI::Test;

{
    # Fake a submission request
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{QUERY_STRING}   = 'flooble=5&flump=dump&poo=shmoo&_submitted=1';
    
    my $data = { flooble => 5,
                 flump   => 'dump',
                 poo   => 'shmoo',
                 #wooble     => undef,   # pk
                 };
                 
    my $form = Wackypk->as_form; # ( debug => 3 );
    
    my $html;
    
    lives_ok { $html = $form->render };
    
    #
    # 'no' pk in form
    #
    unlike( $html, qr(var wooble) );
    unlike( $html, qr(\Q<input id="wooble" name="wooble" type="hidden" />) );
    unlike( $html, qr(name="wooble") );
    
    isa_ok( $form, 'CGI::FormBuilder' );

    is_deeply( scalar $form->field, $data );
    
    #
    # undef pk in create data
    #
    is_deeply( Class::DBI::FormBuilder->_fb_create_data( 'Wackypk', $form ), $data );
    
    ok( $form->validate );
    
    my $obj;
    lives_ok { $obj = Wackypk->create_from_form( $form ) } 'create_from_form';
    
    isa_ok( $obj, 'Class::DBI' );
    
    my $id = $obj->id;
    
    is( $id, 1 ); 
    
}    
