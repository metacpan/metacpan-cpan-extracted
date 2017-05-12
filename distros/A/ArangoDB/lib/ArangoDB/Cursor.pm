package ArangoDB::Cursor;
use strict;
use warnings;
use utf8;
use 5.008001;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use ArangoDB::Document;
use ArangoDB::Constants qw(:api);
use Class::Accessor::Lite ( ro => [qw/id count length/], );

BEGIN {
    if ( eval { require Data::Clone; 1; } ) {
        *_clone = \&Data::Clone::clone;
    }
    else {

        # Clone nested ARRAY and HASH reference data structure.
        *_clone = sub {
            my $orig = shift;
            return unless defined $orig;
            my $reftype = ref $orig;
            if ( $reftype eq 'ARRAY' ) {
                return [ map { !ref($_) ? $_ : _clone($_) } @$orig ];
            }
            elsif ( $reftype eq 'HASH' ) {
                return { map { !ref($_) ? $_ : _clone($_) } %$orig };
            }
        };
    }
}

sub new {
    my ( $class, $conn, $cursor ) = @_;
    my $len = 0;
    if ( defined $cursor->{result} && ref( $cursor->{result} ) eq 'ARRAY' ) {
        $len = scalar @{ $cursor->{result} };
    }
    my $self = bless {
        connection => $conn,
        id         => $cursor->{id},
        length     => $len,
        count      => $cursor->{count},
        has_more   => $cursor->{hasMore},
        position   => 0,
        result     => $cursor->{result} || [],
    }, $class;
    if ( $self->{id} ) {
        $self->{_api_path} = API_CURSOR . '/' . $self->{id};
    }
    weaken( $self->{connection} );
    return $self;
}

sub next {
    my $self = shift;
    if ( $self->{position} < $self->{length} || $self->_get_next_batch() ) {
        return ArangoDB::Document->new( $self->{connection}, _clone( $self->{result}->[ $self->{position}++ ] ) );
    }
    return;
}

sub all {
    my $self = shift;
    my @result;
    while ( !@result || $self->_get_next_batch() ) {
        my $last = $self->{length} - 1;
        push @result, ( @{ $self->{result} } )[ 0 .. $last ];
    }
    my $conn = $self->{connection};
    return [ map { ArangoDB::Document->new( $conn, $_ ) } @result ];
}

sub _get_next_batch {
    my $self = shift;
    return unless $self->{has_more};
    eval {
        my $res = $self->{connection}->http_put( $self->{_api_path}, {} );
        $self->{has_more} = $res->{hasMore};
        $self->{length}   = scalar( @{ $res->{result} } );
        $self->{result}   = $res->{result};
        $self->{position} = 0;
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to get next batch cursor(%d)' );
    }
    return 1;
}

sub delete {
    my $self = shift;
    eval { $self->{connection}->http_delete( $self->{_api_path} ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to delete cursor(%d)' );
    }
}

sub _server_error_handler {
    my ( $self, $error, $message ) = @_;
    my $msg = sprintf( $message, $self->id );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__


=pod

=head1 NAME

ArangoDB::Cursor - An ArangoDB Query Cursor hanlder

=head1 SYNOPSIS

    my $cursor = $db->query('FOR u IN users RETURN u')->execute();
    my @docs;
    while( my $doc = $cursor->next ){
        push @docs, $doc;
    }

=head1 DESCRIPTION

Instance of ArandoDB Query Cursor.

=head1 METHODS

=head2 new()

Constructor.

=head2 next()

Returns next document(Instance of L<ArangoDB::Document>).

=head2 all()

Rreturns all documents in the cursor.(ARRAY reference).

The cursor on the server will be deleted implicitly.

=head2 delete()

Delete a cursor.

The cursor will automatically be destroyed on the server when the client has retrieved all documents from it. 
The client can also explicitly destroy the cursor at any earlier time using this method.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
