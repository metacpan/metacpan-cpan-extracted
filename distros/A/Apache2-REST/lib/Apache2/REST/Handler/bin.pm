package Apache2::REST::Handler::bin ;
use strict ;

use base qw/Apache2::REST::Handler/ ;

=head1 NAME

Apache2::REST::Handler::bin - Proof of concept for binary output.

=cut


=head2 GET

Ouputs the logo png image

=cut

sub GET{
    my ( $self , $req , $resp ) = @_ ;
    
    $req->requestedFormat('bin') ;
    $resp->binMimeType('image/png') ;
    
    my $exFile = __FILE__ ;
    $exFile =~ s/bin\.pm$/bin_logo.png/ ;
    open ( INFILE , '<'.$exFile ) or die "Cannot open $exFile\n" ;
    my $bin = '' ;
    {
        local $/ = undef ;
        $bin = <INFILE>;
    }
    close INFILE ;
    
    $resp->bin($bin) ;
    
    return Apache2::Const::HTTP_OK ;    
}

=head2 isAuth

Allows GET

=cut

sub isAuth{
    my ( $self , $met , $req ) = @_ ;
    return $met eq 'GET' ;
}



1;
