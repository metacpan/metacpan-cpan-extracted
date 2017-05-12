package Role::Database;

use Test::More;
use Test::Roo::Role;

requires qw(_build_database _build_dbd_version);

=head1 NAME

Role::Database

=head1 DESCRIPTION

Role consumed by all database-specific roles such as SQLite and Pg to provide common functionality.

=head1 ATTRIBUTES

=head2 database

The database object. We expect a database-specific role to supply the builder.

=cut

has database => (
    is      => 'lazy',
    clearer => 1,
);

=head2 database_info

Database backend version and other interesting info (if available).  We expect a database-specific role to supply the builder.

=cut

has database_info => (
    is => 'lazy',
);

sub _build_database_info {
    return "no info";
}

=head2 dbd_version

DBD::Foo version string. We expect a database-specific role to supply the builder.

=cut

has dbd_version => (
    is => 'lazy',
);

=head2 schema_class

Defaults to Interchange6::Schema. This gives tests the normal expected schema but allows them to overload with some other test schema if desired.

=cut

has schema_class => (
    is => 'ro',
    default => 'TestVersion::Schema',
);

=head2 schema

Our connected schema,

=cut;

has schema => (
    is => 'lazy',
    clearer => 1,
);

sub _build_schema {
    my $self = shift;

    my $schema_class = $self->schema_class;
    eval "require $schema_class"
      or die "failed to require $schema_class: $@";

    my $schema =  $schema_class->connect( $self->connect_info )
      or die "failed to connect to ";
    return $schema;
}

=head1 MODIFIERS

=head2 before setup

Add diag showing DBD version info.

=cut

before setup => sub {
    my $self = shift;
    diag sprintf("using: %s DBIC %s SQLT %s",
        $self->dbd_version, $DBIx::Class::VERSION, $SQL::Translator::VERSION);
    diag "db: " . $self->database_info;
};

1;
