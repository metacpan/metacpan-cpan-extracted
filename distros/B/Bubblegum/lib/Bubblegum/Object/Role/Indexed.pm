package Bubblegum::Object::Role::Indexed;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'requires', 'with';

with 'Bubblegum::Object::Role::Collection';

our $VERSION = '0.45'; # VERSION

requires 'slice';

1;
