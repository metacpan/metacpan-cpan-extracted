#+##############################################################################
#                                                                              #
# File: Config/Generator/XML.pm                                                #
#                                                                              #
# Description: Config::Generator XML support                                   #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Config::Generator::XML;
use strict;
use warnings;
our $VERSION  = "1.0";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate validate_pos :types);
use XML::Parser qw();

#
# constants
#

use constant TAB => "  ";

#
# return a hash representing a blank line (i.e. no name and no body)
#

sub xml_blank () {
    return({});
}

#
# return a hash representing an XML comment (i.e. no name and a string body)
#

my @xml_comment_options = (
    { type => SCALAR },
);

sub xml_comment ($) {
    my($string) = validate_pos(@_, @xml_comment_options);

    return({ body => $string });
}

#
# return a hash representing an XML element
#

my @xml_element_options = (
    { type => SCALAR },
    { type => ARRAYREF | HASHREF | UNDEF, optional => 1 },
);

sub xml_element ($;$@) {
    my($name, $attr, @body) = validate_pos(@_, @xml_element_options,
        @_ == 3 ? ({ type => SCALAR | HASHREF })
                : ({ type => HASHREF }) x (@_ - 2)
    );
    my(%elt);

    $elt{name} = $name;
    $elt{attr} = $attr if $attr;
    if (@body) {
        if (@body == 1 and not ref($body[0])) {
            $elt{body} = $body[0];
        } else {
            $elt{body} = \@body;
        }
    }
    return(\%elt);
}

#
# parse the given string that must contain valid XML
#

my @xml_parse_options = (
    { type => SCALAR },
);

sub xml_parse ($) {
    my($string) = validate_pos(@_, @xml_parse_options);
    my($parser);

    $parser = XML::Parser->new(Style => __PACKAGE__ . "::Parser");
    return($parser->parse($string));
}

#
# escape a string so that it can be used outside CDATA
#

sub _escape ($) {
    my($string) = @_;

    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    return($string);
}

#
# return the list of attributes of an XML element
#

sub _attrs ($%) {
    my($elt, %option) = @_;
    my($eltname, @names, @attrs);

    return() unless $elt->{attr};
    $eltname = $elt->{name};
    if (ref($elt->{attr}) eq "HASH") {
        # given as hash for convenience
        if ($option{sort}{$eltname}) {
            @names = $option{sort}{$eltname}->(keys(%{ $elt->{attr} }));
        } else {
            @names = sort(keys(%{ $elt->{attr} }));
        }
        foreach my $name (@names) {
            push(@attrs, $name . '="' . $elt->{attr}{$name} . '"');
        }
    } elsif (ref($elt->{attr}) eq "ARRAY") {
        # given as name=value array for full control
        @attrs = @{ $elt->{attr} };
    } else {
        dief("unexpected XML attribute: %s", $elt->{attr});
    }
    return(@attrs);
}

#
# return a string representing a blank line or an XML comment
#

sub _strspc ($$) {
    my($string, $indent) = @_;
    my($xml);

    return("\n") unless defined($string);
    $xml = $indent . "<!--";
    if ($string =~ /\n/) {
        $xml .= "\n";
        foreach my $line (split(/\n/, $string)) {
            $xml .= $indent . TAB() . $line . "\n";
        }
        $xml .= $indent;
    } else {
        $xml .= " $string ";
    }
    $xml .= "-->\n";
    return($xml);
}

#
# return a string representing an XML element (private)
#

sub _strelt ($%);
sub _strelt ($%) {
    my($elt, %option) = @_;
    my($eltname, $indent, $xml, @attrs, $line, $sep);

    $eltname = $elt->{name};
    $indent = TAB() x $option{indent};
    return(_strspc($elt->{body}, $indent)) unless $eltname;
    $xml = $indent . "<" . $eltname;
    @attrs = _attrs($elt, %option);
    if (@attrs) {
        @attrs = map(_escape($_), @attrs);
        $line = $option{line};
        $line = 1 if $option{split}{$eltname};
        if ($line and length("$indent<$eltname @attrs>\n") > $line) {
            $sep = "\n$indent";
            @attrs = (map(TAB() . $_, @attrs), "");
        } else {
            $sep = " ";
        }
        $xml .= join($sep, "", @attrs);
    }
    if (defined($elt->{body}) and not ref($elt->{body})) {
        # string body
        $xml .= ">" . $elt->{body} . "</" . $eltname . ">\n";
    } elsif ($elt->{body} and @{ $elt->{body} }) {
        # structure body
        $xml .= ">\n";
        $option{indent}++;
        foreach my $child (@{ $elt->{body} }) {
            dief("unexpected XML child: %s", $child)
                unless ref($child) eq "HASH";
            $xml .= _strelt($child, %option);
        }
        $xml .= $indent . "</" . $eltname . ">\n";
    } else {
        # no body
        $xml .= "/>\n";
    }
    return($xml);
}

#
# return a string representing an XML element (public)
#

my %xml_string_options = (
    indent => { optional => 1, type => SCALAR, regex => qr/^\d+$/ },
    line   => { optional => 1, type => SCALAR, regex => qr/^\d+$/ },
    sort   => { optional => 1, type => HASHREF },
    split  => { optional => 1, type => HASHREF },
);

sub xml_string ($@) {
    my($elt, %option);

    $elt = shift(@_);
    dief("unexpected XML element: %s", $elt)
        unless ref($elt) eq "HASH";
    %option = validate(@_, \%xml_string_options) if @_;
    $option{indent} ||= 0;
    return(_strelt($elt, %option));
}

#
# wrap the given XML elements into nested elements with no attributes
#

sub xml_wrap (@);
sub xml_wrap (@) {
    my($name, @list) = @_;

    dief("no XML elements given to xml_wrap()!") unless @list;
    return(xml_element($name, undef, xml_wrap(@list))) if ref($list[0]) eq "";
    return(xml_element($name, undef, @list));
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, map("xml_$_",
                              qw(blank comment element parse string wrap)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

#+##############################################################################
#                                                                              #
# XML::Parser-compatible handlers                                              #
#                                                                              #
#-##############################################################################

package Config::Generator::XML::Parser;
use strict;
use warnings;

#
# used modules
#

use No::Worries::Die qw(dief);

#
# handlers
#

sub Init ($) {
    my($parser) = @_;

    $parser->{TopLevel} = $parser->{Current} = [];
    $parser->{Stack} = [];
}

sub Start ($$%) {
    my($parser, $tag, %attr) = @_;
    my($elt);

    $elt = {
        name => $tag,
        attr => \%attr,
        body => [],
    };
    push(@{ $parser->{Stack} }, $parser->{Current});
    push(@{ $parser->{Current} }, $elt);
    $parser->{Current} = $elt->{body};
}

sub End ($$) {
    my($parser, $tag) = @_;
    my($elt);

    $elt = $parser->{Stack}[-1][-1];
    # FIXME: forbid multi-line body?
    if (@{ $elt->{body} } == 0) {
        # no body
        delete($elt->{body});
    } elsif (@{ $elt->{body} } == 1 and not ref($elt->{body}[0])) {
        # string body
        $elt->{body} = $elt->{body}[0];
    } elsif (@{ $elt->{body} } > 1) {
        # enforce body consistency
        foreach my $chunk (@{ $elt->{body} }) {
            dief("unexpected text: %s", $chunk) unless ref($chunk);
        }
    }
    $parser->{Current} = pop(@{ $parser->{Stack} });
}

sub Char ($$) {
    my($parser, $text) = @_;

    return if $text =~ /^\s*$/;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    dief("unexpected multi-line text: %s", $text) if $text =~ /\n/;
    push(@{ $parser->{Current} }, $text);
}

sub Comment ($$) {
    my($parser, $text) = @_;
    my(@lines);

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    foreach my $line (split(/\n/, $text)) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        push(@lines, $line);
    }
    push(@{ $parser->{Current} }, { body => join("\n", @lines) });
}

sub Final ($) {
    my($parser) = @_;

    delete($parser->{Current});
    delete($parser->{Stack});
    return(@{ delete($parser->{TopLevel}) });
}

1;

__DATA__

=head1 NAME

Config::Generator::XML - Config::Generator XML support

=head1 DESCRIPTION

This module eases XML content generation by providing several functions to
generate XML abstractions (xml_blank(), xml_comment(), xml_element(),
xml_parse() and xml_wrap()) and one function to convert these abstractions
into strings (xml_string()).

Note: only a subset of XML is supported. This means that this module is not
suited for HTML generation.

=head1 FUNCTIONS

This module provides the following functions (none of them being exported by
default):

=over

=item xml_blank()

return an XML abstraction representing a blank line

=item xml_comment(STRING)

return an XML abstraction representing a comment

=item xml_element(NAME[, ATTR[, BODY]])

return an XML abstraction representing an element:

=over

=item * ATTR: defines the attributes as a hash or array reference

=item * BODY: defines the body as a string or list of XML abstractions

=back

=item xml_parse(STRING)

parse the given string (that must contain well formed XML) and return the list
of XML abstractions it contains

=item xml_string(ELEMENT[, OPTIONS])

return the string representation of the given XML abstraction; supported
options:

=over

=item * C<indent>: how many spaces to prepend to each line (default: 0)

=item * C<line>: maximum line length (longer lines will be wrapped)

=item * C<sort>: which elements to have their attributes sorted differently,
as a hash: name => sorting function

=item * C<split>: which elements to split (i.e. to have their attributes split
on different lines), as a hash: name => boolean

=back

=item xml_wrap(NAMES, ELEMENTS)

wrap the given XML elements into nested elements of the given names (with no
attributes)

=back

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2013-2016
