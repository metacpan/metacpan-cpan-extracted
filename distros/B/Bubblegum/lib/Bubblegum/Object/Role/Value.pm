package Bubblegum::Object::Role::Value;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Role 'with';
use Bubblegum::Constraints -isas, -types;

with 'Bubblegum::Object::Role::Defined';

our $VERSION = '0.45'; # VERSION

sub do {
    my $self = CORE::shift;
    my $code = CORE::shift;

    $code = $code->codify if isa_string $code;
    type_coderef $code;

    local $_ = $self;
    return $code->($self);
}

1;
