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

sub except_titles($self, @titles) {
    # This is not want you want to do in real life, just call filter()
    # Here, we want the arguments that would be passed to filter.
    return $self->_smooth__prepare_for_filter(title__not_in => \@titles);
}
