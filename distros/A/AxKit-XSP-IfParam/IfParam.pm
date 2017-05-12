# $Id: IfParam.pm,v 1.1.1.1 2001/06/07 15:40:36 matt Exp $

package AxKit::XSP::IfParam;

use strict;
use Apache::AxKit::Language::XSP;

use vars qw/@ISA $NS $VERSION/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://axkit.org/NS/xsp/if-param/v1';

$VERSION = "1.4";

sub parse_start {
    my ($e, $tag) = @_; 

    $e->manage_text(0);
    return 'if ($cgi->param(q|' . $tag . '|)) {';
}

sub parse_end {
     # compat only
    return '}';
}

1;
                
__END__

=head1 NAME

AxKit::XSP::IfParam - Equivalent of XSP Param taglib, but conditional.

=head1 SYNOPSIS

Add the taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::IfParam

Add the C<if-param:> namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:if-param="http://axkit.org/NS/xsp/if-param/v1"
         xmlns:param="http://axkit.org/NS/xsp/param/v1"
    >

Then use the tags:

  <if-param:foo>
    Someone sent a foo param! Value was: <param:foo/>
  </if-param:foo>

=head1 DESCRIPTION

This library is almost exactly the same as the XSP param taglib,
except it gives conditional sections based on parameters. So
rather than having to say:

  <xsp:logic>
  if (<param:foo/>) {
    ...
  }
  </xsp:logic>

You can just say:

  <if-param:foo>
    ...
  </if-param>

Which makes life much easier.

=head1 AUTHOR

Matt Sergeant, matt@axkit.com

=head1 LICENSE

This software is Copyright 2001 AxKit.com Ltd.

You may use or redistribute this software under the same terms as
Perl itself.
