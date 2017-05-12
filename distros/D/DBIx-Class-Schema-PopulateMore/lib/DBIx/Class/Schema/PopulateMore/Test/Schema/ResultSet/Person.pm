package #hide from pause
 DBIx::Class::Schema::PopulateMore::Test::Schema::ResultSet::Person;

use parent 'DBIx::Class::Schema::PopulateMore::Test::Schema::ResultSet';


=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::ResultSet::Person - Person Resultset

=head1 DESCRIPTION

Resultset Methods for the Person Source

=head1 METHODS

This module defines the following methods.

=head2 older_than($int)

Only people over a given age

=cut

sub older_than
{
    my ($self, $age) = @_;
    
    return $self->search({age=>{'>'=>$age}});
}


=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
