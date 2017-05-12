package Crypt::Perl::X::UnknownHash;

use strict;
use warnings;

use parent 'Crypt::Perl::X::Base';

sub new {
    my ($class, $hash_name) = @_;

    return $class->SUPER::new( "This framework does not know a hashing algorithm named “$hash_name”." );
}

1;
