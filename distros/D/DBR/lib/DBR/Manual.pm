package DBR::Manual;

=pod

=head1 DRAFT

B<This documentation is in early draft form!>

=head1 NAME

DBR - Database Repository ORM (object-relational mapper).

=head1 SYNOPSIS

    # common packages
    use DBR;
    use DBR::Util::Logger;
    use DBR::Util::Operator;

    # typical connection
    my $logger = DBR::Util::Logger->new( -logpath => './dbr.log', -logLevel => 'debug2' );
    my $dbr = DBR->new( -logger => $logger, -conf => './dbr.conf' );
    my $dbh = $dbr->connect( 'car_dealer' );  # instance handle

    # metadata access (dbr tools)
    my $meta = $dbr->get_instance( 'dbrconf' );


=head1 DESCRIPTION

DBR stands for Database Repository, and functions as an ORM
(Object Relational Mapper) to your database.

DBR tries to make your use of a database safe, concise, efficient
and clear. The objective is to treat your database records like
objects, and deliver the most common functionality with a minimum
of fuss. You shouldn't have wo worry about efficiency, readability 
or value translation.

Admittedly, DBR isn't going to be an instant solution for someone
who wants to hit the ground running with a lightweight application.
It is primarily designed for large applications with large schemas.
(though it's just as capable of handling a two table SQLite database
as it is a 1,000 table monster)

In order to get much of any functionality, you'll have to spend a
little time teaching it about your schema(s). The tools included
will allow you to scan your schemas, enter relationships, and so on.
After you've done this, you can begin to reap the benefits.

A bit of a disclaimer: DBR isn't going to fit all people's tastes.
It's not attempting to be a flexible foundation class or toolkit for
you to build your schema specific modules on top of (as many other 
ORM packages attempt to be.) The intent is to try to solve the ORM
problem with a design where metadata is king, not code.


=head2 FEATURES

=over

=item concise

Even when your task requires touching several tables in the underlying database, it takes surpsisingly little code to fetch the data you need. Then you just use the data and the DBR objects will attempt to do the "right thing"(TM). 

For example:

    my $orders = $dbrh->orders->where( 'customer.name' => LIKE '%Jones' );

    while ( $orders->next ) {
        print "Order " . $_->order_id . " shipped " . $_->shipment->method->name . "\n";
    }

would be the equivalent of writing out some SQL like:

    select
      o.order_id,
      m.name
    from
      orders o,
      customers c,
      shipments s,
      ship_methods m
    where
      c.name like '%Jones' and
      o.customer_id = c.cust_id and
      o.shipment_id = s.shipment_id and
      s.method_id = m.method_id;

=item smart

DBR automatically profiles your code. It remembers what fields you need,
and fetches them for you next time. It also reads ahead in the resultset whenever
fetching related records. Both of these features prevent it from issuing bazillions of
tiny queries to the database.

=item efficient

Most DBR objects are blessed arrayrefs instead of hashrefs. Using DBR to fetch
your data is almost as fast as using fetchrow_arrayref, but far more powerful.

Access to large quantities of data are automatically chunked behind the scenes.
Stop worrying about blowing up the memory on your server just because you need
to retrieve a few million records in one shot.

=item convenient

Database fields can hold a representation of data that you can access
in raw or formatted form via automatic translators that wrap the field.

Currently available for Dollars, Unixtime, Percent and Enumeration.

=item no SQL

Table joins are replaced with the names of relationships associated with
foreign keys.  All you end up doing is:

    $car->model->make->name # Don't worry about the underlying DB queries. It's efficient.

or

    where( 'car.model.make.name' => 'Ford' )

=item post-fetch organization

Create a lookup map (hash):

    # what preference did customers have for shipping method by gender last year?

    $dbh->orders->
      where( order.date => BETWEEN( '1/1/2008', '1/1/2009' ) )->
        hashmap_multi( 'order.date.month', 'shipment.method.name', 'customer.gender' );

or

    # get purchase items grouped by shipment method and order

    $dbh->items->
      where( 'order.customer' => $customer_id )->
        hashmap_multi( 'order.shipment.method.name', 'order.order_id' );



=back

=head1 CONFIGURATION

=head2 Configuration File

Contains the information needed to get to the configuration/metadata database.

This database contains all the information about schemas and instances you
will be connecting to.

For a SQLite config database, your config will define:

    name=dbrconf
    class=master
    dbfile=/path/to/database
    type=SQLite
    dbr_bootstrap=1

    really, all you need to usually do is customize the dbfile path.

For a MySQL config database, your config will define:

    name=dbrconf
    class=master
    hostname=db.host.domain.com
    database=myapp
    user=dbusername
    password=dbpassword
    type=Mysql
    dbr_bootstrap=1

    typically customize just hostname, database, user and password.

The class could also be "query", for a read-only replicated copy, for example.

=head2 Bootstrap

When you create a new() DBR, you typically point it at the above config file.

From there, all further actions to your application databases are thru the
DBR object.

=head2 Debug Logging

A common logger instance is required by DBR and shared by all related objects.

=head1 METADATA

=head2 Schema

=head2 Instance

=head2 Table

=head2 Field

=head2 Enumeration

=head1 API

Be sure to also check out:

L<http://code.google.com/p/perl-dbr/wiki/ObjectsAndMethods>

=head2 DBR

=head3 new

=head3 get_instance

=head3 connect

=head3 timezone

=head3 remap

=head3 unmap

=head2 Instance Handle

=head3 TABLENAME

=head3 begin

=head3 commit

=head3 rollback

=head3 select (v1)

=head3 insert (v1)

=head3 update (v1)

=head3 delete (v1)

=head2 Object

=head3 where

=head3 all

=head3 get

=head3 insert

=head3 enum

=head3 parse

=head2 Resultset

=head3 next

=head3 each

=head3 hashmap_multi

=head3 hashmap_single

=head3 count

=head3 values

=head3 raw_hashrefs

=head3 raw_arrayrefs

=head3 raw_keycol

=head2 Record

=head3 FIELDNAME

=head3 get

=head3 RELATIONNAME

=head3 gethash

=head3 set

=head3 delete

=head2 Translator

=head3 Dollars

=head4 dollars

=head4 format

=head4 cents

=head3 Unixtime

=head4 date

=head4 time

=head4 datetime

=head4 fancytime

=head4 fancydate

=head4 fancydatetime

=head4 unixtime

=head4 midnight

=head4 endofday

=head3 Enum

=head4 handle

=head4 name

=head4 in

=head4 id

=head2 Operators

    use DBR::Util::Operator;

=head3 GT (greater-than)

    where( 'item.price' => GT 3.59 );

=head3 LT (less-than)

    where( 'item.price' => LT 3.59 );

=head3 GE (greater-than-or-equal-to)

    where( 'item.price' => GE 3.59 );

=head3 LE (less-than-or-equal-to)

    where( 'item.price' => LE 3.59 );

=head3 NOT

=head3 LIKE

    where( name => LIKE( '%ing' )

=head3 NOTLIKE

    where( name => LIKE( 'George%' )

=head3 BETWEEN

    where( price => BETWEEN( 3.00, 4.50 ) )

=head3 NOTBETWEEN

    where( price => NOTBETWEEN( 50, 100 ) )

=head2 Logger

=head3 logErr

=head3 logWarn

=head3 logInfo

=head3 logDebug

    verbose

=head3 logDebug2

    very verbose

=head3 logDebug3

    really, really verbose

=head1 TOOLS

=head2 dbr-admin

=head2 dbr-load-spec

=head2 dbr-dump-spec

=head2 dbr-scan-db

=head1 TODO

=over

=item dbr-admin

This tool works, but it has various quirks that make it a bit
difficult to use at present.

=item fast metadata browser

DBR needs a fast and effective browser, especially for looking up
the relationship names and enumeration handles.  The dbr-admin tool
is helpful but clunky, the dbr-spec-dump also can be use for this
purpose, but...

=item cross-module scoping

DBR's current pre-fetch scoping support only works within a file.
It needs to be extended.  For now, don't pass DBR objects between
packages, unless they are in the same file.

=item debug support

Attempting to Dumper data with DBR objects will explode with metadata
you never wanted to see.  DBR needs dumper support.

=item OR support

DBR doesn't want to you to make an OR query.  It usually results in
an inefficient table scan.  In fact, you just can't with DBR!
All the constraints in a where() are ANDed together.

Should you be able to OR?

=back

=head1 BUGS

=head2 MySQL sub-queries

DBR will magically perform a sub-query when you use the reverse
direction of a relationship.  For example, given an e-commerce
scenario with an Order that has Items, the item has a foreign key
to its order, so C<order.items> would be traversing that foreign
key in the reverse direction, causing a sub-query of items matching
the order's pkey.  MySQL handles the sub-query very poorly, and
depending on the volume of data, you may need to identify the order pkeys
of interest first, and then use C<< where( order_id => $order_ids ) >>
explicitly instead.

=head2 perl-dbr project

See L<http://code.google.com/p/perl-dbr/issues/list>.

=head1 SEE ALSO

Google Code project: L<http://code.google.com/p/perl-dbr>

API Diagram: L<http://code.google.com/p/perl-dbr/wiki/ObjectsAndMethods>

=head1 AUTHOR

Daniel Norman, C<dnorman@drjays.com>.

=head1 COPYRIGHT AND LICENSE

Copyright 2009, Daniel Norman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
