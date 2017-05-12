package DBIx::Class::Journal;

use base qw/DBIx::Class/;

use strict;
use warnings;

our $VERSION = '0.900201';
$VERSION = eval $VERSION; # no errors in dev versions

## On create/insert, add new entry to AuditLog and new content to AuditHistory

sub _journal_schema {
    my $self = shift;
    $self->result_source->schema->_journal_schema;
}

sub insert {
    my ($self, @args) = @_;
    return if $self->in_storage;

    my $res = $self->next::method(@args);
    $self->journal_log_insert;

    return $res;
}

sub journal_log_insert {
    my ($self) = @_;

    if ( $self->in_storage ) {
        my $j = $self->_journal_schema;
        my $change_id = $j->journal_create_change()->id;
        $j->journal_update_or_create_log_entry( $self, create_id => $change_id );
        $j->journal_record_in_history( $self, audit_change_id => $change_id );
    }
}

## On delete, update delete_id of AuditLog

sub delete {
    my $self = shift;
    my $ret = $self->next::method(@_);
    $self->journal_log_delete(@_);
    return $ret
}

sub journal_log_delete {
    my ($self) = @_;

    unless ($self->in_storage) {
        my $j = $self->_journal_schema;
        $j->journal_update_or_create_log_entry( $self, delete_id => $j->journal_create_change->id );
    }
}

## On update, copy row's new contents to AuditHistory

sub update {
    my $self = shift;
    my $ret = $self->next::method(@_);
    $self->journal_log_update(@_);
    return $ret
}

sub journal_log_update {
    my $self = shift;

    if ($self->in_storage) {
        my $j = $self->_journal_schema;
        my $change_id = $j->journal_create_change->id;
        $j->journal_record_in_history( $self, audit_change_id => $change_id );
    }
}

=head1 NAME

DBIx::Class::Journal - Auditing for tables managed by DBIx::Class

=head1 SYNOPSIS

Load the module into your L<DBIx::Class> Schema Class:

 package My::Schema;
 use base 'DBIx::Class::Schema';

 __PACKAGE__->load_components(qw/Schema::Journal/);

Optionally set where the journal is stored:

 __PACKAGE__->journal_connection(['dbi:SQLite:t/var/Audit.db']);

And then call C<< $schema->bootstrap_journal >> (I<once only>) to create all
the tables necessary for the journal, in your database.

Later on, in your application, wrap operations in transactions, and optionally
associate a user with the changeset:

 $schema->changeset_user($user->id);
 my $new_artist = $schema->txn_do( sub {
    return $schema->resultset('Artist')->create({ name => 'Fred' });
 });

=head1 DESCRIPTION

The purpose of this L<DBIx::Class> component module is to create an
audit-trail for all changes made to the data in your database (via a
DBIx::Class schema). It creates I<changesets> and assigns each
create/update/delete operation an I<id>. The creation and deletion date of
each row is stored, as well as the historical contents of any row that gets
changed.

All queries which need auditing B<must> be called using
L<DBIx::Class::Schema/txn_do>, which is used to create changesets for each
transaction.

To track who did which changes, the C<user_id> (an integer) of the current
user can be set, and a C<session_id> can also be set; both are optional. To
access the auditing schema to look at the auditdata or revert a change, use
C<< $schema->_journal_schema >>.

=head1 DEPLOYMENT

Currently the module expects to be deployed alongside a new database schema,
and track all changes from first entry. To do that you need to create some
tables in which to store the journal, and you can opitonally configure which
data sources (tables) have their operations journalled by the module.

Connect to your schema and deploy the journal tables as below. The module
automatically scans your schema and sets up storage for journal entries.

 # optional - defaults to all sources
 My::Schema->journal_sources([qw/ table1 table2 /]);

 $schema = My::Schema->connect(...);
 $schema->journal_schema_deploy;

Note that if you are retrofitting journalling to an existing database, then as
well as creating the journal you will need to populate it with a history so
that when rows are deleted they can be mapped back to a (fake) creation.

If you ever update your original schema, remember that you must then also
update the journal's schema to match, so that the AuditHistory has the
corresponding new columns in which to save data.

=head1 TABLES

The journal schema contains a number of tables. These track row creation,
update and deletion, and also are aware of multiple operations taking place
within one transaction.

=over 4

=item ChangeSet

Each changeset row has an auto-incremented C<ID>, optional C<user_id> and
C<session_id>, and a C<set_date> which defaults to the current datetime. This
is the authoritative log of one discrete change to your database, which may
possible consist of a number of ChangeLog operations within a single
transaction.

=item ChangeLog

Each operation done within the transaction is recorded as a row in the
ChangeLog table. It contains an auto-incrementing C<ID>, the C<changeset_id>
and an C<order> column to establish the order in which changes took place.

=item AuditLog

For every table in the original database that is to be audited, an AuditLog
table is created. When a row appears in the original database a corresponding
row is added here with a ChangeLog ID in the C<create_id> column, and when
that original row is deleted the AuditLog is updated to add another ChangeLog
ID this time into the C<delete_id> column. A third id column contains the
primary key of the original row, so you can find it in the AuditHistory.

Note that currently only integer-based single column primary keys are
supported in your original database tables.

=item AuditHistory

For every table in the original database to be audited, an AuditHistory table
is created. This is where the actual field data from your original table rows
are stored on creation and on each update.

Each row in the AuditHistory has a C<change_id> field containing the ID of the
ChangeLog row. The other fields correspond to all the fields from the original
table (with any constraints removed). Each time a column value in the original
table is changed, the entire row contents after the change are added as a new
row in this table.

=back

=head1 CLASS METHODS

Call these in your Schema Class such as the C<My::Schema> package file, as in
the SYNOPSIS, above.

=over 4

=item journal_connection \@connect_info

Set the connection information for the database to save your audit information
to.

Leaving this blank assumes you want to store the audit data into your current
database. The storage object will be shared by the regular schema and the
journalling schema.

=item journal_components @components

If you want to add components to your journal
(L<DBIx::Class::Schema::Versioned> for example) pass them here.

=item journal_sources \@source_names

Set a list of source names you would like to audit. If unset, all sources are
used.

NOTE: Currently only sources with a single-column integer PK are supported, so
use this method if you have sources which don't comply with that limitation.

=item journal_storage_type $type

Enter the special storage type of your journal schema if needed. See
L<DBIx::Class::Storage::DBI> for more information on storage types.

=item journal_user \@rel

The user_id column in the L</ChangeSet> will be linked to your user id with a
C<belongs_to> relation, if this is set with the appropriate arguments. For
example:

 __PACKAGE__->journal_user(['My::Schema::User', {'foreign.userid' => 'self.user_id'}]);

=back

=head1 OBJECT METHODS

Once you have a connection to your database, call these methods to manage the
journalling.

=over 4

=item bootstrap_journal

This calls C<journal_schema_deploy> followed by C<prepopulate_journal> to
create your journal tables and if necessary populate them with a snapshot of
your current original schema data.

Do not run this method more than once on your database, as redeploying the
journal schema is not supported.

=item journal_schema_deploy

Will use L<DBIx::Class::Schema/deploy> to set up the tables for journalling in
your schema. Use this method to set up your journal.

Note that if you are retrofitting journalling to an existing database, then as
well as creating the journal you will need to populate it with a history so
that when rows are deleted they can be mapped back to a (fake) creation.

Do not run this method more than once on your database, as redeploying the
journal schema is not supported.

=item prepopulate_journal

Will load the current state of your original source tables into the audit
history as fake inserts in a single initial changeset. The advantage to this
is that later deletetions of the row will be consistent in the journal with an
initial state.

Note that this can be an intensive and time consuming task, depending on how
much data you have in your original sources; all of it will be copied to the
journal history. However this step is essential if you are retrofitting
Journalling to a schema with existing data, otherwise when you delete a row
the Journal will die because it cannot relate that to an initial row insert.

=item changeset_user $user_id

Set the C<user_id> for the following changeset(s). This must be an integer.

=item changeset_session $session_id

Set the C<session_id> for the following changeset(s). This must be an integer.

=item deploy

Overloaded L<DBIx::Class::Schema/deploy> which will deploy your original
database schema and following that will deploy the journal schema.

=item txn_do $code_ref, @args

Overloaded L<DBIx::Class::Schema/txn_do>, this must be used to start a new
ChangeSet to cover a group of changes. Each subsequent change to an audited
table will use the C<changeset_id> created in the most recent C<txn_do> call.

Currently nested C<txn_do> calls cause a single ChangeSet object to be created.

=back

=head2 Deprecated Methods

=over 4

=item journal_deploy_on_connect $bool

If set to a true value will cause C<journal_schema_deploy> to be called on
C<connect>. Not recommended (because re-deploy of a schema is not supported),
but present for backwards compatibility.

=back

=head1 TROUBLESHOOTING

For PostgreSQL databases you must enable quoting on SQL command generation by
passing C<< { quote_char => q{`}, name_sep => q{.} } >> when connecting to the
database.

=head1 SEE ALSO

=over 4

=item *

L<DBIx::Class> - You'll need it to use this.

=back

=head1 LIMITATIONS

=over 4

=item *

Only single-column integer primary key'd tables are supported for auditing.

=item *

Rows changed as a result of C<CASCADE> settings on your database will not be
detected by the module and hence not journalled.

=item *

Updates made via L<DBIx::Class::ResultSet/update> are not yet supported.

=item *

No API for viewing or restoring changes yet.

=back

Patches for the above are welcome ;-)

=head1 AUTHOR

Jess Robinson <castaway@desert-island.me.uk>

Matt S. Trout <mst@shadowcatsystems.co.uk> (ideas and prodding)

=head1 LICENCE

You may distribute this code under the same terms as Perl itself.

=cut

1;
