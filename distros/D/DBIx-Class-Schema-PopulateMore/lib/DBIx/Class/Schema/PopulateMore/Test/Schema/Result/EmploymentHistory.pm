package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result::EmploymentHistory;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result::EmploymentHistory - Information about a Persons as an Employee;

=head1 DESCRIPTION

Additional Information about a person when working for a company

=head1 ATTRIBUTES

This class defines the following attributes.

=head1 PACKAGE METHODS

This module defines the following package methods

=head2 table

Name of the Physical table in the database

=cut

__PACKAGE__
    ->table('employment_history');


=head2 add_columns

Add columns and meta information

=head3 fk_person_id, fk_company_id

two fields making up a key to the CompanyPerson

=head3 started

The date we started working for the company

=cut

__PACKAGE__
    ->add_columns(
        employment_history_id => {
            data_type=>'integer',
        },
        fk_person_id => {
            data_type=>'integer',
        },
        fk_company_id => {
            data_type=>'integer',
        },
        started => {
            data_type=>'datetime',
            default_value=>\'CURRENT_TIMESTAMP',
        });


=head2 primary_key

Sets the Primary keys for this table

=cut

__PACKAGE__
    ->set_primary_key(qw/employment_history_id/);
    

=head2 employment_history

each instance of a company_person has a related employment history

=cut

__PACKAGE__
    ->belongs_to (company_person => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::CompanyPerson', {
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
