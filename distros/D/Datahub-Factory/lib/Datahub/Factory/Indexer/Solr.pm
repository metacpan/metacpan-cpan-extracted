package Datahub::Factory::Indexer::Solr;

use Datahub::Factory::Sane;

our $VERSION = '1.73';

use Moo;
use Catmandu;
use HTTP::Request::Common;
use HTTP::Request::StreamingUpload;
use JSON;
use LWP::UserAgent;
use URI::URL;
use XML::LibXML;
use namespace::clean;

with 'Datahub::Factory::Indexer';

has request_handler => (is => 'ro', required => 1);

sub _build_out {
    my $self = shift;

    my $ua = LWP::UserAgent->new(
        env_proxy  => 1,
        keep_alive => 1,
        timeout    => 120,
        agent      => 'Mozilla/5.0',
    );

    return $ua;
}

sub index {
	my $self = shift;

    my ($request_handler, $response, $request); 

    # Index the JSON data

    $request_handler = url $self->{request_handler};
    $request_handler->equery('commit=false&delete_boost_fields=false');

    $request = HTTP::Request::StreamingUpload->new(
        POST    => "$request_handler",
        path    => $self->{file_name},
        headers => HTTP::Headers->new(
            'Content-Type'   => 'application/json',
            'Content-Length' => -s $self->{file_name},
        ),
    );

    $response = $self->out->request($request);

    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } else {
        my $message = decode_json($response->decoded_content);
        Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $message->{error}->{msg},
            url              => $response->request->uri->as_string,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content,
        });
        return undef;
    }
}

sub commit {
    my $self = shift;

    my ($request_handler, $response, $request, $result); 

    $request_handler = url $self->{request_handler};

    # Commit the index
    my @path = $request_handler->path_components;
    pop @path;
    $request_handler->path_components(@path);
    $request_handler->equery('commit=true');

    $request = HTTP::Request->new(
         GET     => $request_handler,
    );

    $response = $self->out->request($request);

    if ($response->is_success) {
        my $dom = XML::LibXML->load_xml(string => $response->decoded_content);
        
        foreach my $int ($dom->findnodes('/response/lst'))  {
            $result->{responseHeader}->{status} = $int->findvalue('./int[@name="status"]');
            $result->{responseHeader}->{QTime} = $int->findvalue('./int[@name="QTime"]');
        }

        return $result;
    } else {
        my $message = decode_json($response->decoded_content);
        Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $message->{error}->{msg},
            url              => $response->request->uri->as_string,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content,
        });
        return undef;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Indexer::Solr - Index data in Solr via a data import handler.

=head1 SYNOPSIS

    use Datahub::Factory;

    my $indexer = Datahub::Factory->indexer('Solr')->new('request_handler' => 'http://path');

    $indexer->index();
    $indexer->commit();

=head1 DESCRIPTION


=head1 AUTHORS

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2017 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut

