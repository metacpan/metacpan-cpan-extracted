package Example::Model::InfoRequest;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';
namespace 'info';
content_type 'application/json';

has username => (is=>'ro', required=>1, property=>1);  
has first_name => (is=>'ro', property=>1);
has last_name => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
