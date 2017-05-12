
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 6;


use Class::DBI::FormBuilder::DBI::Test; # also includes Bar


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=Scooby&street=SnackStreet&town=3&_submitted=1';

my $data = { street => 'SnackStreet',
             name   => 'Scooby',
             town   => 3,
             #id     => undef,
             toys    => undef,
             job => undef,
             };

my $form = Person->as_form;

is_deeply( scalar $form->field, $data );

# forms built from a class name should include no id field, 
my $html = $form->render;
unlike( $html, qr(<input id="id" name="id" type="hidden" />) );
unlike( $html, qr(name="id") );

my $obj;
lives_ok { $obj = Person->retrieve_or_create_from_form( $form ) } 'retrieve_or_create - create';
isa_ok( $obj, 'Class::DBI' );

$data->{id} = 24; # new id
$data->{town} = 'Toonton';
my $obj_data = { map { $_ => $obj->$_ || undef } keys %$data };
is_deeply( $obj_data, $data );





    
    

    