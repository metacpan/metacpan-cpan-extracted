# $Id: RDFStore.pm,v 1.9 2004/11/16 04:33:33 asc Exp $
use strict;

package Apache::XPointer::RDQL::RDFStore;
use base qw (Apache::XPointer::RDQL);

$Apache::XPointer::RDQL::RDFStore::VERSION = '1.1';

=head1 NAME

Apache::XPointer::RDQL::RDFStore - mod_perl handler to address XML fragments using the RDF Data Query Language.

=head1 SYNOPSIS

 <Directory /foo/bar>

  <FilesMatch "\.rdf$">
   SetHandler	perl-script
   PerlHandler	Apache::XPointer::RDQL::RDFStore

   PerlSetVar   XPointerSendRangeAs  "XML"
  </FilesMatch>

 </Directory>

 #

 my $ua  = LWP::UserAgent->new();
 my $req = HTTP::Request->new(GET => "http://example.com/foo/bar/baz.rdf");

 $req->header("Range" => qq(SELECT ?title, ?link
                            WHERE
                            (?item, <rdf:type>, <rss:item>),
                            (?item, <rss::title>, ?title),
                            (?item, <rss::link>, ?link)
                            USING
                            rdf for <http://www.w3.org/1999/02/22-rdf-syntax-ns#>,
                            rss for <http://purl.org/rss/1.0/>));

 $req->header("Accept" => "application/rdf+xml");

 my $res = $ua->request($req);

=head1 DESCRIPTION

Apache::XPointer::RDQL::RDFStore is a mod_perl handler to address XML fragments
using the HTTP 1.1 I<Range> and I<Accept> headers and the XPath scheme,
as described in the paper : I<A Semantic Web Resource Protocol: XPointer and HTTP>.

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

 <rdf:RDF
      xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
      xmlns:rdfstore='http://rdfstore.sourceforge.net/contexts/'
      xmlns:voc0='http://purl.org/rss/1.0/'>
  <rdf:Description rdf:about='rdf:resource:rdfstore123'>
   <voc0:title>The Daily Cartoon for November 15</voc0:title>
   <voc0:link>http://feeds.feedburner.com/BenHammersleysDangerousPrecedent?m=1</voc0:link>
  </rdf:Description>
 </rdf:RDF>

 --match
 Content-type: text/xml; charset=UTF-8

 <rdf:RDF
      xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
      xmlns:rdfstore='http://rdfstore.sourceforge.net/contexts/'
      xmlns:voc0='http://purl.org/rss/1.0/'>
  <rdf:Description rdf:about='rdf:resource:rdfstore456'>
   <voc0:title>Releasing RadioPod</voc0:title>
   <voc0:link>http://feeds.feedburner.com/BenHammersleysDangerousPrecedent?m=178</voc0:link>
  </rdf:Description>
 </rdf:RDF>

 --match--

=item * B<application/xml+rdf>

 <rdf:RDF
      xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
      xmlns:rdfstore='http://rdfstore.sourceforge.net/contexts/'
      xmlns:voc0='http://purl.org/rss/1.0/'>

  <rdf:Description rdf:about='rdf:resource:rdfstoreS789'>
   <rdf:type rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq' />
   <rdf:type rdf:resource='x-urn:cpan:ascope:apache-xpointer-rdql:range'/ >
   <rdf:li rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#_1' />
   <rdf:li rdf:resource='http://www.w3.org/1999/02/22-rdf-syntax-ns#_2' />
  </rdf:Description>

  <rdf:Description rdf:about='http://www.w3.org/1999/02/22-rdf-syntax-ns#_1'>
   <voc0:title>The Daily Cartoon for November 15</voc0:title>
   <voc0:link>http://feeds.feedburner.com/BenHammersleysDangerousPrecedent?m=1</voc0:link>
  </rdf:Description>

  <rdf:Description rdf:about='http://www.w3.org/1999/02/22-rdf-syntax-ns#_2'>
   <voc0:title>Releasing RadioPod</voc0:title>
   <voc0:link>http://feeds.feedburner.com/BenHammersleysDangerousPrecedent?m=178</voc0:link>
  </rdf:Description>

 </rdf:RDF>

=back

I<Required>

=head2 XPointerAllowCGI

If set to B<On> then the handler will check for CGI parameters as well
as HTTP headers. CGI parameters are checked only if no matching HTTP
header is present.

Case insensitive.

=head2 XPointerCGIRangeParam

The name of the CGI parameter to check for an RDQL range.

Default is B<range>

=head2 XPointerCGIAcceptParam

The name of the CGI parameter to list one or more acceptable
content types for a response.

Default is B<accept>

=head1 MOD_PERL COMPATIBILITY

This handler will work with both mod_perl 1.x and mod_perl 2.x.

=cut

use DBI;
use RDFStore::Model;
use RDFStore::NodeFactory;

sub send_as {
    my $pkg = shift;
    my $as  = shift;

    if ($as eq "multipart/mixed") {
	return "send_multipart";
    }

    elsif ($as eq "application/rdf+xml") {
	return "send_xml";
    } 

    else {
	return undef;
    }
}

sub query {
    my $pkg    = shift;
    my $apache = shift;
    my $query  = shift;

    my $bind = $pkg->bind($query);

    my $dbh = undef;
    my $sth = undef;

    eval {
	$dbh = DBI->connect("DBI:RDFStore:");
    };

    if ($@) {
	return $pkg->_fatal($apache,
			    "failed to create DB connection, $@");
    }

    eval {
	$sth = $dbh->prepare($query);
    };

    if ($@) {
	return $pkg->_fatal($apache,
			    "failed to prepare query statement, $@");
    }

    $sth->execute();

    if ($dbh->err()) {
	return $pkg->_fatal($apache,
			    $dbh->errstr());
    }

    $sth->bind_columns(map { \$_->{value} } @$bind);

    #

    return {success => 1,
	    bind    => $bind,
	    result  => $sth};
}

sub send_multipart {
    my $pkg    = shift;
    my $apache = shift;
    my $res    = shift;

    my $factory = RDFStore::NodeFactory->new();
    
    while ($res->{'result'}->fetch()) {

	my $model   = RDFStore::Model->new();
	my $subject = $factory->createUniqueResource();

	map { 
	    
	    my $property = $factory->createResource($_->{namespaceuri},$_->{localname});
	    my $object   = $_->{value};

	    $model->add($factory->createStatement($subject,$property,$object));
	} @{$res->{'bind'}};

	$apache->print(qq(--match\n));
	$apache->print(sprintf("Content-type: text/xml; charset=%s\n\n","UTF-8"));

	$apache->print(sprintf("%s\n",$model->serialize()));
    }

    $apache->print(qq(--match--\n));
    return 1;
}

sub send_xml {
    my $pkg    = shift;
    my $apache = shift;
    my $res    = shift;

    #

    my $ns_rdf   = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";   
    my $ns_xp    = "x-urn:cpan:ascope:apache-xpointer-rdql:";

    my $factory  = RDFStore::NodeFactory->new();
    my $model    = RDFStore::Model->new();

    my $range    = $factory->createResource($ns_xp,"range");
    my $type     = $factory->createResource($ns_rdf,"type");
    my $sequence = $factory->createResource($ns_rdf,"Seq");
    my $li       = $factory->createResource($ns_rdf,"li");

    my $seq = $factory->createUniqueResource();

    $model->add($factory->createStatement($seq,$type,$range));
    $model->add($factory->createStatement($seq,$type,$sequence));

    for (my $i = 0; $res->{'result'}->fetch(); $i++) {

	my $result = $factory->createOrdinal($i+1);

	map { 
	    
	    my $property = $factory->createResource($_->{namespaceuri} . $_->{localname});
	    my $object   = $_->{value};

	    $model->add($factory->createStatement($result,$property,$object));

	} @{$res->{'bind'}};

	$model->add($factory->createStatement($seq,$li,$result));
    }

    $apache->print($model->serialize());
    return 1;
}

sub _fatal {
    my $pkg    = shift;
    my $apache = shift;
    my $err    = shift;

    $apache->log()->error($err);
    
    return {success  => 0,
	    response => $pkg->_server_error()};
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2004/11/16 04:33:33 $

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
