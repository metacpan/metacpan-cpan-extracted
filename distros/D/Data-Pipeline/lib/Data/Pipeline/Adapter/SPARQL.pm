package Data::Pipeline::Adapter::SPARQL;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Iterator::Source;

use Carp ();

use RDF::Query;
use URI;

has 'url' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_url',
);

has 'model' => (
    is => 'ro',
    isa => 'Object',
    lazy => 1,
    default => sub {
        require RDF::Core::Model;
        require RDF::Core::Storage::Memory;
        RDF::Core::Model -> new( Storage => RDF::Core::Storage::Memory -> new )
    }
);

has 'query' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

# we want to do some of the processing on the remote site if we can

has '+source' => (
    default => sub {
        my($self) = @_;

        my $q = RDF::Query -> new( $self -> query );

        unless( defined $q ) {
            Carp::croak "Unable to parse query: " . RDF::Query -> error;
        }

        my $i;

        my @options;

        if( $self -> has_url ) {
            $i = $q -> execute_with_named_graphs(
                $self -> model,
                RDF::Trine::Node::Resource -> new($self -> url)
            );
        }
        else {
            $i = $q -> execute( $self -> model );
        }

        my $next = _convert_objects($i -> next);

        return Data::Pipeline::Iterator::Source -> new(
            has_next => sub { defined $next },
            get_next => sub { my $n = $next; $next = _convert_objects($i -> next); return $n; }
        );
    }
);

sub _convert_objects {
    my($h) = @_;

    return undef unless $h;

    for my $k ( keys %{$h} ) {
        if( UNIVERSAL::isa($h->{$k}, 'RDF::Trine::Node::Resource' ) ) {
             $h -> {$k} = $h -> {$k} -> uri_value;
        }
        elsif( UNIVERSAL::isa($h->{$k}, 'RDF::Trine::Node::Literal' ) ) {
             $h -> {$k} = $h -> {$k} -> literal_value;
        }
    }

    $h;
}


1;

__END__
