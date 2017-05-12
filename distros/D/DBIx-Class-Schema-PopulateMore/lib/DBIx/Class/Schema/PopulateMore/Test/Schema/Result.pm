package # hide from PAUSE
 DBIx::Class::Schema::PopulateMore::Test::Schema::Result;
 
use parent 'DBIx::Class::Core';
       
=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema::Result - A base result class

=head1 DESCRIPTION

Defines the base case for loading DBIC Schemas.  We add in some additional
helpful functions for administering you schemas.

=head1 PACKAGE METHODS

The following is a list of package methods declared with this class.

=head2 load_components

Components to preload.

=cut

__PACKAGE__->load_components(qw/ 
    PK::Auto 
    InflateColumn::DateTime
/);


=head1 METHODS

This module declares the following methods.

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut


1;
