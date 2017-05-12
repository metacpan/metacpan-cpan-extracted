package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result::FriendList;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result';

=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result::FriendList - An example Friends Class;

=head1 DESCRIPTION

Probably not the best way to do a friend list relationship.

=head1 ATTRIBUTES

This class defines the following attributes.

=head1 PACKAGE METHODS

This module defines the following package methods

=head2 table

Name of the Physical table in the database

=cut

__PACKAGE__
    ->table('friend_list');


=head2 add_columns

Add columns and meta information

=head3 fk_person_id

ID of the person with friends

=head3 fk_friend_id

Who is the friend?

=cut

__PACKAGE__
    ->add_columns(
        fk_person_id => {
            data_type=>'integer',
        },
        fk_friend_id => {
            data_type=>'integer',
        },
);
        

=head2 primary_key

Sets the Primary keys for this table

=cut

__PACKAGE__
    ->set_primary_key(qw/fk_person_id fk_friend_id/);
    

=head2 befriender

The person that 'owns' the friendship (list)

=cut

__PACKAGE__
    ->belongs_to( befriender => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person', {
        'foreign.person_id' => 'self.fk_person_id' });


=head2 friendee

The actual friend that befriender is listing

=cut

__PACKAGE__
    ->belongs_to( friendee => 'DBIx::Class::Schema::PopulateMore::Test::Schema::Result::Person', { 
        'foreign.person_id' => 'self.fk_friend_id' });


=head1 METHODS

This module defines the following methods.

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
