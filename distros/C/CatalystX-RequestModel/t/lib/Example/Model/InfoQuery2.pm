package Example::Model::InfoQuery2;

use Moose;
use CatalystX::QueryModel;

extends 'Catalyst::Model';

has page => (is=>'ro', property=>1);  
has offset => (is=>'ro', property=>1);
has search => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
