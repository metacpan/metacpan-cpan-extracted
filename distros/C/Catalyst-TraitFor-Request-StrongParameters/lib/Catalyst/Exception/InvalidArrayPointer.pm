package Catalyst::Exception::InvalidArrayPointer;

use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::Exception::StrongParameter';

has 'pointer' => (is=>'ro', required=>1);
has '+message' => (is=>'ro', lazy=>1, default=>sub { "Pointer '@{[ $_[0]->pointer ]}' is not an array." });
 
__PACKAGE__->meta->make_immutable;
