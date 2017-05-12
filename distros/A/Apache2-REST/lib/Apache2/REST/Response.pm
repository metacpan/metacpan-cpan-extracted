package Apache2::REST::Response ;

use strict ;
use warnings ;

use base qw/Class::AutoAccess/ ;

use Apache2::Const qw( 
                       :common :http 
                       );


=head1 NAME

Apache2::REST::Response - Container for an API Response.

=head2 SYNOPSIS

 ... 
 $resp->status(Apache2::Const::HTTP_OK) ;
 $resp->message('Everything went smootly') ;
 $resp->data()->{'item'} = 'This is the returned item' ;
 ...

=cut

=head2 new

Builds a new one.

=cut

sub new{
    my ( $class ) = @_ ;
    
    my $self = {
        'status' => Apache2::Const::HTTP_OK ,
        'message' => '' ,
        'data' => {},
        'binMimeType' => undef ,
        'bin' => undef ,
	'stream' => undef,
	'multipart_stream' => undef,
    };
    return bless $self , $class ;
}

=head2 cleanup

Cleanup this response so it can go out without any
empty attributes.

Internal use.


=cut

sub cleanup{
    my ( $self ) = @_ ;
    foreach my $key ( keys %$self ){
        unless( defined $self->{$key} ){
            delete $self->{$key} ;
        }
    }
    
}

=head2 status

Get/Sets the HTTP status of this response

=cut

=head2 message

Get/Sets a more explicit message related to the status

=cut

=head2 data

Hash of the actual data returned by the handler (see L<Apache2::REST::Handler> ).

=cut

=head2 bin

Get/Set the binary content to return in case the bin writer is used.

=cut

=head2 binMimeType

Get/Set the MIME type of the binary content.

=cut

=head2 stream

Get/Set the L<Apache2::REST::Stream> to render this response as a stream
of data.

Setting this will trigger a '_Stream' version of writers to be used.

=head2 multipart_stream

Get/Set the L<Apache2::REST::Stream> to render this response as a stream
of data composed of multipart response parts.

Setting this will trigger a '_multipart' version of writers to be used.

=cut

1;
