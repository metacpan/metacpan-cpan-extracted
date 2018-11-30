use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result;

our $VERSION = '0.0001';

use parent 'DBIx::Class::Smooth::Result';

sub base { $_[1] || 'TestFor::DBIx::Class::Smooth::Schema::ResultBase' }

sub default_result_namespace { 'TestFor::DBIx::Class::Smooth::Schema::Result' }

sub perl_version { 20 }

sub experimental {
    [qw/
        postderef
        signatures
    /];
}

1;
