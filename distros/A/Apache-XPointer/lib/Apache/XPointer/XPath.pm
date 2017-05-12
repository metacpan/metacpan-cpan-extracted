# $Id: XPath.pm,v 1.10 2004/11/16 04:38:52 asc Exp $
use strict;

package Apache::XPointer::XPath;
use base qw (Apache::XPointer);

$Apache::XPointer::XPath::VERSION = '1.1';

=head1 NAME

Apache::XPointer::XPath - mod_perl handler to address XML fragments using XPath.

=head1 SYNOPSIS

 <Directory /foo/bar>

  <FilesMatch "\.xml$">
   SetHandler	perl-script
   PerlHandler	Apache::XPointer::XPath

   PerlSetVar   XPointerSendRangeAs  "multipart/mixed"
  </FilesMatch>

 </Directory>

 #

 my $ua  = LWP::UserAgent->new();
 my $req = HTTP::Request->new(GET => "http://example.com/foo/bar/baz.xml");

 $req->header("Range"  => qq(xmlns("x=x-urn:example")xpointer(*//x:thingy)));
 $req->header("Accept" => qq(application/xml, multipart/mixed));

 my $res = $ua->request($req);

=head1 DESCRIPTION

Apache::XPointer is a mod_perl handler to address XML fragments using
the HTTP 1.1 I<Range> and I<Accept> headers and the XPath scheme, as described
in the paper : I<A Semantic Web Resource Protocol: XPointer and HTTP>.

Additionally, the handler may also be configured to recognize a conventional
CGI parameter as a valid range identifier.

If no 'range' property is found, then the original document is
sent unaltered.

If an I<Accept> header is specified with no corresponding match, then the
server will return (406) HTTP_NOT_ACCEPTABLE.

Successful queries will return (206) HTTP_PARTIAL_CONTENT.

=head1 OPTIONS

=head2 XPointerSendRangeAs

Return matches as one of the following content-types :

=over 4

=item * B<multipart/mixed>

 --match
 Content-type: text/xml; charset=UTF-8

 <foo xmlns="x-urn:example:foo" xmlns:baz="x-urn:example:baz">
  <baz:bar>hello</baz:bar>
 </foo>

 --match
 Content-type: text/xml; charset=UTF-8

 <foo xmlns="x-urn:example:foo" xmlns:baz="x-urn:example:baz">
  <baz:bar>world</baz:bar>
 </foo>

 --match--

=item * B<application/xml>

 <xp:range xmlns:xp="x-urn:cpan:ascope:apache-xpointer#"
           xmlns:default="x-urn:example.com">
  <xp:match>

   <default:foo>
    <default:bar>hello</default:bar>
   </default:foo>

  </xp:match>
  <xp:match>

   <default:foo>
    <default:bar>world</default:bar>
   </default:foo>

  </xp:match>
 </xp:range>

=back

I<Required>

=head2 XPointerAllowCGI

If set to B<On> then the handler will check for CGI parameters as well
as HTTP headers. CGI parameters are checked only if no matching HTTP
header is present.

Case insensitive.

=head2 XPointerCGIRangeParam

The name of the CGI parameter to check for an XPath range.

Default is B<range>

=head2 XPointerCGIAcceptParam

The name of the CGI parameter to list one or more acceptable
content types for a response.

Default is B<accept>

=head1 MOD_PERL COMPATIBILITY

This handler will work with both mod_perl 1.x and mod_perl 2.x.

=cut

use XML::LibXML;
use XML::LibXML::XPathContext;

sub send_as {
    my $pkg = shift;
    my $as  = shift;

    if ($as eq "multipart/mixed") {
	return "send_multipart";
    }

    elsif ($as eq "application/xml") {
	return "send_xml";
    } 

    else {
	return undef;
    }
}

sub parse_range {
    my $pkg    = shift;
    my $apache = shift;
    my $range  = shift;

    my %ns      = ();
    my $pointer = undef;

    $range =~ s/^\s+//;
    $range =~ s/\s+$//;

    # FIX ME - hooks to deal with '^' escaped
    # parens per the XPointer spec

    while ($range =~ /\G\s*xmlns\(([^=]+)=([^\)]+)\)/mg) {
	$ns{ $1 } = $2;
    }
    
    $range =~ /xpointer\((.*)\)$/;
    $pointer = $1;
    
    return {query => $pointer,
	    ns    => \%ns };
}

sub query {
    my $pkg     = shift;
    my $apache  = shift;
    my $args    = shift;

    my $parser = XML::LibXML->new();
    my $doc    = undef;

    eval {
	$doc = $parser->parse_file($apache->filename());
    };
    
    if ($@) {
	$apache->log()->error(sprintf("failed to parse file '%s', %s",
				      $apache->filename(),$@));

	return {success  => 0,
		response => $pkg->_server_error()};
    }
    
    my $context = XML::LibXML::XPathContext->new($doc);
    my $ns      = $args->{'ns'};

    foreach my $prefix (keys %$ns) {
	$context->registerNs($prefix,$ns->{$prefix});
    }

    #

    my $result = undef;
    
    eval {
	$result = $context->findnodes($args->{'query'});
    };
    
    if ($@) {
	$apache->log()->error(sprintf("failed to find nodes for '%s', %s",
				      $args->{'query'},$@));

	return {success  => 0,
		response => $pkg->_server_error()};
    }

    #

    return {success  => 1,
	    encoding => $doc->encoding(),
	    result   => $result};
}

sub send_multipart {
    my $pkg    = shift;
    my $apache = shift;
    my $res    = shift;

    foreach my $node ($res->{'result'}->get_nodelist()) {

	# note : $node->toString() does not serialize
	#         namespace information
	#        $node->toStringC14N() results in : $node's
	#         root element from being included (I'm sure
	#         there's magic XPath to deal with this but 
	#         I haven't figured it out yet; mal-formed
	#         XML

	my $root = XML::LibXML::Element->new($node->localname());

	$root->setNamespace($node->namespaceURI(),
			    $node->prefix());

	foreach my $child ($node->childNodes()) {

	    # see also : libxml/tree.h
	    # XML_ELEMENT_NODE= 1

	    if ($child->nodeType() == 1) {
		$root->setNamespace($child->namespaceURI(),
				    $child->prefix());
	    }

	    $root->addChild($child);
	}

	$apache->print(qq(--match\n));
	$apache->print(sprintf("Content-type: text/xml; charset=%s\n\n",$res->{'encoding'}));
	$apache->print($root->toString(1,1));
	$apache->print(qq(\n));
    }

    $apache->print(qq(--match--\n));
    return 1;
}

sub send_xml {
    my $pkg    = shift;
    my $apache = shift;
    my $res    = shift;

    # Note : the document-ness of $doc handles
    #         all the goofy XMLNS hoops we jump
    #         through above

    my $doc = XML::LibXML::Document->new();
    $doc->setEncoding($res->{'encoding'});
    
    my $root = XML::LibXML::Element->new("range");
    $root->setNamespace("x-urn:cpan:ascope:apache-xpointer-xpath#","xp");

    foreach my $node ($res->{'result'}->get_nodelist()) {
	my $item = XML::LibXML::Element->new("xp:match");
	$item->addChild($node);
	$root->addChild($item);
    }

    $doc->setDocumentElement($root);
    
    #

    $apache->print($doc->toString());
    return 1;
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2004/11/16 04:38:52 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Apache::XPointer>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut 

return 1;
