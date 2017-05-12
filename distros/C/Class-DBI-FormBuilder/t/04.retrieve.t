
use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;


    
if ( ! require DBD::SQLite2 ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

#plan tests => 5;

use Class::DBI::FormBuilder::DBI::Test; # also includes Bar


{
    # Fake an update request, and supply a non-existant id
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{QUERY_STRING}   = "id=99999&_submitted=1";
    
    my $form = Person->as_form;
    
    is_deeply( scalar $form->field, { street => undef,
                                      name   => undef,
                                      town   => undef,
                                      #id     => 99999,
                                      toys    => undef,
                                      job => undef,
                                      } );
    
    my $obj;
    lives_ok { $obj = Person->retrieve_from_form( $form ) };
    
    
    ok( ! $obj, 'no such object' );
    
    
}    
    
