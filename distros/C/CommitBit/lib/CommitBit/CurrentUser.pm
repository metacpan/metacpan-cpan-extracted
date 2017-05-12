package CommitBit::CurrentUser;

use warnings;
use strict;

use base 'Jifty::CurrentUser';

sub password_is {
    my $self = shift;
    my $pass = shift;
    return 1 if ( $self->user_object->__value('password') eq $pass );
    return undef;

}

sub _init {
    my $self = shift;
    my %args = (@_);

    if ( delete $args{'_bootstrap'} ) {
        $self->is_bootstrap_user(1);
    } elsif ( keys %args ) {
        $self->user_object(
            CommitBit::Model::User->new( current_user => $self ) );
        $self->user_object->load_by_cols(%args);
    }
    $self->SUPER::_init(%args);
}

1;
