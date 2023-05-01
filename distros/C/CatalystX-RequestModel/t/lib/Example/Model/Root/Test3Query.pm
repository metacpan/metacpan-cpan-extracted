package Example::Model::Root::Test3Query;

use Moose;
use CatalystX::QueryModel;

extends 'Catalyst::Model';

has username => (is=>'ro', required=>1, property=>1);  
has password => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
