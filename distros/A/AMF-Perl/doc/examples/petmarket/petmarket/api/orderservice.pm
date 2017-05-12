package petmarket::api::orderservice;


# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

#This is server side for the Macromedia's Petmarket example.
#See http://www.simonf.com/amfperl for more information.

use warnings;
use strict;

use petmarket::api::dbConn;
use vars qw/@ISA/;
@ISA=("petmarket::api::dbConn");

sub methodTable
{
    return {
        "placeOrder" => {
            "description" => "Empties the cart", 
            "access" => "remote", 
        },
    };
    
}

sub placeOrder
{
    my ($self, $userid, $cartid) = @_;

    $self->dbh->do("DELETE FROM cart_details WHERE cartid='$cartid'");
}

1;
