package Data::Paginated;

our $VERSION = '1.01';

use strict;
use warnings;

use base 'Data::Pageset';

use Carp;

=head1 NAME

Data::Paginated - paginate a list of data

=head1 SYNOPSIS

	my $paginator = Data::Paginated->new({
		entries => \@my_list,
		entries_per_page => $entries_per_page, 
		current_page => $current_page,
	});

	my @to_print = $paginator->page_data;

=head1 DESCRIPTION

Data::Paginated is a thin wrapper around Data::Pageset which adds the
extra functionality of being able to get all the entries from a list
that are on a given page.

=head1 METHODS

=head2 new

	my $paginator = Data::Paginated->new({
		entries => \@my_list,
		entries_per_page => $entries_per_page,
		current_page => $current_page,
	});

This can take all the arguments that can be passed to Data::Pageset,
with the exception that instead of passing simply the total number of
items in question, you actually pass the items as a reference.

=head2 page_data

	my @to_print = $paginator->page_data;

This returns a list of the entries that will be on the current page.

So, if you have a list of [ 1 .. 10 ], 3 entries per page, and current
page is 2, this will return (4, 5, 6).

=cut

sub new {
	my ($class, $conf) = @_;
	my $entries = delete $conf->{entries} or croak "entries must be supplied";
	my $self = $class->SUPER::new({ %$conf, total_entries => scalar @$entries });
	$self->{__DATA_PAGINATED_ENTRIES} = $entries;
	return $self;
}

sub page_data {
	my $self = shift;
	return @{ $self->{__DATA_PAGINATED_ENTRIES} }
		[ $self->first - 1 .. $self->last - 1 ];
}

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Data-Paginated@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2005 Kasei

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Data::Pageset>, L<Data::Page>.

=cut

1;

