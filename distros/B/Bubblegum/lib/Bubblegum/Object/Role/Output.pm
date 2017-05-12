package Bubblegum::Object::Role::Output;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'requires', 'with';

with 'Bubblegum::Object::Role::Defined';

our $VERSION = '0.45'; # VERSION

requires 'print';
requires 'say';

1;
