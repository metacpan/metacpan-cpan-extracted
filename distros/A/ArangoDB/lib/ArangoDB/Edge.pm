package ArangoDB::Edge;
use strict;
use warnings;
use utf8;
use 5.008001;
use Carp qw(croak);
use parent 'ArangoDB::AbstractDocument';
use ArangoDB::Constants qw(:api);

sub from {
    return $_[0]->{_from};
}

sub to {
    return $_[0]->{_to};
}

sub _api_path {
    my $self = shift;
    return API_EDGE . '/' . $self;
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $action ) = @_;
    my $msg = sprintf( 'Failed to %s the edge(%s)', $action, $self );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 NAME

ArangoDB::Edge - An ArangoDB edge

=head1 DESCRIPTION

Instance of ArangoDB edge.

=head1 METHODS

=head2 new($raw_edge)

Constructor.

=head2 id()

Returns identifer of the edge.

=head2 revision()

Returns revision of the edge.

=head2 collection_id()

Returns collection identifier of the edge.

=head2 content()

Returns content of the edge.

=head2 get($attr_name)

Get the value of an attribute of the edge.

=head2 set($attr_name,$value)

Update the value of an attribute (Does not write to database)

=head2 fetch()

Fetch the edge data from database.

=head2 save()

Save the changes of edge to database.

=head2 delete()

Delete the edge from database.

$with_rev_check is boolean flag. If it's true, the ArangoDB checks that the revision of the edge. If there is a conflict, this method raise a error.

=head2 from()

Returns document id that start of the edge.

=head2 to()

Returns document id that end of the edge.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
