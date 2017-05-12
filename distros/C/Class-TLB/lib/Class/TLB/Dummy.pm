package Class::TLB::Dummy ;

use strict ;
use warnings ;

=head1 NAME

Class::TLB::Dummy - A dummy resource for test purpose.

=cut

=head2 new

Returns a new instance of this.

=cut

sub new{
    my ( $class , $id ) = @_ ;
    my $self = {'id' => $id } ;
    return bless $self , $class ;
}

=head2 doSomething

Do something and return a string for display.

=cut

sub doSomething{
    my ( $self ) = @_ ;
    return "I (".$self->{'id'}.") did something";
}


=head2 oneFail

Fails only if id is 1

=cut

sub oneFail{
    my ( $self ) = @_ ;
    if ( $self->{'id'} == 1 ){
        die "I am 1 and I fail" ;
    }
    #select(undef,undef,undef, 0.01);
    return "I am ".$self->{'id'} ;
}

=head2 doFail

This fails each time

=cut

sub doFail{
    my ( $self ) = @_ ;
    die "Arghhh" ;
}


1;
