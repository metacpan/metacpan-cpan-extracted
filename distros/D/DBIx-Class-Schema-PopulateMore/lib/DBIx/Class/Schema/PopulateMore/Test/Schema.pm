package # hide from PAUSE
 DBIx::Class::Schema::PopulateMore::Test::Schema;

use Path::Class;
use parent 'DBIx::Class::Schema';


=head1 NAME

DBIx::Class::Schema::PopulateMore::Test::Schema; Test Schema

=head1 DESCRIPTION

Defines the base case for loading DBIC Schemas.  This schema currently defines
three sources, Person, FriendList, and Gender

=head1 PACKAGE METHODS

The following is a list of package methods declared with this class.

=head2 load_components

Load the components

=cut

__PACKAGE__->load_components(qw/ 
    Schema::PopulateMore 
/);


=head2 load_namespaces

Automatically load the classes and resultsets from their default namespaces.

=cut

__PACKAGE__->load_namespaces(
    default_resultset_class => 'ResultSet',
);


=head1 ATTRIBUTES

This class defines the following attributes.

=head1 METHODS

This module declares the following methods

=head2 connect_and_setup

Creates a schema, deploys a database and sets the testing data.  By default we
use a L<DBD::SQLite> database created 

=cut

sub connect_and_setup {
    my $class = shift @_;
    
    my ($dsn, $user, $pass) = (
      $ENV{DBIC_POPULATE_DSN} || $class->default_dsn,
      $ENV{DBIC_POPULATE_USER} || '',
      $ENV{DBIC_POPULATE_PASS} || '',
    );
    
    return $class
        ->connect($dsn, $user, $pass, { AutoCommit => 1 })
        ->setup;
}

=head2 default_dsn

returns a dsn string, suitable for passing to L<DBD::SQLite>, creating the
database as a temporary file.

=cut

sub default_dsn
{
    return "dbi:SQLite:dbname=:memory:";
}

=head2 setup

deploy a database and populate it with the initial data

=cut

sub setup {
    my $self = shift @_;
    $self->deploy();
    return $self;
}

=head2 cleanup

cleanup any temporary files

=cut

sub cleanup {
    my $self = shift @_;
}

sub DESTROY {
    (shift)->cleanup;
}

=head1 AUTHOR

Please see L<DBIx::Class::Schema::PopulateMore> For authorship information

=head1 LICENSE

Please see L<DBIx::Class::Schema::PopulateMore> For licensing terms.

=cut



1;
