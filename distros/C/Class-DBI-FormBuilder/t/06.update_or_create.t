
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


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'name=Brian&street=NastyStreet&town=2&id=5&_submitted=1';

my $data = { street => 'NastyStreet',
             name   => 'Brian',
             town   => 2,
             #id     => 5,
             toys    => undef,
             job => undef,
             };

my $form = Person->as_form;

is_deeply( scalar $form->field, $data );

my $obj;
lives_ok { $obj = Person->update_or_create_from_form( $form ) } 'update_or_create - update';
isa_ok( $obj, 'Class::DBI' );

$data->{town} = 'Uglyton';
my $obj_data = { map { $_ => $obj->$_ || undef } keys %$data };
is_deeply( $obj_data, $data );

is( $obj->id, 5 );



    
    

    