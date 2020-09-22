use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultSetBase;

our $VERSION = '0.0001';

use parent 'DBIx::Class::Smooth::ResultSetBase';

__PACKAGE__->load_components(qw/
    Helper::ResultSet
    Helper::ResultSet::OneRow
    Helper::ResultSet::Bare
    Helper::ResultSet::DateMethods1
    Smooth::Lookup::Operators
    Smooth::Lookup::DateTime
    Smooth::Lookup::substring
    Smooth::Lookup::ident
    Smooth::Flatten::DateTime
/);

use experimental qw/postderef signatures/;

1;
