package petmarket::api::cartservice;


# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

#This is server side for the Macromedia's Petmarket example.
#See http://www.simonf.com/amfperl for more information.

use warnings;
no warnings "uninitialized";
use strict;

use petmarket::api::dbConn;
use vars qw/@ISA/;
@ISA=("petmarket::api::dbConn");

use AMF::Perl::Util::Object;

sub methodTable
{
    return {
        "getStatesAndCountries" => {
            "description" => "Returns list of states and countries.",
            "access" => "remote", 
        },
        "getCreditCards" => {
            "description" => "Returns list of allowed credit cards.",
            "access" => "remote", 
        },
        "getShippingMethods" => {
            "description" => "Returns list of shipping methods.",
            "access" => "remote", 
			"returns" => "AMFObject"
        },
        "validateCartOID" => {
            "description" => "Validate that the supplied rat OID is good.",
            "access" => "remote", 
        },
        "getCartItems" => {
            "description" => "List the items in the cart with the given ID",
            "access" => "remote", 
			"returns" => "AMFObject"
        },
        "getCartTotal" => {
            "description" => "Return the total number of items and total cost of the cart with the given ID",
            "access" => "remote", 
        },
        "newCart" => {
            "description" => "Returns id of a new Cart object.",
            "access" => "remote", 
        },
        "addCartItem" => {
            "description" => "Adds the given item to the given cart and returns the new totals",
            "access" => "remote", 
        },
        "updateCartItem" => {
            "description" => "Updates the given item in the given cart and returns the new totals",
            "access" => "remote", 
        },
        "deleteCartItem" => {
            "description" => "Deletes the given item from the given cart and returns the new totals",
            "access" => "remote", 
        },
    };
    
}

sub getStatesAndCountries
{
    my ($self) = @_;
    my %locations;
            
    my @states = (
            "AL", "AK", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "GU", "HI", "IA",
            "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MS", "MT",
            "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "PR", "RI",
            "SC", "SD", "TN", "TX", "UT", "VA", "VI", "VT", "WA", "WI", "WV", "WY"
    );
    my @countries = ("USA");
            
    $locations{"STATES_array"} = \@states;
    $locations{"COUNTRIES_array"} = \@countries;
            
    return \%locations;
}

sub getCreditCards 
{
    my ($self) = @_;
    my @cards = ("American Express", "Discover/Novus", "MasterCard", "Visa");
    return \@cards;
}
	
sub getShippingMethods 
{
    my @columns = ("shippingoid", "shippingname", "shippingdescription", "shippingprice", "shippingdays");
    my @names = ("Ground", "2nd Day Air", "Next Day Air", "3 Day Select");
    my @descriptions = (
        "Prompt, dependable, low-cost ground delivery makes Ground an excellent choice for all your routine shipments. Ground reaches every address throughout the 48 contiguous states.",
        "2nd Day Air provides guaranteed on-time delivery to every address throughout the United States (excluding intra-Alaska shipments) and Puerto Rico by the end of the second business day. This service is an economical alternative for time-sensitive shipments that do not require overnight or morning service.",
        "Next Day Air features fast, reliable delivery to every address in all 50 states and Puerto Rico. We guarantee delivery by 10:30 a.m., noon, or end of day the next business day depending on destination (noon or 1:30 p.m. on Saturdays).",
        "The ideal mix of economy and guaranteed on-time delivery, 3 Day Select guarantees delivery within three business days to and from every address in the 48 contiguous states."
    );
    my @prices = (13.00, 26.00, 39.00, 18.00);
    my @days = (6, 2, 1, 3);

    my @methods;

    for (my $i = 0; $i < scalar @names; $i++) 
    {
        my @row;
        push @row, $i;
        push @row, $names[$i];
        push @row, $descriptions[$i];
        push @row, $prices[$i];
        push @row, $days[$i];

        push @methods, \@row;
    }

        return AMF::Perl::Util::Object->pseudo_query(\@columns, \@methods);
}

sub validateCartOID
{
    my ($self, $id) = @_;
    return $id;
}

sub newCart
{
    my ($self) = @_;
    my ($id, $count);
    do
    {
        $id = "cart" . time() . "." . (int(rand 1000000) + 1);
        my $ary_ref = $self->dbh->selectall_arrayref("SELECT count(*) FROM cart_details WHERE cartid = '$id'");
        $count = $ary_ref->[0]->[0];
    }
    while ($count > 0);

    $self->dbh->do("INSERT INTO cart_details SET cartid='$id'");

    return $id;
}

#TODO - where does the item quantity come from?
sub getCartItems
{
    my ($self, $cartid) = @_;
    my @result;
    my $ary_ref = $self->dbh->selectall_arrayref("SELECT d.quantity, a.productid, a.itemid, unitcost, b.descn, attr1, c.name,e.catid FROM item a, item_details b, product_details c, cart_details d, product e WHERE a.itemid=b.itemid AND a.productid= c.productid AND a.productid=e.productid AND a.itemid=d.itemid AND d.cartid='$cartid'");
    foreach my $rowRef (@$ary_ref)
    {
        my ($cartQuantity, $productid, $itemid, $unitcost, $descn, $attr, $productname, $catid) = @$rowRef;
        my @row;
        push @row, $itemid;
        push @row, 999;
        push @row, $itemid;
        push @row, $attr;
        push @row, $cartQuantity;
        push @row, $productid;
        push @row, $unitcost;
        push @row, "";
        push @row, $productname;
        push @row, $catid;
        push @row, "888888";
        push @result, \@row;
    }

    my @columnNames = ("ITEMOID", "ITEMQUANTITY", "ITEMID", "ITEMNAME", "QUANTITY", "PRODUCTOID", "LISTPRICE", "DESCRIPTION", "NAME", "CATEGORYOID", "COLOR");

    return AMF::Perl::Util::Object->pseudo_query(\@columnNames, \@result);
}

sub getCartTotal
{
    my ($self, $cartid) = @_;
    my ($count, $total);

    my $ary_ref = $self->dbh->selectall_arrayref("SELECT unitcost, quantity FROM cart_details a, item_details b WHERE a.itemid=b.itemid AND a.cartid='$cartid'");
    foreach my $rowRef (@$ary_ref)
    {
        my ($unitcost, $quantity) = @$rowRef;
        $total += $quantity * $unitcost;
        $count += $quantity;
    }

    my $result = new AMF::Perl::Util::Object;
    $result->{total} = $total;
    $result->{count} = $count;
    return $result;
}

sub addCartItem
{
    my ($self, $cartid, $itemid, $quantity) = @_;
    $self->dbh->do("INSERT INTO cart_details SET cartid='$cartid', itemid='$itemid', quantity=$quantity");
    my $result = $self->getCartTotal($cartid);
    $result->{"itemoid"} = $itemid;
    return $result;
}

sub updateCartItem
{
    my ($self, $cartid, $itemid, $quantity) = @_;
    $self->deleteCartItem($cartid, $itemid);
    return $self->addCartItem($cartid, $itemid, $quantity);
}

sub deleteCartItem
{
    my ($self, $cartid, $itemid) = @_;
    $self->dbh->do("DELETE FROM cart_details WHERE cartid='$cartid' AND itemid='$itemid'");
    my $result = $self->getCartTotal($cartid);
    $result->{"itemoid"} = $itemid;
    return $result;
}

1;
