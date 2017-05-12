package DBIx::DataModel::Meta;

1;

__END__

=encoding ISO8859-1

=head1 NAME

DBIx::DataModel::Meta - meta-information for DBIx::DataModel

=head1 DESCRIPTION

The family of classes in C<DBIx::DataModel::Meta> are designed
to hold meta-information about schemas, tables, joins, etc.

Under normal circumstances these classes will be mostly invisible to
L<DBIx::DataModel> users : they are used primarily for internal
needs. Instances of L<DBIx::DataModel::Meta::Schema>,
L<DBIx::DataModel::Meta::Table>, etc. are created automatically
when a new schema is populated; then the relevant information
is exposed through façade methods in L<DBIx::DataModel::Schema>,
L<DBIx::DataModel::Source::Table>, etc.

This "meta-object protocol" is specific to L<DBIx::DataModel> : it does
not use L<Moose> nor any of its alternative implementations, because
the needs here are simpler and domain-specific.

Meta-objects are accessed from ordinary objects through the C<metadm>
keyword, so as not to collide with a possible  L<Moose> integration.

=head1 METHODS

This class is empty; it merely acts as parent for all
C<DBIx::DataModel::Meta::*> subclasses.
