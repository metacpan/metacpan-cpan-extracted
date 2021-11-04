package Catalyst::Exception::InvalidArrayPointer;

use Moose;
use namespace::clean -except => 'meta';

extends 'Catalyst::Exception::StructuredParameter';

has 'pointer' => (is=>'ro', required=>1);
has '+errors' => (init_arg=>undef, default=>sub { ["Pointer '@{[ $_[0]->pointer ]}' is not an array."] });

__PACKAGE__->meta->make_immutable;
