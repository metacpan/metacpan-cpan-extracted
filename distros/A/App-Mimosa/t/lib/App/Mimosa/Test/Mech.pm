package App::Mimosa::Test::Mech;
use Moose;

use App::Mimosa::Test ();

extends 'Test::WWW::Mechanize::Catalyst';

has '+catalyst_app' => default => 'App::Mimosa';

1;

