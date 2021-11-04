package Catalyst::Exception::StrongParameter;

use Moose;
use namespace::clean -except => 'meta';
 
with 'Catalyst::Exception::Basic';
 
__PACKAGE__->meta->make_immutable;
