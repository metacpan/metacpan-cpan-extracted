package DBIx::Class::Schema::Journal;

use base qw/DBIx::Class/;

use Scalar::Util 'blessed';
use DBIx::Class::Schema::Journal::DB;
use Class::C3::Componentised ();

__PACKAGE__->mk_classdata('journal_storage_type');
__PACKAGE__->mk_classdata('journal_connection');
__PACKAGE__->mk_classdata('journal_deploy_on_connect');
__PACKAGE__->mk_classdata('journal_sources'); ## [ source names ]
__PACKAGE__->mk_classdata('journal_user'); ## [ class, field for user id ]
__PACKAGE__->mk_classdata('journal_copy_sources');
__PACKAGE__->mk_classdata('__journal_schema_prototype');
__PACKAGE__->mk_classdata('_journal_schema'); ## schema object for journal
__PACKAGE__->mk_classdata('journal_component');
__PACKAGE__->mk_classdata('journal_components');
__PACKAGE__->mk_classdata('journal_nested_changesets');
__PACKAGE__->mk_classdata('journal_prefix');

use strict;
use warnings;

our $VERSION = '0.01';

sub _journal_schema_prototype {
    my $self = shift;
    if (my $proto = $self->__journal_schema_prototype) {
          return $proto;
    }
    my $c = blessed($self)||$self;
    my $journal_schema_class = "${c}::_JOURNAL";
    Class::C3::Componentised->inject_base($journal_schema_class, 'DBIx::Class::Schema::Journal::DB');
    $journal_schema_class->load_components($self->journal_components)
        if $self->journal_components;
    my $proto = $self->__journal_schema_prototype (
        $journal_schema_class->compose_namespace( $c.'::Journal')
    );


    my $comp = $self->journal_component || "Journal";

    my $prefix = $self->journal_prefix || '';
    foreach my $audit (qw(ChangeSet ChangeLog)) {
        my $class = blessed($proto) . "::$audit";

        Class::C3::Componentised->inject_base($class, "DBIx::Class::Schema::Journal::DB::$audit");

        $class->journal_define_table(blessed($proto), $prefix);

        $proto->register_class($audit, $class);

        $self->register_class($audit, $class)
            if $self->journal_copy_sources;
    }

    ## Create auditlog+history per table
    my %j_sources = map { $_ => 1 } $self->journal_sources
       ? @{$self->journal_sources}
       : $self->sources;

    foreach my $s_name ($self->sources) {
        next unless($j_sources{$s_name});
        $self->create_journal_for($s_name => $proto);
        $self->class($s_name)->load_components($comp);
    }
    return $proto;
}

sub connection {
    my $self = shift;
    my $schema = $self->next::method(@_);

    my $journal_schema = (ref $self||$self)->_journal_schema_prototype->clone;

    if($self->journal_connection) {
        $journal_schema->storage_type($self->journal_storage_type)
            if $self->journal_storage_type;
        $journal_schema->connection(@{ $self->journal_connection });
    } else {
        $journal_schema->storage( $schema->storage );
    }

    $self->_journal_schema($journal_schema);


    if ( $self->journal_nested_changesets ) {
        $self->_journal_schema->nested_changesets(1);
        die 'FIXME nested changeset schema not yet supported... add parent_id to ChangeSet here';
    }

    $self->journal_schema_deploy()
        if $self->journal_deploy_on_connect;

    ## Set up relationship between changeset->user_id and this schema's user
    if(!@{$self->journal_user || []}) {
        #warn "No Journal User set!"; # no need to warn, user_id is useful even without a rel
        return $schema;
    }

    $self->_journal_schema->class('ChangeSet')->belongs_to('user', @{$self->journal_user});
    $self->_journal_schema->storage->disconnect();

    return $schema;
}

sub journal_schema_deploy {
    my $self = shift;

    $self->_journal_schema->deploy(@_);
}

sub create_journal_for {
    my ($self, $s_name, $journal_schema) = @_;

    my $source = $self->source($s_name);

    foreach my $audit (qw(AuditLog AuditHistory)) {
        my $audit_source = $s_name.$audit;
        my $class = blessed($journal_schema) . "::$audit_source";

        Class::C3::Componentised->inject_base($class, "DBIx::Class::Schema::Journal::DB::$audit");

        $class->journal_define_table($source, blessed($journal_schema));

        $journal_schema->register_class($audit_source, $class);

        $self->register_class($audit_source, $class)
            if $self->journal_copy_sources;
    }
}

# XXX FIXME deploy is not idempotent :-(
sub bootstrap_journal {
    my $self = shift;
    $self->journal_schema_deploy;
    $self->prepopulate_journal;
}

# copy data from original schema sources into the journal as inserts in one
# changeset, so that later deletes will not fail to be journalled.
sub prepopulate_journal {
    my $self = shift;
    my $schema = $self;

    # woah, looks like prepopulate has already run?
    return if $schema->_journal_schema->resultset('ChangeSet')->count != 0;

    # using our own overridden txn_do (see below) will create a changeset
    $schema->txn_do( sub {
        my %j_sources = map { $_ => 1 } $self->journal_sources
        ? @{$self->journal_sources}
        : $self->sources;

        my $j_schema = $self->_journal_schema;
        my $changelog_rs = $j_schema->resultset('ChangeLog');
        my $chs_id = $j_schema->current_changeset;

        foreach my $s_name ($self->sources) {
            next unless $j_sources{$s_name};

            my $from_rs = $schema->resultset($s_name);
            my @pks = $from_rs->result_source->primary_columns;
            $from_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

            my $to_rs  = $j_schema->resultset("${s_name}AuditHistory");
            my $log_rs = $j_schema->resultset("${s_name}AuditLog");

            my $page = 1;
            while (
                my @x = $from_rs->search(undef, {
                    rows => 1_000,
                    page => $page++,
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                })
            ) {
                # get some number of change log IDs to be generated for this page
                my @log_ids = map $_->id,
                   $changelog_rs->populate([
                       map +{ changeset_id => $chs_id }, (0 .. $#x)
                   ]);


                my @datas;
                for my $idx (0 .. $#x ) {
                   push @datas, {
                       create_id => $log_ids[$idx],
                       map { $_ => $x[$idx]->{$_} } @pks,
                   }
                }
                # create the audit log entries for the rows in this page
                $log_rs->populate([@datas]);

                # now populate the audit history
                $to_rs->populate([
                    map +{
                        %{$x[$_]},
                        audit_change_id => $log_ids[$_],
                    }, (0 .. $#x)
                ]);
            }
        }
    });
}

sub txn_do {
    my ($self, $user_code, @args) = @_;

    my $jschema = $self->_journal_schema;

    my $code = $user_code;

    my $current_changeset = $jschema->_current_changeset;
    if ( !$current_changeset || $self->journal_nested_changesets ) {
        my $current_changeset_ref = $jschema->_current_changeset_container;

        unless ( $current_changeset_ref ) {
            # this is a hash because scalar refs can't be localized
            $current_changeset_ref = { };
            $jschema->_current_changeset_container($current_changeset_ref);
        }

        # wrap the thunk with a new changeset creation
        $code = sub {
            my $changeset = $jschema->journal_create_changeset( parent_id => $current_changeset );
            local $current_changeset_ref->{changeset} = $changeset->id;
            $user_code->(@_);
        };

    }

    if ( $jschema->storage != $self->storage ) {
        my $inner_code = $code;
        $code = sub { $jschema->txn_do($inner_code, @_) };
    }

    return $self->next::method($code, @args);
}

sub changeset_user {
    my ($self, $userid) = @_;

    return $self->_journal_schema->current_user()
       if @_ == 1;

    $self->_journal_schema->current_user($userid);
}

sub changeset_session {
    my ($self, $sessionid) = @_;

    return $self->_journal_schema->current_session()
       if @_ == 1;

    $self->_journal_schema->current_session($sessionid);
}

1;
