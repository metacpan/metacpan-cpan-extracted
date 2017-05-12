
use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 4;


use Class::DBI::FormBuilder::DBI::Test; # also includes Bar


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=Scooby&street=SnackStreet&town=3&id=5&_submitted=1';

my $submitted_data = { street => 'SnackStreet',
                       name   => 'Scooby',
                       town   => 3,
                       #id     => 5,
                       toys    => undef,
                       job => undef,
                       };

my $data = { street => 'NastyStreet',
             name   => 'Brian',
             town   => 'Uglyton',
             id     => 5,
             };

my $form = Person->as_form;

is_deeply( scalar $form->field, $submitted_data );

my $obj;
lives_ok { $obj = Person->retrieve_or_create_from_form( $form ) } 'retrieve_or_create - retrieve';
isa_ok( $obj, 'Class::DBI' );

my $obj_data = { map { $_ => $obj->$_ || undef } keys %$data };
is_deeply( $obj_data, $data );





    
    

    