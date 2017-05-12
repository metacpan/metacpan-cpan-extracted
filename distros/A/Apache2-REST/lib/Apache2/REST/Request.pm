package Apache2::REST::Request ;
use Apache2::Request ;

use base qw(Apache2::Request);

use Encode ;

=head1 NAME

Apache2::REST::Request - Apache2::Request subclass.

=head1 DESCRIPTION

This module adds extra features to the standard C<Apache2::Request>.

As a consequence, you can use any method available on C<Apache2::Request>, plus
the additional methods below.


=head2 new

See L<Apache2::Request>

=cut

sub new {
    my($class, @args) = @_;
    my $self = {
        r => Apache2::Request->new(@args) ,
        'paramEncoding' => 'UTF-8' ,
        'requestedFormat' => '' ,
    };
    return bless $self,  $class;
}

=head2 param

See L<Apache2::Request::param> .

This decodes the param according to $this->paramEncoding

=cut

sub param{
    my ( $self , @args ) = @_ ;
    if ( wantarray ){
        my @ret = $self->{r}->param(@args) ;
        return map{ Encode::decode($self->paramEncoding() , $_ ) } @ret  ;
    }
    my $ret = $self->{r}->param(@args) ;
    return Encode::decode($self->paramEncoding() , $ret );
}

=head2 paramEncoding

Gets/Set the paramEncoding of this Request

=cut

sub paramEncoding{
    my ( $self , $v ) = @_ ;
    if ( $v ){ $self->{'paramEncoding'} = $v ;}
    return $self->{'paramEncoding'} ;
}

=head2 requestedFormat

Get/Set the requested format.

You can use this to force the returned format from a particular resource.
Or to allow methods based on the format.

=cut

sub requestedFormat{
    my ( $self , $v ) = @_ ;
    if ( $v ){ $self->{'requestedFormat'} = $v ;}
    return $self->{'requestedFormat'};
}


1;
