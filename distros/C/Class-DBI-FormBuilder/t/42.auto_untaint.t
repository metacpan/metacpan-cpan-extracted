use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 4;
use Class::DBI::FormBuilder::DBI::Test; 


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = '_submitted=1&name=joe&town=2';

# limit fields
{
    my $html = Person->as_form( fields => [ qw( name town ) ] )->render;
    
    # got a validation function for every column
    foreach my $col ( qw( name town ) )
    {
        like( $html, qr(var $col) );
    }
    
    # except id
    unlike( $html, qr(var id street) );
    # and street
    unlike( $html, qr(var street) );
}    