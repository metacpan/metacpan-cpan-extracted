package AxKit::XSP::Cookie;
use strict;
use Apache::AxKit::Language::XSP;
use Apache::Cookie;

use vars qw/@ISA $NS $VERSION/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://axkit.org/NS/xsp/cookie/v1';

$VERSION = "1.41";

## Taglib subs

# NONE! ;-)

my $cookie_context  = '';

## Parser subs

sub parse_start {
    my ($e, $tag, %attribs) = @_; 
    #warn "Checking: $tag\n";

    if ($tag eq 'create') {
        $cookie_context = 'create';
        my $code = '{ my $__cookie = Apache::Cookie->new($r);';

        if ($attribs{name}) {
            $code .= '$__cookie->name(q|' . $attribs{name} . '|);';
        }
        if ($attribs{value}) {
            $code .= '$__cookie->value(q|' . $attribs{value} . '|);';
        }
        if ($attribs{domain}) {
            $code .= '$__cookie->domain(q|' . $attribs{domain} . '|);';
        }
        if ($attribs{path}) {
            $code .= '$__cookie->path(q|' . $attribs{path} . '|);';
        }
        if ($attribs{secure}) {
            $code .= '$__cookie->secure(q|' . $attribs{secure} . '|);';
        }
        if ($attribs{expires}) {
            $code .= '$__cookie->expires(q|' . $attribs{expires} . '|);';
        }

        return $code;
    }
    elsif ($tag eq 'name') {
        if ($cookie_context eq 'create') {
           return '$__cookie->name(""';
        }
    }
    elsif ($tag eq 'value') {
        return '$__cookie->value(""';
    }
    elsif ($tag eq 'domain') {
        return '$__cookie->domain(""';
    }
    elsif ($tag eq 'expires') {
        return '$__cookie->expires(""';
    }
    elsif ($tag eq 'path') {
        return '$__cookie->path(""';
    }
    elsif ($tag eq 'secure') {
        return '$__cookie->secure(""';
    }
    elsif ($tag eq 'fetch') {
        $cookie_context = 'fetch';
        $e->start_expr($tag);
        my $code = 'my (%__cookies, $__cookie, $__cookie_name);' . "\n"; 
        $code .= '%__cookies = Apache::Cookie->fetch;';
        $code .= '$__cookie_name = ""';
        if ($attribs{name}) {
            $code .= '. q|' . $attribs{name} . '|;';
            $code .= '$__cookie = $__cookies{$__cookie_name} || Apache::Cookie->new($r);';
        }
       return $code;
    }
    else {
        die "Unknown cookie tag: $tag";
    }
}


sub parse_char {
    my ($e, $text) = @_;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    return ". q|$text|";
}


sub parse_end {
    my ($e, $tag) = @_;

    if ($tag eq 'create') {
        $cookie_context = '';
        return '$__cookie->bake;}' . "\n";
    }
    elsif ($tag eq 'name') {
        if ($cookie_context eq 'create') {
            return ');';
        }
        else {
            return ';$__cookie = $__cookies{$__cookie_name} || Apache::Cookie->new($r);';

        }
    }
    elsif ($tag eq 'value') {         
        if ($cookie_context eq 'create') {
            return ');';
        }
    }
    elsif ($tag eq 'expires') {
        if ($cookie_context eq 'create') {
            return ');';
        }
    }
    elsif ($tag eq 'domain') {
        if ($cookie_context eq 'create') {
            return ');';
        }
    }
    elsif ($tag eq 'path') {
        if ($cookie_context eq 'create') {
            return ');';
        }
    }
    elsif ($tag eq 'secure') {
        if ($cookie_context eq 'create') {
            return ');';
        }
    }
    elsif ($tag eq 'fetch') {
        $cookie_context = '';
        $e->append_to_script('$__cookie->value;');
        $e->end_expr;
        return '';
    }
}

sub parse_comment {
    # compat only
}

sub parse_final {
   # compat only
}

1;
                
__END__

=head1 NAME

AxKit::XSP::Cookie - An XSP library for setting and getting HTTP cookies.

=head1 SYNOPSIS

Add the taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Cookie

Add the cookie: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:cookie="http://axkit.org/NS/xsp/cookie/v1"
    >

Then, put the taglib to work:

Set a cookie:

    <cookie:create name="newCookie" value="somevalue" />

Get the value for a previous cookie:

    <cookie:fetch name="oldCookie" />

=head1 DESCRIPTION

The XSP cookie: tag library implements a simple way to set/get HTTP cookies.

=head1 TAG REFERENCE

In order to provide maximum flexibility for XSP developers, the cookie: taglib allows all of its arguments to be passed either
as attributes of the two 'wrapper' elements (C<<cookie:create>> and C<<cookie:fetch>>), or as child elements of the same.

In practice, the choice between passing arguments as attributes vs. passing them as child elements boils down to whether or
not the value being passed is being set dynamically or not. If the arguments are hard-coded, you can safely pass the values 
as either an attribute or a child element. If, however, you need to pass a value that is not defined until run-time, you
B<must> use a child element since XSP does not allow the value of taglib attributes to be set dynamically. See the EXAMPLES
below for clarification.

=head2 C<<cookie:create>>

This tag is used to create a new HTTP cookie, or to update an existing one. As one of the cookie: lib's 'wrapper' elements
this tag allows the following attributes or child elements:

=over 4

=item * name

=item * value

=item * expires

=item * path

=item * domain

=item * secure

=back

Please see the descriptions below for the allowed values for each of these arguments.

=head2 C<<cookie:fetch>>

The other, simpler of the two 'wrapper' elements this tag allows B<only> the B<name> attribute/child. The tag is used to
retrieve the value of a prevously set cookie whose name matches the B<name> argument.

=head2 C<<cookie:name>>

When used as the child of a C<<cookie:create>> element this tag B<sets> the cookie's name. When it used as the child of a
C<<cookie:fetch>> element it is used to define the name of the cookie to retrieve.

=head2 C<<cookie:value>>

Allowed only as the child of a C<<cookie:create>> element, this tag defines the value for the cookie.

=head2 C<<cookie:path>>

Allowed only as the child of a C<<cookie:create>> element, this tag defines the 'path' field for the cookie.

=head2 C<<cookie:expires>>

Allowed only as the child of a C<<cookie:create>> element, this tag sets the cookie's expiry date. It accepts the same types
values that Apache::Cookie does.

=head2 C<<cookie:domain>>

Allowed only as the child of a C<<cookie:create>> element, this tag defines the 'domain' field for the cookie.

=head2 C<<cookie:secure>>

Accepting only the values of O or 1, this tag sets or unsets the cookie's 'secure' flag. It is allowed only as the child 
of a C<<cookie:create>> element.

=head1 EXAMPLES

Fetch the value for a previous cookie whose B<name> argument is hard-coded into the script:

    <cookie:fetch name="chocolateChip"/>

Fetch the value for a previous cookie whose B<name> is determined at run-time:

    <cookie:fetch>
      <cookie:name><xsp:expr>$perl_var_containing_cookiename</xsp:expr></cookie:name>
    </cookie:fetch>

Set a cookie using only hard-coded arguments:

    <cookie:create
            name="oatmealRaisin"
            value="tasty"
            expires="+3M"
    >

Set a cookie using a mix of dynamic child elements and static attributes:

    <cookie:create
            name="peanutButter"
            domain=".mydomain.tld"
            secure="1"
    >
      <cookie:value><xsp:expr>$cookie_value</xsp:expr></cookie:value>
      <cookie:expires><xsp:expr>$cookie_expiry</xsp:expr></cookie:expires>
      <cookie:path><xsp:expr>$cookie_path</xsp:expr></cookie:path>
    </cookie:create>

As stated above, you can pass static arguments either as attributes or child elements of the enclosing tag. Thus:

    <cookie:create name="pistachioChocolateChunk"/>
      ...

and

    <cookie:create>
      <cookie:name>pistachioChocolateChunk</cookie:name>
      ...

are functionally equivalent.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2001 Kip Hampton. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

AxKit, Apache::Cookie, CGI::Cookie

=cut
