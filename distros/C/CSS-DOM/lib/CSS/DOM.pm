package CSS::DOM;

use 5.008002;

$VERSION = '0.17';

use   # to keep CPANTS happy :-)
   strict;
use   # same here
   warnings;

use CSS::DOM::Exception
	'SYNTAX_ERR' ,'HIERARCHY_REQUEST_ERR', 'INDEX_SIZE_ERR';
use CSS::DOM::Constants 'STYLE_RULE';
use Scalar::Util 'weaken';

require CSS::DOM::RuleList;

use constant 1.03 our $_constants = {
	ruls => 0,
	ownr => 1, # owner rule
	node => 2, # owner node
	dsbl => 3,
	hrfe => 4,
	medi => 5,
	fetc => 6, # url fetcher
	prsh => 7, # parent sheet
	prpp => 8, # property parser
};
{ no strict; delete @CSS::DOM::{_constants => keys %{our $_constants}} }


# NON-DOM METHODS

# classy method
sub new {
	my $self = bless[],shift;
	my %args = @_;
	if(defined(my $arg = delete $args{url_fetcher})) {
		$self->[fetc] = $arg;
	}
	$self->[prpp] = delete $args{property_parser};
	$self;
}

# objectionable methods
sub url_fetcher {
	my $old = (my$ self = shift)->[fetc];
	$ self -> [ fetc ] = shift if @ _ ;
	$old
}
sub property_parser { shift->[prpp] }


# FUNCTIONS

sub parse {
	require CSS::DOM::Parser;
	goto &CSS::DOM::Parser::parse;
}

sub compute_style {
	my %args = @_;
	# ~~~ for now we just ignore medium/height/width/ppi. We need to
	#     support those, too.

	require CSS::DOM::Style;
	my $style = new CSS::DOM::Style;

	my $elem = delete $args{element};
	my $pseudo = delete $args{pseudo};
	$pseudo && $pseudo =~ s/^::?//;
	
	# The specificity returned by the style rule is a three-character
	# string representing the number of id, attr, and elem selector
	# components (e.g., li.red.level gives "\0\2\1"). We prefix that
	# with two more chars, to make:
	#   XXXXX
	#   ||||`-- element
	#   |||`-- attribute
	#   ||`-- id
	#   |`-- style attribute
	#   `-- style sheet

	# ‘Style attribute’ is \1 or \0, indicating whether the CSS proper-
	# ties originate from a style attribute. ‘Style sheet’ is
	# as follows:
	#  "\0") user agent normal declarations
	#  "\1") user normal declarations
	#  "\2") author normal     "
	#  "\3") user agent !important declarations
	#  "\4") author !important "
	#  "\5") user      "       "

	# The individual properties are sorted according to this scheme.


	# ~~~ This isn’t the most efficient algorithm. Perhaps we can cache
	#     some of this.

	my %specificity; # per property

	my @normal_spec;
	my @important_spec;
	my @sheets;
	if(defined $args{ua_sheet}) {
		push @normal_spec, chr 0;
		push @important_spec, chr 3;
		push @sheets, delete $args{ua_sheet};
	}
	if(defined $args{user_sheet}) {
		push @normal_spec, chr 1;
		push @important_spec, chr 5;
		push @sheets, delete $args{user_sheet};
	}
	if(defined $args{author_sheets}) {
		my $s = delete $args{author_sheets};
		push @normal_spec, (chr 2) x @$s;
		push @important_spec, (chr 4) x @$s;
		push @sheets, @$s;
	}
	while(@sheets) {
		my $n = shift @normal_spec;
		my $i = shift @important_spec;
		my $s = shift @sheets;
		my @rules = $s->cssRules;
		while(@rules) {
			my $r = shift @rules;
			my $type = $r->type;
			if($type == STYLE_RULE) {
				next unless
				  my $specificity = $r->_selector_matches(
				    $elem, $pseudo
				  );
				my $sty = $r->style;
				for(0..$sty->length-1) {
					my $p = $sty->item($_);
					my $spec = (
					 $sty->getPropertyPriority($p)
					  =~
					 /^important\z/i
					 ? $i : $n
					) . "\0$specificity";
					no warnings 'uninitialized';
					$spec ge $specificity{$p} and
					  $style->setProperty(
					   $p, $sty->getPropertyValue($p)
					  ),
					  $specificity{$p} = $spec;
				}
			}
		}
	}
	
	my $sty = $elem->style;
	for(0..$sty->length-1) {
					my $p = $sty->item($_);
					my $spec = (
					 $sty->getPropertyPriority($p)
					  =~
					 /^important\z/i
					 ? "\4" : "\3"
					) . "\1\0\0\0";
					no warnings 'uninitialized';
					$spec ge $specificity{$p} and
					  $style->setProperty(
					   $p, $sty->getPropertyValue($p)
					  ),
					  $specificity{$p} = $spec;
	}

	return $style;
}


# DOM STUFF:

# StyleSheet interface:

sub type { 'text/css' }
sub disabled {
	my $old = (my $self = shift) ->[dsbl];
	@_ and $self->[dsbl] = shift;
	$old
};
sub ownerNode { defined $_[0][node]?$_[0][node]:() }
sub set_ownerNode { weaken($_[0]->[node] = $_[1]) }
sub parentStyleSheet { shift->[prsh]||() }
sub _set_parentStyleSheet { weaken($_[0]->[prsh] = $_[1]) }
sub href { shift->[hrfe] }
sub set_href { $_[0]->[hrfe] = $_[1] }
sub title { no warnings 'uninitialized';
           ''.(shift->ownerNode || return)->attr('title') }

# If you find a bug in here, Media.pm’s method probably also needs fixing.
sub media {
	wantarray ? @{$_[0]->[medi]||return} :
		($_[0]->[medi] ||= (
			require CSS::DOM::MediaList,
			CSS::DOM::MediaList->new
		))
}


# CSSStyleSheet interface:

sub ownerRule {
	shift->[ownr] || ()
}
sub _set_ownerRule {
	weaken($_[0]->[ownr] = $_[1]);
}

# If you find a bug in the following three methods, Media.pm’s methods
# probably also need fixing.
sub cssRules { 
	wantarray
		? @{shift->[ruls]||return}
		: (shift->[ruls]||=new CSS::DOM::RuleList);
}

sub insertRule { # This is supposed to raise an HIERARCHY_REQUEST_ERR if
                 # the rule cannot be inserted at the specified  index;
                 # e.g.,  if an  @import  rule is inserted after a stan-
                 # dard rule. But we don’t do that, in order to maintain
                 # future compatibility.
	my ($self, $rule_string, $index) = @_;
	
	require CSS::DOM::Parser;
	my ($at,$rule);
	{
		local *@;
		$rule = CSS::DOM::Parser::parse_statement(
		 $rule_string,$self
		);
		$at = $@
	}
	$at and die new CSS::DOM::Exception SYNTAX_ERR, $at;

#	$rule->_set_parentStyleSheet($self);

	my $list = $self->cssRules; # cssRules takes care of ||=
	splice @$list, $index, 0, $rule;

	$index < 0        ? $#$list + $index :
	$index <= $#$list ? $index           :
	                    $#$list
}

sub deleteRule {
	my ($self,$index) = @_;
	my $list = $self->[ruls];
	$index > $#$list and die CSS::DOM::Exception->new(
		INDEX_SIZE_ERR,
		"The index passed to deleteRule ($index) is too large"
	);
	splice @$list, $index, 1;
	return # nothing;
}



my %features = (
	stylesheets => { '2.0' => 1 },
#	css => { '2.0' => 1 },
	css2 => { '2.0' => 1 },
);

sub hasFeature {
	my($feature,$v) = (lc $_[1], $_[2]);
	exists $features{$feature} and
		!defined $v || exists $features{$feature}{$v};
}

                              !()__END__()!

=encoding utf8

=head1 NAME

CSS::DOM - Document Object Model for Cascading Style Sheets

=head1 VERSION

Version 0.17

This is an alpha version. The API is still subject to change. Many features
have not been implemented yet (but patches would be welcome :-).

The interface for feeding CSS code to CSS::DOM changed incompatibly in
version 0.03.

=for comment
This is an alpha version. If you could please test it and report any bugs
(via e-mail), I would be grateful.

=head1 SYNOPSIS

  use CSS::DOM;

  my $sheet = CSS::DOM::parse( $css_source );

  use CSS::DOM::Style;
  my $style = CSS::DOM::Style::parse(
      'background: red; font-size: large'
  );

  my $other_sheet = new CSS::DOM; # empty
  $other_sheet->insertRule(
     'a{ text-decoration: none }',
      $other_sheet->cssRules->length,
  );
  # etc.
  
  # access DOM properties
  $other_sheet->cssRules->[0]->selectorText('p'); # change it
  $style->fontSize;          # returns 'large'
  $style->fontSize('small'); # change it

=head1 DESCRIPTION

This set of modules provides the CSS-specific interfaces described in the
W3C DOM
recommendation.

The CSS::DOM class itself implements the StyleSheet and CSSStyleSheet DOM
interfaces.

This set of modules has two modes:

=over

=item 1

It can validate property values,
ignoring those that are invalid (just like a real web browser), and support shorthand
properties. This means you can set font to '13px/15px My Font' and have the 
font-size, line-height, and font-family properties (among others) set automatically. Also, C<color: green; color: kakariki> will assign 'green' 
to the color
property, 'kakariki' not being a recognised color value.

=item 2

It can
blithely accept all property assignments as being valid. In the case of
C<color: green; color: kakariki>, 'kakariki' will be assigned, since it overrides the previous
assignment.

=back

These two modes are controlled by the C<property_parser> option to the
constructors.

=head1 CONSTRUCTORS

=over 4

=item CSS::DOM::parse( $string )

This method parses the C<$string> and returns a style sheet object. If you
just have a CSS style declaration, e.g., from an HTML C<style> attribute,
see L<CSS::DOM::Style/parse>.

=item new CSS::DOM

Creates a new, empty style sheet object. Use this only if you plan to build
the style sheet piece by piece, instead of parsing a block of CSS code.

=back

You can pass named arguments to both of those. C<parse> accepts all of
them; C<new> understands only the first two, C<property_parser> and
C<url_fetcher>.

=over

=item property_parser

Set this to a L<PropertyParser|CSS::DOM::PropertyParser> object to specify
which properties are supported and how they are parsed.

If this option is not specified or is set to C<undef>, all property
values are treated as valid.

See L<CSS::DOM::PropertyParser> for more details.

=item url_fetcher

This has to be a code ref that returns the contents
of the style sheet at the URL passed as the sole argument. E.g.,

  # Disclaimer: This does not work with relative URLs.
  use LWP::Simple;
  use CSS::DOM;
  $css = '@import "file.css"; /* other stuff ... ';
  $ss = CSS::DOM::parse $css, url_fetcher => sub { get shift };
  $ss->cssRules->[0]->styleSheet; # returns a style sheet object
                                  # corresponding to file.css

The subroutine can choose to return C<undef> or an empty list, in which 
case the @import 
rule's C<styleSheet> method will return null (empty list or C<undef>), as
it would if no C<url_fetcher> were specified.

It can also return named items after the CSS code, like this:

  return $css_code, decode => 1, encoding_hint => 'iso-8859-1';

These correspond to the next two items:

=item decode

If this is specified and set to a true value, then CSS::DOM will treat the
CSS code as a string of bytes, and try to decode it based on @charset rules
and byte order marks.

By default it assumes that it is already in Unicode (i.e., decoded).

=item encoding_hint

Use this to provide a hint as to what the encoding might be.

If this is specified, and C<decode> is not, then C<< decode => 1 >> is
assumed.

=back

=head1 STYLE SHEET ENCODING

See the options above. This section explains how and when you I<should> use
those options.

According to the CSS spec, any encoding specified in the 'charset' field on
an HTTP Content-Type header, or the equivalent in other protocols, takes
precedence. In such a case, since CSS::DOM doesn't deal with HTTP, you have
to decode it yourself.

Otherwise, you should use C<< decode => 1 >> to instruct CSS::DOM to use
byte order marks or @charset rules.

If neither of those is present, then encoding data in the referencing
document (e.g., <link charset="..."> or an HTML document's own encoding),
if available/applicable, should be used. In this case, you should use the
C<< encoding_hint >> option, so that CSS::DOM has something to fall back
to.

If you use C<< decode => 1 >> with no encoding hint, and no BOM or @charset
is to be found, UTF-8 is assumed.

=head1 SYNTAX ERRORS

The two constructors above, and also
L<C<CSS::DOM::Style::parse>|CSS::DOM::Style/parse>, set C<$@> to the empty 
string upon success. If 
they
encounter a syntax error, they set C<$@> to the error and return an object
that represents whatever was parsed up to that point.

Other methods that parse CSS code might die on encountering
syntax errors, and should usually be wrapped in an C<eval>.

The parser follows the 'future-compatible' syntax described in the CSS 2.1
specification, and also the spec's rules for handling parsing errors.
Anything not handled by those two is a syntax error.

In other words, a syntax error is one of the following:

=over 4

=item *

An unexpected closing bracket, as
in these examples

  a { text-decoration: none )
  *[name=~'foo'} {}
  #thing { clip: rect( ]

=item *

An HTML comment delimiter within a rule; e.g.,

  a { text-decoration : none <!-- /* Oops! */ }
  <!-- /*ok*/ @media --> /* bad! */ print { }

=item *

An extra C<@> keyword or semicolon where it doesn't belong; e.g.,

  @media @print { .... }
  @import "file.css" @print;
  td, @page { ... }
  #tabbar td; #tab1 { }

=back

=head1 OBJECT METHODS

=head2 Attributes

=over 4

=item type

Returns the string 'text/css'.

=item disabled

Allows one to specify whether the style sheet is used. (This attribute is
not actually used yet by CSS::DOM.) You can set it by passing an argument.

=item ownerNode

Returns the node that 'owns' this style sheet.

=item parentStyleSheet

If the style sheet belongs to an '@import' rule, this returns the style
sheet containing that rule. Otherwise it returns an empty list.

=item href

Returns the style sheet's URI, if applicable.

=item title

Returns the value of the owner node's title attribute.

=item media

Returns the MediaList associated with the style sheet (or a plain list in
list context). This defaults to an
empty list. You can pass a comma-delimited string to the MediaList's
C<mediaText> method to initialise it.

(The medium information is not actually used [yet] by CSS::DOM, but you
can put it there.)

=item ownerRule

If this style sheet was created by an @import rule, this returns the rule;
otherwise it returns an empty list (or undef in scalar context).

=item cssRules

In scalar context, this returns a L<CSS::DOM::RuleList> object (simply a
blessed
array reference) of L<CSS::DOM::Rule> objects. In list context it returns a
list.

=back

=head2 Methods

=over 4

=item insertRule ( $css_code, $index )

Parses the rule contained in the C<$css_code>, inserting it in the style
sheet's list of rules at the given C<$index>.

=item deleteRule ( $index )

Deletes the rule at the given C<$index>.

=item hasFeature ( $feature, $version )

You can call this either as an object or class method.

This is actually supposed to be a method of the 'DOMImplementation' object.
(See, for instance, L<HTML::DOM::Interface>'s method of the same name,
which delegates to this one.) This returns a boolean indicating whether a
particular DOM module is implemented. Right now it returns true only for
the 'CSS2' and 'StyleSheets' features (version '2.0').

=back

=head2 Non-DOM Methods

=over 4

=item set_ownerNode

This allows you to set the value of C<ownerNode>. Passing an argument to
C<ownerNode> does nothing, because it is supposed to be read-only. But you
have to be able to set it somehow, so that's why this method is here.

The style sheet will hold a weak reference to the object passed to this
method.

=item set_href

Like C<set_ownerNode>, but for C<href>.

=item property_parser

=item url_fetcher

These two both return what was passed to the constructor. The second one,
C<url_fetcher> also allows an assignment, but this is not propagated to
sub-rules and is intended mainly for internal use.

=back

=head1 FUNCTIONS

=over

=item CSS::DOM::parse

See L</CONSTRUCTORS>, above.

=item CSS::DOM::compute_style( %options )

B<Warning:> This is still highly experimental and crawling with bugs.

This computes the style for a given HTML element. It does not yet calculate
actual measurements (e.g., converting percentages to pixels), but simply
applies the cascading rules and selectors. Pseudo-classes are
not yet supported (but pseudo-elements are).

The precedence rules for normal vs important declarations in the CSS 2 
specification are used. (CSS 2.1 is unclear.) The precedence is as follows,
from lowest to highest:

 user agent normal declarations
 user normal declarations
 author normal     "
 user agent !important declarations
 author !important "
 user      "       "

The C<%options> are as follows. They are all optional except for 
C<element>.

=over

=item ua_sheet

The user agent style sheet

=item user_sheet

The user style sheet

=item author_sheets

Array ref of style sheets that the HTML document defines or links to.

=item element

The element, as an L<HTML::DOM::Element> object.

=item pseudo

The pseudo-element (e.g., 'first-line'). This can be specified with no 
colons (the way Opera
requires it) or
with one or two colons (the way Firefox requires it).

=item medium

=item height

=item width

=item ppi

(To be implemented)

=back

The 

=back

=head1 CLASSES AND DOM INTERFACES

Here are the inheritance hierarchy of CSS::DOM's various classes and the
DOM interfaces those classes implement. For brevity's sake, a simple '::'
at the beginning of a class name in the left column is used for
'CSS::DOM::'. Items in brackets do not exist yet. (See also 
L<CSS::DOM::Interface> for a
machine-readable list of standard methods.)

  Class Inheritance Hierarchy  Interfaces
  ---------------------------  ----------
  
  CSS::DOM                     StyleSheet, CSSStyleSheet
  ::Array
      ::MediaList              MediaList
      ::StyleSheetList         StyleSheetList
      ::RuleList               CSSRuleList
  ::Rule                       CSSRule, CSSUnknownRule
      ::Rule::Style            CSSStyleRule
      ::Rule::Media            CSSMediaRule
      ::Rule::FontFace         CSSFontFaceRule
      ::Rule::Page             CSSPageRule
      ::Rule::Import           CSSImportRule
      ::Rule::Charset          CSSCharsetRule
  ::Style                      CSSStyleDeclaration, CSS2Properties
  ::Value                      CSSValue
  ::Value::Primitive           CSSPrimitiveValue, RGBColor, Rect
  ::Value::List                CSSValueList
 [::Counter                    Counter]

CSS::DOM does not implement the following interfaces (see L<HTML::DOM> for
these):

  LinkStyle
  DocumentStyle
  ViewCSS
  DocumentCSS
  DOMImplementationCSS
  ElementCSSInlineStyle

=head1 IMPLEMENTATION NOTES

=over 4

=item *

Attributes of objects are accessed via methods of the same name. When the
method
is invoked, the current value is returned. If an argument is supplied, the
attribute is set (unless it is read-only) and its old value returned.

=item *

Where the DOM spec. says to use null, undef or an empty list is used.

=item *

Instead of UTF-16 strings, CSS::DOM uses Perl's Unicode strings.

=item *

Each method that the specification says returns an array-like object (e.g.,
a RuleList) will return such an object in scalar context, or a simple list
in list context. You can use
the object as an array ref in addition to calling its C<item> and 
C<length> methods.

=begin for-me

If I implement any methods that make use of the DOMTimeStamp interface, I
need to document that simple Perl scalars containing the time as returned
by Perl’s built-in ‘time’ function are used.

=end for-me

=back

=head1 PREREQUISITES

perl 5.8.2 or higher

L<Exporter> 5.57 or later

L<Encode> 2.10 or higher

L<Clone> 0.09 or higher

=head1 BUGS

The parser has not been updated to conform to the April 2009 revision of 
the CSS 2.1 candidate recommendation. Specifically, unexpected closing 
brackets are not ignored, but cause syntax errors; and @media rules 
containing unrecognised statements are themselves currently treated as 
unrecognised (the unrecognised inner statements should be ignored, 
rendering the outer @media rule itself valid).

If you create a custom property parser that defines
'list-style-type' to include multiple tokens, then counters will become
C<CSS_CUSTOM> CSSValue objects instead of C<CSS_COUNTER> CSSPrimitiveValue
objects.

If you change a property parser's property definitions such that a 
primitive value becomes a list, or vice versa, and then try to modify the
C<cssText> property of an existing value object belonging to that property,
things will go awry.

=for comment
This is because we can’t change a list into a prim and vice versa, because
one is a hash and the other is an array.

Whitespace and comments are sometimes preserved in serialised CSS and 
sometimes not.
Expect inconsistency.

To report bugs, please e-mail the author.

=head1 ACKNOWLEDGEMENTS

Thanks to Ville Skyttä, Nicholas Bamber and Gregor Herrmann for their
contributions.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2007-18 Father Chrysostomos <sprout [at] cpan
[dot] org>

This program is free software; you may redistribute it and/or modify
it under the same terms as perl. The full text of the license can be found
in the LICENSE file included with this module.

=head1 SEE ALSO

All the classes listed above under L</CLASSES AND DOM INTERFACES>.

L<CSS::SAC>, L<CSS.pm|CSS> and L<HTML::DOM>

The DOM Level 2 Style specification at
S<L<http://www.w3.org/TR/DOM-Level-2-Style>>

The CSS 2.1 specification at S<L<http://www.w3.org/TR/CSS21/>>
