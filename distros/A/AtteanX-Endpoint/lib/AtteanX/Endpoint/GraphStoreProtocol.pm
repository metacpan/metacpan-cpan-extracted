use v5.14;
use warnings;

=head1 NAME

AtteanX::Endpoint::GraphStoreProtocol - SPARQL 1.2 Graph Store Protocol

=head1 VERSION

This document describes AtteanX::Endpoint::GraphStoreProtocol version 0.004

=head1 SYNOPSIS

  plackup -p 9091 scripts/endpoint.psgi

=head1 DESCRIPTION

The AtteanX::Endpoint::GraphStoreProtocol class implements the logic for the
SPARQL Graph Store Protocol.

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

package AtteanX::Endpoint::GraphStoreProtocol 0.004 {
	use Moo;
	use Attean;
	use Attean::RDF qw(iri);
	use Encode qw(encode);
	use UUID::Tiny ':std';
	use Types::Standard qw(ConsumerOf CodeRef HashRef ArrayRef Str Int);
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

Extract the SPARQL Graph Store Protocol request from C<< $request >>, run the
corresponding query/update, and populate C<< $response >> with results or error
information.

=cut

	sub run {
		my $self	= shift;
		my $req		= shift;
		my $env		= $req->env;
		my $response	= shift;
		my $gsp_path	= shift;

		my $config	= $self->{conf};
		my $model	= $self->{model};
		my $headers	= $req->headers;
		my $type	= $headers->header('Accept') || 'application/sparql-results+xml';
		if (my $t = $req->param('media-type')) {
			$type	= $t;
			$headers->header('Accept' => $type);
		}

# 		my $ae		= $req->headers->header('Accept-Encoding') || '';
		my ($graph, $new, $default)	= $self->get_gsp_graph($req, $gsp_path);
		unless ($graph) {
			die AtteanX::Endpoint::ClientError->new(
				code => 400,
				message => 'No graph specified', uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_no_graph'
			);
		}
		my $base	= $req->base;
		my $parser	= Attean->get_parser('SPARQL')->new(base => $base);
		my $algebra;
		my $content;
		if ($req->method eq 'GET' or $req->method eq 'HEAD') {
			my $sparql		= 'CONSTRUCT WHERE { ?s ?p ?o }';
			($algebra)	= eval { $parser->parse($sparql, base => $base) };
			$self->log_gsp_request( $req );
			if ($@ or not($algebra)) {
				my $error	= $@ || 'Internal error';
				$self->log_error( $req, $error );
				my $eclass	= ($error =~ /Syntax/) ? 'AtteanX::Endpoint::ClientError' : 'AtteanX::Endpoint::ServerError';
				die $eclass->new(message => 'SPARQL GSP parse error', uri => 'http://id.kasei.us/rdf-endpoint/error/parse_error', details => { error => $error });
			}
		} else {
			unless ($config->{endpoint}{update}) {
				die AtteanX::Endpoint::ClientError->new(code => 405, message => 'Method not allowed', uri => 'http://id.kasei.us/rdf-endpoint/error/bad_http_method');
			}
			if ($req->method eq 'PUT' or $req->method eq 'POST') {
				my $ct		= $req->headers->header('Content-Type');
				
				unless ($ct) {
					die AtteanX::Endpoint::ClientError->new(
						code => 400,
						message => 'No Content-Type specified for PUT request', uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_no_media_type'
					);
				}

				if ($req->method eq 'POST' and $ct =~ m#^multipart/form-data#) {
					my $uploads	= $req->uploads;
					my @ops;
					foreach my $file (keys %$uploads) {
						my $f	= $uploads->get($file);
						my $ct	= $f->content_type;
						my $ok	= open(my $fh, '<:raw', $f->path);
						unless ($ok) {
							die AtteanX::Endpoint::ServerError->new(
								code => 500,
								message => "Failed to open uploaded file in GSP request", uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_upload_error'
							);
						}
						my $insert	= $self->update_for_io($req, $graph, $ct, $fh);
						push(@ops, $insert);
					}
					my $seq		= Attean::Algebra::Sequence->new(children => \@ops);
					$algebra	= $seq;
				} else {
					my $pclass	= Attean->get_parser(media_type => $ct) // Attean->get_parser('turtle');
					unless ($pclass) {
						die AtteanX::Endpoint::ClientError->new(
							code => 400,
							message => "No parser available for media type $ct", uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_unrecognized_media_type'
						);
					}
					
					my $parser	= $pclass->new();
					my $iter = eval { $parser->parse_iter_from_bytes($req->content) };
					if ($@) {
						die AtteanX::Endpoint::ClientError->new(
							code => 400,
							message => "Failed to parse the body in GSP request: " . $req->method, uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_body_syntax_error'
						);
					}
					
					my @ops;
					if ($req->method eq 'PUT') {
						my $drop	= Attean::Algebra::Clear->new(drop => 1, silent => 1, target => 'GRAPH', graph => $graph);
						push(@ops, $drop);
					}
					my $insert	= Attean::Algebra::Modify->new(insert => [$iter->as_quads($graph)->elements]);
					push(@ops, $insert);
					my $seq		= Attean::Algebra::Sequence->new(children => \@ops);
		# 			warn $seq->as_string;
					$algebra	= $seq;
				}
			} elsif ($req->method eq 'DELETE') {
				$algebra	= Attean::Algebra::Clear->new(drop => 1, silent => 1, target => 'GRAPH', graph => $graph);
			} else {
				die AtteanX::Endpoint::ClientError->new(
					code => 400,
					message => "Unsupported HTTP method: " . $req->method, uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_unrecognized_http_method'
				);
			}
		}

		if ($self->log->is_trace) {
			$self->log->trace("Algebra:\n" . $algebra->as_string);
		}
		my $default_graphs	= [$graph];
		my $planner	= $self->planner;
		if ($self->log->is_trace) {
			$self->log->debug('Planning with default graphs:');
			foreach my $g (@$default_graphs) {
				$self->log->trace($g->as_string);
			}
		}

		my $plan	= $planner->plan_for_algebra($algebra, $model, $default_graphs);
		if ($self->log->is_debug) {
			$self->log->debug("Plan:\n" . $plan->as_string);
		}
		my $empty_graph	= do {
			my $iter		= $model->get_quads(undef, undef, undef, $graph);
			my $st			= $iter->next;
			ref($st) ? 0 : 1;
		};
		my $code;
		if ($new) {
			$code	= 201;
		} elsif ($req->method eq 'PUT') {
			# Return 201 Created on empty graphs (these are considered newly created)
			# unless it's the default graph (which always exists, so can't be "created").
			$code	= ($empty_graph and not($default)) ? 201 : 204;
		} elsif ($req->method eq 'POST') {
			$code	= 204;
		} elsif ($req->method eq 'DELETE') {
			$code	= $empty_graph ? 404 : 204;
		} elsif ($req->method =~ m/^(GET|HEAD)$/) {
			if ($self->graph->equals($graph)) {
				# never return a 404 for the default graph
				$code	= 200;
			} else {
				$code	= $empty_graph ? 404 : 200;
			}
		} else {
			die $req->method;
		}
		eval {
			my $iter	= $plan->evaluate($model);
			if ($req->method eq 'GET' or $req->method eq 'HEAD') { # RDF content
				my $sclass	= Attean->negotiate_serializer(request_headers => $headers, role => 'Attean::API::TripleSerializer') // Attean->get_serializer('ntriples');
				my @args;
				$self->log->debug("Serializer class: $sclass");
				my $s		= $sclass->new(@args);
				my $stype	= $s->canonical_media_type;
				if ($req->method eq 'GET') {
					$content	= $s->serialize_iter_to_bytes($iter);
				}
				$response->headers->content_type($stype);
			} else {
				$response->headers->content_type('text/plain');
				$content	= "OK\n";
			}
		};
		
		if ($new) {
			$response->header('Location' => $graph->value);
		}
		
		if ($@) {
			my $error	= $@;
			$self->log->fatal($error);
			die AtteanX::Endpoint::ServerError->new(code => 500, message => 'SPARQL GSP execution error', uri => 'http://id.kasei.us/rdf-endpoint/error/execution_error', details => { error => $@ });
		}
	
		$response->status($code);
		$response->body($content);
		return $content;
	}

=item C<< update_for_io( $request, $graph, $content_type, $io ) >>

Parses RDF content of type C<< $content_type >> from C<< $io >>, and inserts
it into the specified C<< $graph >>, clearing that graph first if
C<< $request->method >> is 'PUT'.

C<< $io >> is expected to be a byte-oriented filehandle (one opened with the
C<< :raw >> layer, for example). A handle carrying a character encoding layer
is also accepted, as its contents are re-encoded to UTF-8 before parsing.

=cut
	
	sub update_for_io {
		my $self	= shift;
		my $req		= shift;
		my $graph	= shift;
		my $ct		= shift;
		my $io		= shift;
		my $bytes	= do { local $/; <$io> } // '';
		$bytes		= encode('UTF-8', $bytes) if (utf8::is_utf8($bytes));
		my $pclass	= Attean->get_parser(media_type => $ct) // Attean->get_parser('turtle');
		unless ($pclass) {
			die AtteanX::Endpoint::ClientError->new(
				code => 400,
				message => "No parser available for media type $ct", uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_unrecognized_media_type'
			);
		}
		
		my $parser	= $pclass->new();
		my $iter = eval { $parser->parse_iter_from_bytes($bytes) };
		if ($@) {
			die AtteanX::Endpoint::ClientError->new(
				code => 400,
				message => "Failed to parse the body in GSP request: " . $req->method, uri => 'http://id.kasei.us/rdf-endpoint/error/gsp_body_syntax_error'
			);
		}
		
		my @ops;
		if ($req->method eq 'PUT') {
			my $drop	= Attean::Algebra::Clear->new(drop => 1, silent => 1, target => 'GRAPH', graph => $graph);
			push(@ops, $drop);
		}
		my $insert	= Attean::Algebra::Modify->new(insert => [$iter->as_quads($graph)->elements]);
		return $insert;
	}

=item C<< get_gsp_graph( $request ) >>

Return a list C<< ( $g, $new ) >> of the graph identified by the GSP request
(either directly- or indirectly-identified, or C<< $self->graph >> for the
default graph), and a boolean flag indicating if the graph should be newly
created (in the case of a POST to the GSP endpoint without identifying a
graph).

=cut

	sub get_gsp_graph {
		my $self	= shift;
		my $req		= shift;
		my $env		= $req->env;
		my $host	= $env->{'HTTP_HOST'};
		my $scheme	= $env->{'psgi.url_scheme'};
		my $gsp_path	= shift;
		my $direct	= ((substr($req->path, 0, length($gsp_path)) eq $gsp_path) and not($req->param('graph')) and length($req->path) > length($gsp_path));
		my $query     = $req->parameters;
		my $g;
		my $new		= 0;
		my $is_default	= 0;
		if ($req->query_string eq 'default') {
			my $default	= $self->graph;
			$g	= $default;
			$is_default	= 1;
		} elsif (my $graph = $req->param('graph')) {
			$g	= iri($graph);
		} elsif ($direct) {
			my $uri	= "${scheme}://$host" . $req->path;
			$g	= iri($uri);
		} else {
			$g	= Attean::IRI->new('urn:uuid:' . uc(uuid_to_string(create_uuid())));
			$new	= 1;
		}
		return ($g, $new, $is_default);
	}

=item C<< log_gsp_request( $request ) >>

Log the request.

=cut

	sub log_gsp_request {
		my $self	= shift;
		my $req		= shift;
		$self->log->info("GSP query:\n" . $req->method);
		$self->_log( $req, { level => 'info' } );
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
