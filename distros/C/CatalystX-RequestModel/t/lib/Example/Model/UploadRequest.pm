package Example::Model::UploadRequest;

use Moose;
use CatalystX::RequestModel;

extends 'Catalyst::Model';
content_type 'multipart/form-data';

has notes => (is=>'ro', required=>1, property=>1);  
has file => (is=>'ro', property=>1);

__PACKAGE__->meta->make_immutable();
