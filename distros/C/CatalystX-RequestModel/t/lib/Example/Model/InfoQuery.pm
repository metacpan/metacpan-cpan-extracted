package Example::Model::InfoQuery;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';
content_type 'application/x-www-form-urlencoded';
content_in 'query';

has page => (is=>'ro', required=>1, property=>1);  
has offset => (is=>'ro', property=>1);
has search => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
