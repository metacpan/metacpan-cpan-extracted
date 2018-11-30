use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultSet;

our $VERSION = '0.0001';

use parent 'DBIx::Class::Smooth::ResultSet';

sub base { $_[1] || 'TestFor::DBIx::Class::Smooth::Schema::ResultSetBase' }

sub perl_version { 20 }

sub experimental {
    [qw/
        signatures
        postderef
    /];
}

1;
