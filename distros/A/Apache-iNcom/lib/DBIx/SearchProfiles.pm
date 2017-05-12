#
#    SearchProfiles.pm - Profiles based DBI access.
#
#    This file is part of DBIx::SearchProfiles.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
package DBIx::SearchProfiles;

use DBI;

use strict;

use vars qw( $VERSION );

BEGIN {
    ($VERSION) = '$Revision: 1.9 $' =~ /Revision: ([\d.]+)/;
}

=pod

=head1 NAME

DBIx::SearchProfiles - Access to SQL database via template query.

=head1 SYNOPSIS

    use DBIx::SearchProfiles;

    my $DB = new DBIx::SearchProfiles( $dbh, $profiles);

    my $record  = $DB->record_get( "customer", 1024 );

    my $records = $DB->template_search( "cust_low_balance",
					{ low_balance => 50 } );

    $DB->record_insert( "customer", $customer_data );

=head1 DESCRIPTION

DBIx::SearchProfiles is a module which wraps around a DBI database
handle and provides another way than raw SQL to access the database.
Its aims is to take the SQL out of the code in well defined and
documented search profiles which has easier to maintain than embedded
SQL all over the application. Moreover, this decoupling of the
application logic from the SQL programming makes it possible to review
the SQL by a DBA which might not be a programmer. It may also makes
the application's code more obvious and clearer which is a Good
Thing (tm)

=head1 ACCESS METHODS

The DBIx::SearchProfiles module offers three method of access to
the underlying database :

=over

=item RAW SQL ACCESS

This is the lowest level and is thin wrapper around the underlying DBI
methods. The caller specifies the SQL statement and the params to use
for the query.

    Ex: $DB->sql_insert( "INSERT INTO customer (?,?,?)", @params );

=item RECORD ACCESS

This class of access generates automatically the SQL statement to use
based on the fields present in the table and the fields passed as
parameters. This type of access is very handy for insert or update where
you don't want to specify all the fields.

    Ex: $DB->record_insert( "customer", $customer_data );

Where I<customer> is the name of the profile definition to use and
$customer_data is a reference to an hash which contains the customer's
infos.


=item TEMPLATE ACCESS

This is the most interesting type of access. The problem with the
previous type of access is that it is convenivent and efficient for
simple query but when you want something more complex it fails
miserably. (Say one where you want other operators than =, and where
you are joining 6 tables together) In the template based access, you
use a template query in which the parameters will be substituted. The
query can be as complex as you want and the parameter subsitutions
also.

    Ex: $DB->template_search( "troublesome_customers", $search_spec );

=back

Each class of access provides 5 methods to access the data. (SQL has
an extra one, but its the exception) :

=over

=item *_get

The C<*_get> methods ( C<sql_get()>, C<record_get()> and
C<template_get()> ) will return only one record in the form of an hash
reference. Each keys corresponds to one column of the table. (So two
columns must not have the same name.)

=item *_search

The C<*_search> methods (C<sql_search()>, C<record_search()> and
C<template_search()>) will return a reference to an array of hash.
Each hash is a table row where the keys are the column's names.

Also the C<record_search()> and C<template_search()> methods have support
for limiting the number of rows returned and to results offset.
(1-50,51-100,etc).


=item *_insert

The C<*_insert> methods are for inserting one record in a table.

=item *_update

The C<*_update> methods are for updating records in a table.

=item *_delete

The C<*_delete> methods are for deleting records from the table.

=back

=head1 INITIALIZATION

To get a database search profiles handle, you use the C<new> method. 

    Ex: my $DB = new DBIx::SearchProfiles( $dsn, $profiles );

The $dsn parameter can either be an already connected DBI handle or a
reference to an hash which contains three parameters I<DataSource>,
I<UserName> and I<Password> which will be used to open one. Note that
on destruction, the connection will only be closed if the connection
was established by the DBIx::SearchProfiles modules.

The $profiles parameter can either be a reference to an hash which
contains the search profiles, or the name of a file which will be
evaluated and that must return a reference to an hash which will
contains the search profiles. Note that whenever the search profiles'
file changes on disk, the profiles are reloaded.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $dsn		= shift;
    my $profiles	= shift;

    my $self = {};
    if ( ref $dsn eq "HASH" ) {
	my $dbh = DBI->connect( $dsn->{DataSource}, $dsn->{UserName},
				$dsn->{Password}, { RaiseError => 1 } );
	$self->{dbh}	= $dbh;
	$self->{did_connect} = 1;
    } else {
	$self->{dbh} = $dsn;
    }

    my $profiles_file = undef;
    unless ( ref $profiles eq "HASH" ) {
	$profiles_file = $profiles;
	$profiles = undef;
    }
    $self->{profiles}	    = $profiles;
    $self->{profiles_file}  = $profiles_file;

    bless $self, $class;
}

sub DESTROY {
    my $self = shift;

    # Disconnect from database, if we opened the connection.
    if ( $self->{did_connect} ) {
	$self->{dbh}->disconnect;
    }
}

=pod

=head1 DBI WRAPPER METHODS

=head2 commit

Simply call commit on the underlying DBI handle.

=cut

sub commit {
    my $self = shift;

    $self->{dbh}->commit;
}

=pod

=head2 rollback

Simply call rollback on the underlying DBI handle.

=cut

sub rollback {
    my $self = shift;

    $self->{dbh}->rollback;
}

=pod

=head1 PROFILE DEFINITIONS

A search profiles collection is a reference to an hash where each key points
ta profile definition. A search profile definition is an hash which contains
several elements which will be used to build query automatically.

Here is an example profiles :

    {
    category	    =>
	{
	    query   => q{ SELECT id,category FROM category 
			  WHERE category_id = ? },
	    params  => [ "category_id" ],
	},
    product_srch    =>
      {
       query	    => q{ SELECT DISTINCT code,code_manu,category_id,category,
				 manufacturer_id,manufacturer,
				 price,description 
			  FROM products p ,manufacturer m ,category c
			  WHERE ( ? = -1 OR c.id  = ? )    AND
				( ? = -1 OR m.id  = ? )	   AND
				category_id = c.id	   AND
				manufacturer_id = m.id	   AND
				( code = ? OR code_manu    = ?
					   OR category     LIKE ?
					   OR manufacturer LIKE ?
					   OR description  LIKE ?
				)
			 },
       params	    => [ qw( category_id category_id manufacturer_id
			     manufacturer_id
			     search search search search search ) ],
       order	    => "category_id,manufacturer_id,code",
       defaults	    => { category_id => -1, manufacturer_id => -1 },
       limit	    => 25,
      },
    order_items	    =>
      {
       fields	 => [qw( quantity subtotal ) ],
       keys	 => [ qw( order_no code ) ],
       table	 => "order_items",
      },
    }

In this example, you have a simple query profile (category), a complex
template search (product_srch) and an example of a profile for record based 
access.

Here is the meaning of the different fields :

=over

=item table (RECORD ACCESS ONLY)

The name of the table on which we will operate.

=item keys (RECORD ACCESS ONLY)

A reference to an array which contains the name of the fields which
are the primary key for the table.

=item fields (RECORD ACCESS ONLY)

A reference to an array which contains the name of the fields which
are not primary keys in the table.

=item defaults

Reference to an hash of parameter defaults. This will be used to
complete when no values are present. 

=item limit

Used by C<record_search> and C<template_search> as the default
number of records to return at a time for this query.

=item max

Used by C<record_search> and C<template_search> as the default
maximum total number of records to return for a query.

=item order

Used by C<record_search> and C<template_search> as the default ordering
for the query.

=item query (TEMPLATE ACCESS ONLY)

This is the query template. It should contains the SQL that will be
executed with the standard DBI (?) placeholders embedded in it.

=item params (TEMPLATE ACCESS ONLY)

A reference to an array which contains the name of the params that will
be substituted in the template. There should be one element for every
placeholder in the query.

=back

=cut

sub has_profile {
    my ( $self, $name ) = @_;

    $self->load_profiles;
    return exists $self->{profiles}{$name};
}

sub list_profile {
    my $self  = shift;

    $self->load_profiles;
    return keys %{$self->{profiles}};
}

sub get_profile {
    my ($self,$name) = shift;

    $self->load_profiles;
    return $self->{profiles}{$name};
}

sub profiles {
    my $self = shift;

    $self->load_profiles;
    return values %{$self->{profiles}};
}

sub load_profiles {
    my $self = shift;

    my $file = $self->{profiles_file};
    return unless $file;

    die "No such file: $file\n" unless -f $file;
    die "Can't read $file\n"	unless -r _;

    my $mtime = (stat _)[9];
    return if $self->{profiles} and $self->{profiles_mtime} <= $mtime;

    $self->{profiles} = do $file;
    die "Error in search profiles: $@\n" if $@;
    die "Search profiles didn't return an hash ref\n"
      unless ref $self->{profiles} eq "HASH";

    $self->{profiles_mtime} = $mtime;
}

=pod

=head1 SQL ACCESS METHODS

=head2 sql_do ( $statement, @params );

Thin wrapper around DBI C<do> method. The first argument is the SQL to
be executed and the remaining arguments are passed as params to the query.

=cut

sub sql_do {
    my $self	    = shift;
    my $statement   = shift;

    my $dbh = $self->{dbh};

    $dbh->do( $statement, undef, @_ );
}

=pod

=head2 sql_get ( $statement, @params );

This method will execute the SELECT query passed in the first argument
using the remaining parameters as placeholder substitutions.

It returns an hash ref (or undef if the query didn't match any record)
corresponding to the first row returned.

=cut

sub sql_get {
    my $self	    = shift;
    my $statement   = shift;

    die "Statement doesn't start with SELECT"
      unless  $statement =~ /^\s*SELECT /i;

    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( $statement );
    $sth->execute( @_ );

    my @fields = @{$sth->{NAME}};
    my $record = $sth->fetch;
    return undef unless $record;

    my $i = 0;
    return { map { $fields[$i++] => $_ } @$record };
}

=pod

=head2 sql_search ( $statement, @params );

This method will execute the SELECT query passed in the first argument
using the remaining parameters as placeholder substitutions.

It returns a reference to an array of hash.

=cut

sub sql_search {
    my $self	    = shift;
    my $statement   = shift;

    die "Statement doesn't start with SELECT"
      unless  $statement =~ /^\s*SELECT /i;

    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( $statement );
    $sth->execute( @_ );

    my $result = [];
    my @fields = @{$sth->{NAME}};
    while ( my $record = $sth->fetch ) {
	my $i = 0;
	push @$result, { map { $fields[$i++] => $_ } @$record };
    }

    return $result;
}

=pod

=head2 sql_insert ( $statement, @params );

This method will execute the INSERT query passed in the first argument
using the remaining parameters as placeholder substitutions.

Return value is undefined.

=cut

sub sql_insert {
    my $self = shift;
    my $statement   = shift;

    die "Statement doesn't start with INSERT"
      unless  $statement =~ /^\s*(INSERT) /i;

    $self->sql_do( $statement, @_ );
}

=pod

=head2 sql_update ( $statement, @params );

This method will execute the UPDATE query passed in the first argument
using the remaining parameters as placeholder substitutions.

Return value is undefined.

=cut

sub sql_update {
    my $self	    = shift;
    my $statement   = shift;

    die "Statement doesn't start with UPDATE"
      unless  $statement =~ /^\s*(UPDATE) /i;

    $self->sql_do( $statement, @_ );
}

=pod

=head2 sql_delete ( $statement, @params );

This method will execute the DELETE query passed in the first argument
using the remaining parameters as placeholder substitutions.

Return value is undefined.

=cut

sub sql_delete {
    my $self	    = shift;
    my $statement   = shift;

    die "Query doesn't start with DELETE"
      unless  $statement =~ /^\s*(DELETE) /i;

    $self->sql_do( $statement, @_ );
}

=pod

=head1 RECORD BASED ACCESS

=over

=head2 record_get ( $name, params );

This method will return an hash reference to a record. The first argument
is the name of the profile where the table information will be found. The params argument can either be :

=over

=item ARRAY OR ARRAY REF

Each element of the array is mapped to an element of the I<keys> field
of the profile. It is an error if the number of elements is different than
the number of keys defined in the table.

=item HASH REF

The key will be built by using the name of the keys as specified in the
I<keys> field of the profile, or by using the I<defaults> hash if present.

It is an error if some portion of the key is missing.

=back

=cut

sub record_get {
    my $self = shift;
    my $name = shift;

    my $fdat;
    my @values;
    if ( ref $_[0] eq "HASH" ) {
	$fdat = shift;
    } elsif ( ref $_[0] eq "ARRAY" ) {
	@values = @{$_[0]};
    } else {
	@values = @_;
    }
    $fdat ||= {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $table	= $profile->{table};
    my $keys	= $profile->{keys};

    my @keys	= ();
    unless (@values) {
	for my $name ( @$keys ) {
	    my $value = defined $fdat->{$name} ? $fdat->{$name} :
	      $profile->{defaults}{$name};
	    die "Missing key attribute $name\n"
	      unless defined $value;
	    push @keys,	$name . " = ?";
	    push @values,	$value;
	}
    } else {
	die "Number of values doesn't match the number of keys\n" 
	  unless @$keys == @values;
	for my $name ( @$keys ) {
	    push @keys, $name . " = ?";
	}
    }

    my $query = "SELECT * FROM $table WHERE " . join ( " AND ", @keys );
    $self->sql_get( $query, @values );
}

=pod

=head2 record_search ( $name, \%params );

This method will build a search on the table specified in the profile
$name. $params is a reference to an hash where each keys that is
present in the I<fields> or I<keys> of the profile will be used as a
constraint in the query. The test is for equality, if you want
something more complex, use C<template_search>.

There are a few magic parameters :

=over

=item dbix_sp_order

Will override the order clause of the query. If not present the I<order>
field of the profile will be used.

=item dbix_sp_limit

Limit the number of records returned by the query. If not present the
I<limit> field of the profile will be used.

=item dbix_sp_max

Set the maximum number of records that the query may fetch, this override
the I<max> field of the profile but cannot be set higher.

=item dbix_sp_start

If there is a I<limit> set for the query, this parameter will start
returning records from that offset in the result. Offset is 0 indexed.

=back

The I<params> argument is modified on return. Here is a list of the
modified elements :

=over

=item dbix_sp_found

The number of record returned.

=item dbix_sp_total

The total number of record matching the query.

=back

Like all *_search methods C<record_search> will return a reference to
an array of hash.

=cut

sub record_search {
    my $self = shift;
    my $name = shift;
    my $fdat = shift || {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $table	    = $profile->{table};
    my $fields	    = $profile->{fields};
    my $keys	    = $profile->{keys};
    my $order_by    = $fdat->{dbix_sp_order} || $profile->{order};

    # Set defaults value for do_bounded_search
    $fdat->{dbix_sp_start} ||= 0;
    $fdat->{dbix_sp_limit} ||= $profile->{limit} || 0;

    my $max	    = $fdat->{dbix_sp_max} ||= $profile->{max} || 0;
    # Maximum cannot be set higher than the one set in the profile.
    if ( defined $profile->{max} && $max > $profile->{max} ) {
	$max = $fdat->{dbix_sp_max} = $profile->{max};
    }

    my %fields = map { $_ => 1 } @$fields, @$keys;
    my @names	= ();
    my @values	= ();
    while ( my ($name,$value) = each %$fdat ) {
	next unless  $fields{$name};
	push @names, $name . " = ?";
	push @values, $value;
    }

    # Build query
    my $query = "SELECT * FROM $table";
    $query .= " WHERE " . join( " AND ", @names ) if @names;
    $query .= " ORDER BY $order_by"	     if $order_by;
    $query .= " LIMIT $max" if $max;

    $self->do_bounded_search( $fdat, $query, @values );
}

sub do_bounded_search {
    my ($self,$fdat,$statement) = @_[0,1,2];

    die "Statement doesn't start with SELECT"
      unless  $statement =~ /^\s*SELECT /i;

    my $dbh = $self->{dbh};

    my $sth = $dbh->prepare( $statement );
    $sth->execute( @_[3 .. $#_] );

    my $result = [];
    my @fields = @{$sth->{NAME}};

    my $start  = $fdat->{dbix_sp_start};
    my $limit  = $fdat->{dbix_sp_limit};

    my $total  = 0;
    my $offset = 0;
    my $found  = 0;
    while ( my $record = $sth->fetch ) {
	# Check if this record is between the bounds we are looking for
	if ( ! $limit || ($offset >= $start && $offset < $start + $limit ) ) {
	    my $i = 0;
	    push @$result, { map { $fields[$i++] => $_ } @$record };
	    $found++;
	}
	$offset++,$total++;
    }
    $fdat->{dbix_sp_found} = $found;
    $fdat->{dbix_sp_total} = $total;
    return $result;
}

=pod

=head2 record_insert ( $name, \%params );

This method will insert a record in the table specified by the profile
$name. The I<params> argument is a reference to an hash which contains
the record data to be inserted. The hash should contains one element
for each key specified in the I<keys> field of the profile. Each
elements in the fields that is a valid table fields (as specified by
the I<fields> element of the profile) will be inserted. Any elements
specified I<defaults> and not present in the I<params> hash will also
be inserted.

Return value is undefined.

=cut

sub record_insert {
    my $self = shift;
    my $name = shift;
    my $fdat = shift || {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $table	= $profile->{table};
    my @fields	= (@{$profile->{keys}}, @{$profile->{fields}} );

    my @names	= ();
    my @values	= ();
    for my $name ( @fields ) {
	my $value = defined $fdat->{$name} ? $fdat->{$name} :
	  $profile->{defaults}{$name};
	next unless defined $value;
	push @names,	$name;
	push @values,	$value;
    }

    die "Nothing to insert\n" unless @values;

    my $statement = "INSERT INTO $table ( " . join (", ", @names ) .
      ") VALUES (" . join ( ",", ("?") x @names ) . ")";

    $self->sql_do( $statement, @values );
}

=pod

=head2 record_update ( $name, \%params );

This method will update a record in the table specified by the profile
$name. The I<params> argument is a reference to an hash which contains
the record data to be updated. The hash should contains one element
for each key specified in the I<keys> field of the profile. Each
elements in the fields that is a valid table fields (as specified by
the I<fields> element of the profile) will be updated. Any elements
specified I<defaults> and not present in the I<params> hash will also
be updated.

Return value is undefined.

=cut

sub record_update {
    my $self = shift;
    my $name = shift;
    my $fdat = shift || {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $table	= $profile->{table};
    my $fields	= $profile->{fields};
    my $keys	= $profile->{keys};

    my @names	= ();
    my @values	= ();
    for my $name ( @$fields ) {
	my $value = defined $fdat->{$name} ? $fdat->{$name} :
	  $profile->{defaults}{$name};
	next unless defined $value;
	push @names, $name . " = ?";
	push @values, $value;
    }

    die "Nothing to update\n" unless @values;

    my @keys	= ();
    for my $name ( @$keys ) {
	my $value = $fdat->{$name};
	die "Missing key attribute $name\n"
	  unless defined $value;
	push @keys,	$name . " = ?";
	push @values,	$value;
    }

    my $query = "UPDATE $table SET " . join( ", ", @names ) .
      " WHERE " . join ( " AND ", @keys );

    $self->sql_do( $query, @values );
}

=pod

=head2 record_delete ( $name, $keys );

This method will delete a record in the table specified by the profile
$name. The I<keys> argument is a reference to an hash which contains
the keys to the record to delete. The hash should contains one element
for each key specified in the I<keys> field of the profile.

Return value is undefined.

=cut

sub record_delete {
    my $self = shift;
    my $name = shift;
    my $fdat = shift || {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $table	= $profile->{table};
    my $keys	= $profile->{keys};

    my @keys	= ();
    my @values	= ();
    for my $name ( @$keys ) {
	my $value   = $fdat->{$name};
	die "Missing key attribute $name\n"
	  unless defined $value;
	push @keys,	$name . " = ?";
	push @values,	$value;
    }

    my $query = "DELETE FROM $table WHERE " . join ( " AND ", @keys );
    $self->sql_do( $query, @values );
}

=pod

=head1 TEMPLATE BASED ACCESS

All of the C<template_*> methods accepts two parameters, $name and
params. The $name parameter specified the profile to use as a template
for the operation (get,search,insert,update or delete). The other
parameter is used as substitutions for the placeholders of the
template. Those substitutions can be specified in three manners :

=over

=item ARRAY OR ARRAY REF

Each element of the array is mapped to an element of the I<params> field
of the profile. It is an error if the number of elements is different than
the number of params defined in the profile.

=item HASH REF

Each substitutions will be mapped to one of the element of the
I<params> hash in the order specified by the I<params> element of the
profile. If a params element isn't present, a default one will be
used. (Either the value specified in the profile's defaults element or
NULL).

=back

=head2 template_get ( $name, params )

This method will return an hash reference to a record using the
profile $name.

=cut

sub template_get {
    my $self = shift;
    my $name = shift;

    my ( $fdat, @params );

    # Params is either an hash ref in which we will look
    # for named base params or it can be an array (or array ref)
    # of which the elements will be used for substitutions in
    # the SQL query
    if ( ref $_[0] eq "HASH" ) {
	$fdat = shift;
    } elsif ( ref $_[0] eq "ARRAY" ) {
	@params = @{$_[0]};
    } else {
	@params = @_;
    }
    $fdat ||= {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $query_spec  = $profile->{query};
    die "Query doesn't start with SELECT"
      unless  $query_spec =~ /^\s*SELECT /i;

    # Fetch the params from the query
    my $params_spec = $profile->{params} || [];
    if ( @params ) {
	die "Number of params doesn't match the number of specs\n"
	  unless @params == @$params_spec;
    } else {
	@params = map { 
	    defined $fdat->{$_} ? $fdat->{$_} : $profile->{defaults}{$_}
	} @$params_spec;
    }
    $query_spec .= " LIMIT 1" unless $query_spec =~ /LIMIT/;

    $self->sql_get( $query_spec, @params );
}

=pod

=head2 template_search ( $name, params )

This method will run a search using the query template specified in
the profile named $name and return the results in a reference to an
array of hashes.

This methods accept the same magic parameters in the %params element
as the C<record_search> method. It also modifies the same element in
%params as that method.

=cut

sub template_search {
    my $self = shift;
    my $name = shift;

    my ( $fdat, @params );

    # Params is either an hash ref in which we will look
    # for named base params or it can be an array (or array ref)
    # of which the elements will be used for substitutions in
    # the SQL query
    if ( ref $_[0] eq "HASH" ) {
	$fdat = shift;
    } elsif ( ref $_[0] eq "ARRAY" ) {
	@params = @{$_[0]};
    } else {
	@params = @_;
    }
    $fdat ||= {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $query_spec  = $profile->{query};
    die "Query doesn't start with SELECT"
      unless  $query_spec =~ /^\s*SELECT /i;

    my $params_spec = $profile->{params} || [];
    my $order_by    = $fdat->{dbix_sp_order} || $profile->{order};

    # Set defaults value for do_bounded_search
    $fdat->{dbix_sp_start} ||= 0;
    $fdat->{dbix_sp_limit} ||= $profile->{limit} || 0;

    my $max	    = $fdat->{dbix_sp_max} ||= $profile->{max} || 0;
    # Maximum cannot be set higher than the one set in the profile.
    if ( defined $profile->{max} && $max > $profile->{max} ) {
	$max = $fdat->{dbix_sp_max} = $profile->{max};
    }

    # Fetch the param from the query
    if ( @params ) {
	die "Number of params doesn't match the number of specs\n"
	  unless @params == @$params_spec;
    } else {
	@params = map { 
	    defined $fdat->{$_} ? $fdat->{$_} : $profile->{defaults}{$_}
	} @$params_spec;
    }

    # Set ORDER and LIMIT clause
    unless ( !defined $order_by || $query_spec =~ /ORDER\s+BY/i) {
	$query_spec .= " ORDER BY $order_by";
    }

    unless ( ! $max || $query_spec =~ /\bLIMIT\b/i ) {
	$query_spec .= " LIMIT $max";
    }

    $self->do_bounded_search( $fdat, $query_spec, @params );
}

=pod

=head2 template_insert ( $name, params )

This method will insert a record according to the profile in $name.
Normal template substitutions will be used.

Return value is undefined.

=cut

sub template_insert {
    my $self = shift;
    my $name = shift;

    my ( $fdat, @params );

    # Params is either an hash ref in which we will look
    # for named base params or it can be an array (or array ref)
    # of which the elements will be used for substitutions in
    # the SQL query
    if ( ref $_[0] eq "HASH" ) {
	$fdat = shift;
    } elsif ( ref $_[0] eq "ARRAY" ) {
	@params = @{$_[0]};
    } else {
	@params = @_;
    }
    $fdat ||= {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $statement_spec  = $profile->{query};
    die "Query doesn't start with INSERT"
      unless  $statement_spec =~ /^\s*INSERT /;

    my $params_spec = $profile->{params} || [];

    # Fetch the param from the query
    if ( @params ) {
	die "Number of params doesn't match the number of specs\n"
	  unless @params == @$params_spec;
    } else {
	@params = map { 
	    defined $fdat->{$_} ? $fdat->{$_} : $profile->{defaults}{$_}
	} @$params_spec;
    }

    $self->sql_do( $statement_spec, @params );
}

=pod

=head2 template_update ( $name, params )

This method will update records according to the profile $name and
using standard template's placholders substitutions semantics.

Return value is the number of rows updated.

=cut

sub template_update {
    my $self = shift;
    my $name = shift;

    my ( $fdat, @params );

    # Params is either an hash ref in which we will look
    # for named base params or it can be an array (or array ref)
    # of which the elements will be used for substitutions in
    # the SQL query
    if ( ref $_[0] eq "HASH" ) {
	$fdat = shift;
    } elsif ( ref $_[0] eq "ARRAY" ) {
	@params = @{$_[0]};
    } else {
	@params = @_;
    }
    $fdat ||= {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $statement_spec  = $profile->{query};
    die "Query doesn't start with UPDATE"
      unless  $statement_spec =~ /^\s*UPDATE /;

    my $params_spec = $profile->{params} || [];

    # Fetch the param from the query
    if ( @params ) {
	die "Number of params doesn't match the number of specs\n"
	  unless @params == @$params_spec;
    } else {
	@params = map { 
	    defined $fdat->{$_} ? $fdat->{$_} : $profile->{defaults}{$_}
	} @$params_spec;
    }

    $self->sql_do( $statement_spec, @params );
}

=pod

=head2 template_delete ( $name, params )

This method will delete records according to the template $name and
using regular template's placeholders substitutions semantics.

Return value is the number of records deleted.

=cut

sub template_delete {
    my $self = shift;
    my $name = shift;

    my ( $fdat, @params );

    # Params is either an hash ref in which we will look
    # for named base params or it can be an array (or array ref)
    # of which the elements will be used for substitutions in
    # the SQL query
    if ( ref $_[0] eq "HASH" ) {
	$fdat = shift;
    } elsif ( ref $_[0] eq "ARRAY" ) {
	@params = @{$_[0]};
    } else {
	@params = @_;
    }
    $fdat ||= {};

    $self->load_profiles;

    my $profile = $self->{profiles}{$name};
    die "No such profile: $name\n" unless $profile;

    my $statement_spec  = $profile->{query};
    die "Query doesn't start with DELETE"
      unless  $statement_spec =~ /^\s*DELETE /;

    my $params_spec = $profile->{params} || [];

    # Fetch the param from the query
    if ( @params ) {
	die "Number of params doesn't match the number of specs\n"
	  unless @params == @$params_spec;
    } else {
	@params = map { 
	    defined $fdat->{$_} ? $fdat->{$_} : $profile->{defaults}{$_}
	} @$params_spec;
    }

    $self->sql_do( $statement_spec, @params );
}

1;

__END__

=pod

=head1 BUGS AND LIMITATIONS

Please report bugs, suggestions, patches and thanks to
<bugs@iNsu.COM>.

The search limitations and offset SQL generation is probably not completely
portable. It uses LIMIT and OFFSET which are maybe not supported across SQL92
implementation. (PostgreSQL supports it so...)

To find the number of records that will be returned by a query (in
*_search) we use C<count(*)>. This could cause a number of problems.

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=head1 SEE ALSO

DBIx::Recordset(3) DBI(3) DBIx::UserDB(3)

=cut

