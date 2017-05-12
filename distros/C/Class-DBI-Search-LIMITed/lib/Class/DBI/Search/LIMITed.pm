package Class::DBI::Search::LIMITed;

our $VERSION = '1.01';

use strict;
use warnings;

use base 'Class::DBI::Search::Basic';

sub fragment {
  my $self = shift;
  my $frag = $self->SUPER::fragment;
  if (defined(my $limit = $self->opt('limit'))) {
    $frag .= " LIMIT $limit";
  }
  return $frag;
}

1;

__END__

=head1 NAME

Class::DBI::Search::LIMITed - add 'LIMIT' to Class::DBI searches

=head1 SYNOPSIS

	use base 'Class::DBI';

	__PACKAGE__->add_searcher(
		limited_search => 'Class::DBI::Search::LIMITed'
	);

	my @by_date = My::Class->limited_search( ... , {
			order_by => 'name',
			limit    => 10,
	});

	# or, if you want it to be the default search

	__PACKAGE__->add_searcher(
		search => 'Class::DBI::Search::LIMITed'
	);

	my @by_date = My::Class->search( ... , {
			order_by => 'name',
			limit    => '20, 10',
	});

=head1 DESCRIPTION

This is a simple search plugin to a Class::DBI subclass which allows for 
the addition of a LIMIT option to a SELECT query.

=head1 METHODS

=head2 add_searcher

	__PACKAGE__->add_searcher(
		method_name => 'Class::DBI::Search::LIMITed'
	);

As with all Search plugins you can choose the method name for the search
that it generates. You can either make a distinct limit-ed search method
(e.g. search_limited()), or just make it your default search() method.

=head2 fragment

This overrides the default 'fragment' method in Class::DBI::Search::Basic
to add any 'limit' option passed in your search query.

=head1 CAVEATS

This is only useful for databases which support a LIMIT modifier, such
as MySQL. 

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Class-DBI-Search-LIMITed@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


