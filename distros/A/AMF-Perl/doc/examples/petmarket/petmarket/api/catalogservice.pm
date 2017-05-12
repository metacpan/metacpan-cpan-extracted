package petmarket::api::catalogservice;


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

use Flash::FLAP::Util::Object;

sub methodTable
{
    return {
        "getCategories" => {
            "description" => "Returns list of categories",
            "access" => "remote", 
	    "returns" => "AMFObject"
        },
        "getProducts" => {
            "description" => "Returns list of products",
            "access" => "remote", 
	    "returns" => "AMFObject"
        },
        "getItems" => {
            "description" => "Returns list of items",
            "access" => "remote", 
	    "returns" => "AMFObject"
        },
        "searchProducts" => {
            "description" => "Returns products whose name (or whose category's name) matches a string",
            "access" => "remote", 
	    "returns" => "AMFObject"
        },
    };
    
}

sub getCategories
{
    my ($self) = @_;
    my @result;
    my $ary_ref = $self->dbh->selectall_arrayref("SELECT catid, name FROM category_details");
    foreach my $rowRef (@$ary_ref)
    {
        my ($catid, $name) = @$rowRef;
        my @row;
        push @row, $catid;
        push @row, $name;
        push @row, lc $name;
        push @row, "888888";
        push @result, \@row;
    }

    my @columnNames = ("CATEGORYOID", "CATEGORYDISPLAYNAME", "CATEGORYNAME", "COLOR");

    return Flash::FLAP::Util::Object->pseudo_query(\@columnNames, \@result);
}


sub getProducts
{
    my ($self, $catid) = @_;
    my @result;
    my $ary_ref = $self->dbh->selectall_arrayref("SELECT catid, a.productid, name, image, descn FROM product a, product_details b WHERE a.productid=b.productid AND catid='$catid'");
    foreach my $rowRef (@$ary_ref)
    {
        my ($catid, $productid, $name, $image, $descn) = @$rowRef;
        my @row;
        push @row, $catid;
        push @row, $productid;
        push @row, $productid;
        push @row, $name;
        push @row, $image;
        push @row, $descn;
        push @result, \@row;
    }

    my @columnNames = ("CATEGORYOID", "PRODUCTOID", "PRODUCTID", "NAME", "IMAGE", "DESCRIPTION");

    return Flash::FLAP::Util::Object->pseudo_query(\@columnNames, \@result);
}


sub getItems
{
    my ($self, $productid) = @_;
    my @result;
    my $ary_ref = $self->dbh->selectall_arrayref("SELECT a.productid, a.itemid, unitcost, b.descn, attr1, c.name FROM item a, item_details b, product_details c WHERE a.itemid=b.itemid AND a.productid=c.productid AND c.productid='$productid'");
    foreach my $rowRef (@$ary_ref)
    {
        my ($productid, $itemid, $unitcost, $descn, $attr, $productname) = @$rowRef;
        my @row;
        push @row, $itemid;
        push @row, $itemid;
        push @row, $attr;
        push @row, 999;
        push @row, $productid;
        push @row, $unitcost;
        push @row, $descn;
        push @row, $productname;
        push @row, $productid;
        push @result, \@row;
    }

    my @columnNames = ("ITEMOID", "ITEMID", "ITEMNAME", "QUANTITY", "PRODUCTIOID", "LISTPRICE", "DESCRIPTION", "NAME", "CATEGORYOID");

    return Flash::FLAP::Util::Object->pseudo_query(\@columnNames, \@result);
}

sub searchProducts
{
    my ($self, $query) = @_;
    my @result;

    my @catids;
    my $ary_ref = $self->dbh->selectall_arrayref("SELECT a.catid  FROM category a, category_details b WHERE a.catid=b.catid AND b.name like '%$query%'");
    foreach my $rowRef (@$ary_ref)
    {
        my ($catid) = @$rowRef;
        push @catids, $catid;
    }

    @catids = map {"'$_'"} @catids;
    my $catIdList = join ",", @catids;

    my $productQuery = "SELECT DISTINCT a.productid, b.name, a.catid, c.name FROM product a, product_details b, category_details c WHERE a.productid=b.productid AND a.catid=c.catid AND (b.name like '%$query%'";
    $productQuery .= " OR a.catid IN ($catIdList)" if $catIdList;
	$productQuery .= ")";

    $ary_ref = $self->dbh->selectall_arrayref($productQuery);
    foreach my $rowRef (@$ary_ref)
    {
        my ($productid, $productName, $catid, $catName) = @$rowRef;
        my @row;
        push @row, $productid;
        push @row, $productName;
        push @row, $catid;
        push @row, "8888";
        push @row, lc $catName;
        push @row, $catName;
        push @result, \@row;
    }

    my @columnNames = ("PRODUCTOID", "NAME", "CATEGORYOID", "COLOR", "CATEGORYNAME", "CATEGORYDISPLAYNAME");

    return Flash::FLAP::Util::Object->pseudo_query(\@columnNames, \@result);
}


1;
