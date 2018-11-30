use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultSet::Book;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::ResultSet -components => [qw/

/];
use DBIx::Class::Smooth::Q;
use experimental qw/postderef signatures/;

sub except_titles($self, @titles) {
    return $self->_prepare_for_filter([title__not_in => \@titles]);
}
