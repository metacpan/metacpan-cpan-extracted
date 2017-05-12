package Apache::SPARQL::RDFStore;

use strict;
use base qw (Apache::SPARQL);

$Apache::SPARQL::RDFStore::VERSION = '0.3';

use RDFStore::Model;

use DBI;

# for output-xslt parameter fancyness
use XML::LibXML;
use XML::LibXSLT;

sub query {
        my ($class, $ap, $query, $query_uri, $graph_id, $output_xslt, $output_type, $format, $limit ) = @_;

	$query = $class->_cat($ap, $query_uri)
		if(    ! $query or
			$query eq '' or
			$query =~ m/^\s+$/ );

	my $smart = $class->_param($ap, 'smart'); #1/0 flag whether or not use simple RDF/S inferencing
	$smart = ( $smart and $smart !~ m/(0|no|off)/ ) ? 1 : 0 ;

	if( defined $limit and $limit < 0 ) {
        	$class->_error( $ap, "Negative LIMIT $limit" );
		return $Apache::SPARQL::Responses{ 'OperationPointError' };
		};

	if( $format !~ s/^\s*(rdfxml|ntriples|xml)\s*$/$1/ ) {
		$class->_error( $ap, "Format $format is not supported" );
		return $Apache::SPARQL::Responses{ 'OperationPointError' };
		};

	#
	# more advanced stuff
	#
	# Any other CGI paramter starting with the 'rdflet_' prefix is passed down to the SPARQL query itself, and can be referred
	# into the SPARQL query as $$param_name. Multiple parameters result into a OR-ed list of value - each value can be either
	# a full qulified URI resource or a literal (with it xml:lang or rdf:datatype attached), using some N-Triples/Turtle like syntax.
	#	
	# Example:
	#
	# Given /sparql/?sparqlet_URL=<http://foo.bar/com.html>
	#
	# and the following SPARQL '&query' paramter
	#
	#       prefix dc: <http://purl.org/dc/elements/1.1/>
	#       select ?title
	#       where ( $$URL dc:title ?title )
	#
	# would re-write the query as:
	#
	#       prefix dc: <http://purl.org/dc/elements/1.1/>
	#       select ?title
	#       where ( <http://foo.bar/com.html> dc:title ?title )
	#
	# which will get the title of item 'http://foo.bar/com.html' - similarly if sparqler_title="foo bar title"@ch and so on..

	my %sparqlet_parameters = ();
	my @params = $class->_param( $ap ); #any param
	map {
		my $name = $_;
		if ( $name =~ s/^sparqlet_// ) {
			$sparqlet_parameters{ $name } = { 'r' => [], 'l' => [] }
				unless( exists $sparqlet_parameters{ $name } );

			my @values = $class->_param( $ap, 'sparqlet_'.$name );
			foreach my $value ( @values ) {
				if ( $value =~ s/^\s*\<([^>]+)\>\s*// ) {
					push @{ $sparqlet_parameters{ $name }->{ 'r' } }, $1;
				} elsif( $value =~ s/^\s*(%?[\"\']((([^\"\'\\\n\r])|(\\([ntbrf\\'\"])|([0-7][0-7?)|([0-3][0-7][0-7])))*)[\"\'](\@([a-z0-9]+(-[a-z0-9]+)?))?%?)\s*// ) {
					push @{ $sparqlet_parameters{ $name }->{ 'l' } }, $1;
					};
				};
			};
		} @params;

	# merge graph-id/s and 
	#if( $class->_SPARQLhas_Source( $query ) ) {
	#} else {
	#	};
	my $data = new RDFStore::Model;
	if($graph_id) {
		foreach my $graph_id ( @{ $graph_id } ) {
			# bad - try to guess out format from file extension
			eval {
				$data->getReader( ($graph_id =~ /\.(nt|ntriples)$/) ? 'N-Triples' : 'RDF/XML' )->parsestring(
					$class->_cat( $ap, $graph_id ) );
				};
			if($@) {
        			$class->_error( $ap, "Cannot process graph-id $graph_id: $@ " );
				return $Apache::SPARQL::Responses{ 'OperationPointError' };
				};
			};
		};

	my $dbh = DBI->connect("DBI:RDFStore:", "sparqler", 0, {
			'sourceModel' => $data,
			'smarter' => $smart } );

	unless($dbh) {
        	$class->_error( $ap, "Oh dear, can not connect to rdfstore: $!" );
        	return $Apache::SPARQL::Responses{ 'OperationPointError' };
		};

	$query = $class->_preprocess_SPARQL_query( $ap, $query, %sparqlet_parameters );

	my $sth;
	eval {
		$sth=$dbh->prepare($query);
		$sth->execute();
		};

	if($@) {
		$sth->finish;
		$class->_error( $ap, "Malformed query: $@ " );
		return $Apache::SPARQL::Responses{ 'MalformedQuery' };
		};

	my $serialization_format;
	if( $sth->func('getQueryStatement')->getQueryType eq 'SELECT' ) {
		if( $format eq 'rdfxml' ) {
			# which is the RDF/XML result format
			# see http://www.w3.org/2001/sw/DataAccess/tests/result-set#
			$serialization_format = 'dawg-results';
		} elsif( $format eq 'xml' ) {
			# see http://www.w3.org/2001/sw/DataAccess/rf1/
			$serialization_format = 'dawg-xml';
		} elsif( $format eq 'ntriples' ) {
			if( $output_xslt ) {
				$sth->finish;
				$class->_error( $ap, "N-Triples output can be applied to XSLT style-sheet $output_xslt" );
				return $Apache::SPARQL::Responses{ 'OperationPointError' };
				};
	
			$serialization_format = 'N-Triples';
			};

		# XSLT and limit make sense only for SELECT queries due we do return dawg-xml format
		my $tot=0;
		if( $output_xslt ) {

			# prepare to output things
			$ap->content_type( ( $output_type ) ? $output_type : $class->_get_content_type( $format ) );

			if (! $class->_mp2 ) {
				$ap->send_http_header();
				};

			$output_xslt = $class->_cat( $ap, $output_xslt );
			unless( $output_xslt ) {
				$sth->finish;
				$class->_error( $ap, "Cannot fetch XSLT style-sheet $output_xslt" );
				return $Apache::SPARQL::Responses{ 'OperationPointError' };
				};

			# need to read the whole result string in-memory becuase XSLT does not stream - need to look at STX?
			my $whole_xml;

			eval {

			if( defined $limit and $limit == 0 ) {
				# HACK due we do not do LIMIT into our SPARQL engine yet
				$whole_xml = $sth->func( $serialization_format, 'fetchrow_XML' );
				$whole_xml =~ m|<results>|;
				$whole_xml = $` . $& . '</results></sparql>';
			} else {
				while ( my $xml = $sth->func( $serialization_format, 'fetchrow_XML' ) ) {
					$whole_xml .= $xml;
					$tot++;
					if( defined $limit and $tot == $limit ) {
						$whole_xml .= '</results></sparql>'
							unless( $whole_xml =~ m|</results>\s*</sparql>\s*$|m ); # HACK!
						last;
						};
					};
				};

				}; # end eval

			if($@) {
				$sth->finish;
				$class->_error( $ap, "Cannot process query: $@ " );
				return $Apache::SPARQL::Responses{ 'OperationPointError' };
				};

			my $parser = XML::LibXML->new();
			my $xslt_engine = XML::LibXSLT->new();

			my($source, $style_doc, $stylesheet, $results);

			eval {

				$source = $parser->parse_string($whole_xml);
				$style_doc = $parser->parse_string($output_xslt);

				$stylesheet = $xslt_engine->parse_stylesheet($style_doc);
				$results = $stylesheet->transform($source);

        			$ap->print( $stylesheet->output_string($results) );

				}; # end eval

                	if($@) {
				$sth->finish;
				$class->_error( $ap, "Cannot process query output with $output_xslt XSLT style-sheet: $@ " );
				return $Apache::SPARQL::Responses{ 'OperationPointError' };
				};
		} else {
			# prepare to output things
			$ap->content_type( $class->_get_content_type( $format ) );

			if (! $class->_mp2 ) {
				$ap->send_http_header();
				};

			# we stream otherwise

			eval {

			if( defined $limit and $limit == 0 ) {
				# HACK due we do not do LIMIT into our SPARQL engine yet
				my $xml = $sth->func( $serialization_format, 'fetchrow_XML' );
				$xml =~ m|<results>|;
				$xml = $` . $& . '</results></sparql>';
				$ap->print( $xml );
			} else {
				while ( my $xml = $sth->func( $serialization_format, 'fetchrow_XML' ) ) {
					$tot++;
					if( defined $limit and $tot == $limit ) {
						$xml .= '</results></sparql>'
							unless( $xml =~ m|</results>\s*</sparql>\s*$|m ); # HACK!

						$ap->print( $xml );

						last;
					} else {
						$ap->print( $xml );
						};
					};
				};
			
				}; # end eval

                	if($@) {
				$sth->finish;
				$class->_error( $ap, "Cannot process query output with $output_xslt XSLT style-sheet: $@ " );
				return $Apache::SPARQL::Responses{ 'OperationPointError' };
				};
			};
	} else {
		# prepare to output things
		$ap->content_type( $class->_get_content_type( $format ) );

		if (! $class->_mp2 ) {
			$ap->send_http_header();
			};

		# we need to reject output-xslt param here I guess

		if( $format eq 'rdfxml' ) {
			$serialization_format = 'RDF/XML';
		} elsif( $format eq 'xml' ) {
			$sth->finish;
			$class->_error( $ap, "XML output is not possible but SELECT queries" );
			return $Apache::SPARQL::Responses{ 'OperationPointError' };
		} elsif( $format eq 'ntriples' ) {
			$serialization_format = 'N-Triples';
			};

		eval {

		while (my $rdf = $sth->func( $serialization_format, 'fetchsubgraph_serialize' )) {
			# we stream otherwise
			$ap->print( $rdf );
			};

			}; # end eval
		};

	$sth->finish;

        return $Apache::SPARQL::Responses{ 'OK' };
        };

sub _preprocess_SPARQL_query {
	my ( $class, $ap, $query, %parameters ) = @_;

	my $preprocessed_query = $query;

        foreach my $param ( keys %parameters ) {
		my $to_substitute = '';
		if ( scalar( @{$parameters{ $param }->{'r'}} ) > 0 ) {
			$to_substitute = '<' .  join(' , ', @{ $parameters{ $param }->{'r'} } ) . '>';
		} elsif( scalar( @{$parameters{ $param }->{'l'}} ) == 1 ) {
			$to_substitute = $parameters{ $param }->{'l'}->[0];
		} elsif( scalar( @{$parameters{ $param }->{'l'}} ) > 1 ) {
			$to_substitute = '<' .  join(' , ', @{ $parameters{ $param }->{'l'} } ) . '>';
			};

                $preprocessed_query =~ s|\$\$$param|$to_substitute|mig;
                };

        #$class->_debug( $ap, "PREPROCESSED_QUERY:\n\n$preprocessed_query\n\n" );

        return $preprocessed_query;
	};

sub _error {
	my ($class, $ap, $err ) = @_;

	$ap->log()->error( " [ Apache::SPARQL::RDFStore ERROR ] $err " );
	};

sub _debug {
	my ($class, $ap, $msg ) = @_;

	$ap->log()->error( " [ Apache::SPARQL::RDFStore DEBUG ] $msg " );
	};

sub _SPARQLhas_Source {
        my ($class, $query) = @_;

        return ( $query =~ m/\s*(FROM|FROM NAMED|LOAD|WITH)\s*((\<[^>]*\>)|(([a-zA-Z0-9\-_$\.]+)?:([a-zA-Z0-9\-_$\.]+)))\s+/i );
        };

#   format       "rdfxml", "xml", "turtle", "ntriples" ... [defaults vary] (1)
sub _get_content_type {
	my ($class, $format) = @_;

	my $content_type;
	if( $format eq 'rdfxml' ) {
		$content_type = 'application/rdf+xml';
	} elsif( $format eq 'xml' ) {
		$content_type = 'application/sparql-results+xml';
	} elsif( $format eq 'turtle' ) {
		$content_type = 'application/x-turtle';
	} elsif( $format eq 'ntriples' ) {
		$content_type = 'application/ntriples';
	} else {
		$content_type = 'text/plain';
		};
	};

sub getGraph {
        my ($class, $ap, $graph_id, $format ) = @_;

        return $Apache::SPARQL::Responses{ 'MalformedRequest' };
        };

sub getServiceDescription {
        my ($class, $ap) = @_;

        return $Apache::SPARQL::Responses{ 'MalformedRequest' };
        };

=cut

=head1 NAME

Apache::SPARQL::RDFStore - A mod_perl handler which implements SPARQL HTTP bindings with RDFStore


=head1 SYNOPSIS

 <Location /rdfstore>

   SetHandler   perl-script
   PerlHandler  Apache::SPARQL::RDFStore

 </Location>

 #

 my $ua  = LWP::UserAgent->new();
 my $req = HTTP::Request->new(GET => "http://pim.example/rdfstore?query=PREFIX+foaf%3A+%3Chttp%3A%2F%2Fxmlns.com%2Ffoaf%2F0.1%2F%3E%0
D%0ASELECT+%3Fpg%0D%0AWHERE%0D%0A++%28%3Fwho+foaf%3Aname+%22Norm+Walsh%22%29%0D%0A++%28%3Fwho+foaf%3Aweblog+%3Fpg%29%0D%0A");

 my $res = $ua->request($req);

=head1 DESCRIPTION

Apache::SPARQL::RDFStore is a mod_perl handler which implements SPARQL HTTP bindings with RDFStore...

=head1 MOD_PERL COMPATIBILITY

This handler will work with both mod_perl 1.x and mod_perl 2.x.

=head1 AUTHOR

Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

 Apache::SPARQL
 http://www.w3.org/TR/rdf-sparql-protocol/
 http://www.w3.org/2001/sw/DataAccess/proto-wd/ (editor working draft)
 http://www.w3.org/2001/sw/DataAccess/prot26
 http://www.w3.org/TR/rdf-sparql-query/
 http://www.w3.org/2001/sw/DataAccess/rq23/ (edit working draft)

=head1 LICENSE

see LICENSE file included into this distribution

=cut

return 1;
