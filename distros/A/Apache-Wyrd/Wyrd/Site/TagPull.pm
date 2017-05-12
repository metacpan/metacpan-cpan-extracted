package Apache::Wyrd::Site::TagPull;
use strict;
use base qw(Apache::Wyrd::Site::Pull);
use Apache::Wyrd::Services::SearchParser;
use Apache::Wyrd::Services::SAK qw(:hash);
use Apache::Wyrd::Interfaces::Dater;
use Date::Calc qw(Add_Delta_Days);
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::TagPull.pm - Display a list of Pages by subject

=head1 SYNOPSIS

  <BASENAME::TagPull search="newsletter AND current">
    <BASENAME::Template name="list"><table>$:items</table></BASENAME::Template>
    <BASENAME::Template name="item">
      <tr><td><a href="$:name">$:title</a>?:published{, posted: $:published}
      ?:description{<BR>&#151$:description}</td></tr>
    </BASENAME::Template>
    <BASENAME::Template name="selected">
      <tr><td><b>$:title?:published{, posted: $:published}</b>
      ?:description{<BR>&#151;$:description}</td></tr>
    </BASENAME::Template>
  </BASENAME::TagPull>

=head1 DESCRIPTION

TagPulls operate on the Page attribute "tags" which is a map attribute of
the Index object.  Given a search string of these tags, the Index is queried
for documents which have those tags as items in their "tags" attribute.  The
list is returned following the format defined by the TagPull's templates:
list, item, and selected.

Note, however, that like C<Apache::Wyrd::Site::Pull>'s "eventdate"
attribute, the "tags" attribute is optional and must be defined as a map of
the index itself.  (See C<Apache::Wyrd::Site::Index> for more details of
these optional attributes.)

Each of these templates represents a component of the HTML that is
expressed.  All of them follow the C<Apache::Wyrd::Interfaces::Setter>-style
conventions for placemarkers and conditional expressions:

=over

=item list

"list" is the HTML which bounds the list itself: in one of the list tags, it
represents the list tags themselves (e.g. <UL>...</UL>).  Where the items of
the list are to appear, the placemarker $:items should appear.

=item item

"item" is the HTML which represents an individual page.  Whatever attributes of
the Page you want to display in the list need to be given in placemarkers of
this template.

=item selected

Identical to "item", but used only if the document in the TagPull list is
the document on which it appears.  This template is kept separate from the
item template to allow the document to be treated differently on the page on
which it appears, for example, not at all, or unlinked, so that it is clear
it can't be navigated to.  (Not normally used, see "metoo" flag, below.)

=back

Another feature of a TagPull is that if it encloses any HTML with Setter-style placemarkers, it will assume that it should treat that text as a template for the HTML enclosing the list, and replace the $:list placemarker with the complete list itself.

One more feature of TagPulls is that they will change the private attribute "_pull_results" of the enclosing Wyrd to an integer representing how many of the results were found.  What the parent Wyrd does with this data is not determined by the TagPull.

=head2 HTML ATTRIBUTES

=over

=item search

The search string in conventional logical format.  Other than quotes, which
provide no meaning in tokenized search expressions, either the +/- or the
formal AND, OR, NOT, DIFF modifiers may be used to express the set of tagged
pages which are to be displayed.  Parentheses may also be used.

=item sort

Sort the list by the attributes indicated in this token list.  Sorting is done in precedence given by these tokens from left to right, for example "title, published, isbn" is by title first, then by date, then by ISBN.  These items must, of course, be attributes of the Page Wyrds that are indexed.

Sorting is done in alphabetical order when comparing non-numerical strings, ascending order when comparing numbers, and in reverse chronology when searching by one of the attributes designated in the site's implementation of Apache::Wyrd::Site::Pull::_date_fields().

=item before

Item publication date must be before the date (given in YYYYMMDD format)

=item after

Item publication date must be before the date (given in YYYYMMDD format)

=item eventdate

See C<Apache::Wyrd::Site::Pull>.

=item limit

Limit of how many documents to present.  Can be a single digit for how many
from the top to present, two digits separated by a comma for a range from
the top, or a comma to the left or right of a digit to represent a range
from the top up to an item or from the item to the end of the series,
respectively.  This limit is appled after all other filters.

=item attribute

attribute description

=back

=head2 FLAGS

=over

=item autohide

Instruct the TagPull not to display at all if the TagPull has no results.  Otherwise, an empty list is presented.

=item metoo

Cause the page the TagPull occurs on to appear in the pull, which is not the default behavior.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<_set_defaults> (void)

This method provides the default templates for the list, item, selected, and
header templates.

=cut

sub _set_defaults {
	my ($self) = @_;
	$self->{list} ||= '<ul>$:items</ul>';
	$self->{item} ||= '<li>?:published{$:published &#151; }<a href="$:name">$:title</a>?:description{<BR>$:description}</li>';
	$self->{selected} ||= '<li>?:published{$:published&#151;}<b>$:title</b>?:description{<BR>$:description}</li>';
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the _format_output method.

=cut

sub _format_output {
	my ($self) = @_;
	my $pull_results = 0;
	$self->_set_defaults;
	my $out = undef;
	my @sort = token_parse($self->{'sort'});
	my @docs = $self->_get_docs;

	#optional filters
	@docs = $self->_doc_filter(@docs) if ($self->can('_doc_filter'));
	@docs = grep {$_->{'published'} < $self->{'before'}} @docs if ($self->{'before'});
	@docs = grep {$_->{'published'} > $self->{'after'}} @docs if ($self->{'after'});
	@docs = grep {$_->{'name'} ne $self->dbl->self_path} @docs unless($self->_flags->metoo);
	@docs = $self->_process_eventdate(@docs) if ($self->{'eventdate'});
	if (@sort) {
		for (my $i = 0; $i < @sort; $i++) {
			#date keys are reverse by default
			$sort[$i] = "-$sort[$i]" if (grep {$sort[$i] eq $_} $self->_date_fields);
		}
		@docs = sort {sort_by_ikey($a, $b, @sort)} @docs;
	}
	@docs = reverse(@docs) if ($self->_flags->reverse);
	@docs = $self->_process_limit(@docs) if ($self->{'limit'});

	@docs = $self->_process_docs(@docs);
	$out = $self->_format_list(@docs);
	$pull_results = scalar(@docs);
	if ($self->_flags->autohide and !$pull_results) {
		$self->_data('');
		return;
	}
	if ($self->_data =~ /\$:/) {
		my $set = $self->_template_hash;
		$set->{'list'} = $out;
		$out = $self->_clear_set($set);
	}
	#add to the total for the parent, in case there are other pull results
	$self->{_parent}->{_pull_results} += $pull_results;
	$self->_data($out);
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Site::Pull

Abstract document-list Wyrd

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _get_docs {
	my ($self) = @_;
	my $all = $self->{'all'};
	my $any = $self->{'any'};
	my $tags = $self->{'search'};
	#list, item, selected are templates
	my (@docs) = ();
	if ($tags) {
		my @phrases = split ',', $tags;
		foreach my $phrase (@phrases) {
			push @docs, $self->logic_search($phrase);
		}
		@docs = uniquify_by_key('id', @docs);
	} elsif ($any) {
		my @tags = parse_token($tags);
		foreach my $tag (@tags) {
			#pile on any matching document
			push @docs, $self->search($tag);
		}
		#eliminate duplicates
		@docs = uniquify_by_key('id', @docs);
	} else {
		my %docs = ();
		my @tags = token_parse($tags);
		my $tag = pop @tags;
		@docs = $self->search($tag);
		while ($tag = pop(@tags)) {
			#map next tag onto a hash
			%docs = map {$_->{'id'}, 1} $self->search($tag);
			#filter out any docs that aren't already there
			@docs = grep {$docs{$_->{'id'}}} @docs;
		}
	}
	#warn join qq'\n======\n', map {$_->{id}} @docs;
	return @docs;
}

sub logic_search {
	my ($self, $phrase) = @_;
	my $parser = Apache::Wyrd::Services::SearchParser->new($self);
	return $parser->parse($phrase);
}

sub search {
	my ($self, $phrase) = @_;
	return $self->{'index'}->word_search($phrase,'tags', $self->_search_params);
};

sub _process_limit {
	my ($self, @docs) = @_;
	my $limit = $self->{'limit'};
	return @docs unless($limit);
	$limit = ",$limit" if ($limit =~ /^\d+$/);
	unless ($limit =~ /^\d*,\d*$/) {
		$self->_error("Illegal value for limit: $limit");
		return @docs;
	}
	my ($begin, $end) = split ',', $limit;
	$begin += 0;
	$begin ||= 1;
	$end += 0;
	$end ||= scalar(@docs);
	if ($end < $begin) {
		($begin, $end) = ($end, $begin);
	}
	my $offset = $begin - 1;
	$offset = 0 if ($offset < 0);
	my $length = $end - $offset;
	$length = 0 if ($length < 0);
	@docs = splice (@docs, $offset, $length);
	return @docs;
}

sub _format_list {
	my ($self, @docs) = @_;
	my $out = '';
	foreach my $doc (@docs) {
		if ($doc->{'id'} eq $self->dbl->self_path) {
			$out .= $self->_clear_set($doc, $self->{selected});
		} else {
			$out .= $self->_clear_set($doc, $self->{item});
		}
	}
	$out = $self->_set({items => $out}, $self->{list});
	return $out;
}

1;