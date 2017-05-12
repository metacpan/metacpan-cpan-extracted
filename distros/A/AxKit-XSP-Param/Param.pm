# $Id: Param.pm,v 1.7 2001/06/04 10:08:43 matt Exp $

package AxKit::XSP::Param;
use strict;
use Apache::AxKit::Language::XSP;

use vars qw/@ISA $NS $VERSION/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://axkit.org/NS/xsp/param/v1';

$VERSION = "1.4";

## Taglib subs

# NONE! ;-)

## Parser subs

sub parse_start {
    my ($e, $tag, %attribs) = @_; 
    #warn "Checking: $tag\n";

    $e->start_expr($tag);
    $e->append_to_script('$cgi->param(q|' . $tag . '|)');
    $e->end_expr();
    return '';    
}

sub parse_char {
     # compat only
}


sub parse_end {
     # compat only
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

AxKit::XSP::Param - A namespace wrapper for accessing HTTP request paramaters.

=head1 SYNOPSIS

Add the param: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:param="http://axkit.org/NS/xsp/param/v1"
    >

And add the taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Param

=head1 DESCRIPTION

The XSP param: tag library implements a simple way to access HTTP request parameters (query string and posted form data) by
field name. 

Thus, the B<value> submitted from this text box

    <input type="text" name="username"/>

is available after POSTing as

    <param:username/>

The same is true for information passed through the query string.

The best way to describe this taglib's use is with a few examples:

B<Simple inline text insertion> -

    <p>
      Greetings, <param:username />, welcome to our site! 
    </p>

B<As the contents of another element> -

    <custom-element><param:param_name /></custom-element>

B<As the attribute value for another elememnt> -

    <input type="hidden" name="foo">
      <xsp:attribute name="value"><param:foo/></xsp:attribute>
    </input>

Note that if the specified parameter field does not exist no error is thrown. So, this:

    <input type="hidden" name="secret_data">
      <xsp:attribute name="value"><param:bogus_name/></xsp:attribute>
    </input>

Will result in following after proccessing:

    <input type="hidden" name="secret_data" value="">

=head2 Tag Reference

There are no named functions for this tag library. 

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2001 Kip Hampton. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

AxKit

=cut
