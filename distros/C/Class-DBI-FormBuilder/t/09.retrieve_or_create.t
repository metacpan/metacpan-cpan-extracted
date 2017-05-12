
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 3;


use Class::DBI::FormBuilder::DBI::Test; # also includes Bar

# The difference from 08 is the id= in the query string - this would be wrong, 
# and results in the fatal error in the last test

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=Scooby&street=SnackStreet&town=3&id=&_submitted=1';

my $data = { street => 'SnackStreet',
             name   => 'Scooby',
             town   => 3,
             #id     => '',
             toys    => undef,
             job => undef,
             };

my $form = Person->as_form;

# 
my $html = $form->render;
like( $html, qr(<input id="id" name="id" type="hidden" value="" />) );

is_deeply( scalar $form->field, $data );


my $obj;
dies_ok { $obj = Bar->retrieve_or_create_from_form( $form ) } 'retrieve_or_create - die';

