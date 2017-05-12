package Data::OpenGraph;
use strict;
use Carp ();
use Data::OpenGraph::Parser;
use constant +{
    HAVE_LWP => eval { require LWP::UserAgent } && !$@ ? 1 : 0,
};

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    bless { %args }, $class;
}

sub property {
    my ($self, $name) = @_;
    return $self->{properties}->{$name};
}

sub parse_uri {
    my ($class, $uri) = @_;
    if (HAVE_LWP) {
        my $ua = LWP::UserAgent->new();
        my $res = $ua->get( $uri );
        if (! $res->is_success) {
            Carp::croak( "Failed to get $uri: " . $res->status_line);
        }
        return $class->parse_string( $res->decoded_content );
    } else {
        Carp::croak( "No applicable UserAgent (such as LWP::UserAgent) found" );
    }
}

sub parse_string {
    my ($class, $string) = @_;
    my $properties = Data::OpenGraph::Parser->new()->parse_string( $string );
    Data::OpenGraph->new( properties => \%$properties );
}

1;

__END__

=head1 NAME

Data::OpenGraph - Parse OpenGraph Contents

=head1 SYNOPSIS

    use Data::OpenGraph;

    my $og = Data::OpenGraph->parse_uri( "http://some.content/with/opengraph.html" );

    my $ua = LWP::UserAgent->new();
    my $res = $ua->get( "http://some.content/with/opengraph.html" );
    my $og = Data::OpenGraph->parse_uri( $res->decoded_content );

    my $title = $og->property( "title" );
    my $type  = $og->property( "type" );

=head1 DESCRIPTION

WARNINGS: ALPHA CODE! Probably very incomplete. Please send pull-reqs if you would like this module to be better

Data::OpenGraph is a simple Opengraph ( http://ogp.me ) parser. It just parses some HTML looking for meta tags with property attribute that looks like "og:.+".

Currently nested attributes such as "audio:title", "audio:artist" are store verbatim, so you need to access them like:

    $og->property( "audio:title" );
    $og->property( "audio:artist" );

=head1 METHODS

=head2 Data::OpenGraph->new(properties => \%properties)

Creates a new OpenGraph container. You probably won't be using this much.

=head2 Data::OpenGraph->parse_string( $string )

Creates a new OpenGraph container by parsing $string.

=head2 Data::OpenGraph->parse_uri( $uri )

Fetches the uri, then creates a new OpenGraph container by parsing the content. On HTTP errors, this method will croak. 

=head1 SEE ALSO

L<RDF::RDFa::Parser>

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Daisuke Maki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
