# TODO: If the model supports caching roles, add headers and check for http 304
# TODO: Implement and support Accept-Language models (port from RDF::Trine::Store::LanguagePreference)
# TODO: Add next/prev link headers if query is paged
# TODO: Add configuration and link headers to indicate LDF/SPARQL mirrors

use v5.14;
use warnings;

=head1 NAME

AtteanX::Endpoint - SPARQL 1.2 Protocol Endpoint

=head1 VERSION

This document describes AtteanX::Endpoint version 0.004

=head1 SYNOPSIS

  plackup -p 9091 scripts/endpoint.psgi

=head1 DESCRIPTION

The AtteanX::Endpoint class implements a PSGI SPARQL Protocol endpoint.

=head1 ATTRIBUTES

=over 4

=item C<< planner >>

=item C<< model >>

=item C<< conf >>

A hash reference containing configuration data for the endpoint. For example:

  {
    endpoint  => {
      service_description => {
        named_graphs => 1,
        default => 1,
      },
      load_data => 0,
      update => 0,
    }
  }

=item C<< graph >>

The L<Attean::API::IRI> of the graph in the model that represents the default graph.

=back

=head1 METHODS

=over 4

=cut

package AtteanX::Endpoint {
	our $VERSION	= "0.004";
	use Moo;
	use Attean;
	use Attean::RDF qw(iri);
	use Try::Tiny;
	use JSON;
	use Encode;
	use Plack::Request;
	use Plack::Response;
	use Scalar::Util qw(blessed refaddr);
	use List::MoreUtils qw(any);
	use File::ShareDir qw(dist_dir);
	use HTTP::Negotiate qw(choose);
	use IO::Compress::Gzip qw(gzip);
	use HTML::HTML5::Writer qw(DOCTYPE_XHTML_RDFA);
	use Carp qw(croak);
	use Types::Standard qw(ConsumerOf CodeRef HashRef ArrayRef Str Int);
# 	use IO::Handle;
# 	use Digest::MD5 qw(md5_base64);
 	use XML::LibXML 1.70;
	use AtteanX::Endpoint::GraphStoreProtocol;
	use AtteanX::Endpoint::Protocol;
# 	use RDF::RDFa::Generator 0.102;
# 	use Hash::Merge::Simple qw/ merge /;
# 	use Fcntl qw(:flock SEEK_END);
	use AtteanX::Endpoint::Error;
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
	
	sub BUILDARGS {
		my $class		= shift;
		my @params = @_;
		my %args;
		if (blessed($params[0]) and $params[0]->does('Attean::API::Model')) {
			# ->new( $model, \%conf )
			$args{ model }	= shift @params;
			$args{ conf }	= shift @params;
			$args{ graph }	= Attean::IRI->new('http://example.org/graph');
		} elsif (any { blessed($_) && $_->does('Attean::API::Model') } @params) {
			# Assume the buildargs can be taken directly
			return $class->SUPER::BUILDARGS(@params);
		} else {
			# ->new( \%conf )
			my $conf		= shift @params;
			my $store_conf	= $conf->{store};
			my $store;
			my $file;
			if (ref($store_conf) eq 'HASH') {
				my $name	= delete $store_conf->{name};
				$file		= delete $store_conf->{load_file};
				my $sclass	= Attean->get_store($name);
				$store		= $sclass->new( %$store_conf );
			} else {
				(my $name_, $file)	= split(';', $store_conf, 2);
				my ($name, @args)	= split('=', $name_);
				my $sclass	= Attean->get_store($name);
				$store	= $sclass->new(@args);
			}
			my $model	= Attean::MutableQuadModel->new( store => $store );
			
			my $guri	= 'http://example.org/default-graph';
			if (my $dataset = $conf->{dataset}) {
				$guri	= $dataset->{default};
			}
			my $graph	= Attean::IRI->new($guri);
			if (defined($file) and length($file)) {
				$graph		= Attean::IRI->new('file://' . File::Spec->rel2abs($file));
				open(my $fh, '<:encoding(UTF-8)', $file) or die $!;
				#$self->log->debug("Parsing data from $file...");
				my $pclass	= Attean->get_parser( filename => $file ) // 'AtteanX::Parser::Turtle';
				my $parser	= $pclass->new(base => $graph);
				my $iter	= $parser->parse_iter_from_io($fh);
				my $quads	= $iter->as_quads($graph);
				$model->add_iter($quads);
			}
			
			$args{ model }	= $model;
			$args{ conf }	= $conf;
			$args{ graph }	= $graph;
		}
		
		return $class->SUPER::BUILDARGS(%args);
	}

=item C<< run ( $request ) >>

Run the SPARQL request contained in the given C<< $request >> object and return
a response object.

=cut
	
	sub run {
		my $self	= shift;
		my $req		= shift;
		
		try {
			return $self->_run($req, @_);
		}
		catch {
			my $e		= $_;
			my $resp	= Plack::Response->new;
			my $error	= {};
			my ($code, $status);
			if (ref($e)) {
				$error->{describedby}	= $e->uri;
				$code	= $e->code;
				$status	= $e->message;
				if (my $d = $e->details) {
					$error->{details}		= $d;
				}
			} else {
				$code	= 500;
				$status	= 'Internal Server Error';
				$error->{message}	= $e;
				warn $e;
			}
			
			$error->{title}	= $status;
			
			my @variants	= (
				['text/plain', 0.98, 'text/plain'],
				['application/json-problem', 0.99, 'application/json-problem'],
			);
			my $headers	= $req->headers;
			my $stype	= choose( \@variants, $headers ) || 'text/plain';
			if ($stype eq 'application/json-problem') {
				$resp->headers->content_type( 'application/json-problem' );
				$resp->status($code);
				my $content	= encode_json($error);
				$resp->body($content);
			} else {
				$resp->headers->content_type( 'text/plain' );
				$resp->status($code);
				my @messages	= grep { defined($_) } @{ $error }{ qw(title detail message) };
				my $content		= join("\n\n", $status, @messages);
				$resp->body($content);
			}
			return $resp;
		}
	}
	
	sub _run {
		my $self	= shift;
		my $req		= shift;
		
		my $config	= $self->{conf};
		my $endpoint_path = $config->{endpoint}{endpoint_path} || '/sparql';
		my $gsp_path = $config->{endpoint}{gsp_path} || '/gsp';
		
		my $response	= Plack::Response->new;

		our $VERSION;
		my $server = "AtteanX::Endpoint/$VERSION";
		$server .= " " . $response->headers->header('Server') if defined($response->headers->header('Server'));
		$response->headers->header('Server' => $server);

		if ($req->path eq $endpoint_path or substr($req->path, 0, length($gsp_path)) eq $gsp_path) {
			# no-op
		} else {
			my $content;
			my $path	= $req->path_info;
			$path		=~ s#^/##;
			my $dir		= $ENV{ATTEAN_ENDPOINT_SHAREDIR} || File::Spec->catdir((eval { dist_dir('AtteanX-Endpoint') } || 'share'), 'endpoint');
			my $abs		= File::Spec->rel2abs($dir);
			my $file	= File::Spec->catfile($abs, 'www', $path);
			if (-r $file) {
				open( my $fh, '<', $file ) or croak $!;
				$response->status(200);
				$content	= $fh;
			} else {
				my $path	= $req->path;
				$response->status(404);
				$content	= <<"END";
	<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n<html><head>\n<title>404 Not Found</title>\n</head><body>\n
	<h1>Not Found</h1>\n<p>The requested URL $path was not found on this server.</p>\n</body></html>
END
			}
			$response->body($content);
			return $response;
		}
	
		my $ae		= $req->headers->header('Accept-Encoding') || '';
		if ($req->path eq $endpoint_path) {
			my $handler	= AtteanX::Endpoint::Protocol->new( model => $self->model, conf => $self->conf, graph => $self->graph );
			my $content	= $handler->run($req, $response, $gsp_path);
			$self->wrap_response_with_encoding($req, $response, $ae, $content);
		} else {
			my $handler	= AtteanX::Endpoint::GraphStoreProtocol->new( model => $self->model, conf => $self->conf, graph => $self->graph );
			my $content	= $handler->run($req, $response, $gsp_path);
			$self->wrap_response_with_encoding($req, $response, $ae, $content);
		}
		return $response;
	}

=item C<< wrap_response_with_encoding ( $request, $response, $ae, $body ) >>

If $ae includes 'gzip' as a requested Accept-Encoding value, and the body of
$response (or $body) is non-empty, gzip-compress the content body, setting
the response body to the new compressed data, and set Content-Encoding and
Content-Length headers appropriately on $response. Otherwise, set the
the response body to the uncompressed content, and set the Content-Length
header on $response.

=cut
	
	sub wrap_response_with_encoding {
		my $self	= shift;
		my $req		= shift;
		my $response	= shift;
		my $ae		= shift;
		my $content	= $response->body || shift;
		return unless (defined($content));
		
		my $length	= 0;
		my %ae		= map { $_ => 1 } split(/\s*,\s*/, $ae);
		if ($ae{'gzip'}) {
			my $orig	= length($content);
			my ($rh, $wh);
			pipe($rh, $wh);
			if (ref($content)) {
				gzip $content => $wh;
			} else {
				gzip \$content => $wh;
			}
			close($wh);
			my $body	= do { local($/) = undef; <$rh> };
 			$self->log->info("Compressed $orig bytes to " . length($body) . " bytes");
			$length		= bytes::length($body);
			$response->headers->header('Content-Encoding' => 'gzip');
			$response->headers->header('Content-Length' => $length);
			$response->body( $body ) unless ($req->method eq 'HEAD');
		} else {
			local($/)	= undef;
			my $body	= ref($content) ? <$content> : $content;
			$length		= bytes::length($body);
			$response->headers->header('Content-Length' => $length);
			$response->body( $body ) unless ($req->method eq 'HEAD');
		}
	}
}

package Plack::App::AtteanX::Endpoint 0.004 {
	use parent qw(Plack::Component);
	use Plack::Request;
	
	sub configure {
		my $self	= shift;
		$self->{config}	= shift;
		return $self;
	}
	
	sub prepare_app {
		my $self = shift;
		my $config = $self->{config};
		$self->{endpoint} = eval { AtteanX::Endpoint->new( $config ) };
		if ($@) {
			warn $@;
		}
	}

	sub call {
		my($self, $env) = @_;
		my $req	= Plack::Request->new($env);
		unless ($req->method =~ /^(GET|HEAD|POST|PUT|DELETE)$/) {
			return [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ];
		}

		my $ep		= $self->{endpoint};
		my $resp	= $ep->run( $req );
		return $resp->finalize;
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
