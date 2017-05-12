package Class::DBI::Search::Count;

our $VERSION = '1.00';

use strict;
use warnings;

use base 'Class::DBI::Search::Basic';

sub sql { 
	my $self = shift;
	my $class = $self->class;
	$class->set_sql(plugged_count => qq{
		SELECT COUNT(*) FROM __TABLE__ WHERE %s
	}) unless $class->can('sql_plugged_count');
	return $class->sql_plugged_count($self->fragment);
}

sub run_search {
	my $self = shift;
	return $self->sql->select_val(@{ $self->bind });
}

1;

__END__

=head1 NAME

Class::DBI::Search::Count - return count of results rather than results

=head1 SYNOPSIS

	use base 'Class::DBI';

	__PACKAGE__->add_searcher(
		search_count => 'Class::DBI::Search::Count'
	);

	my $recent = CD->search_count(year => 2005);

This is equivalent to, but, as the counting is done at the database
rather than in perl, faster than:

  my $recent = CD->search(year => 2005)->count;

=head1 DESCRIPTION

This is a simple search plugin for Class::DBI to return a count of
results rather than the results themselves.

=head1 METHODS

=head2 add_searcher

	__PACKAGE__->add_searcher(
		method_name => 'Class::DBI::Search::Count'
	);

As with all Search plugins you can choose the method name for the search
that it generates. 

=head2 sql

We override the SQL to be our own COUNT(*) version

=head2 run_search

We override this to return our count rather than the search results.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-Search-Count@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


