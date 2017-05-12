package Apache2::REST::Handler::test ;

use  Apache2::REST::Handler::test::user ;

use strict ;
use base qw/Apache2::REST::Handler/  ;

use Apache2::Const qw( 
                       :common :http 
                       );

=head2 NAME

Apache2::REST::Handler::test - test handler access '/test/' to test your installation

=cut

=head2 GET

=cut

sub GET{
    my ($self, $req , $resp ) = @_ ;
    
    if ( $req->param('die') ){
        die "This is an error\n" ;
    }
    
    $resp->data()->{'test_mess'} = 'This is a GET test message' ;
    ## It is OK
    return Apache2::Const::HTTP_OK ;
}

=head2 POST

Performs a fake POST

=cut

sub POST{
    my ($self, $req , $resp ) = @_ ;
    $resp->data()->{'test_mess'} = 'This is a POST test message' ;
    ## It is OK
    return Apache2::Const::HTTP_OK ;
}

=head2 PUT

Performs a fake PUT

=cut

sub PUT{
    my ($self, $req , $resp ) = @_ ;
    $resp->data()->{'test_mess'} = 'This is a PUT test message' ;
    ## It is OK
    return Apache2::Const::HTTP_OK ;
}

=head2 DELETE

Performs a fake DELETE

=cut

sub DELETE{
    my ($self, $req , $resp ) = @_ ;
    $resp->data()->{'test_mess'} = 'This is a DELETE test message' ;
    ## It is OK
    return Apache2::Const::HTTP_OK ;
}


=head2 buildNext

Builds a new test::user using the fragment after C<test/>.
For instance, if request resource is C<test/1/> , it will build
a Apache2::REST::Handler::test::user containing the user id C<1>

=cut

sub buildNext{
    my ( $self , $frag , $req ) = @_ ;
    
    my $subh = Apache2::REST::Handler::test::user->new($self) ;
    $subh->{'userid'} = $frag  ;
    return $subh ;
}

=head2 isAuth

Any method is allowed

=cut

sub isAuth{
    my ($self , $method , $req ) = @_ ;
    return 1 ;
}



1;
