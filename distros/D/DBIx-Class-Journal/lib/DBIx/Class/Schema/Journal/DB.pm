package DBIx::Class::Schema::Journal::DB;

use base 'DBIx::Class::Schema';

__PACKAGE__->mk_classdata('nested_changesets');
__PACKAGE__->mk_group_accessors( simple => 'current_user' );
__PACKAGE__->mk_group_accessors( simple => 'current_session' );
__PACKAGE__->mk_group_accessors( simple => '_current_changeset_container' );

require DBIx::Class::Schema::Journal::DB::AuditLog;
require DBIx::Class::Schema::Journal::DB::AuditHistory;
require DBIx::Class::Schema::Journal::DB::ChangeLog;
require DBIx::Class::Schema::Journal::DB::ChangeSet;

sub _current_changeset {
    my $self = shift;
    my $ref = $self->_current_changeset_container;
    $ref && $ref->{changeset};
}

# this is for localization of the current changeset
sub current_changeset {
    my ( $self, @args ) = @_;

    $self->throw_exception(
       'setting current_changeset is not supported, use txn_do to create a new changeset'
    ) if @args;

    my $id = $self->_current_changeset;

    $self->throw_exception(
       q{Can't call current_changeset outside of a transaction}
    ) unless $id;

    return $id;
}

sub journal_create_changeset {
    my ( $self, @args ) = @_;

    my %changesetdata = ( @args );

    delete $changesetdata{parent_id} unless $self->nested_changesets;

    if( defined( my $user = $self->current_user() ) ) {
        $changesetdata{user_id} = $user;
    }
    if( defined( my $session = $self->current_session() ) ) {
        $changesetdata{session_id} = $session;
    }

    ## Create a new changeset, then run $code as a transaction
    my $cs = $self->resultset('ChangeSet');

    $cs->create({ %changesetdata });
}

sub journal_create_change {
    my $self = shift;
    $self->resultset('ChangeLog')->create({
       changeset_id => $self->current_changeset
    });
}

sub journal_update_or_create_log_entry {
    my ($self, $row, @cols) = @_;

    my $s_name = $row->result_source->source_name;

    my %id = map { $_ => $row->get_column($_)} $row->primary_columns;

    $self->resultset("${s_name}AuditLog")->update_or_create({ @cols, %id });
}

sub journal_record_in_history {
    my ($self, $row, @cols) = @_;

    my $s_name = $row->result_source->source_name;

    $self->resultset("${s_name}AuditHistory")->create({ $row->get_columns, @cols });
}


1;
