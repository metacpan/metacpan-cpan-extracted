use v5.14;
use warnings;

=head1 NAME

AtteanX::Endpoint::Protocol - SPARQL 1.2 Protocol

=head1 VERSION

This document describes AtteanX::Endpoint::Protocol version 0.004

=head1 SYNOPSIS

  plackup -p 9091 scripts/endpoint.psgi

=head1 DESCRIPTION

The AtteanX::Endpoint::Protocol class implements the logic for the
SPARQL Protocol.

=head1 ATTRIBUTES

=over 4

=item C<< graph >>

The L<Attean::API::IRI> of the graph in the model that represents the default graph.

=item C<< model >>

=item C<< conf >>

=item C<< planner >>

=back

=head1 METHODS

=over 4

=cut

package AtteanX::Endpoint::Protocol 0.004 {
	use Moo;
	use Attean;
	use Encode qw(encode_utf8);
	use Scalar::Util qw(blessed);
	use Attean::RDF qw(iri);
	use Attean::DatasetModel;
	use UUID::Tiny ':std';
	use Module::Load::Conditional qw(can_load);
	use Types::Standard qw(ConsumerOf CodeRef HashRef ArrayRef Str Int);
	use HTML::HTML5::Writer qw(DOCTYPE_XHTML_RDFA);
	use namespace::clean;

	with 'MooX::Log::Any';

	has 'planner' => (
		is => 'ro',
		isa => ConsumerOf['Attean::API::QueryPlanner'],
		required => 1,
		default => sub {
			Attean::IDPQueryPlanner->new();
		}
	);
	has 'model' => (is => 'ro', isa => ConsumerOf['Attean::API::Model'], required => 1);
	has 'conf'	=> (is => 'ro', isa => HashRef, required => 1);
	has 'graph'	=> (is => 'ro', isa => ConsumerOf['Attean::API::IRI'], required => 1);

=item C<< run( $request, $response ) >>

Extract the SPARQL Protocol request from C<< $request >>, run the corresponding
query/update, and populate C<< $response >> with results or error information.

=cut

	sub run {
		my $self	= shift;
		my $req		= shift;
		my $env		= $req->env;
		my $response	= shift;

		my $config	= $self->{conf};
		my $model	= $self->{model};
		my $headers	= $req->headers;
		my $type	= $headers->header('Accept') || 'application/sparql-results+xml';
		if (my $t = $req->param('media-type')) {
			$type	= $t;
			$headers->header('Accept' => $type);
		}
	
		my $ae		= $req->headers->header('Accept-Encoding') || '';
	
		my $sparql;
		my $content;
		my $ct	= $req->header('Content-type');
		my $is_update	= 0;
		if ($req->method !~ /^(GET|POST)$/i) {
			my $method	= uc($req->method);
			$content	= "Unexpected method $method (expecting GET or POST)";
			$self->log_error( $req, $content );
			$response->header('Allow' => 'GET, POST');
			die AtteanX::Endpoint::ClientError->new(code => 405, message => 'Method not allowed', uri => 'http://id.kasei.us/rdf-endpoint/error/bad_http_method');
		} elsif (defined($ct) and $ct eq 'application/sparql-query') {
			$sparql	= $req->content;
		} elsif (defined($ct) and $ct eq 'application/sparql-update') {
			$is_update	= 1;
			if ($config->{endpoint}{update} and $req->method eq 'POST') {
				$sparql	= $req->content;
			}
		} elsif ($req->param('query')) {
			my @sparql	= $req->param('query');
			if (scalar(@sparql) > 1) {
				$content	= "More than one query string submitted";
				$self->log_error( $req, $content );
				die AtteanX::Endpoint::ClientError->new(code => 400, message => 'Multiple query strings not allowed', uri => 'http://id.kasei.us/rdf-endpoint/error/multiple_queries');
			} else {
				$sparql = $sparql[0];
			}
		} elsif ($req->param('update')) {
			$is_update	= 1;
			my @sparql	= $req->param('update');
			if (scalar(@sparql) > 1) {
				$content	= "More than one update string submitted";
				$self->log_error( $req, $content );
				die AtteanX::Endpoint::ClientError->new(code => 400, message => 'Multiple update strings not allowed', uri => 'http://id.kasei.us/rdf-endpoint/error/multiple_updates');
			}
		
			if ($config->{endpoint}{update} and $req->method eq 'POST') {
				$sparql = $sparql[0];
			} elsif ($req->method ne 'POST') {
				my $method	= $req->method;
				$content	= "Update operations must use POST";
				$self->log_error( $req, $content );
				$response->header('Allow' => 'POST');
				die AtteanX::Endpoint::ClientError->new(code => 405, message => "$method Not Allowed for Update Operation", uri => 'http://id.kasei.us/rdf-endpoint/error/bad_http_method_update');
			}
		}
	
		my $dir			= $ENV{ATTEAN_ENDPOINT_SHAREDIR} || File::Spec->catdir((eval { dist_dir('AtteanX-Endpoint') } || 'share'), 'endpoint');
		if ($sparql) {
			my %args;
			$args{ update }		= 1 if ($config->{endpoint}{update} and $req->method eq 'POST');
			$args{ load_data }	= 1 if ($config->{endpoint}{load_data});
		
			my $base	= Attean::IRI->new( value => $req->base->as_string );
			my $parser	= Attean->get_parser('SPARQL')->new(base => $base);
			$parser->update(1) if ($args{update});
			my ($algebra)	= eval { $args{update} ? $parser->parse_update($sparql, base => $base) : $parser->parse($sparql, base => $base) };
			
			if ($@ or not($algebra)) {
				my $error	= $@ || 'Internal error';
				$self->log_error( $req, $error );
				my $eclass	= ($error =~ /Expect|Syntax/) ? 'AtteanX::Endpoint::ClientError' : 'AtteanX::Endpoint::ServerError';
				if ($req->method ne 'POST' and $error =~ /read-only queries/sm) {
					$error	= 'Updates must use a HTTP POST request.';
					die $eclass->new(message => 'Updates must use a HTTP POST request', uri => 'http://id.kasei.us/rdf-endpoint/error/bad_http_method_update');
				} else {
					die $eclass->new(message => 'SPARQL query/update parse error', uri => 'http://id.kasei.us/rdf-endpoint/error/parse_error', details => { error => $error, sparql => $sparql });
				}
			}
			
			my $protocol_specifies_query_dataset	= 0;
			my $protocol_specifies_update_dataset	= 0;
			my @default_graphs	= ($self->graph);
			{
				my @default	= map { iri($_) } $req->parameters->get_all('default-graph-uri');
				my @named	= map { iri($_) } $req->parameters->get_all('named-graph-uri');
				if (scalar(@default) or scalar(@named)) {
					$protocol_specifies_query_dataset	= 1;
					if ($is_update) {
						if (scalar(@default)) {
							die AtteanX::Endpoint::ClientError->new(
								code => 400,
								message => 'Unexpected default-graph-uri specified in update request',
								uri => 'http://id.kasei.us/rdf-endpoint/error/invalid_update_dataset'
							);
						} else {
							die AtteanX::Endpoint::ClientError->new(
								code => 400,
								message => 'Unexpected named-graph-uri specified in update request',
								uri => 'http://id.kasei.us/rdf-endpoint/error/invalid_update_dataset'
							);
						}
					}
					$model	= Attean::MutableDatasetModel->new( model => $model, graphs => [@named, @default] );
					@default_graphs	= scalar(@default) ? @default : (Attean::IRI->new('urn:uuid:' . uc(uuid_to_string(create_uuid())))); # some default graph that will not match any data
				}
			}
		
			my @update_default;
			my @update_named;
			{
				@update_default	= map { iri($_) } $req->parameters->get_all('using-graph-uri');
				@update_named	= map { iri($_) } $req->parameters->get_all('using-named-graph-uri');
				if (scalar(@update_named) or scalar(@update_default)) {
					if ($is_update) {
						my $specifies_dataset	= 0;
						$algebra->walk( prefix => sub {
							my $a		= shift;
							if ($a->isa('Attean::Algebra::Modify')) {
								$specifies_dataset	||= $a->specifies_dataset;
							}
						});
						if ($specifies_dataset) {
							die AtteanX::Endpoint::ClientError->new(
								code => 400,
								message => 'Update request specifies dataset in both using-graph-uri/using-named-graph-uri parameter and USING/WITH clause',
								uri => 'http://id.kasei.us/rdf-endpoint/error/update_specifies_multiple_datasets'
							);
						}
					} else {
						if (scalar(@update_default)) {
							die AtteanX::Endpoint::ClientError->new(
								code => 400,
								message => 'Unexpected using-graph-uri specified in query request',
								uri => 'http://id.kasei.us/rdf-endpoint/error/invalid_query_dataset'
							);
						} else {
							die AtteanX::Endpoint::ClientError->new(
								code => 400,
								message => 'Unexpected using-named-graph-uri specified in query request',
								uri => 'http://id.kasei.us/rdf-endpoint/error/invalid_query_dataset'
							);
						}
					}
					$protocol_specifies_update_dataset	= 1;
					$model	= Attean::MutableDatasetModel->new( model => $model, graphs => [@update_named, @update_default] );
					@default_graphs	= scalar(@update_default) ? @update_default : (Attean::IRI->new('urn:uuid:' . uc(uuid_to_string(create_uuid())))); # some default graph that will not match any data
				}
			}
		
# 			my $match	= $headers->header('if-none-match') || '';
# 			my $etag	= md5_base64( join('#', $self->run_tag, $model->etag, $type, $ae, $sparql) );
# 			if (length($match)) {
# 				if (defined($etag) and ($etag eq $match)) {
# 					$response->status(304);
# 					return $response;
# 				}
# 			}
		
			{
				$self->log_query( $req, $sparql );
				if ($self->log->is_trace) {
					$self->log->trace("Algebra:\n" . $algebra->as_string);
				}
				my $default_graphs	= \@default_graphs;
				my $planner	= $self->planner;

				if ($self->log->is_trace) {
					$self->log->debug('Planning with default graphs:');
					foreach my $g (@$default_graphs) {
						$self->log->trace($g->as_string);
					}
				}

				$planner->suppress_dataset( $protocol_specifies_query_dataset );
				my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
				if ($self->log->is_debug) {
					$self->log->debug("Plan:\n" . $plan->as_string);
				}
				eval {
					my $iter	= $plan->evaluate($model);
					$response->status(200);
					my $accept	= $headers->header('Accept');
					if (defined($accept) and $accept eq '*/*') {
						$headers->remove_header('Accept');
					}
					
					my $is_ask		= $algebra->child->isa('Attean::Algebra::Ask');
					my $is_rdf		= ($algebra->child->isa('Attean::Algebra::Construct') or $algebra->child->isa('Attean::Algebra::Describe'));
					
					if ($is_update) {
						$content	= "OK\n";
						$response->headers->content_type('text/plain');
					} else {
						my $role	= $is_rdf ? 'Attean::API::TripleSerializer' : 'Attean::API::ResultSerializer';
						my $default	= $is_rdf ? 'ntriples' : 'sparqlxml';
						my %args;
						if ($is_ask) {
							$args{restrict}	= ['AtteanX::Serializer::SPARQLJSON', 'AtteanX::Serializer::SPARQLXML'];
						}
						my $sclass	= eval { Attean->negotiate_serializer(request_headers => $headers, role => $role, %args) } // Attean->get_serializer($default);
						if ($sclass eq 'AtteanX::Serializer::SPARQLHTML') {
							my $s		= $sclass->new(full_document => 0);
							my $table	= $s->serialize_iter_to_bytes($iter);
							my $tpath	= File::Spec->catfile($dir, 'templates', 'results.html');
							my $template	= do { local($/); open(my $fh, '<:utf8', $tpath); <$fh> };
							
							$template	=~ s/\$RESULTS\$/$table/sm;
							$template	=~ s/\$QUERY\$/$sparql/sm;
							$content	= $template;
							my $stype	= $s->canonical_media_type;
							$response->headers->content_type($stype);
						} else {
							my $s		= $sclass->new();
							$content	= $s->serialize_iter_to_bytes($iter);
							my $stype	= $s->canonical_media_type;
							$response->headers->content_type($stype);
						}
					}
				};
				if ($@) {
					my $error	= $@;
					$self->log->fatal($error);
					die AtteanX::Endpoint::ServerError->new(code => 500, message => 'SPARQL query/update execution error', uri => 'http://id.kasei.us/rdf-endpoint/error/execution_error', details => { error => $@, sparql => $sparql });
				}
			}
		} elsif ($req->method eq 'POST') {
			$content	= "POST without recognized query or update";
			$self->log_error( $req, $content );
			die AtteanX::Endpoint::ClientError->new(message => 'Missing SPARQL Query/Update String', uri => 'http://id.kasei.us/rdf-endpoint/error/missing_sparql_string');
		} else {
			$content	= $self->service_description($req, $response, $type, $dir);
# 			$response->headers->header('Link', '</sparql-service-description>; rel="service-desc"');
		}
	
		return $content;
	}
	
	sub service_description {
		my $self		= shift;
		my $req			= shift;
		my $response	= shift;
		my $type		= shift;
		my $dir			= shift;
		my $config	= $self->{conf};

		my @serializers;
		foreach my $sclass (Attean->serializers()) {
			if (can_load( modules => { $sclass => 0 })) {
				next unless ($sclass->does('Attean::API::Serializer'));
				next unless ($sclass->can('canonical_iri'));
				my $iri	= $sclass->canonical_iri;
				push(@serializers, "<${iri}>");
			}
		}
		
		my @functions	= map { "<$_>" } Attean->get_functions();
		my @aggregates	= map { "<$_>" } Attean->get_aggregates();

		my @features;
		push(@features, 'sd:DereferencesURIs') if ($config->{endpoint}{load_data});

		my $env			= $req->env;
		my $sclass		= Attean->get_serializer( media_type => $type );
		if ($sclass and $sclass->does('Attean::API::TripleSerializer')) {
			my $host		= $env->{'HTTP_HOST'};
			my $scheme		= $env->{'psgi.url_scheme'};
			my $path		= $env->{'PATH_INFO'};
			my $endpoint	= "${scheme}://${host}${path}";
			my $prefixes	= <<'END';
			@prefix sparql: <http://www.w3.org/ns/sparql#> .
			@prefix sd: <http://www.w3.org/ns/sparql-service-description#> .
			@prefix void: <http://rdfs.org/ns/void#> .
END
			
			my $formats		= scalar(@serializers) ? 'sd:resultFormat ' . join(', ', @serializers) . ' ;' : '';
			my $functions	= scalar(@functions) ? 'sd:extensionFunction ' . join(', ', @functions) . ' ;' : '';
			my $aggregates	= scalar(@aggregates) ? 'sd:extensionAggregate ' . join(', ', @aggregates) . ' ;' : '';
			my $features	= scalar(@features) ? 'sd:feature ' . join(', ', @features) . ' ;' : '';
			
			my $ttl	= <<"END";
				
				${prefixes}
				[] a sd:Service ;
					sd:endpoint <${endpoint}> ;
					sd:supportedLanguage sd:SPARQLQuery ;
					sd:supportedVersion sparql:version-1.2, sparql:version-1.2-basic, sparql:version-1.1, sparql:version-1.0 ;

					$formats

					${functions}
					${aggregates}
					${features}
					
					.
END

# TODO dataset details:
# 					sd:defaultDataset [
# 						a sd:Dataset ;
# 						sd:defaultGraph [
# 							a sd:Graph ;
# 							void:triples 100
# 						] ;
# 						sd:namedGraph [
# 							a sd:NamedGraph ;
# 							sd:name <http://www.example/named-graph> ;
# 							sd:graph [
# 								a sd:Graph ;
# 								void:triples 2000
# 							]
# 						]
# 					] ;


			my $parser	= Attean->get_parser('Turtle')->new();
			my $iter = $parser->parse_iter_from_bytes(encode_utf8($ttl));
			my $map		= URI::NamespaceMap->new( {
				'sparql'	=> iri('http://www.w3.org/ns/sparql#'),
				'sd'		=> iri('http://www.w3.org/ns/sparql-service-description#'),
				'void'		=> iri('http://rdfs.org/ns/void#'),
				'rdf'		=> iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#'),
			} );
			my $ser	= $sclass->new( namespaces => $map );

			$response->status(200);
			$response->headers->content_type($type);
			return $ser->serialize_iter_to_bytes($iter);
		} else {
			my $stype		= 'text/html';
			my $template	= File::Spec->catfile($dir, 'index.html');
			my $parser		= XML::LibXML->new(validation => 0, suppress_errors => 1, no_network => 1, recover => 2);
			my $doc			= $parser->parse_file( $template );
# 			my $gen			= RDF::RDFa::Generator->new( style => 'HTML::Head');
# 			$gen->inject_document($doc, $sdmodel);
		
			my $writer	= HTML::HTML5::Writer->new( markup => 'xhtml', doctype => DOCTYPE_XHTML_RDFA );
			my $content	= encode_utf8( $writer->document($doc) );
			$response->status(200);
			$response->headers->content_type('text/html');
			return $content;
		}
	}

=item C<< log_query ( $request, $sparql ) >>

Log the C<< $sparql >> query string after having been parsed from the
C<< $request >> but before evaluation.

=cut

	sub log_query {
		my $self	= shift;
		my $req		= shift;
		my $message	= shift;
		$self->log->info("SPARQL query:\n" . $message);
		$self->_log( $req, { level => 'info', message => $message } );
	}

=item C<< log_error ( $message ) >>

=cut

	sub log_error {
		my $self	= shift;
		my $req		= shift;
		my $message	= shift;
		$self->log->error($message);
		$self->_log( $req, { level => 'error', message => $message } );
	}

	sub _log {
		my $self	= shift;
		my $req		= shift;
		my $data	= shift;
		my $logger	= $req->logger || sub {};
	
		$logger->($data);
	}
}

1;

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/atteanx-endpoint/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) Gregory Todd Williams.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
