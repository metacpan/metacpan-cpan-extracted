package Apache::SPARQL;

$Apache::SPARQL::VERSION = '0.22';

use strict;

use mod_perl;
use LWP::UserAgent;

use constant MP2 => ($mod_perl::VERSION >= 1.99) ? 1 : 0;

BEGIN {
	if (MP2) {
		require Apache2;
		require Apache::RequestRec;
		require Apache::RequestIO;
		require Apache::RequestUtil;
		require Apache::Const;
		require Apache::Log;
		require Apache::URI;
		require Apache::File;
		require APR::Table;
		require APR::URI;
		require CGI;

		CGI->compile(qw(param));
	} else {
		require Apache;
		require Apache::Constants;
		require Apache::Log;
		require Apache::Request;
		require Apache::URI;
		require Apache::File;
		};
	};

# see http://www.w3.org/2001/sw/DataAccess/proto-wd/#mapping
%Apache::SPARQL::Responses = (
	'OK' => 200,
	'GraphCreated' => 201,
	'OperationRequestAccepted' => 202,
	'PermanentlyMoved' => 301,
	'TemporarilyMoved' => 307,
	'MalformedRequest' => 400,
	'MalformedQuery' => 400,
	'Unauthorized' => 401,
	'Forbidden' => 403,
	'NotFound' => 404,
	'NoDeletionPerformed' => 409,
	'RequestRefused' => 409,
	'OperationPointError' => 500,
	'UnsupportedOperation' => 501,
	'Unavailable' => 503
	);

sub handler($$) {
	my ($class, $ap) = @_;

	return $Apache::SPARQL::Responses{ 'MalformedRequest' }
		unless(	$ap->method eq 'GET' or
			$ap->method eq 'OPTIONS' );

	my $uri_query_string = $ap->args;
	if(	$uri_query_string and
		$uri_query_string ne '' and
		$uri_query_string !~ m/^\s*$/ ) {

		my $query_lang = $class->_param($ap, 'query-lang');
		$query_lang = 'sparql'
			unless($query_lang);

		my $query = $class->_param($ap, 'query');
		my $query_uri = $class->_param($ap, 'query-uri');
		my @graph_id = $class->_param($ap, 'graph-id');

		# see some more at http://lists.w3.org/Archives/Public/public-rdf-dawg/2005AprJun/0054.html
		my @data = $class->_param($ap, 'data');
		push @graph_id, @data; #merge graph-id and data parameters - need to clarify this
		my $format = $class->_param($ap, 'format');
		my $output_xslt = $class->_param($ap, 'output-xslt');
		my $output_type = $class->_param($ap, 'output-type');
		my $limit = $class->_param($ap, 'limit');

		# FIXME - if no query params assumes getGraph() - correct?
		if(	$query or
			$query_uri ) {
			return $class->query( $ap, $query, $query_uri, \@graph_id, $output_xslt, $output_type, $format, $limit );
		} else {
			return $class->getGraph( $ap, \@graph_id, $format );
			};
	} else {
		return $class->getServiceDescription( $ap );
		};
	};

sub query {
	my ($class, $ap, $query, $query_uri, $graph_id, $output_xslt, $output_type, $format, $limit ) = @_;

	return $Apache::SPARQL::Responses{ 'MalformedRequest' };
	};

sub getGraph {
	my ($class, $ap, $graph_id, $format ) = @_;

	return $Apache::SPARQL::Responses{ 'MalformedRequest' };
	};

sub getServiceDescription {
	my ($class, $ap) = @_;

	return $Apache::SPARQL::Responses{ 'MalformedRequest' };
	};

sub _cat {
	my ($class, $ap, $file_or_uri) = @_;

	my $subr = $ap->lookup_uri( $file_or_uri );
	my $filename = $subr->filename;

	if( -e $filename && -r _ ) {
		my $content='';
		my $fh = Apache::File->new($filename);
		while(<$fh>) {
			$content.=$_;
			};
		close($fh);
		return $content;
	} else {
		return $class->_wget( $ap, $file_or_uri );
		};
	};

# does HTTP GET of given URI
sub _wget {
	my ($class, $ap, $uri, $accept) = @_;

	my $ua = LWP::UserAgent->new( timeout => 60 );

	my $server = $ap->server;
	my %headers = ( "User-Agent" => "sparqlserver\@".$server->server_hostname."/".$Apache::SPARQL::VERSION );

	if( $accept ) {
        	$headers{'Accept'} = $accept;
	} else {
		#otherwise try any
        	$headers{'Accept'} = 'application/rdf+xml,application/xml,text/xml,application/x-turtle,application/turtle,text/rdf+n3;q=0.9,*/*;q=0.5';
		};

        my $response = $ua->get( $uri, %headers );

	return
		unless($response->is_success);

	return $response->content;
	};

sub _mp2 {
	return MP2;
	};

sub _param {
	my ($class, $ap, $field) = @_;

	if ( $class->_mp2 ) {
		if($field) {
			return CGI::param($field);
		} else {
			my @params = CGI::param();
			return @params;	
			};
		};

	my $request = Apache::Request->new($ap);

	if($field) {
		return $request->param($field);
	} else {
		my @params = $request->param;
		return @params;	
		};
	};

sub _nometh {
	my ($class, $ap, $field) = @_;

	my $caller = (caller(1))[3];
	$caller =~ s/.*:://;

	$ap->log()->error(sprintf("package %s does not define a '%s' method", $class, $caller));

	return 0;
	};

sub _header_in {
	my ($class, $ap, $field) = @_;

	return ( $class->_mp2 ) ? $ap->headers_in()->{$field} : $ap->header_in($field);
	};

sub _header_out {
	my ($class, $ap, $field, $value) = @_;

	( $class->_mp2 ) ? $ap->headers_out()->{$field} = $value: $ap->header_out($field,$value);
	};

=cut

=head1 NAME

Apache::SPARQL - mod_perl handler base class to implement a SPARQL query service using HTTP bindings.

=head1 SYNOPSIS

 <Location /rdfstore>

   SetHandler	perl-script
   PerlHandler	Apache::SPARQL

 </Location>

 #

 my $ua  = LWP::UserAgent->new();
 my $req = HTTP::Request->new(GET => "http://pim.example/rdfstore?query=PREFIX+foaf%3A+%3Chttp%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2F%3E%0D%0ASELECT+%3Fpg%0D%0AWHERE%0D%0A++%28%3Fwho+foaf%3Aname+%22Norm+Walsh%22%29%0D%0A++%28%3Fwho+foaf%3Aweblog+%3Fpg%29%0D%0A");

 my $res = $ua->request($req);

=head1 DESCRIPTION

Apache::SPARQL is a mod_perl handler base class to implement a SPARQL query service using HTTP bindings.

=head1 IMPORTANT

This package is a base class and not expected to be invoked
directly. Please use one of the backends handlers instead.

=head1 SUPPPORTED BACKENDS

 Apache::SPARQL::RDFStore

=head1 MOD_PERL COMPATIBILITY

This handler will work with both mod_perl 1.x and mod_perl 2.x.

=head1 AUTHOR

Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

 Apache::SPARQL::RDFStore
 http://www.w3.org/TR/rdf-sparql-protocol/
 http://www.w3.org/2001/sw/DataAccess/proto-wd/ (editor working draft)
 http://www.w3.org/2001/sw/DataAccess/prot26
 http://www.w3.org/TR/rdf-sparql-query/
 http://www.w3.org/2001/sw/DataAccess/rq23/ (edit working draft)

=head1 LICENSE

see LICENSE file included into this distribution

=cut

return 1;
