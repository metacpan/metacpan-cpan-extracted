
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 5;


use Class::DBI::FormBuilder::DBI::Test; # also includes Bar

# ------------------------------------------------------------------------
{
    # Fake an update request, and supply an id (assume first object inserted 
    # in 01.create.t has id = 1)
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{QUERY_STRING}   = "id=1&_submitted=1";
    
    my $form = Person->as_form; # search_form; # as_form;
    
    is_deeply( scalar $form->field, { street => undef,
                                      name   => undef,
                                      town   => undef,
                       #               id     => 1,
                                      toys    => undef,
                                      job => undef,
                       #search_opt_order_by => undef,
                       #search_opt_cmp => '=',
                                      } );
    
    my $obj;
    lives_ok { $obj = Person->retrieve_from_form( $form ) };
    
    
    
    #use Data::Dumper;
    #warn Dumper( $form );
    
    #warn "Invalids: ",  " $_: " . Dumper( $_->{invalid} ) for $form->fields;
    
    isa_ok( $obj, 'Class::DBI' );

    is( $obj->id, 1, 'got correct object' );
    is( $obj->name, 'DaveBaird', 'retrieved updated object' );
    
    
    
}    

