

use strict;
use warnings;

use Test::More;
use Test::Exception;

if ( ! DBD::SQLite2->require ) 
{
    plan skip_all => "Couldn't load DBD::SQLite2";
}

plan tests => 2;
use Class::DBI::FormBuilder::DBI::Test; 


$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'id=1&_submitted=1';

my $dbaird = Person->retrieve( 1 );

my $data = { street => 'NiceStreet',
             name   => 'DaveBaird',
             town   => 'Trumpton',
             toys    => [ qw( 1 2 3 ) ],
             };        

my $obj_data = { map { $_ => $dbaird->$_ || undef } keys %$data };
$obj_data->{toys} = [ map { $_->id } $dbaird->toys ];
is_deeply( $obj_data, $data );

my $form = $dbaird->as_form( selectnum => 2 );

my $html = $form->render;

like( $html, qr(<select id="toys" multiple="multiple" name="toys">\s*<option selected="selected" value="1">RedCar</option>\s*<option selected="selected" value="2">BlueBug</option>\s*<option selected="selected" value="3">GreenBlock</option>\s*<option value="4">YellowSub</option>\s*</select>), 'finding has_many rels' );




