package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Company;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Company - A Company Class

=head1 DESCRIPTION

Companies are entities people work for.  A person can work for one or more
companies.  For the purposed of making this easy (for now) we will say that
a company can exist without employees and that there is no logic preventing
a person from working for more than one company at a time.

=head1 PACKAGE METHODS

This module defines the following package methods

=head2 table

Name of the Physical table in the database

=cut

__PACKAGE__
    ->table('company');


=head2 add_columns

Add columns and meta information

=head3 company_id

Primary Key which is an auto generated autoinc

=head3 name

The company's name

=cut

__PACKAGE__
    ->add_columns(
        company_id => {
            data_type=>'integer',
        },
        name => {
            data_type=>'varchar',
            size=>64,
        });


=head2 primary_key

Sets the Primary keys for this table

=cut

__PACKAGE__
    ->set_primary_key(qw/company_id/);


=head2 company_persons

Each Company might have a resultset from the company_person table.  This is a
bridge table in a many-many type relationship

=cut

__PACKAGE__
    ->has_many( 
        company_persons => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::CompanyPerson',
        {'foreign.fk_company_id' => 'self.company_id'});
    

=head2 employees

A resultset of Persons via a resultset of connecting CompanyPersons

=cut

__PACKAGE__
    ->many_to_many( employees => 'company_persons', 'employee' );
    

=head1 METHODS

This module defines the following methods.

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
