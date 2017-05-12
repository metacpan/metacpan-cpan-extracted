package Apache2::REST::AppAuth ;
use warnings ;
use strict ;

use Apache2::Const qw( 
                       :common :http 
                       );

=head1 NAME

Apache2::REST::AppAuth - Base class for application authentication

=cut


=head2 new

Returns a new instance of this class.

If you override this, remember it is called without
arguments by the framework.


=cut

sub new{
    my ( $class ) = @_ ;
    return bless {} , $class ;
}

=head2 init

Override this if you want to initialise this plugin
with properties accessible through the Apache2::Request 

Called by the framework like this:

    $this->init($req) ;

=cut

sub init{
    my ( $self , $req ) = @_ ;
    # Nothing by default
}



=head2 authorize

Implement this to let the Application authentifier
decide if the application can access the API or not.

Please set resp->status() and resp->message() ;

Returns true if authorized. False otherwise.

Called like this by the framework:

$this->authorize($req , $resp ) ;

=cut

sub authorize{
    my ( $self , $req , $resp ) = @_ ;
    return 1 ;
}


1;
