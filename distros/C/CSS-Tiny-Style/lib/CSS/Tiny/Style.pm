package CSS::Tiny::Style;

use version; $VERSION = qv('0.0.3');

use warnings;
use strict;
use Carp;

use CSS::Tiny;
use HTML::Element;

package CSS::Tiny;

sub selectors {
    my $self = shift;
    return keys %{ $self };
}

sub styles {
    my $self = shift;
    my @styles = $self->_sorted_styles;

    return @styles;
}

sub _sorted_styles {
    return sort { $a->specificity <=> $b->specificity } shift->_all_styles
}

sub _all_styles {
    my $self = shift;
    my @res;
    while (my ($selector, $properties) = each %{ $self }) {
	push @res, CSS::Tiny::Style->new($selector, $properties);
    }
    return @res;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;

    return unless exists $self->{$attr};
    return CSS::Tiny::Style->new($attr, $self->{$attr});
}


sub style {
    my $self = shift;
    my $style = shift;

    return unless exists $self->{$style};
    return CSS::Tiny::Style->new($style, $self->{$style});
}

package CSS::Tiny::Style;

use warnings;
use strict;
no warnings qw/uninitialized/;

use Carp;
use overload
    '""' => \&stringify;

sub new {
    my $class = shift;
    $class = ref $class || $class;

    my $selector = shift || croak "Need a selector";
    my $properties = shift || {};

    my $self = $properties;
    $self->{_selector} = $selector;
    $self->{_selarr}   = undef;    # set later to [];

    bless $self, $class;
}

sub stringify {
    my $self = shift;
    my @fields = grep { !/^_/ } keys %{ $self };
    for (@fields) { $_ = join ":", $_, $self->{$_} };
    return join ';', @fields;
}

##################################################################################################################
# from css spec at http://www.w3.org/TR/REC-CSS2/selector.html#q1
##################################################################################################################
#
#  *			Matches any element.	Universal selector
#
#  E			Matches any E element (i.e., an element of type E).
#
#  E F			Matches any F element that is a descendant of an E element.
#
#  E > F		Matches any F element that is a child of an element E.
#
#  E:first-child	Matches element E when E is the first child of its parent.
#
#  E + F		Matches any F element immediately preceded by a sibling element E.
#
#  E[foo]		Matches any E element with the "foo" attribute set (whatever the value).
#
#  E[foo="warning"]	Matches any E element whose "foo" attribute value is exactly equal to "warning".
#
#  E[foo~="warning"]	Matches any E element whose "foo" attribute value is a list of space-separated values,
# 			one of which is exactly equal to "warning".
#
#  E[lang|="en"]	Matches any E element whose "lang" attribute has a hyphen-separated list of values
# 			beginning (from the left) with "en".
#
#  DIV.warning		Language specific. (In HTML, the same as DIV[class~="warning"].)
#
#  E#myid		Matches any E element with ID equal to "myid".	ID selectors
#
##################################################################################################################

sub element_match {
    my $self = shift;
    my $el = shift || croak "No element to match";

    return if lc $el->tag eq 'html';
    return if lc $el->tag eq 'head';
    return if $el->look_up("_tag", "head");

    my @sel = @_;

    @sel = $self->selector_array unless @sel;


    no strict 'refs';

    my $sel = shift @sel;
    for (qw/tag id class/) {
	my $sub = "_$_";

	next unless (my $val = &$sub($sel));  # skip test if no value in selector

	my $att = /tag/ ? '_tag' : $_;        # HTML::Element behaviour
	$val = $val eq '*' ? $el->tag : $val; # always matches


	return unless ($val && ((lc $val) eq (lc $el->attr($att))));
    }
    use strict 'refs';
    return 1;
}

sub match {
    my $self = shift;

    # the next argument is an element or a listref of elements
    my @el = shift; if (ref $el[0] eq 'ARRAY') { @el = @{$el[0]} };

    my ($sel, $rel, @sel);
    if (@_) {
	(
	 $sel,	# the first selector
	 $rel, 	# the relationship, i.e.: '>' or '+' or ' '
	 @sel	# the remaining selector
	) = @_;
    } else {
	($sel, $rel, @sel) = $self->selector_array;
    }


    #+++++++++++++++++++++++++++++++++++++++++++++++++++++
    # 1) loop through elements
    # 2) check if one matches
    # 3) if it matches, loop through his relatives
    # 4) return true if one matches
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++

    my $match = 0;
    for (@el) {
	if ($self->element_match($_, $sel)) {
	    # if element matches, check his relatives
	    if ($rel) {
		my $rellist = $_->$rel;
		$match = $self->match($rellist, @sel)
	    } else {
		$match = 1;
	    }
	}
	last if $match;
    };
    return $match;
}

sub selector {
    my $self = shift;
    $self->{'_selector'};
}


*selarr = *selector_array;
sub selector_array {
    my $self = shift;
    unless (defined $self->{_selarr}) {
	my $selector = $self->selector;
	my @sel = _sel_arr($selector);
	$self->{_selarr} = [@sel];
    }
    return @{ $self->{_selarr} };
}

sub add_to {
    my $self = shift;
    my $element = shift;

    my $style = $element->attr('style');
    $style = $style eq "" ? $self->stringify : (join ";", ($style, $self->stringify));
    #$style =~ s/^;//; # why why why?
    $element->attr('style', $style)
}

###########################################################################################################
# from CSS spec at http://www.w3.org/TR/CSS21/cascade.html#specificity
###########################################################################################################
# A selector's specificity is calculated as follows:
#
#     * count the number of ID attributes in the selector (= a)
#     * count the number of other attributes and pseudo-classes in the selector (= b)
#     * count the number of element names in the selector (= c)
#     * ignore pseudo-elements.
#
# Concatenating the three numbers a-b-c (in a number system with a large base) gives the specificity.
#
# Example(s):
#
# Some examples:
#
# *             {}  /* a=0 b=0 c=0 -> specificity =   0 */
# LI            {}  /* a=0 b=0 c=1 -> specificity =   1 */
# UL LI         {}  /* a=0 b=0 c=2 -> specificity =   2 */
# UL OL+LI      {}  /* a=0 b=0 c=3 -> specificity =   3 */
# H1 + *[REL=up]{}  /* a=0 b=1 c=1 -> specificity =  11 */
# UL OL LI.red  {}  /* a=0 b=1 c=3 -> specificity =  13 */
# LI.red.level  {}  /* a=0 b=2 c=1 -> specificity =  21 */
# #x34y         {}  /* a=1 b=0 c=0 -> specificity = 100 */
###########################################################################################################

sub specificity {
    my $self = shift;
    return 0 if $self->selector eq '*';
    return (
	    $self->count_ids * 100 +
	    $self->count_attributes * 10 +
	    $self->count_tags
	    );
}

sub tag { _tag(shift->selector) }

sub id { _id(shift->selector) }

sub class { _class(shift->selector) }

sub count_ids {
    my @sel = shift->selarr;
    return scalar grep { /\#/ } @sel
}

sub count_attributes {
    my @sel = shift->selarr;
    return scalar grep { /\./ || /\[/ } @sel
}

sub count_tags {
    my @sel = shift->selarr;
    return int (((scalar grep { !/\*/ } @sel) / 2) + 1)
}

sub _sel_arr {
    local $_ = shift;
    my @d;

    while ($_) {
	my ($tag, $op);


	s/([a-zA-Z0-9.\#\*]+)\s*$//; $tag = $1;
	$op  = $1 if (s/(\s*[+>]*\s*)$//);


	push @d, $tag if $tag;

	for ($op) {
	    /\+/    && do { push @d, 'left';    last; };
	    /\>/    && do { push @d, 'parent';  last; };
	    /^\s+$/ && do { push @d, 'lineage';	last; };
	}
    }
    return @d;
}

sub _tag {
    local $_ = shift;

    return '*' if (/^\./ || /^\#/);
    /^(\w+)[\#\.]*/;
    return $1;
}

sub _id {
    local $_ = shift;
    /\#(\w+)\W*/;
    return $1;
}

sub _class {
    local $_ = shift;
    /\.(\w+)\W*/;
    return $1;
}


1;
__END__

=head1 NAME

CSS::Tiny::Style - Object oriented interface to CSS stylesheets


=head1 VERSION

This document describes CSS::Tiny::Style version 0.0.3


=head1 SYNOPSIS

    #------------------------------------------------------
    # simple example
    #------------------------------------------------------

    use CSS::Tiny;
    use CSS::Tiny::Style;
    use HTML::Element; 

    $el = HTML::Element->new('p');
    $el->attr('class', 'myclass');

    $cts = CSS::Tiny::Style->new('p.myclass')
    $cts->match($el) # return true

    #------------------------------------------------------
    # more interesting example
    #------------------------------------------------------
    # inline a stylesheet onto the single HTML elements
    #------------------------------------------------------

    use HTML::TreeBuilder;


    my $tree = HTML::TreeBuilder->new();
    $tree->parse_file('filename.html');

    $css = CSS::Tiny->read( 'stylesheet.css' );

    for my $el ($tree->descendants) {
	for my $st ($css->styles) {
	    if ($st->match($el)) {
		$st->add_style($el);
	    }
	}
    }
    print $tree->as_HTML;
  
  

=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 Constructor

=head3 new

  my $selector_string = 'div.index li.new';
  my $style = CSS::Tiny::Style->new($selector_string);

Returns a new CSS::Tiny::Style object

=head2 Using with CSS::Tiny

CSS::Tiny::Styles provides two additional methods to CSS::Tiny, making
it possible to generate CSS::Tiny::Styles on the fly by parsing a stylesheet like this:

    $css = CSS::Tiny->read( 'stylesheet.css' );

=head3 CSS::Tiny->styles

    @styles = CSS::Tiny->styles

Returns a list of CSS::Tiny::Style objects made up of all the style definitions in CSS::Tiny


=head3 CSS::Tiny->selectors

    @selectors = CSS::Tiny->selectors

Returns a list of selector strings in the CSS::Tiny object


=head2 Selectors

=head3 tag

  my $style = CSS::Tiny::Style->new('pre');
  print $style->tag; # prints "pre"

Returns the tag part of the selector


=head3 id

  my $style = CSS::Tiny::Style->new('li#leftmenu');
  print $style->id; # prints "leftmenu"

Returns the id part of the selector


=head3 class

  my $style = CSS::Tiny::Style->new('p.big');
  print $style->class; # prints "big"

Returns the class part of the selector


=head3 selector

  my $style = CSS::Tiny::Style->new('div.sidebar p.new');
  print $style->selector; # prints "div.sidebar p.new"

Returns the selector string


=head3 selector_array

  my $style = CSS::Tiny::Style->new('div.main div.sidebar > p.new');
  @sel_arr = $style->selector_array;
  print join "::" @sel_arr;
  # prints 

Returns an array of element tags (i.e: p.important) alternated with
strings derived from relative selectors (i.e.: the ">" or "+" or " "
between element tags.

Relative selectors are transformed as follows:

'+' becomes 'left'

'>' becomes 'parent'

' ' becomes 'lineage'


=head3 selarr

selarr is an alias for selector_array

=head2 Specificity

=head3 specificity

  my $style = CSS::Tiny::Style->new('h1.menu li.myclass');
  print $style->specificity # prints 22

Returns the selector's specificity as described in
L<http://www.w3.org/TR/CSS21/cascade.html#specificity>. A base 100 is
used.

=head3 count_tags

  my $style = CSS::Tiny::Style->new('h1.menu li.myclass #foo');
  print $style->count_tags # prints 2

Return the number of tags in the selector


=head3 count_ids

  my $style = CSS::Tiny::Style->new('h1#bar li.myclass #foo');
  print $style->count_ids # prints 2

Return the number of ids in the selector


=head3 count_attributes

  my $style = CSS::Tiny::Style->new('h1.menu li #foo');
  print $style->count_attributes # prints 1

Return the number of attributes in the selector


=head2 Matching and inlining

=head3 match

    $el = HTML::Element->new('p');
    $el->attr('class', 'myclass');

    $cts = CSS::Tiny::Style->new('p.myclass')
    $cts->match($el) # return true

Returns true if the style selector matches on the HTML::Element
object, taking into account all its relatives (siblings, ancestors,
parent).

=head3 element_match

    $el = HTML::Element->new('p');
    $el->attr('class', 'myclass');

    $cts = CSS::Tiny::Style->new('p.myclass')
    $cts->element_match($el) # return true

Returns true if the style selector matches on the HTML::Element object
without taking into account the ancestors.

=head3 add_to

Inlines the style definition into the element.


=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.




=head1 DEPENDENCIES

  CSS::Tiny
  HTML::Element

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS

No bugs have yet been reported.

Please report any bugs or feature requests to
C<bug-css-tiny-style@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 LIMITATIONS

=head2 Attribute selectors

Does not handle E[foo] type selectors

=head2 Repeated properties

Allows duplicated setting of the same property in a inline style definition

=head2 Inheritance

Does not handle inherited properties

=head1 AUTHOR

Simone Cesano  C<< <scesano@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Simone Cesano C<< <scesano@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
