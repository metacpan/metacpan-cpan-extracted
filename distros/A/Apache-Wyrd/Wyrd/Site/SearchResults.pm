package Apache::Wyrd::Site::SearchResults;
use strict;
use base qw(
	Apache::Wyrd::Interfaces::IndexUser
	Apache::Wyrd::Site::Pull
	Apache::Wyrd::Interfaces::Dater
	Apache::Wyrd::Interfaces::Setter
	Apache::Wyrd
);
our $VERSION = '0.98';

# searchparam - name of parameter containing the search string, default 'searchstring'
# item - list item template
# failed - template of error message for failed search
# decimal - decimals of percentile

=pod

=head1 NAME

Apache::Wyrd::Site::SearchResults - Perform a word-search of Pages

=head1 SYNOPSIS

  <BASENAME::SearchResults max="20">
    <BASENAME::Template name="list"><table>$:items</table></BASENAME::Template>
    <BASENAME::Template name="item">
      <tr><td><a href="$:name">$:title</a>?:published{, posted: $:published}
      ?:description{<BR>&#151;$:description}</td></tr>
    </BASENAME::Template>
    <BASENAME::Template name="instructions>
      ...instructions here...
    </BASENAME::Template>
    <BASENAME::Template name="failed>
      The search for 
        <BASENAME::CGISetter>
          "$:searchstring"
        </BASENAME::CGISetter>did not produce any results.
    </BASENAME::Template>
  </BASENAME::SearchResults>

=head1 DESCRIPTION

SearchResults is another form of C<Apache::Wyrd::Site::Pull>, which uses the
contents of the CGI variable "searchstring" to produce a list of search results
from an C<Apache::Wyrd::Site::Index> object.  The searchstring variable can
use any combination of parens, quotes, logical terms and +/- elements to limit
the wordsearch to a smaller set.  This Pull processes the list of hashrefs of
document metadata returned by the index object.

The SearchResults object also adds to each result item the key-value pairs:

=over

=item rank

Meaning the rank (1 = best) of the document as to relevance within the search set.

=item counter

The ordinal number of the item in the found set.

=item weighted_rank

Meaning the relative rank of the document in comparison with the others of the
found set (in percent, 100=best).

=item relevance

The generic, unweighted relevance score, based on a function of word-incidents
to document size (wordcount).

=back

To allow the individual items of the "search results" block to be related to
each other.  Additionally, if a previous search result is given in the CGI
variable "previous" and the CGI variable "within" is a non-null value (as would
be returned by a hidden INPUT tag named "previous" and a checkbox named "within",
The searcstring will be limited to the previous results.

Additionally, the CGI variable "max" is used to limit the search results to
"max" number of items or less, and the "next" and "beginning" CGI variables are
used to define a window of "max" number of of search results within a search
set, which is to say that as the frame moves to the window defined by "next",
the C<Apache::Wyrd::Intefaces::Setter> elements will set C<$:next> in the list
template to the current value of the CGI variable "next" + the value of "max".
This allows the webmaster to easily construct a moving-window search result.

=head2 HTML ATTRIBUTES

=over

=item decimals

How many digits after the decimal point to include in weighted results.

=item sort

Which attributes of the sorted objects should be used to sort the list.  Note
that if a sort item begins with "rev_", the sort is performed in reverse.

=item instructions

What to provide in case no searchstring parameter was given.

=item failed

What to provide in case of a failed search.  Often suppled as an
Apache::Wyrd::Template Wyrd.

=item list/item

As with C<Apache::Wyrd::Site::Pull>, the templates (also often supplied as
Apache::Wyrd::Template Wyrds, which provide formatting to the list itself and
to the items of the list.

=back

=head2 FLAGS

=over

=item reverse

Sort in reverse.

=item weighted

Sort by weighted relevance rather than generic score.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<_set_defaults> (void)

method description

=cut

sub _set_defaults {
	my ($self) = @_;
	my %default = (
		max => 0,
		string => '',
		previous => '',
		'sort' => ($self->_flags->weighted ? 'relevance' : 'score'),
		decimals => 0,
		beginning => 1,
		within => 0,
		override => '',
	);
	foreach my $param (keys %default) {
		$self->{$param} = $self->dbl->param("search$param") || $self->{$param} || $default{$param};
	}
}

=over

=item (array) C<_doc_filter> (array)

A "hook" method for filtering each (hashref-ed) search result.  The search
results are given as an array of hashrefs, and similar array is expected.

=cut

sub _doc_filter {
	my ($self) = shift;
	return @_;
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the _format_output method.

=cut


sub _format_output {
	my ($self) = @_;

	my $index = $self->_init_index;
	$self->_set_defaults;

	my $max_results = $self->max;
	my $beginning = $self->beginning;
	my $sort_param = $self->sort;
	my $override = $self->override;
	#if the sort param begins with rev_, change the sort param to the base param, but set the reverse flag.
	if ($sort_param =~ s/^rev_//) {
		$self->_flags->reverse(1);
	}
	my $string = $self->string;
	my $previous = $self->previous;
	my $within = $self->within;

	if ($override) {
		$string = $override;
	} elsif ($within and $string and $previous) {
		$string = "($previous) AND ($string)";
	}

	if ($string =~ /\({5}/) {
		$string = $previous;
		$self->dbl->param('searchstring', $previous);
		$self->_data($self->_clear_set({'message' => 'This search has become too complicated to parse as-is.  Please re-phrase your search and try again.'}, $self->{'error'}));
		return;
	}

	if ($string) {
		my @objects = $index->parsed_search($string);
		my $template = ($self->{'item'} || $self->_data);
		my $max_score = 1;
		my $average_count = 0;
		foreach my $object (@objects) {
			$max_score = $object->{'score'} if ($object->{'score'} > $max_score);
			$average_count += $object->{'count'};
			foreach my $attr (keys %$object) {
				delete $object->{$attr} unless ($object->{$attr});
			}
		}
		$average_count = $average_count/scalar(@objects) if (@objects);
		$average_count ||= 50; #if all else fails, assume 50 words.
		my $max_relevance = 0;
		foreach my $object (@objects) {
			$object->{'count'} ||= $average_count; #use an average count for undefined counts
			$object->{'relevance'} = $object->{'score'} / $object->{'wordcount'};
			$max_relevance = $object->{'relevance'} if ($object->{'relevance'} > $max_relevance);
		}
		my ($out, $counter) = ();
		my @processed_objects = ();
		foreach my $object (sort {$b->{$sort_param} <=> $a->{$sort_param}} @objects) {
			$counter++;
			$object->{'rank'} = (int(($object->{'score'} * 100 * (10 ** $self->{'decimals'})/$max_score) + .5) / (10 ** ($self->{'decimals'}))) . '%';
			$object->{'weighted_rank'} = (int(($object->{'relevance'} * 100 * (10 ** $self->{'decimals'})/$max_relevance) + .5) / (10 ** ($self->{'decimals'}))) . '%';
			$object->{'counter'} = $counter;
			push @processed_objects, $object;
		}
		@processed_objects = $self->_process_docs(@processed_objects);

		@objects = $self->_doc_filter(@processed_objects);

		#so did any objects survive the filters?
		my $total = @objects;
		unless ($total) {
			$self->_data($self->{'failed'} || "<i>Sorry, no pages matched your query</i>");
			return;
		}

		#reverse the sort order if the reverse flag is set.
		@objects = reverse @objects if ($self->_flags->reverse);

		my $next_beginning = 0;
		my $previous_beginning = 0;
		#apply limits if they exist
		if ($max_results) {
			my $start = $beginning - 1;
			$start = 0 if ($start < 0);
			@objects = splice @objects, $start, $max_results;
			my $new = $beginning + $max_results;
			#don't add a new beginning if it overpasses the total
			$next_beginning =  $new if ($new < $total);
			$previous_beginning = $beginning - $max_results;
			$previous_beginning = 0 if ($previous_beginning < 1);
		}

		#template them up and post them out
		foreach my $object (@objects) {
			$out .= $self->_text_set($object, $template);
		}
		$self->_data($self->_set({
				items=> $out,
				total => $total,
				remaining => $total - $max_results,
				previous => $previous_beginning,
				next => $next_beginning,
				current => $string,
			}, $self->_data));
	} else {
		#no search, show some instructions instead
		$self->_data($self->{'instructions'});
	}
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Index

=item Apache::Wyrd::Services::MySQLIndex

=item Apache::Wyrd::Site::Index

=item Apache::Wyrd::Site::MySQLIndex

Various index objects for site organization.

=item Apache::Wyrd::Interfaces::IndexUser

Convenience class for Wyrds which interface with Indexes

=item Apache::Wyrd::Site::Pull

Abstract class for lists of pages

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;