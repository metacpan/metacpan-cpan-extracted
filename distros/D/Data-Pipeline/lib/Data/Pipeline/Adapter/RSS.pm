package Data::Pipeline::Adapter::RSS;

use Moose;
extends 'Data::Pipeline::Adapter';

use Data::Pipeline::Iterator::Source;

use MooseX::Types::Moose qw( CodeRef );
use Data::Pipeline::Types qw( Iterator );

#use XML::RSS::Parser;
use XML::RAI;

has url => (
    is => 'ro',
    isa => 'Str|CodeRef',
    default => sub { Carp::croak "url undefined for RSS adapter" },
    lazy => 1
);

has '+source' => (
    default => sub {
        my($self) = @_;

        my $url = $self -> url;
        $url = $url -> ( ) if is_CodeRef( $url );
        $url = to_Iterator( $url );
        #my $parser = XML::RSS::Parser -> new;
        #my $rss = XML::RAI -> parse_uri( $self -> url); #$parser -> parse_uri( $self -> url );

        my $items = [ ]; # = $rss -> items;

        return Data::Pipeline::Iterator::Source -> new(
            get_next => sub { 
                while( !@{$items} && !$url -> finished ) {
                    my $rss = XML::RAI -> parse_uri( $url -> next);
                    $items = $rss -> items;
                }
                _make_hash(shift @{$items}) },
            has_next => sub { @{$items} > 0 || !$url -> finished }
        );
    }
);

sub _make_hash {
    my($item) = @_;

    +{ map { ref($_) && @$_==1 ? $_->[0] : $_ } map { ($_ => [$item -> $_]) } grep { defined( $item -> $_ ) } qw(
        abstract
        content
        content_strict
        contentstrict
        contributor
        coverage
        created
        created_strict
        creator
        description
        format
        identifier
        issued
        issued_strict
        language
        link
        modified
        modified_strict
        ping
        pinged
        publisher
        relation
        rights
        source
        subject
        title
        type
        valid
    ) };
}

1;

__END__
