package Apache::XPointer::RDQL;
use base qw (Apache::XPointer);

$Apache::XPointer::RDQL::VERSION = '1.1';

=head1 NAME

Apache::XPointer::RDQL - mod_perl handler for addressing XML fragments using the RDF Data Query Language.

=head1 SYNOPSIS

 <Directory /foo/bar>

  <FilesMatch "\.rdf$">
   SetHandler	perl-script
   PerlHandler	Apache::XPointer::RDQL::RDFStore

   PerlSetVar   XPointerSendRangeAs  "application/rdf+xml"
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

 $req->header("Accept" => qq(mulitpart/mixed));

 my $res = $ua->request($req);

=head1 DESCRIPTION

Apache::XPointer::RDQL::RDFStore is a mod_perl handler to address XML fragments using
the HTTP 1.1 I<Range> and I<Accept> headers and the XPath scheme, as described
in the paper : I<A Semantic Web Resource Protocol: XPointer and HTTP>.

Additionally, the handler may also be configured to recognize a conventional
CGI parameter as a valid range identifier.

If no 'range' property is found, then the original document is
sent unaltered.

If an I<Accept> header is specified with no corresponding match, then the
server will return (406) HTTP_NOT_ACCEPTABLE.

Successful queries will return (206) HTTP_PARTIAL_CONTENT.

=head1 IMPORTANT

This package is a base class and not expected to be invoked
directly. Please use one of the RDQL parser-specific handlers instead.

=head1 SUPPORTED PARSERS

=head2 RDFStore

Consult L<Apache::XPointer::RDQL::RDFStore>

=head1 MOD_PERL COMPATIBILITY

This handler will work with both mod_perl 1.x and mod_perl 2.x.

=cut

use Apache::XPointer::RDQL::Parser;

sub parse_range {
    my $pkg    = shift;
    my $apache = shift;
    my $range  = shift;

    $range =~ s/^\s+//;
    $range =~ s/\s+$//;
    $range =~ s/\bWHERE/\f FROM <%s> WHERE/;

    my $query  = sprintf($range,$apache->filename());
    my $parser = Apache::XPointer::RDQL::Parser->new();

    $parser->parse($query);
    return (undef,$parser);
}

sub bind {
    my $pkg   = shift;
    my $query = shift;

    my @bind   = ();

    foreach my $var ($query->bind_variables()) {

	my ($prefix,$localname) = $query->bind_predicate($var);
	my $uri = $query->lookup_namespaceURI($prefix);

	push @bind, {localname    => $localname,
		     prefix       => $prefix,
		     namespaceuri => $uri,
		     value        => undef};
    }

    return \@bind;
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2004/11/16 04:33:33 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Apache::XPointer>

http://www.w3.org/Submission/RDQL/

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under
the same terms as Perl itself.

=cut

return 1;
