package Catmandu::Plack::unAPI;

use Catmandu::Sane;
use Catmandu;
use Catmandu::Util qw(is_array_ref);
use Plack::App::unAPI;
use Plack::Request;
use Moo;

use parent 'Plack::Component';

our $VERSION = '0.11';

has formats => (
    is      => 'ro',
    default => sub {
        return {
            json => {
                type     => 'application/json',
                exporter => [ 'JSON', pretty => 1 ],
                docs     => 'http://json.org/',
            },
            yaml => {
                type     => 'text/yaml',
                exporter => [ 'YAML' ],
                docs     => 'http://en.wikipedia.org/wiki/YAML',
            }
        }
    }
    # TODO: check via pre-instanciation
);

has store => (
    is     => 'ro',
    coerce => sub {
        if (is_array_ref($_[0])) {
            Catmandu->store(@$_[0])
        } elsif(!ref $_[0]) {
            Catmandu->store($_[0])
        } else {
            $_[0];
        }
    }
);

has query => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        if (my $store = $_[0]->store) {
            sub { $store->bag->get($_[0]) }
        } else {
            sub { }
        }
    }
);

has unapi => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        unAPI( map {
            my $format = $_[0]->formats->{$_};
            $_ => [
                $_[0]->format_as_app($format),
                $format->{type},
                docs => $format->{docs},
            ]
        } keys %{$_[0]->formats})
    }
);

sub format_as_app {
    my ($self, $format) = @_;

    sub { 
        my ($env) = @_;
        my $req   = Plack::Request->new($env);
        my $id    = $req->param('id');
    
        my $record = $self->query->($id);
        if (ref $record) {
            my $out;
            my $exporter = is_array_ref($format->{exporter}) 
                         ? $format->{exporter} : [$format->{exporter}];
            $exporter = Catmandu->exporter( @$exporter, file => \$out );
            $exporter->add($record);
            $exporter->commit;
            [ 200, [ 'Content-Type' => $format->{type} ] , [ $out ] ]; 
        } elsif(defined $record) {
            [ 400, [ 'Content-Type' => 'text/plain' ], [ $record ] ];
        } else {
            [ 404, [ 'Content-Type' => 'text/plain' ], [ 'Not Found' ] ];
        }
    }
}

sub call {
    my ($self, $env) = @_;
    $self->unapi->($env);
}

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Plack::unAPI - unAPI webservice based on Catmandu

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/gbv/Catmandu-Plack-unAPI.png)](https://travis-ci.org/gbv/Catmandu-Plack-unAPI)
[![Coverage Status](https://coveralls.io/repos/gbv/Catmandu-Plack-unAPI/badge.png?branch=devel)](https://coveralls.io/r/gbv/Catmandu-Plack-unAPI?branch=devel)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-Plack-unAPI.png)](http://cpants.cpanauthors.org/dist/Catmandu-Plack-unAPI)

=end markdown


=head1 DESCRIPTION

Catmandu::Plack::unAPI implements an unAPI web service as PSGI application.

=head1 SYNOPSIS

Set up an C<app.psgi> for instance to get data via L<http://arxiv.org>
identifier using L<Catmandu::Importer::ArXiv>:

    use Catmandu::Plack::unAPI;
    use Catmandu::Importer::ArXiv;

    Catmandu::Plack::unAPI->new(
        query => sub {
            my ($id) = @_;
            return if $id !~ qr{^(arXiv:)?[0-9abc/.]+}i;
            Catmandu::Importer::ArXiv->new( id => $id )->first;
        }
    )->to_app;

Retrieving items from a L<Catmandu::Store> is even simpler:

    Catmandu::Plack::unAPI->new( store => $store )->to_app;

Start the application, e.g. with C<plackup app.psgi> and query via unAPI:

    curl 'localhost:5000'
    curl 'localhost:5000?id=1204.0492&format=json'

=head1 CONFIGURATION

=over

=item query

Code reference with a query method to get an item (as reference) by a given
identifier (HTTP request parameter C<id>). If the method returns undef, the
application returns HTTP 404. If the methods returns a scalar, it is used as
error message for HTTP response 400 (Bad Request).

=item store

Instance of L<Catmandu::Store> or store name and options as array reference to
query items from.

=item formats

Hash reference with format names mapped to MIME type, L<Catmandu::Exporter>
configuration and (optional) documentation for each format. By default only
JSON and YAML are configured as following:

    json => {
        type     => 'application/json',
        exporter => [ 'JSON', pretty => 1 ],
        docs     => 'http://json.org/'
    },
    yaml => {
        type     => 'text/yaml',
        exporter => [ 'YAML' ],
        docs     => 'http://en.wikipedia.org/wiki/YAML'
    }

=back

=head1 LIMITATIONS

An exporter is instanciated for each request, so performance may be low
depending on configuration.

The error response is always C<text/plain>, this may be configurable in a
future release.

Timeouts are not implemented yet.

=head1 AUTHOR

Jakob Voß E<lt>jakob.voss@gbv.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<http://unapi.info/>

=item L<Catmandu::Plack::REST>

=back

=cut
