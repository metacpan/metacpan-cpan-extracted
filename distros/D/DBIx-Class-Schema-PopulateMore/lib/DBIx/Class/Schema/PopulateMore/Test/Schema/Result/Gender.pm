package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Gender;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Gender - A Gender Class

=head1 DESCRIPTION

Tests for this type of FK relationship

=head1 PACKAGE METHODS

This module defines the following package methods

=head2 table

Name of the Physical table in the database

=cut

__PACKAGE__
    ->table('gender');


=head2 add_columns

Add columns and meta information

=head3 gender_id

Primary Key which is an auto generated UUID

=head3 label

Text label of the gender (ie, 'male', 'female', 'transgender', etc.).

=cut

__PACKAGE__
    ->add_columns(
        gender_id => {
            data_type=>'integer',
        },
        label => {
            data_type=>'varchar',
            size=>12,
        },
    );


=head2 primary_key

Sets the Primary keys for this table

=cut

__PACKAGE__
    ->set_primary_key(qw/gender_id/);
    
    
=head2 

Marks the unique columns

=cut

__PACKAGE__
    ->add_unique_constraint('gender_label_unique' => [ qw/label/ ]);


=head2 people

A resultset of people with this gender

=cut

__PACKAGE__
    ->has_many(
        people => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person', 
        {'foreign.fk_gender_id' => 'self.gender_id'}
    );


=head1 METHODS

This module defines the following methods.

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
