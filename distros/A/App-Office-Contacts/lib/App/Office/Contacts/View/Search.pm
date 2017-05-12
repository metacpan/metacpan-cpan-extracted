package App::Office::Contacts::View::Search;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

extends 'App::Office::Contacts::View::Base';

our $VERSION = '2.04';

# -----------------------------------------------

sub build_search_html
{
	my($self) = @_;

	$self -> db -> logger -> log(debug => 'View::Search.build_search_tab()');

	# Make browser happy by turning the HTML into 1 long line.

	my($html) = $self -> db -> templater -> render
		(
			'search.tx',
			{
				sid => $self -> db -> session -> id,
			}
		);
	$html =~ s/\n//g;

	return $html;

} # End of build_search_html.

# -----------------------------------------------

sub display
{
	my($self, $target, $result) = @_;

	$self -> db -> logger -> log(debug => "View::Search.display($target, " . scalar @$result . ')');

	my($html) = <<EOS;
<div id="dt_example">
<div id="container">
<table class="display" id="result_table" cellpadding="0" cellspacing="0" border="0" width="100%">
<thead>
<tr>
	<th>Count</th>
	<th>Type</th>
	<th>Role</th>
	<th>Name</th>
	<th>Surname</th>
	<th>Email address</th>
	<th>Email type</th>
	<th>Phone</th>
	<th>Phone type</th>
</tr>
</thead>
<tbody>
EOS
	my($count) = 0;

	my($class);

	for my $row (@$result)
	{
		$class = (++$count % 2 == 1) ? 'odd gradeC' : 'even gradeC';

		# Allow for contacts who simply don't have email or phone data.

		$$row{email}      ||= '-';
		$$row{email_type} ||= '-';
		$$row{phone}      ||= '-';
		$$row{phone_type} ||= '-';
		$$row{surname}    ||= '-';
		$html             .= <<EOS;
<tr class="$class">
	<td>$count</td>
	<td>$$row{type}</td>
	<td>$$row{role}</td>
	<td>$$row{name}</td>
	<td>$$row{surname}</td>
	<td>$$row{email}</td>
	<td>$$row{email_type}</td>
	<td>$$row{phone}</td>
	<td>$$row{phone_type}</td>
</tr>
EOS
	}

	$html .= <<EOS;
</tbody>
<tfoot>
<tr>
	<th>Count</th>
	<th>Type</th>
	<th>Role</th>
	<th>Name</th>
	<th>Surname</th>
	<th>Email address</th>
	<th>Email type</th>
	<th>Phone</th>
	<th>Phone type</th>
</tr>
</tfoot>
</table>
</div>
</div>
EOS

	return $html;

} # End of display.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::View::Search - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class extends L<App::Office::Contacts::View::Base>, with these attributes:

=over 4

=item o (None)

=back

=head1 Methods

=head2 build_search_html()

Returns the HTML used to populate the 'Search' tab.

=head2 display($target, $result)

Returns the HTML which is the result of a search request from the user.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
