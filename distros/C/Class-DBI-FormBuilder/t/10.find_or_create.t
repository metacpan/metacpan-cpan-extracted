
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
$ENV{QUERY_STRING}   = 'name=Winston&street=DowningStreet&town=4&_submitted=1';

my $submitted_data = { street => 'DowningStreet',
                       name   => 'Winston',
                       town   => 4,
                       #id     => undef,
                       toys    => undef,
                       job => undef,
                       };

my $form = Person->as_form;

is_deeply( scalar $form->field, $submitted_data );

my $obj;
lives_ok { $obj = Person->find_or_create_from_form( $form ) } 'find_or_create - create';
isa_ok( $obj, 'Class::DBI' );

$submitted_data->{id} = 25; # new id
$submitted_data->{town} = 'London';

my $obj_data = { map { $_ => $obj->$_ || undef } keys %$submitted_data };
is_deeply( $obj_data, $submitted_data );






