package ArangoDB::Document;
use strict;
use warnings;
use utf8;
use 5.008001;
use Carp qw(croak);
use parent 'ArangoDB::AbstractDocument';
use ArangoDB::Constants qw(:api);
use ArangoDB::Edge;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{_api_path} = API_DOCUMENT . '/' . $self;
    return $self;
}

sub any_edges {
    my ( $self, $vertex ) = @_;
    return $self->_get_edges('any');
}

sub in_edges {
    my ( $self, $vertex ) = @_;
    return $self->_get_edges('in');
}

sub out_edges {
    my ( $self, $vertex ) = @_;
    return $self->_get_edges('out');
}

sub _api_path {
    $_[0]->{_api_path};
}

sub _get_edges {
    my ( $self, $direction ) = @_;
    my $vertex = $self->{_document_handle};
    my $api    = API_EDGES . '/' . $self->{_collection_id} . '?vertex=' . $vertex . '&direction=' . $direction;
    my $res    = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "get edges($vertex) that related to" );
    }
    my $conn = $self->{connection};
    my @edges = map { ArangoDB::Edge->new( $conn, $_ ) } @{ $res->{edges} };
    return \@edges;
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the document(%s)', $action, $self->{_document_handle} );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Document - An ArangoDB document

=head1 DESCRIPTION

Instance of ArangoDB document.

=head1 METHODS

=head2 new($raw_doc)

Constructor.

=head2 id()

Returns identifer of the document.

=head2 revision()

Returns revision of the document.

=head2 collection_id()

Returns collection identifier of the document.

=head2 document_handle()

Returns document-handle.

=head2 content()

Returns content of the document.

=head2 get($attr_name)

Get the value of an attribute of the document

=head2 set($attr_name,$value)

Update the value of an attribute (Does not write to database)

=head2 fetch()

Fetch the document data from database.

=head2 save($with_rev_check)

Save the changes of document to database.

$with_rev_check is boolean flag. If it's true, the ArangoDB checks that the revision of the document. If there is a conflict, this method raise a error.

=head2 delete()

Delete the document from database.

=head2 any_edges()

Returns the list of edges starting or ending in the document.

=head2 in_edges()

Returns the list of edges ending in the document.

=head2 out_edges()

Returns the list of edges starting in the document.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
