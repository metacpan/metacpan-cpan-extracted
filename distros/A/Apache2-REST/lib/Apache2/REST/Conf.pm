package Apache2::REST::Conf ;
use strict ;
use base qw/Class::AutoAccess/ ;

=head1 NAME

Apache2::REST::Conf - A configuration container.

=cut


=head2 new

Returns a new default configuration.

=cut

sub new{
    my ( $class ) = @_ ;
    
    my $self = {
        'Apache2RESTErrorOutput' => 'both',
    } ;
    return bless $self , $class ;
}



1;
