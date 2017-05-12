package DBIx::Class::LookupColumn::LookupColumnComponent;

use strict;
use warnings;

=head1 NAME

DBIx::Class::LookupColumn::LookupColumnComponent - A dbic component for building accessors for a lookup table.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

use base qw(DBIx::Class);
use Carp qw(confess);
use Class::MOP;
use Smart::Comments -ENV;
use Hash::Merge::Simple qw/merge/;

use DBIx::Class::LookupColumn::Manager;




=head1 SYNOPSIS

 # ===== use the component in your table definition =====
 package MySchema::Result::User;
 __PACKAGE__->load_components( B<qw/LookupColumn/> );>
 __PACKAGE__->table("user");
 __PACKAGE__->add_columns( "user_id",{}, "name", {}, "user_type_id", {} );
 __PACKAGE__->set_primary_key("user_id");
 __PACKAGE__->add_lookup(  'type', 'user_type_id', 'UserType' );

 # === use the generated accessors ===

 $user->type; # fetches the type value (e.g. 'Administrator') directly from the cache

 # checks that 'Administrator' is a valid value, get its id, and tests if it matches $user->user_type_id
 $user->is_type('Administrator');
 
 # checks that 'User' is a valid value, get its id, and sets it as $user->user_type_id
 $user->set_type('User'); 

=head1 DESCRIPTION

This is the actual implementation of L<DBIx::Class::LookupColumn>, that is why you can and should use C<'LookupColumn'> 
instead of C<'LookupColumn::LookupColumnComponent'> in the C<load_components> function call.


This module generates convenient methods (accessors) for accessing data in a B<Lookup table> (see L<DBIx::Class::LookupColumn/Lookup Tables>.
It uses L<DBIx::Class::LookupColumn::Manager> to cache and store the entire lookup tables in memory.


=head1 METHODS

=head2 add_lookup

 add_lookup( $relation_name, $foreign_key, $lookup_table, \%options?)

Add a Lookup relation from a Table to a B<Lookup table> from a foreign key by generating
new accessors and setters.
The relation is defined by its B<name> ( C<$relation_name> ), the B<foreign key> and the 
B<Lookup table>.

It will add three methods to the class: see L</GENERATED METHODS>.


B<Arguments>:

=over 4

=item $relation_name

The name of the relation, used for making default names for the generated methods.

=item  $foreign_key

the foreign key column in the table on which to add the lookup relation.

=item $lookup_table

The Lookup table, on which the foreign key points.

=item \%options?

An optional HashRef, with the following keys:

=over 8

=item name_accessor

the name of the generated accessor, defaults to C<${relation_name}>

=item name_setter

the name of the generated setter, defaults to C<set_${relation_name}>

=item name_checker

the name of the generated method (checker), defaults to C<is_${relation_name}>


=back

B<Example>:

  MySchema::Result::User->add_lookup(  'permission', 'permission_type_id', 'PermissionType',
	{name_accessor => 'get_the_permission',
	name_setter   => 'set_the_permission,
	name_checker  => 'is_the_permission'
	}
);

Will add methods C<get_the_permission>, C<set_the_permission> and C<is_the_permission>
in MySchema::Result::User.

=back


=head1 GENERATED METHODS

=head2 name_accessor

Return the value/definition/name in the target lookup table, storing the whole
looup table in the cache if not already done.

B<Example>:

 print User->find($user_id)->type; # 'Administrator'

=head2 name_setter

Set the foreign key in the instance to point to the given value/definition/name.

B<Example>:

 User->find($user_id)->set_type('Guest')

=head2 name_checker

Test if the lookup value of the row instance points to the same value as the argument.

B<Example>:

 User->find($user_id)->is_type('Guest') 

Returns true if the value in the Lookup Table UserType associated with the key  User->find($user_id)->user_type_id
is equals to 'Guest'.

=cut




sub add_lookup {
    my ( $class, $relname, $foreign_key, $lookup_table, $options ) = @_;
    
 	#### add_lookup relation_name, foreign_key, lookup_table, options: $relname, $foreign_key, $lookup_table, $options
 
    # as it suggests $options is an optional argument
   	$options ||= {};
        
    my $defaults = {  
    				name_accessor => $relname,
    				name_setter   => "set_$relname",
    				name_checker  => "is_$relname",
    				field_name    => 'name',
        			}; 
    
    my $params = merge $defaults, $options;
    
    my $field_name	= $params->{field_name};
    
    my $fetch_id_by_name = sub { 
   		my ($self, $name) = @_;
   		DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME(  $self->result_source->schema, $lookup_table, $field_name, $name);
    };
    
    my $meta = Class::MOP::Class->initialize($class) or die;
        # test if not already present
        foreach my $method ( @$params{qw/name_accessor name_setter name_checker/} ) {
            confess "ERROR: method $method already defined"
                if $meta->get_method($method);
        }

        $meta->add_method( $params->{name_accessor}, sub {
            my $self = shift; # $self isa Row
            my $schema = $self->result_source->schema;
            return DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID( $schema, $lookup_table, $field_name, $self->get_column($foreign_key) );
        });
        
        
        $meta->add_method( $params->{name_setter}, sub {
            my ($self, $new_name) = @_; 
            my $schema = $self->result_source->schema;
            my $id = $fetch_id_by_name->( $self, $new_name );
            $self->set_column($foreign_key, $id);
        });
        

         $meta->add_method( $params->{name_checker}, sub {
            my ($self, $name) = @_; # $self isa Row
            my $schema = $self->result_source->schema;
            my $id = $self->get_column( $foreign_key );
            return unless defined $id;
            return $fetch_id_by_name->( $self, $name ) eq $id;
        });
}


=head1 AUTHORS

Karl Forner <karl.forner@gmail.com>

Thomas Rubattel <rubattel@cpan.org>


=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-lookupcolumn-lookupcolumncomponent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LookupColumn-LookupColumnComponent>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LookupColumn::LookupColumnComponent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LookupColumn-LookupColumnComponent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LookupColumn-LookupColumnComponent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LookupColumn-LookupColumnComponent>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LookupColumn-LookupColumnComponent/>

=back


=head1 LICENCE AND COPYRIGHT

Copyright 2012 Karl Forner and Thomas Rubattel, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms as Perl itself.

=cut

1; # End of DBIx::Class::LookupColumn::LookupColumnComponent