package Bubblegum::Object::Role::Defined;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'with';

with 'Bubblegum::Object::Role::Item';

our $VERSION = '0.45'; # VERSION

sub defined {
    return 1
}

1;
