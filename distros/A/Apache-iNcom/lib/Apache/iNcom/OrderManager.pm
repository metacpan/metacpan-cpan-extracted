#
#    OrderManager.pm - Object that manages order checkout.
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Apache::iNcom::OrderManager;

use strict;

use DBIx::SearchProfiles;

use Apache::Constants qw( OK );
use HTML::Embperl;

use vars qw( $VERSION );

BEGIN {
    ($VERSION) = '$Revision: 1.5 $' =~ /Revision: ([\d.]+)/;
}

=pod

=head1 NAME

Apache::iNcom::OrderManager - Module responsible for order management.

=head1 SYNOPSIS

    my $order = $Order->checkout( "order", $Cart, %fdat );
    my $report $Order->order_report( $order );

=head1 DESCRIPTION

This is the part of the Apache::iNcom framework that is responsible
for managing the order process. Once the user is ready to check out,
the OrderManager rides in. This module enters the user's order in the
database according to an order profile. It can also generate order
reports and such.

It is in that module that future development will place links with
CyberCash (tm) and other online payment systems.

=head1 DATABASE

The order should be entered in two tables. One table table contains
the global order informations : order no, client's information,
status, total, taxes, etc., and another table contains the ordered
items.

To make order customizable, the OrderManager uses DBIx::SearchProfiles
to insert the information. That design is similar to DBIx::UserDB in
that only a few fields are required by the framework and the schema
can easily be adapted for application specific needs.

The mandatory fields in the main table are the C<order_no> field,
which should be a primary key on the table, and the C<status> field.
The status field is used to track the order process.

You may also want to add monetary fields for C<total>, C<subtotal> and
for the taxes, shipping and discount informations since that will
always be available in the order.

The mandatory fields in the items table is C<order_no> which links the
items to the order table. What will be inserted in that table are the
cart items, so you may want to use the following fields : C<price>,
C<subtotal>, C<quantity> and fields for the discount information.

=head1 ORDER PROFILES

The order profiles is a file which is C{eval}-ed at runtime. (It is
also reloaded whenever it changes on disk. It should return an hash
reference which contains the name of a profile associated with an hash
reference which may contains the following items :

=over

=item order_template

The record template that will be used to insert the order
informations.

=item order_item_template

The record template that will be used to insert order items.

=item order_no

The template query that will be used to generate order number.

=item taxes_fields

The field names that should be given to the order's taxes. This is an
array reference which defaults to [taxes0, taxes1, taxes2...] if there
is more than one taxes or [ taxes ] if there is only one taxes.

=item shipping_fields

The field names that should be given to the order's shipping charges.
This is an array reference which defaults to [ shipping0, shipping1,
shipping2...] if there more than one shipping charges or [ shipping ]
if only one is present.

=item discount_fields

The field names that should be given to the order's discounts.
This is an array reference which defaults to [discount0, discount1,
discount2...] if there more than one discount or [ discount ] if only
one is present.


=item item_discount_fields

The field names that should be given to the items' discounts.
This is an array reference which defaults to [discount0, discount1,
discount2...] if there more than one discount or [ discount ] if only
one is present.

=back

    Example of an order profile : 

    {
	order =>
	{
	    order_template	    => "order",
	    order_item_template	    => "order_items",
	    order_no		    => "order_no",
	    taxes_fields	    => [qw( gst gsp ) ],
	},
    }

=head1 INITIALIZATION

An object is automatically initialized on each request by the
Apache::iNcom framework. It is accessible through the $Order global
variable in Apache::iNcom pages.


=head1 METHODS

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my ($database,$profile_file,$request) = @_;

    my $self = { DB		=> $database,
		 profile_file	=> $profile_file,
		 request	=> $request,
	       };

    bless $self, $class;
}

sub load_profiles {
    my $self = shift;

    my $file = $self->{profile_file};

    die "No such file: $file\n" unless -f $file;
    die "Can't read $file\n"	unless -r _;

    my $mtime = (stat _)[9];
    return if $self->{profiles} and $self->{profiles_mtime} <= $mtime;

    $self->{profiles} = do $file;
    die "Error in order profiles: $@\n" if $@;
    die "Order profiles didn't return an hash ref\n"
      unless ref $self->{profiles} eq "HASH";

    $self->{profiles_mtime} = $mtime;
}

sub build_multi_fields {
    my ( $order, $name, $fields, $field_names ) = @_;

    if ( ref $fields ) {
	my $i = 0;
	my @multi_fields = ();
	if ( $field_names ) {
	    foreach my $f ( @$field_names ) {
		$order->{$f} = $fields->[$i++];
	    }
	} else {
	    foreach my $f ( @$fields ) {
		$order->{$name . "_" . $i++} = $f;
	    }
	}
    } else {
	if ( $field_names ) {
	    my $f = $field_names->[0];
	    $order->{$f} = $fields;
	} else {
	    $order->{$name} = $fields;
	}
    }

}

sub build_order_fields {
    my ( $profile, $order_no, $order_data, $cart ) = @_;

    my $order_fields = { %{$order_data} };
    $order_fields->{subtotal}   = $cart->subtotal;
    $order_fields->{total}	= $cart->total;
    $order_fields->{order_no}   = $order_no;
    $order_fields->{status}	= "created";

    build_multi_fields( $order_fields, "taxes",
			scalar($cart->taxes), $profile->{taxes_fields}
		      );
    build_multi_fields( $order_fields, "discount",
			scalar($cart->discount), $profile->{discount_fields}
		      );
    build_multi_fields( $order_fields, "shipping",
			scalar($cart->shipping), $profile->{shipping_fields}
		      );

    return $order_fields;
}

=pod

=head2 checkout ( $name, $cart, $order_data )

This method enter the user order in the database. It takes the following 
parameters :

=over

=item $name

The name of the order profile to use.

=item $cart

The cart that contains the user's order.

=item $order_data

An hash reference which contains other informations that should be stored
with the order. (Like customer's name and address for example.)

=back

The cart is emptied if the checkout is successful. NOTE: This is the
only method in the framework that will do an explicit commit to make
sure that the order is correctly entered in the database.

The method returns an hash references which contains the order
informations.

=cut

sub checkout {
    my ( $self, $name, $cart, $order_data ) = @_;

    $self->load_profiles;

    my $order = $self->{profiles}{$name};
    die "No such profile $name\n" unless $order;

    my $DB	= $self->{DB};
    my $order_no;
    my $order_fields;

    # Insert order in database.
    eval {
	$order_no = $DB->template_get( $order->{order_no} )->{order_no};
	die "No order_no returned by query\n" unless defined $order_no;

	# Insert order
	$order_fields = build_order_fields( $order,$order_no,
					    $order_data, $cart );
	$DB->record_insert( $order->{order_template}, $order_fields );
	$order_fields->{items} = [];

	# Insert order items
	foreach my $item ( $cart->items ) {
	    my $item_data = { order_no => $order_no,
			      %$item,
			    };
	    build_multi_fields( $item_data, "discount",
				$item->{discount}, 
				$order->{item_discount_fields}
			      );
	    $DB->record_insert( $order->{order_item_template},
				$item_data );
	    push @{$order_fields->{items}}, $item_data;
	}
	# Commit
	$DB->commit;
    };
    if ($@) {
	$DB->rollback;
	die $@;
    }

    # Here we may handle online payment and
    # other stuff

    # Update status to processeed
    eval {
	$DB->record_update( $order->{order_template},
			    { order_no  => $order_no,
			      status	=> "processed",
			    }
			  );
	# Commit
	$DB->commit;
    };
    if ($@) {
	$DB->rollback;
	die $@;
    }

    # Empty the cart
    $cart->empty;

    return $order_fields;
}

=pod

=head2 order_report ( $order, $template )

This method will generate an order report for a particular order. The
first parameter is the order as returned by C<checkout>, the second is
the template file that should be used. This is a standard
Apache::iNcom pages. The report will be generated in the namespace of
the calling page, so standard Apache::iNcom globals will be
accessible. DONT ABUSE IT. Also the order for which the report is generated
will be accessible through the %order global hash.

=cut
use vars qw( %order );

sub order_report {
    my ( $self, $order, $report_tmpl ) = @_;

    # Generate report
    my $report;
    my $request = $self->{request};

    no strict 'refs';
    *order = $order;
    local *{"$request->{package}\:\:order"} = \%order;

    my $params = { output	=> \$report,
		   inputfile	=> $report_tmpl,
		   # optDisableHtmlScan + optRawInput +
		   # optKeepSpaces + optReturnError
		   options	=> 512|16|1048576||262144 };
    my $result = Apache::iNcom::Request::Include( $params );
    die "Error in report generation: $result\n" if ($result != OK );

    return $report;
}


1;

__END__

=pod

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom(3) Apache::iNcom::Request(3) Apache::iNcom::CartManager(3)

=cut

