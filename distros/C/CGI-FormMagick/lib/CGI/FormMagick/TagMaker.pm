=head1 NAME

CGI::FormMagick::TagMaker - Generate HTML tags

=cut

package CGI::FormMagick::TagMaker;
require 5.004;

use strict;
use vars qw($VERSION @ISA $AUTOLOAD);
$VERSION = '1.01';

use Class::ParamParser;
@ISA = qw( Class::ParamParser );

=head1 SYNOPSIS

    use CGI::FormMagick::TagMaker;

    my $html = CGI::FormMagick::TagMaker->new();
    $html->input( type => 'submit' ),

=head1 DESCRIPTION

This Perl 5 object class can be used to generate any HTML tags in a format that
is consistent with the W3C HTML 4.0 standard.  There are no restrictions on what
tags are named, however; you can ask for any new or unsupported tag that comes
along from Netscape or Microsoft, and it will be made.  Additionally, you can
generate lists of said tags with one method call, or just parts of said tags (but
not both at once).

In this implementation, "standard format" means that tags are made as pairs
(<TAG></TAG>) by default, unless they are known to be "no pair" tags.  Tags that
I know to be "no pair" are [basefont, img, area, param, br, hr, input, option,
tbody, frame, comment, isindex, base, link, meta].  However, you can force any
tag to be "pair" or "start only" or "end only" by appropriately modifying your
call to the tag making method.

Also, "standard format" means that tag modifiers are formatted as "key=value" by
default, unless they are known to be "no value" modifiers.  Modifiers that I know
to be "no value" are [ismap, noshade, compact, checked, multiple, selected,
nowrap, noresize, param].  These are formatted simply as "key" because their very
presence indicates positive assertion, while their absense means otherwise.  For
modifiers with values, the values will always become bounded by quotes, which
ensures they work with both string and numerical quantities (eg: key="value").

Note that this class is a subclass of Class::ParamParser, and inherits
all of its methods, "params_to_hash()" and "params_to_array()".

=for testing
TODO: {
    local $TODO = "Write tests for TagMaker!";
    ok(0, "Fake test just to keep 'make test' happy");
}

=cut


# Names of properties for objects of this class are declared here:
my $KEY_AUTO_GROUP = 'auto_group';  # do we make tag groups by default?
my $KEY_AUTO_POSIT = 'auto_posit';  # with methods whose parameters 
	# could be either named or positional, when we aren't sure what we 
	# are given, do we guess positional?  Default is named.

# These extra tag properties work only with AUTOLOAD:
my $PARAM_TEXT = 'text';  #tag pair is wrapped around this
my $PARAM_LIST = 'list';  #force tag groups to be returned in ARRAY ref

# Constant values used in this class go here:

my $TAG_GROUP = 'group';  # values that "what_to_make" can have
my $TAG_PAIR  = 'pair'; 
my $TAG_START = 'start';
my $TAG_END   = 'end';

my %NO_PAIR_TAGS = (  # comments correspond to Bare Bones sections
	basefont => 1,   # PRESENTATION FORMATTING
	img => 1,   # LINKS, GRAPHICS, AND SOUNDS
	area => 1,   # LINKS, GRAPHICS, AND SOUNDS
	param => 1,   # LINKS, GRAPHICS, AND SOUNDS
	br => 1,   # DIVIDERS
	hr => 1,   # DIVIDERS
	input => 1,   # FORMS
	option => 1,   # FORMS
	tbody => 1,   # TABLES
	frame => 1,   # FRAMES
	comment => 1,   # MISCELLANEOUS
	isindex => 1,   # MISCELLANEOUS
	base => 1,   # MISCELLANEOUS
	'link' => 1,   # MISCELLANEOUS
	meta => 1,   # MISCELLANEOUS
);

my %NO_VALUE_PARAMS = (  # comments correspond to Bare Bones sections
	ismap => 1,   # LINKS, GRAPHICS, AND SOUNDS
	noshade => 1,   # DIVIDERS
	compact => 1,   # LISTS
	checked => 1,   # FORMS
	multiple => 1,   # FORMS
	selected => 1,   # FORMS
	nowrap => 1,   # TABLES
	noresize => 1,   # FRAMES
	param => 1,   # SCRIPTS AND JAVA
);

my %PARAMS_PRECEDENCE = (   # larger number means goes first; undef last
	method => 190,
	action => 185,
	type => 180,
	name => 175,
	width => 170,
	height => 165,
	rows => 160,
	cols => 155,
	border => 150,
	cellspacing => 145,
	cellpadding => 140,
	multiple => 135,
	checked => 130,
	selected => 125,
	value => 120,
	target => 115,
	rev => 113,
	rel => 112,
	href => 110,
	src => 105,
	alt => 100,
);

=head1 SYNTAX

Through the magic of autoloading, this class can make any html tag by calling a
class method with the same name as the tag you want.  For examples, use "hr()" to
make a "<HR>" tag, or "p('text')" to make "<P>text</P>".  This also means that if
you mis-spell any method name, it will still make a new tag with the mis-spelled
name.  For autoloaded methods only, the method names are case-insensitive.

If you call a class method whose name ends in either of ['_start', '_end',
'_pair'], this will be interpreted as an instruction to make just part of one tag
whose name are the part of the method name preceeding that suffix.  For example,
calling "p_start( 'text' )" results in "<P>text" rather than "<P>text</P>". 
Similarly, calling "p_end()" will generate a "</P>" only.  Using the '_pair'
suffix will force tags to be made as a pair, whether or not they would do so
naturally.  For example, calling "br_pair" would produce a "<BR></BR>" rather
than the normal "<BR>".  When using either of ['_start','_pair'], the arguments
you pass the method are exactly the same as the unmodified method would use, and
there are no other symantec differences.  However, when using the '_end' suffix,
any arguments are ignored, as the latter member of a tag pair never carries any
attributes anyway.

If you call a class method whose name ends in "_group", this will be interpreted
as an instruction to make a list of tags whose name are the part of the method
name preceeding the "_group".  For example, calling "td_group(
['here','we','are'] )" results in "<TD>here</TD><TD>we</TD><TD>are</TD>" being
generated.  The arguments that you call this method are exactly the same as for
calling a method to make a single tag of the same name, except that the extra
optional parameter "list" can be used to force an ARRAY ref of the new tags to be
returned instead of a scalar.  The symantec difference is that any arguments
whose values are ARRAY refs are interpreted as a list of values where each one is
used in a separate tag; for a single tag, the literal ARRAY ref itself would be
used.  The number of tags produced is equal to the length of the longest ARRAY
ref passed as an argument.  For any other arguments who have fewer than this
count, their last value is replicated and appended enough times as necessary to
make them the same length.  The value of a scalar argument is used for all the
tags.  For example, calling "input_group( type => checkbox, name => 'letters',
value => ['a','b','c'] )" produces '<INPUT TYPE="checkbox" NAME="letters"
VALUE="a"><INPUT TYPE="checkbox" NAME="letters" VALUE="b"><INPUT TYPE="checkbox"
NAME="letters" VALUE="c">'.

All autoloaded methods require their parameters to be in named format.  These
names and values correspond to attribute names and values for the new tags. 
Since "no value" attributes are essentially booleans, they can have any true or
false value associated with them in the parameter list, which won't be printed. 
If an autoloaded method is passed exactly one parameter, it will be interpreted
as the "text" that goes between the tag pair (<TAG>text</TAG>) or after "start
tags" (<TAG>text).  The same result can be had explicitely by passing the named
parameter "text".  Most static (non-autoloaded) methods require positional
parameters, except for start_html(), which can take either format.  The names of
any named parameters can optionally start with a "-".

=cut

# All HTML tags have a method of this class associated with them.

sub AUTOLOAD {
	my $self = shift( @_ );
	$AUTOLOAD =~ m/([^:]*)$/;   # we don't need fully qualified name
	my $called_sub_name = $1;

	my ($tag_name, $what_to_make) = split( '_', $called_sub_name, 2 );
	unless( lc($what_to_make) =~ 
			/^($TAG_GROUP|$TAG_PAIR|$TAG_START|$TAG_END)$/ ) {
		if( $self->{$KEY_AUTO_GROUP} ) {
			$what_to_make = $TAG_GROUP;
		} else {
			$what_to_make = undef;
		}
	}

	my $rh_params = $self->params_to_hash( \@_, 0, $PARAM_TEXT, 
		{}, $PARAM_TEXT );
	my $ra_text = delete( $rh_params->{$PARAM_TEXT} );
	my $force_list = delete( $rh_params->{$PARAM_LIST} );

	if( lc($what_to_make) eq $TAG_GROUP ) {
		return( $self->make_html_tag_group( 
			$tag_name, $rh_params, $ra_text, $force_list ) );
	}

	return( $self->make_html_tag( 
		$tag_name, $rh_params, $ra_text, $what_to_make ) );
}

# This is provided so AUTOLOAD isn't called instead.
sub DESTROY {
}

sub by_params_precedence {
    local $PARAMS_PRECEDENCE{$a} ||= 0;
    local $PARAMS_PRECEDENCE{$b} ||= 0;
    return $PARAMS_PRECEDENCE{$a} <=> $PARAMS_PRECEDENCE{$b};
}

=head1 FUNCTIONS AND METHODS

Note that all the methods defined below are static, so information specific to
autoloaded methods won't likely apply to them.  All of these methods take
positional arguments unless otherwise specified.

=head2 new()

This function creates a new HTML::TagMaker object (or subclass thereof) and 
returns it.

=for testing
BEGIN: { 
    use_ok('CGI::FormMagick::TagMaker'); 
}
my $t = CGI::FormMagick::TagMaker->new();
isa_ok($t, 'CGI::FormMagick::TagMaker');

=cut

sub new {
	my $class = shift( @_ );
	my $self = bless( {}, ref($class) || $class );
	$self->{$KEY_AUTO_GROUP} = 0;
	$self->{$KEY_AUTO_POSIT} = 0;
	return( $self );
}

=head2 groups_by_default([ VALUE ])

This method is an accessor for the boolean "automatic grouping" property of this
object, which it returns.  If VALUE is defined, this property is set to it.  In
cases where we aren't told explicitely that autoloaded methods are making a
single or multiple tags (using ['_start', '_end', '_pair'] and '_group'
respectively), we look to this property to determine what operation we guess. 
The default is "single".  When this property is true, we can make both single and
groups of tags by using a suffix-less method name; however, making single tags
this way is slower than when this property is false.  Also, be aware that when we
are making a "group", arguments that are ARRAY refs are always flattened, and
when we are making a "single", ARRAY ref arguments are always used literally.

=cut

sub groups_by_default {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_AUTO_GROUP} = $new_value;
	}
	return( $self->{$KEY_AUTO_GROUP} );
}

=head2 positional_by_default([ VALUE ])

This method is an accessor for the boolean "positional arguments" property of
this object, which it returns.  If VALUE is defined, this property is set to it. 
With methods whose parameters could be either named or positional, when we aren't
sure what we are given, do we guess positional?  Default is named.

=cut

sub positional_by_default {
	my $self = shift( @_ );
	if( defined( my $new_value = shift( @_ ) ) ) {
		$self->{$KEY_AUTO_POSIT} = $new_value;
	}
	return( $self->{$KEY_AUTO_POSIT} );
}

=head2 make_html_tag( NAME[, PARAMS[, TEXT[, PART]]] )

This method is used internally to do the actual construction of single html tags.
 You can call it directly when you want faster code and/or more control over how
tags are made.  The first argument, NAME, is a scalar that defines the actual
name of the tag we are making (eg: 'br'); it is case-insensitive.  The optional
second argument, PARAMS, is a HASH ref containing attribute names and values for
the new tag; the names (keys) are case-insensitive.  The attribute values are all
printed literally, so they should be scalars.  The optional third argument, TEXT,
is a scalar containing the text that goes between the tag pairs; it is not a tag
attribute.  The optional fourth argument, PART, is a scalar which indicates we
should make just a certain part of the tag; acceptable values are ['pair',
'start', 'end'], and it is case-insensitive.  This method knows which HTML tags
are normally paired or not, which tag attributes take specified values or not,
and acts accordingly.

=cut

sub make_html_tag {
	my ($self, $tag_name, $rh_params, $text, $what_to_make) = @_; 
	$tag_name     = lc($tag_name);
	$what_to_make = lc($what_to_make);
	$text         = $text || '';

	my %tag_params = map { ( lc($_) => $rh_params->{$_} ) } 
		(ref($rh_params) eq 'HASH') ? (keys %{$rh_params}) : ();

	unless( $what_to_make =~ /^($TAG_PAIR|$TAG_START|$TAG_END)$/ ) {
		$what_to_make = 
			$NO_PAIR_TAGS{$tag_name} ? $TAG_START : $TAG_PAIR;
	}
	
	my $tag_name_uc = uc($tag_name);
	
	if( $what_to_make eq $TAG_END ) {
		return( "\n</$tag_name_uc>" );
	}
				
	my $param_str = '';
	foreach my $param ( sort by_params_precedence keys %tag_params ) {
		next if( $NO_VALUE_PARAMS{$param} and !$tag_params{$param} );
		$param_str .= ' '.uc( $param );
		unless( $NO_VALUE_PARAMS{$param} ) {
			if ($tag_params{$param}) {
				$param_str .= "=\"$tag_params{$param}\"";
			}
		}
	}

	if( $what_to_make eq $TAG_START ) {
		return( "\n<$tag_name_uc$param_str>$text" );
	}
		
	return( "\n<$tag_name_uc$param_str>$text</$tag_name_uc>" );
}

=head2 make_html_tag_group( NAME[, PARAMS[, TEXT[, LIST]]] )

This method is used internally to do the actual construction of html tag groups. 
You can call it directly when you want faster code and/or more control over how
tags are made.  The first argument, NAME, is a scalar that defines the actual
name of the tag we are making (eg: 'br'); it is case-insensitive.  The optional
second argument, PARAMS, is a HASH ref containing attribute names and values for
the new tag; the names (keys) are case-insensitive.  Any attribute values which
are ARRAY refs are flattened, and the number of tags made is determined by the
length of the longest one.  The optional third argument, TEXT, is a HASH ref (or
scalar) containing the text that goes between the tag pairs; it is not a tag
attribute, but if its an ARRAY ref then its length will influence the number of
tags that are made as the length of tag attribute arrays do.  The optional fourth
argument, LIST, is a boolean/scalar which indicates whether this method returns
the new tags in an ARRAY ref (one tag per element) or as a scalar (tags are
concatenated together); a true value forces an ARRAY ref, scalar is the default. 
This method knows which HTML tags are normally paired or not, which tag
attributes take specified values or not, and acts accordingly.

=cut

sub make_html_tag_group {
	my $self = shift( @_ );
	my $tag_name = lc(shift( @_ ));
	my $rh_params = shift( @_ );
	my $text_in = shift( @_ );
	my $force_list = shift( @_ );

	my %tag_params = map { ( lc($_) => $rh_params->{$_} ) } 
		(ref($rh_params) eq 'HASH') ? (keys %{$rh_params}) : ();

	$tag_params{$PARAM_TEXT} = $text_in;

	my $max_tag_ind = 0;
	foreach my $key (keys %tag_params) {
		my $ra_values = $tag_params{$key};
		unless( ref($ra_values) eq 'ARRAY' ) {
			$tag_params{$key} = [$ra_values];
			next;
		}
		if( $#{$ra_values} > $max_tag_ind ) {
			$max_tag_ind = $#{$ra_values};
		}
	}

	foreach my $ra_values (values %tag_params) {
		my $last_value = $ra_values->[-1];
		push( @{$ra_values}, 
			map { $last_value } (($#{$ra_values} + 1)..$max_tag_ind) );
	}
	
	my $tag_name_uc = uc($tag_name);
	my $ra_text = delete( $tag_params{$PARAM_TEXT} );
	my @param_seq = sort by_params_precedence keys %tag_params;
	my @new_tags = ();

	foreach my $index (0..$max_tag_ind) {
		my $param_str = '';
		foreach my $param ( @param_seq ) {
			next if( $NO_VALUE_PARAMS{$param} and 
				!$tag_params{$param}->[$index] );
			$param_str .= ' '.uc( $param );
			unless( $NO_VALUE_PARAMS{$param} ) {
				$param_str .= "=\"$tag_params{$param}->[$index]\"";
			}
		}
		my $text = $ra_text->[$index];
		if( $NO_PAIR_TAGS{$tag_name} ) {
			push( @new_tags, "\n<$tag_name_uc$param_str>$text" );
		} else {
			push( @new_tags, 
				"\n<$tag_name_uc$param_str>$text</$tag_name_uc>" );
		}
	}

	return( $force_list ? \@new_tags : join( '', @new_tags ) );
}

1;


=head1 COMPATABILITY WITH OTHER MODULES

The methods of this class and their parameters are designed to be compatible with
any same-named methods in the popular CGI.pm class.  This class will produce
identical or browser-compatible HTML from such methods, and this class can accept
all the same argument formats.  Exceptions to this include:

=over 4

=item 0

None of our methods are exported and must be called using indirect
notation, whereas CGI.pm can export any of it's methods.

=item 0

start_html() doesn't support all the same arguments, but those that do have
the same names.  However, the effects of the missing arguments can be easily
replicated by making the appropriate tags explicitely and handing them in via
either the "head" or "body" arguments, where appropriate.  The common arguments
are ['title', 'author', 'meta', 'style', 'head', 'body'], in that order.

=item 0

Our textarea() method is autoloaded, and doesn't have the special symantecs
that CGI.pm's textarea() does.  However, any module who subclasses from this one
can override textarea() with one that matches CGI.pm's symantecs.  The 
"HTML::FormMaker" module does this.

=item 0

Autoloaded methods do not use the presence or absense of arguments to
decide whether to make the new tag as a pair or as "start only".

=item 0

Autoloaded methods that make html tags won't concatenate their arguments
into a single argument under any circumstances, but in some cases the "shortcuts"
of CGI.pm will do so.

=item 0

Currently we don't html-escape any argument values passed to our tag making
functions, whereas CGI.pm sometimes does.  While we expect our caller to do the
escaping themselves where necessary, we may do it later in an update.

=item 0

We go further to make the generated HTML human-readable by: 1. having each
new tag start on a new line; 2. making all tag and attribute names uppercase; 3.
ensuring that about 20 often-used tag attributes always appear in the same order
(eg: 'type' is before 'name' is before 'value'), and before any others.

=back


=head1 COPYING

Copyright (c) 2000-2001, Kirrily "Skud" Robert <skud@cpan.org>

This module is free software; you can redistribute it and/or modify it
under the same terms and Perl itself. 

This module is based on Darren Duncan's HTML::TagMaker, the copyright
notice for which appears below:

Copyright (c) 1999-2000, Darren R. Duncan. All rights reserved. 

This module is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.  However, I do request that this copyright information 
remain attached to the file.  If you modify this module and redistribute a changed
version then please attach a note listing the modifications.

=head1 SEE ALSO

L<CGI::FormMagick>


=cut
