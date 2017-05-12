# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::XSP::TaglibHelper;
use base 'AxKit2::Transformer::XSP';

use XML::LibXML;

use strict;

sub parse_char {
    my ($e, $text) = @_;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    return ". q|$text|";
}

# Try to find the given function name and see if it's in the "use"ing
# module's list of exported functions. Retuns the function spec if
# if it found it, or undef if it didn't.
sub is_function ($$) {
    my ($pkg, $fname) = @_;

    no strict;
    my @exports = @{"$pkg\::EXPORT_TAGLIB"};
    use strict;

    foreach my $funspec(@exports) {
        return $funspec if $funspec =~ /^$fname *\(/;
    }

    return undef;
}

sub func_name ($) {
    my ($funspec) = @_;

    my %opts = func_options($funspec);
    return $opts{isreally} if $opts{isreally};
    my ($argspec) = ($funspec =~ /^ *(.*?)\(/);
    return $argspec;
}

sub func_options ($) {
    my ($funspec) = @_;

    my @args = split (/:\s*/, $funspec);
    shift @args;
    my %retval = ();
    foreach (@args) {
        #                            |     |  Bra!
        my ($key, $value) = ($_ =~ /(.*)=(.*)/);
        $retval{$key} = $value;
    }
    return %retval;
}

sub required_args ($) {
    my ($funspec) = @_;

    my ($argspec) = ($funspec =~ /\(\s*([^\);]*)/);
    my @retval;
    foreach my $arg(split (/,/, $argspec)) {
        $arg =~ s/^\s*//g;
        $arg =~ s/\s*$//g;
        push (@retval, $arg);
    }
    return @retval;
}

sub optional_args ($) {
    my ($funspec) = @_;

    my ($argspec) = ($funspec =~ /; *([^\)]*)/);
    my @retval;
    if ($argspec) {
       foreach my $arg (split (/,/, $argspec)) {
           $arg =~ s/^\s*//g;
           $arg =~ s/\s*$//g;
           push (@retval, $arg);
       }
    }
    return @retval;
}

sub find_arg ($@) {
    my $argname = shift;

    foreach (@_) { return $_ if /^.$argname/ }
    return "";
}

# quieten warnings when compiling
sub handle_result ($$$$$;@);

# The input to this function is the *result* from a taglib function, and
# therefore can be anything. We need to be able to turn it into a set
# of XML tags.
sub handle_result ($$$$$;@) {
    my $funspec     = shift;
    my $lastkey	  = shift; # If parent was a hash, else this is undef.
    my $indentlevel = shift;
    my $document    = shift;
    my $parent      = shift;

    my $indent = '  ' x $indentlevel;

    my %options = func_options($funspec);

    if ($options{as_xml}) {
        $parent->appendWellBalancedChunk(shift);
        return;
    }

    # if we got more than one result (we assume it's an array),
    # we'll act as if we got a single arrayref
    # forcearray makes it always think there's an array; useful
    # for functions that are returning an array of one value
    if ($indentlevel == 0 and ($options{forcearray} or scalar @_ > 1)) {
	# if thre's one item, and it's undef, return an arrayref to an empty array
	if (scalar @_ == 1 and !defined($_[0])) {
		@_ = ([]);
	} else {
	        @_ = ([@_]);
	}
    }
    
    # break down each arg in the results, possibly call self recursively
    foreach my $ref(@_) {
        if ( (ref($ref)) =~ /ARRAY/) {

            # arrays are hard because they're not keyed except by numbers
            # the array list itself will have a wrapper tag of funcname+"-list" if
            # we're at indent level 0, or no wrapper if it's below level 0
            if ($indentlevel == 0) {
                $parent->appendChild($document->createTextNode("\n" . $indent));
                my $el;
                if ($options{listtag}) {
                    $el = $document->createElement($options{listtag});
                }
                else {
                    my $funcname = $options{'array_uses_hash'} ? $lastkey : 
                    	func_name($funspec) || func_name($funspec);
                    $funcname =~ s/_|\s/-/g;    # convert back to XML-style tagnames
                    $el = $document->createElement("${funcname}-list");
                }
                $parent->appendChild($el);
                $parent = $el;
            }

            my $id = 1;
            foreach my $value(@$ref) {
        # each item within an array should have a wrapper "-item" tag
        my $item;
        if ($options{itemtag}) {
            $item = $document->createElement($options{itemtag});
        }
        else {
            my $funcname = $options{'array_uses_hash'} ? $lastkey : 
                    func_name($funspec) || func_name($funspec);
            $funcname =~ s/_|\s/-/g;    # convert back to XML-style tagnames
            $item = $document->createElement("${funcname}-item");
        }
                $item->setAttribute("id", $id++);
                $parent->appendChild($item);
                handle_result($funspec, $lastkey, $indentlevel + 1, $document, $item, $value);
            }
        }
        elsif ( (ref($ref)) =~ /HASH/) {
            # hashes are relatively easy because they're keyed
            $parent->appendChild($document->createTextNode("\n" . $indent));
            while (my ($key, $value) = each %$ref) {
                my $el = $document->createElement($key);
                $parent->appendChild($el);
                handle_result($funspec, $key, $indentlevel + 1, $document, $el, $value);
            }
        }
        else {

            # not arrayref or not hashref: it's either a scalar or an unsupported
            # type, so we'll just dump it as text
            # special case: at the highest level of hierarchy, we can just return a
            # string because it will be turned automatically into a text node by
            # AxKit
            if ($indentlevel == 0) {
                return $_[0];
            }
            elsif (defined $_[0]) {
                $parent->appendChild($document->createTextNode($_[0]));
            }
        }

    }
}

$main::indent = 0;

# quieten warnings when compiling
sub convert_from_dom ($$);
# This function converts from a DOM tree into a collection of hashes.
# It's used for "*" taglib arguments.
sub convert_from_dom ($$) {
    my ($funspec, $node) = @_;
local $main::indent = $main::indent;
$main::indent++;
require Data::Dumper;
    # if we're at the first level, we'll ignore our top node, because we know it's just
    # a dummy root node
    if (UNIVERSAL::isa($node, "XML::LibXML::Element")) {
        my @children = ($node->getChildnodes,$node->getAttributes);
        my $multiple = 0;
        my %mdetect = ();
        # look for multiple children with the same name, which
        # means we should treat it as an array
        foreach (@children) {
            # sometimes we get blank text nodes; we don't want 'em
            next if UNIVERSAL::isa($_, "XML::LibXML::Text") and $_->getData eq '';
  
            $multiple = 1 if $mdetect{$_->getName};
            $mdetect{$_->getName} = 1;
        }
                # special option might force us to treat it as an array regardless
                if (!$multiple && @children == 1) {
                        my %opts = func_options($funspec);
                        if (my $taglist = $opts{tagisarray}) {
                                $multiple = 1
                                        if grep 
                                                { $_ eq $node->getName } 
                                                split(/,/, $opts{tagisarray}); 
                        }

                }

        if ($multiple) {
            my $retval = [];
            foreach (@children) {
            # sometimes we get blank text nodes; we don't want 'em
            next if UNIVERSAL::isa($_, "XML::LibXML::Text") and $_->getData eq '';
                push(@$retval, convert_from_dom($funspec,$_));
            }
            return $retval;
        }
        else {
                        # <list>text</list>  converts to { list => 'text' },
                        # <list><item>text</item></list> converts to { list => { item => 'text' } };
                        # in other words, if there's only one child, we need to figure out
                        # if it's a text node or a regular tag
                        if ((@children > 1) or (@children == 1 and not UNIVERSAL::isa($children[0], "XML::LibXML::Text"))) {
                my $retval   = {};
                foreach (@children) {
					my $name = $_->getName;
            # sometimes we get blank text nodes; we don't want 'em
            next if UNIVERSAL::isa($_, "XML::LibXML::Text") and $_->getData eq '';
					$name = 'TEXT' if UNIVERSAL::isa($_, "XML::LibXML::Text");
                    $retval->{$name} = convert_from_dom($funspec,$_);
               }
                return $retval;
            }
            elsif (@children == 1) {
                my $retval = convert_from_dom($funspec,$children[0]);
                return $retval;
            }
        }
        return "";
    }
    else {

        # we'll just assume it's text for now
        return $node->getData;
    }
}

@AxKit2::XSP::TaglibHelper::function_stack = ();

sub parse_start {
    my ($e, $tag, %attribs) = @_;
    # Dashes are more "XML-like" than underscores, but we can't use
    # dashes in function or argument names. So we'll just convert them
    # arbitrarily here.
    $tag =~ s/-/_/g;

    my $pkg = $AxKit2::XSP::TaglibPkg;

    # horrible hack: if the caller is the SAX library directly,
    # then we'll just have to assume that we're testing TaglibHelper
    $pkg = "AxKit2::XSP::TaglibHelper" if $pkg eq "AxKit2::XSP::SAXHandler";
    my $funspec = is_function($pkg, $tag);

    my $code = "";
    if ($funspec) {
        my %options = func_options($funspec);
        push (@AxKit2::XSP::TaglibHelper::function_stack, $funspec);
        $code = "{ my \%_args = ();";
        while (my ($key, $value) = each %attribs) {
            my $paramspec = find_arg($key, required_args($funspec), optional_args($funspec));
            if ($paramspec =~ /^\*/) {
                $code .= " die 'Argument $key to function $tag is tree type, and cannot be set in an attribute.';\n";
            }
            elsif ($paramspec =~ /^\@/) {
                $key   =~ s/-/_/g;
                $value =~ s/\|/\\\|/g;
                $code .= " \$_args{$key} ||= []; push \@{\$_args{$key}}, q|$value|;\n";
            }
            else {
                $key   =~ s/-/_/g;
                $value =~ s/\|/\\\|/g;
                $code .= " \$_args{$key} = q|$value|;\n";
            }
        }
        # if it's a "conditional" function (i.e. it wraps around conditional tags)
        # we need to pick up the arguments in the attributes only, and execute
        # the function here
        if ($options{conditional}) {
            foreach my $arg(required_args($funspec)) {
                $arg =~ s/^.//g;    # ignore type specs for now
                $code .=
            " die 'Required arg \"$arg\" for tag $tag is missing' if not defined \$_args{$arg};\n";
            }
            $code .= " if ($pkg\::" . func_name($funspec) . "(";

            foreach my $arg(required_args($funspec), optional_args($funspec)) {
                $arg =~ s/^.//g;    # remove type specs from hash references
                $code .= "\$_args{$arg},";
            }
            $code .= ")) {\n";
            $e->manage_text(0);
        }
        else {
            $e->start_expr($tag);
        }
    }
    else {
        my $funspec =
          $AxKit2::XSP::TaglibHelper::function_stack
          [$#AxKit2::XSP::TaglibHelper::function_stack];
        my $paramspec = find_arg($tag, required_args($funspec), optional_args($funspec));

        # if the param is of type '*', then we have to prepare a new DOM tree
        # but we default to assuming it's a scalar argument
        if ($paramspec =~ /^\*/) {
            $code =
" { my \$theparent = \$parent ; \$parent = \$document->createElement('ROOT-$tag'); \$_args{$tag} = \$parent;\n";
            $e->manage_text(0);
        }
        elsif ($paramspec =~ /^\@/) {
	    if (keys %attribs){
		my $attrib_string = '';
		while (my ($key, $value) = each %attribs) {
			$key =~ s/\'/\\\'/g;
			$value =~ s/\'/\\\'/g;			
			$attrib_string .= "'$key','$value',";
		}
		$attrib_string =~ s/,$//;
		$code = " \$_args{$tag} ||= [];
			  my \$href = {};
			  my %h = ($attrib_string);
			  while (my (\$key,\$value) = each %h){
				\$href->{\$key} = \$value;
			  }
			  push \@{\$_args{$tag}}, \$href;\n";
	    }
	    else{
            $code = " \$_args{$tag} ||= []; push \@{\$_args{$tag}}, \"\"\n";
        }
        }
        else {
	    if (keys %attribs){
		my $attrib_string = '';
		while (my ($key, $value) = each %attribs) {
			$key =~ s/\'/\\\'/g;
			$value =~ s/\'/\\\'/g;			
			$attrib_string .= "'$key','$value',";
		}
		$attrib_string =~ s/,$//;
		$code = " \$_args{$tag} ||= [];
			  my \$href = {};
			  my %h = ($attrib_string);
			  while (my (\$key,\$value) = each %h){
			  	last if \$href->{\$key};
				\$href->{\$key} = \$value;
			  }
			  \$_args{$tag} = \$href;\n";
	    	
	    }
	    else{
            $code = " \$_args{$tag} = \"\"\n";
        }
    }
    }
    
    return $code;
}

sub parse_end {
    my ($e, $tag) = @_;
    my $origtag = $tag;
    $tag =~ s/-/_/g;

    my $pkg = $AxKit2::XSP::TaglibPkg;
    $pkg = "AxKit2::XSP::TaglibHelper" if $pkg eq "AxKit2::XSP::SAXHandler";
    my $funspec = is_function($pkg, $tag);

    my $code = "";
    if ($funspec) {
        pop (@AxKit2::XSP::TaglibHelper::function_stack);
        my %options = func_options($funspec);
        if ($options{conditional}) {
            $e->manage_text(1);
            return "}}\n";
        }
        else {
            $code = ";";
            foreach my $arg(required_args($funspec)) {
            $arg =~ s/^.//g;    # ignore type specs for now
            $code .=
        " die 'Required arg \"$arg\" for tag $origtag is missing' if not defined \$_args{$arg};\n";
            }
            $code .=
        " AxKit2::XSP::TaglibHelper::handle_result('$funspec', undef(), 0, \$document, \$parent, $pkg\::"
              . func_name($funspec) . "(";

            foreach my $arg(required_args($funspec), optional_args($funspec)) {
            $arg =~ s/^.//g;    # remove type specs from hash references
            $code .= "\$_args{$arg},";
            }
            $code .= "));}\n";
            $e->append_to_script($code);
            $e->end_expr();
            return '';
        }
    }
    else {

        # what function are we in?
        my $funspec =
          $AxKit2::XSP::TaglibHelper::function_stack
          [$#AxKit2::XSP::TaglibHelper::function_stack];
        my $paramspec = find_arg($tag, required_args($funspec), optional_args($funspec));

        # if the param is of type '*', then we restore the old DOM tree
        if ($paramspec =~ /^\*/) {
            $e->manage_text(1);
            $code =
" \$parent = \$theparent; \$_args{$tag} = AxKit2::XSP::TaglibHelper::convert_from_dom('$funspec',\$_args{$tag}); }";
        }
        return "$code;\n";
    }
}

##############################################################################
# a built-in taglib, so we can test the functionality of TaglibHelper
no strict;

$NS = 'http://apache.org/xsp/testtaglibhelper/v1';
@EXPORT_TAGLIB = (
  'test_hello($name)', 
  'test_echo(*whatever)', 
  'test_echo_array(@array)', 
  'test_get_person($name)', 
  'test_get_people($name)',
  'test_get_people2($name):listtag=people:itemtag=person',
);

use strict;

# now you declare your functions
sub test_hello ($) {
    my ($name) = @_;
    return "Hello, $name!";
}

sub test_echo ($) {
    my ($whatever) = @_;
    return $whatever;
}

sub test_echo_array ($) {
    my ($whatever) = @_;
    return $whatever;
}

sub test_get_person ($) {
    my ($name) = @_;
    srand(time + $$) if not $AxKit2::XSP::TaglibHelper::didsrand;
    $AxKit2::XSP::TaglibHelper::didsrand = 1;
    return {
        person => {
            name  => $name,
              age => int(rand(99)),
        }
    };
}

sub test_get_people ($) {
    my ($name) = @_;
    return [
        test_get_person($name),       test_get_person($name . "2"),
        test_get_person($name . "3"), test_get_person($name . "4"),
    ];
}

sub test_get_people2 ($) {
    my ($name) = @_;
    return (test_get_person($name)->{person}, test_get_person($name . "2")->{person},
      test_get_person($name . "3")->{person}, test_get_person($name . "4")->{person},);
}

1;

__END__

=head1 NAME

TaglibHelper - module to make it easier to write a taglib

=head1 SYNOPSIS

    package My::Taglib;

    use AxKit2::XSP::TaglibHelper;

    @ISA = qw( AxKit2::XSP::TaglibHelper );

    ## Edit $NS to be the namespace URI you want
    $NS = 'http://apache.org/xsp/testtaglib/v1';

    ## Edit @EXPORT_TAGLIB as needed
    @EXPORT_TAGLIB = (
        'func1($arg1)',
        'func2($arg1,$arg2)',
        'func3($arg1,$arg2;$optarg)',
        'func4($arg1,*treearg)',
        'func4($arg1,*treearg):listtag=mylist:itemtag=item',
    );

    use strict;

    sub func1 {
        my ( $arg1 ) = @_ ;
        ...
        return $scalar_or_reference;
    }

    ...

    1;


the functions with the same names as listed in C<@EXPORT_TAGLIB>.

=head1 DESCRIPTION

The TaglibHelper module is intended to make it much easier to build
a taglib module than had previously existed. When you create a library
that uses TaglibHelper, you need only to write "regular" functions that
take string arguments (optional arguments are supported) and return
standard Perl data structures like strings and hashrefs.

=head1 FUNCTION SPECIFICATIONS

The @EXPORT_TAGLIB global variable is where you list your exported
functions. It is of the format:

  funcname(arguments)[:options]

The C<<arguments>> section contains arguments of the form:

=over 4

=item $argument

An argument that is expected to be a plain string

=item *argument

An argument that can take a XML tree in hashref form

=item @argument

An argument that is expected to be an array of plain strings or an array
of hashrefs if the subtag has attributes

=back

These arguments are separated by commas, and optional args are
separated from required ones by a semicolon. For example,
C<$field1,$field2;$field3,$field4> has required parameters C<field1>
and C<field2>, and optional parameters C<field3> and C<field4>.

The options are colon-separated and give extra hints to TaglibHelper in
places where the default behavior isn't quite what you want. All
options are key/value pairs, formatted as B<key1=value1:key2=value2>,
etc. Currently recognized options are:

=over 4

=item listtag

For functions that return arrays, use the indicated wrapper tag for the
list instead of <funcname>-list

=item itemtag

For functions that return arrays of strings, use the indicated wrapper
tag for the list items instead of  <funcname>-item

=item forcearray

For functions that always return an array, you should generally set
this option to "1". the reason is that if your array-returning function
only returns one value in its array, the result won't be treated as an
array otherwise.

=item conditional

The function's return value will not be printed, and instead will be
used to conditionally execute child tags. NOTE that arguments to the
function cannot be brought in via child tags, but instead must come in
via attributes.

=item isreally

This function specification is actually an alias for a perl function of
a different name. For example, a specification of
C<"person($name):isreally=get_person"> allows you to have a tag <ns:person
name="Joe"/> that will resolve to Perl code "get_person('Joe')".

=item as_xml

Set this to true and return a well-balanced chunk of XML, and it will be 
parsed and added to the output.

=item array_uses_hash

Set this to true to use the preceding hash key as the prefix to 
array tag names. In the situation where complex data structures of 
hashes pointing to arrays are returned, then this makes the xml output 
more meaningful. Otherwise the default of the itemtag or <funcname>-item 
is used.

=back

=head1 EXAMPLE

if you had these two functions:


  sub hello ($) {
    my ($name) = @_;
    return "Hello, $name!";
  }

  sub get_person ($) {
    my ($name) = @_;
    return { 
        person => { 
        name => $name,
        age => 25,
        height => 200,
        }
    }
  }

...and you called them with this xsp fragment:

  <test:hello>
    <test:name>Joe</test:name>
  </test:hello>

  <test:get-person name="Bob"/>

...you would get this XML result:

  Hello, Joe!
  <person>
    <height>200</height>
    <age>25</age>
  <name>Bob</name></person>

If your function returned deeper result trees, with hashes containing
hashrefs or something similar, that would be handled fine. There are some
limitations with arrays, however, described in the BUGS AND LIMITATIONS
section.

=head1 STRUCTURED INPUT EXAMPLE

If you wish to send structured data (i.e. not just a scalar) to a taglib
function, use "*" instead of "$" for a variable. The input to a taglib
function specified as "insert_person($pid,*extra)" might be:

  <test:insert-person pid="123">
  <test:extra>
      <weight>123</weight>
      <friends>    
       <pid>3</pid>
       <pid>5</pid>
       <pid>13</pid>
      </friends>
  </test:extra>
  </test:insert-person>

The function call would be the same as:

  insert_function("123", { 
    weight => 123, 
    friends => [ 3, 5, 13 ]
    }
  );

The <friends> container holds repeating tags, notice, and TaglibHelper
figured out automatically that it needs to use an arrayref instead of
hashref for the values. But you'll get unexpected results if you mix
repeating tags and nonrepeating ones:

  <test:extra>
    <weight>123</weight>
    <friend>3</friend>
    <friend>5</friend>
    <friend>13</friend>
  </test:extra>

Just wrap your singular repeated tags with a plural-form tag, in this
case <friends>.

=head1 ARRAY INPUT EXAMPLE

If you wish to send an arbitrary number of values to a taglib function's
parameter, use "@" instead of "$" for the variable in the EXPORT_TAGLIB
header array (but still declare it with "$" in the function declaration).
The parameter will end up turning into an arrayref. For example, you might
have a TaglibHelper header:

  listbox($name;$pretty_name,@option,$default,$multiple,$size,$required)

and a Perl declaration:

  sub listbox ($$$$$$$) {
    my ($name, $pretty_name, $options, $default, $multiple, $size, $required) = @_;
	...
  }

and an XSP file that calls it:

  <test:listbox name="country" pretty_name="Pick a Country" default="" required="1">
    <test:option name="Please choose a country" value=""/>
    <test:option name="United States" value="US"/>
    <test:option name="Canada" value="CA"/>
  </test:listbox>

It would turn into this function call:

  listbox("country", "Pick a Country", [
    { name => "Please choose a country", value => "" },
	{ name => "United States", value => "" },
	{ name => "Canada", value => "CA" },
  ],  "", undef, undef, 1);

Hopefully the example is clear enough.

=head1 BUGS AND LIMITATIONS

Arrays and arrayrefs are generally difficult to work with because the
items within the array have no keys other than the index value. As a
result, if you want items within an array to be identified correctly,
you must currently make all array items point to a hashref that contains
the item's key or you must use the optional arguments to give TaglibHelper
enough "hints" to be able to represent the XML tree the way you want.

=head1 AUTHOR

Steve Willer, steve@willer.cc

=head1 SEE ALSO

AxKit.

=cut

