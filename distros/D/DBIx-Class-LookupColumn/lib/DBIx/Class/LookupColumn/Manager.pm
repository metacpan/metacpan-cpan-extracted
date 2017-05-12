package DBIx::Class::LookupColumn::Manager;
{
  $DBIx::Class::LookupColumn::Manager::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

DBIx::Class::LookupColumn::Manager - a lazy cache system for storing Lookup tables.

=cut

use Carp qw(confess);
use Smart::Comments -ENV;

my %CACHE; # main class variable containing all cached objects


=head1 SYNOPSIS

 use DBIx::Class::LookupColumn::Manager;
 DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME(  $schema, 'PermissionType', 'name', 'Administrator' );
 DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID(  $schema, 'PermissionType', 'name', 1 );


=head1 DESCRIPTION

This class is not intended to be used directly. It is the backbone of the L<DBIx::Class::LookupColumn> module.

It stores B<Lookup tables> ( (id, name) ) in a structure and indexes ids and names both ways, so that it is fast to test if a given
name is defined by a Lookup table.

This module only supports tables having only one single primary key.


=head1 STATIC METHODS

=cut

=head2 FETCH_ID_BY_NAME

 $id = DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME($schema, $lookup_table, $field_name, $name)

Returns the id associated with the value C<$name> in the column C<$field_name> of the Lookup table named C<$lookup_table>.

As a side-effect, it will lazy-load the table C<$lookup_table> in the cache.

B<Arguments>:

=over 4

=item $schema

The L<DBIx::Class::Schema> schema instance.

=item $lookup_table

The name of the Lookup table.

=item $field_name

The name of the column of the Lookup table that contains the value of the terms/definitions (e.g. 'name').

=item $name

The value in the column C<$field_name> we want to fetch the primary key for.

=back

B<Example>:

 my $admin_id = DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME( $schema, 'UserType', 'name', 'Administrator' ).

=head2 FETCH_NAME_BY_ID

 $name = DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME($schema, $lookup_table, $field_name, $id)

Returns the name associated with the id C<$id> in the column C<$field_name> of the Lookup table named C<$lookup_table>.

As a side-effect, it will lazy-load the table C<$lookup_table> in the cache.

B<Arguments>:

=over 4

=item $schema

The L<DBIx::Class::Schema> schema instance.

=item $lookup_table

The name of the Lookup table.

=item $field_name

The name of the column of the Lookup table that contains the value of the terms/definitions (e.g. 'name').

=item $id

The id C<$id> in the column C<$field_name> we want to fetch the value for.

=back

B<Example>:

 my $type_name = DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID( $schema, 'UserType', 'name', 1 ).




=cut

sub FETCH_ID_BY_NAME {
    my ( $class, $schema, $lookup_table, $field_name, $name ) = @_;
	confess "Bad args" unless defined $name;
    my $cache	= $class->_ENSURE_LOOKUP_IS_CACHED(  $schema, $lookup_table, $field_name );
    my $id		= $cache->{name2id}{$name} or confess "name [$name] does not exist in (cached) Lookup table [$lookup_table]";
    return $id;
}




sub FETCH_NAME_BY_ID {
    my ( $class, $schema, $lookup_table, $field_name, $id ) = @_;
	confess "Bad args" unless defined $id;
    my $cache	= $class->_ENSURE_LOOKUP_IS_CACHED( $schema, $lookup_table, $field_name );
    my $name	= $cache->{id2name}{$id} or confess "Bad type_name [$id] in Lookup table [$lookup_table]";
    return $name;
}




sub _ENSURE_LOOKUP_IS_CACHED {
    my ( $class, $schema, $lookup_table, $field_name ) = @_;
	
	# check the table and field names
	my $source_table = $schema->source( $lookup_table ) or confess "unknown table called $lookup_table";
    confess "the $field_name as field name does not exist in the $lookup_table lookup table" 
    	unless $source_table->has_column( $field_name );
		
    #### _ENSURE_LOOKUP_IS_CACHED: $lookup_table, $field_name
 
    unless ( $CACHE{$lookup_table} ) {
		$CACHE{$lookup_table} = {};
		
		# get primary key name         
        my @primary_columns = $schema->source( $lookup_table )->primary_columns;
        confess "Error, no primary defined in lookup table $lookup_table" unless @primary_columns;
        confess "we only support lookup table with ONE primary key for table $lookup_table" if @primary_columns > 1; 
        my $primary_key = shift @primary_columns;
        
       	# query for feching all (id, name) rows from lookup table
        my $rs = $schema->resultset($lookup_table)->search( undef, { select=>[$primary_key, $field_name] });
		
		my ($id, $name);
		my $id2name = $CACHE{$lookup_table}{id2name} ||= {};
		my $name2id = $CACHE{$lookup_table}{name2id} ||= {};
		my $cursor =  $rs->cursor;
		# fetch all and fill the cache
		while ( ($id, $name) = $cursor->next ){
			$id2name->{$id} = $name;
			$name2id->{$name} = $id;
		}
    }
    return $CACHE{$lookup_table};
}




sub RESET_CACHE {
	my ( $class ) = @_;
    %CACHE = ();
}




sub RESET_CACHE_LOOKUP_TABLE {
	my ( $class, $lookup_table ) = @_;
    delete $CACHE{$lookup_table};
}


sub _GET_CACHE{
	my ( $class ) = @_;
	return \%CACHE;
}



=head1 AUTHORS

Karl Forner <karl.forner@gmail.com>

Thomas Rubattel <rubattel@cpan.org>


=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-lookupcolumn-manager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LookupColumn-Manager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LookupColumn::Manager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LookupColumn-Manager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LookupColumn-Manager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LookupColumn-Manager>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LookupColumn-Manager/>

=back



=head1 LICENCE AND COPYRIGHT

Copyright 2012 Karl Forner and Thomas Rubattel, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms as Perl itself.

=cut

1; # End of DBIx::Class::LookupColumn::Manager
