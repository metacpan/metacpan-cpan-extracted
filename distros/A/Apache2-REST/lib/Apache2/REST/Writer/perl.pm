package Apache2::REST::Writer::perl ;
use strict ;
use Data::Dumper ;

=head1 NAME

Apache2::REST::Writer::perl - Apache2::REST::Response Writer for perl

=cut

=head2 new

=cut

sub new{
    my ( $class ) = @_;
    return bless {} , $class;
}

=head2 mimeType

Getter

=cut

sub mimeType{
    # Ideal
    #return 'application/json' ;
    # Reality
    return 'application/x-perl';
}

=head2 asBytes

Returns the response as yaml UTF8 bytes for output.

=cut

sub asBytes{
    my ($self,  $resp ) = @_ ;
    return Dumper($resp) ;
}

1;
