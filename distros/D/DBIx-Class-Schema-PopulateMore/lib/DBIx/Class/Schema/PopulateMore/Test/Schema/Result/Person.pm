package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person - A Person Class

=head1 DESCRIPTION

Tests for this type of FK relationship

=head1 PACKAGE METHODS

This module defines the following package methods

=head2 table

Name of the Physical table in the database

=cut

__PACKAGE__
    ->table('person');


=head2 add_columns

Add columns and meta information

=head3 person_id

Primary Key which is an auto generated autoinc

=head3 fk_gender_id

foreign key to the Gender table

=head3 name

Just an ordinary name

=head3 age

The person's age

=head3 created

When the person was added to the database

=cut

__PACKAGE__
    ->add_columns(
        person_id => {
            data_type=>'integer',
        },
        fk_gender_id => {
            data_type=>'integer',
        },      
        name => {
            data_type=>'varchar',
            size=>32,
        },
        age => {
            data_type=>'integer',
            default_value=>25,
        },
        created => {
            data_type=>'datetime',
            default_value=>\'CURRENT_TIMESTAMP',
        });


=head2 primary_key

Sets the Primary keys for this table

=cut

__PACKAGE__
    ->set_primary_key(qw/person_id/);


=head2 friendlist

Each Person might have a resultset of friendlist 

=cut

__PACKAGE__
    ->has_many( 
        friendlist => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::FriendList',
        {'foreign.fk_person_id' => 'self.person_id'});
    

=head2 gender

This person's gender

=cut

__PACKAGE__
    ->belongs_to( gender => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Gender', { 
        'foreign.gender_id' => 'self.fk_gender_id' });
        

=head2 fanlist

A resultset of the people listing me as a friend (if any)

=cut

__PACKAGE__
    ->belongs_to( fanlist => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::FriendList', { 
        'foreign.fk_friend_id' => 'self.person_id' });


=head2 friends

A resultset of Persons who are in my FriendList

=cut

__PACKAGE__
    ->many_to_many( friends => 'friendlist', 'friendee' );
    

=head2 fans

A resultset of people that have me in their friendlist

=cut

__PACKAGE__
    ->many_to_many( fans => 'fanlist', 'befriender' );
    
    
=head2 companies_person

Each Person might have a resultset from the company_person table.  This is a
bridge table in a many-many type relationship

=cut

__PACKAGE__
    ->has_many( 
        companies_person => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::CompanyPerson',
        {'foreign.fk_person_id' => 'self.person_id'});


=head2 companies

A resultset of Companies via a resultset of connecting CompanyPersons

=cut

__PACKAGE__
    ->many_to_many( companies => 'companies_person', 'company' );
    
    
=head1 METHODS

This module defines the following methods.

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
