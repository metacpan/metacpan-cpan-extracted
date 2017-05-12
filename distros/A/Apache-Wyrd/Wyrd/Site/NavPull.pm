package Apache::Wyrd::Site::NavPull;
use strict;
use base qw(Apache::Wyrd::Site::Pull);
use Apache::Wyrd::Services::SAK qw(:hash token_parse);
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::NavPull - Display a list of documents in a navigation-tree

=head1 SYNOPSIS

  <BASECLASS::NavPull root="/someplace/index.html" maxdepth="3">
    <BASECLASS::Template name="list">
      <blockquote>$:items</blockquote>
    </BASECLASS::Template>
    <BASECLASS::Template name="item">
      <p><a href="$:name">$:title</a></p>
    </BASECLASS::Template>
    <BASECLASS::Template name="selected">
      <p>$:title</p>
    </BASECLASS::Template>
    <BASECLASS::Template name="nearest">
      <p><a href="$:name"><b>$:title</a><b></p>
    </BASECLASS::Template>
  </BASECLASS::NavPull>

=head1 DESCRIPTION

NavPull is designed to make navigation bars self-managing.  It does so by
recursively building the hierarchy out of the stated "parent" attributes of
indexed Pages.  Beginning with a "root", which can be an arbitrary page or
(the default) a section root, it builds the list using five templates:

=over

=item list

"list" is the HTML which bounds the list itself: in one of the list tags, it
represents the list tags themselves (e.g. <UL>...</UL>).  Where the items of
the list are to appear, the placemarker $:items should appear.

=item item

"item" is the HTML which represents an individual page.  Whatever attributes
of the Page you want to display in the list need to be given in placemarkers
of this template.

=item selected

Identical to "item", but used only if the document in the NavPull list is
the document on which it appears.  This template is kept separate from the
item template to allow the document to be treated differently on the page on
which it appears, for example, not at all, or unlinked, so that it is clear
it can't be navigated to.  (Not normally used, see "metoo" flag, below.)

=item nearest

Identical to "selected", but represents the closest parent node before the
depth of the tree runs out.  For example, if the NavPull is instructed to
draw the tree only three nodes deep and the document on which the NavPull
appears is five nodes down, the "nearest" template is used to draw the last
ancestor which appears.  Unless supplied, it defaults to the "item"
template.

=item leaf

When the "tree" tag is in effect, the last page in a branch, i.e. the "leaf"
is drawn using this template.  Unless supplied, it defaults to the "item"
template.

=back

These templates can be extended down the depth of the tree by leaving as-is,
or any depth level can be made different from the shallower ones by
appending the depth level to the template name: list2, item2, selected2,
list3, item3, selected3, etc.  If templates for a depth level are not
provided, they default to the next-shallower depth.

Very crude templates are supplied automatically if no level of the template
is specified in the body of the NavPull.

NOTE: There is some support for multiple parentage.  If a page declares two
parents (separated by commas), the decision as to how to draw the tree
depends on the referrer field of the HTTP request.  If it indicates one of
the ancestors of the page up one geneology, the navigation tree is drawn to
reflect that branch, not the other(s).  Multiple parents must belong in the
same section, however, and there can be no circular relationships between
parents.

=head2 HTML ATTRIBUTES

=over

=item root

The starting point, or "root" of the inverted-tree hierarchy.  If not
provided, the NavPull will seek through the sections of the site (the set of
"section" attrubutes of pages) until it finds a document with a parent
attribute which is the literal string "root" (signifying it has no parents
other than the hierarchy root) and which belongs in the same section as the
document on which the NavPull appears.

root can also be "self", in which case the NavPull will display its progeny
rather than its ancestors.

=item maxdepth

How many nodes down the tree to display.  If the tree does not have that
many nodes, the display will stop at the deepest nodes it can find.

=item sort

If provided, the document will sort within each group of equal-node siblings
(siblings with a common parent) based on this token-list.  As with TagPulls,
the sorting is done in the order of the tags in either alphabetical or
numerical order as appropriate, with those attributes designated "dates" by
Apache::Wyrd::Site::Pull::_date_fields() in reverse chronological order.

Note that there is also support for arbitrary sort orders.  Any set of siblings in a parentage-group may add a colon and numerical value to their parent attribute in order to indicate what order to be listed as siblings of the same node.  For example, parent="/path_to/my/parent.html:2" indicates that this page should be the second page listed among its siblings.  You may skip numbers in order to leave room for expansion among a sibling group, but any siblings missing these digits mixed in with siblings with these digits will appear before them in the list as if all numbered "0".

=back

=head2 FLAGS

=over

=item tree

Normally, the expansion of the depth is along the selected document's
branch.  Only siblings of direct ancestors are shown, not those siblings
children.  This is in keeping with traditional navigation practice.  This
flag overrides this convention, expanding all parent nodes to the depth of
the tree or the maxdepth attribute, whichever comes first.  It is primarily
of use in drawing site-maps.

=item onlynodes

Do not display end-documents, i.e. those Pages without children.

=item reverse

reverse the sort indicated in "sort" above.

=item noself

Remove this page (the one the NavPull is on) from the list, and by
extension, all its children.

=item light_path

Use "nearest" templates for all direct ancestors, instead of the normal
templates for all ancestors except for the nearest on a tree on which this
page does not appear due to its excessive depth.

=back

=head1 BUGS/CAVEATS

Reserves the _format_output method.  Support for multiple parentage has not
proven very useful, since circular hierarchies cannot be tolerated, and any
liberal application of multiple parentage quickly produces circular
relationships.

=cut

sub _format_output {
	my ($self) = @_;
	my $root = $self->{'root'};
	$self->{'sort'} ||= 'rank,shorttitle';
	my $id = undef;
	#list, item, nearest, selected = default templates
	$self->{list} ||= '<ul>$:items</ul>';
	$self->{item} ||= '<li><a href="$:name">$:shorttitle</a></li>';
	$self->{leaf} ||= $self->{item};
	$self->{selected} ||= '<li><b>$:shorttitle</b></li>';
	$self->{nearest} ||= $self->{selected};
	my $index = $self->{'index'};
	if (not($root)) {
		$id =  $self->_get_section_root;
		$self->_debug("$$id{name} is the root of this section");
		unless ($id->{name}) {
			$self->_data("<!-- no root exists for this section -->");
		}
		$id = $id->{name};
	} elsif ($root eq 'self') {
		$self->_debug('using self as the root');
		$id = $self->dbl->self_path;
	} else {
		#assume the user knows what they're doing.  Make no checks on suitability.
		$self->_debug('using supplied root:' . $root);
		$id = $root;
	}
	my $out = $self->_format_list($id, 0, $self->_get_path);#root to use, 0 depth, array of parents of current document
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

sub _format_list {
	my ($self, $id, $depth, @path) = @_;
	my ($out) = ();
	return if ($depth + 1 > ($self->{'maxdepth'} || 2) and not($self->_flags->onlynodes));#This +1 relates to how the maxdepth is always 1 more than is wanted
	my @children = @{$self->index->get_children($id, $self->_search_params)};
	@children = $self->_doc_filter(@children) if ($self->can('_doc_filter'));

	#Sitemap means no leaf nodes, so if there are no children, return.
	if ($self->_flags->onlynodes) {
		return 'abort' unless (@children);
		#but also check for max depth, since we skipped it above.
		return if ($depth + 1 > ($self->{'maxdepth'} || 2));
	}

	#if you don't provide a sort, the sort will be random and change between apache instances.  This means
	#there will be different sha1 hashes for the material, causing unnecessary Widget Index updates.
	my @sort = token_parse($self->{'sort'});
	if (@sort) {
		for (my $i = 0; $i < @sort; $i++) {
			#date keys are reverse by default
			$sort[$i] = "-$sort[$i]" if (grep {$sort[$i] eq $_} $self->_date_fields);
		}
		@children = sort {sort_by_ikey($a, $b, @sort)} @children;
	}
	@children = reverse @children if ($self->_flags->reverse);
	#warn 'children: ' . (join ', ', map {$_->{name}} @$children);
	foreach my $child ($self->_process_docs(@children)) {
		if ($self->_flags->tree) {
			#warn $child->{name};
			my $next = $self->_format_list($child->{name}, $depth + 1, @path);

			#For 'onlynodes', an abort can skip this child.
			next if ($next eq 'abort');

			my $is_self = $child->{name} eq $self->dbl->self_path;
			next if ($is_self and $self->_flags->noself);
			my $template = (
				  ($depth > ($self->{'maxdepth'} || 2)) 
				? $self->_get_template('leaf', $depth) : $is_self
				? $self->_get_template('selected', $depth)	: $self->_get_template('item', $depth)
			);
			$out .= $self->_clear_set($child, $template);
			$out .= $next;
		}
		else {
			my ($match) = grep {$child->{name} eq $_} @path;
			my $next = $self->_format_list($match, $depth + 1, @path);

			#For 'onlynodes', an abort can skip this child.
			next if ($next eq 'abort');

			my $is_self = $child->{name} eq $self->dbl->self_path;
			next if ($is_self and $self->_flags->noself);

			#if this item is not a match for this page, either highlight it as nearest if there are no deeper
			#levels and it is a match for the parentage-path, otherwise treat it like a normal item.
			my $template = (
				  $is_self
				? $self->_get_template('selected', $depth)	: (($match and not($next))
				? $self->_get_template('nearest', $depth)	: ($self->_flags->light_path and $match) 
				? $self->_get_template('nearest', $depth)	: $self->_get_template('item', $depth))
			);
			$out .= $self->_clear_set($child, $template);
			$out .= $next if ($match);
		}
	}
	$self->{_parent}->{_pull_results} += scalar(@children);
	return $self->_clear_set({items => $out}, $self->_get_template('list', $depth));
}

sub _get_template {
	my ($self, $type, $depth) = @_;
	$depth = '' unless ($depth + 0);
	my $template = $self->{"$type$depth"};
	unless ($template) {
		if ($depth) {
			$self->{"$type$depth"} = $self->_get_template($type, $depth - 1);
		} else {
			#warn "no $type$depth";
			return $self->{$type}
		}
	}
}

sub _get_path {
	#returns the parents of this node.
	my ($self, $this_node, $found, @path) = @_;
	my $first = 0;
	unless (ref($found) eq 'HASH') {
		$found = {};
		$this_node ||= $self->dbl->self_path;
		$first = 1;
	}
	if ($this_node eq 'root') {
		$self->_debug('parental path is:' . join(':', @path));
		return @path;
	}
	if ($found->{$this_node}++) {
		$self->_error(
			"Circular geneology for "
			. $path[0]
			. " detected between: "
			. join(', ', sort keys %$found)
			. ".  Backing out..."
		);
		return ();
	}
	my $parents_exist = 0;
	foreach my $parent ($self->_next_parents($this_node)) {
		if (!$parent and !$parents_exist) {
			$self->_error(
				"No further path could be found for "
				. ($path[0] || $this_node)
				. " at $this_node.  Assuming search is finished."
			);
			return @path;
		}
		$parents_exist = 1;
		#Null parents should be filtered out because they would cause an infinite loop.
		#NOTE TO SELF: might be better written as _raise_exception
		if (!$parent) {
			$self->_error("Null parent.  Skipping.");
			next;
		}
		push @path, $this_node unless ($first);#don't include self
		@path = $self->_get_path($parent, $found, @path);
		return @path if (@path);
	}
	$self->_warn(
		"Could not resolve a geneology of $this_node."
	) if ($first);
	return ();
}

sub _get_section_root {
	my ($self) = @_;
	my $section = $self->_get_section;
	my $children = $self->index->get_children('root', $self->_search_params);
	foreach my $child (@$children) {
		$self->_verbose("$$child{name} is in section $$child{section}");
		return $child if ($child->{section} eq $section);
	}
	return {};
}

sub _get_section {
	my ($self) = @_;
	my ($path) = $self->_next_parents;
	my $section = $self->index->lookup($path, 'section');
	$self->_verbose("section is $section");
	return $section || $self->{'section'};
}

sub _next_parents {
	my ($self, $item) = @_;
	$item ||= $self->dbl->self_path;
	my $parent = $self->index->lookup($item, 'parent');
	my @parents = map {$_ =~ s/:.+//; $_} token_parse($parent);
	if (scalar(@parents) > 1) {
		#re-order preference if the referrer is a parent.
		$parent = $parents[0];
		my $referrer = $self->dbl->req->header_in('Referer');
		#use regexp to catch the actual parent out of the referrer while
		#simultaneously identifying the referrer as a parent.
		my ($newparent) = grep {$referrer =~ /$_/} @parents;
		if ($newparent) {
			$self->_verbose("referrer is $newparent");
			$parent = $newparent;
			@parents = ($parent, grep {$_ ne $parent} @parents);
		}
	}
	return @parents;
}

1;