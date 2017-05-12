package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result::CompanyPerson;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result::CompanyPerson - Bridge between Company and Person

=head1 DESCRIPTION

Bridge table for many to many style relationship between Company and Person.

=head1 ATTRIBUTES

This class defines the following attributes.

=head1 PACKAGE METHODS

This module defines the following package methods

=head2 table

Name of the Physical table in the database

=cut

__PACKAGE__
    ->table('company_person');


=head2 add_columns

Add columns and meta information

=head3 fk_person_id

ID of the person with a companies

=head3 fk_company_id

ID of the company with persons

=cut

__PACKAGE__
    ->add_columns(
        fk_person_id => {
            data_type=>'integer',
        },
        fk_company_id => {
            data_type=>'integer',
        },
);
        

=head2 primary_key

Sets the Primary keys for this table

=cut

__PACKAGE__
    ->set_primary_key(qw/fk_person_id fk_company_id/);
    

=head2 employee

The person that is employed by a company

=cut

__PACKAGE__
    ->belongs_to( employee => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person', {
        'foreign.person_id' => 'self.fk_person_id' });


=head2 company

The company that employees the person

=cut

__PACKAGE__
    ->belongs_to( company => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Company', { 
        'foreign.company_id' => 'self.fk_company_id' });


=head2 employment_history

each instance of a company_person has a related employment history

=cut

__PACKAGE__
    ->has_one (employment_history => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::EmploymentHistory', {
        'foreign.fk_company_id' => 'self.fk_company_id',
        'foreign.fk_person_id' => 'self.fk_person_id',
    });


=head1 METHODS

This module defines the following methods.

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
