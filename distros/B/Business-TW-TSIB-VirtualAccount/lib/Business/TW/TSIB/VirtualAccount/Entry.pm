package Business::TW::TSIB::VirtualAccount::Entry;
use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(
    response_code
    account
    date 
    seqno 
    flag 
    time 
    txn_type 
    amount 
    postive 
    entry_type 
    virtual_account 
    id 
    from_bank 
    comment 
    preserved 
    status
    )
);

sub new {
    my $class = shift;
    my $self = shift;
    return bless $self , $class;
}

sub ar_id {
    my $self = shift;
    return substr( $self->{virtual_account} , 9 , 4 );
}

1;

