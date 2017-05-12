package TestApp::Schema::ResultSet::Stations;
use parent 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub controller_search {
   my $self = shift;
   return $self->search({ id => 3 });
}

sub controller_sort {
   my $self = shift;
   return $self->search(undef, { order_by => 'bill' });
}

1;
