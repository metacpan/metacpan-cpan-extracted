use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultBase;

our $VERSION = '0.0001';

use parent 'DBIx::Class::Smooth::ResultBase';
use experimental qw/postderef signatures/;

__PACKAGE__->load_components(qw/
    Helper::Row::RelationshipDWIM
    Smooth::Helper::Row::Creation
    Smooth::Helper::Row::JoinTable
/);

sub db {
    return shift->result_source->schema;
}

1;
