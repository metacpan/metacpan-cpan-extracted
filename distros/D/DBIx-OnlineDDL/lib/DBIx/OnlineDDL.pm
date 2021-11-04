package DBIx::OnlineDDL;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: Run DDL on online databases safely
use version;
our $VERSION = 'v0.940.0'; # VERSION

use v5.10;
use Moo;
use MooX::StrictConstructor;

use Types::Standard        qw( Str Bool HashRef CodeRef InstanceOf Dict Optional );
use Types::Common::Numeric qw( PositiveNum PositiveInt );

use Class::Load;
use DBI::Const::GetInfoType;
use DBIx::BatchChunker 0.92;  # with stmt attrs
use Eval::Reversible;
use List::Util        1.44 (qw( uniq any all first ));  # 1.44 has uniq
use Sub::Util               qw( subname set_subname );
use Term::ProgressBar 2.14;   # with silent option

# Don't export the above, but don't conflict with StrictConstructor, either
use namespace::clean -except => [qw< new meta >];

my $DEFAULT_MAX_ATTEMPTS = 20;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod     use DBIx::OnlineDDL;
#pod     use DBIx::BatchChunker;
#pod
#pod     DBIx::OnlineDDL->construct_and_execute(
#pod         rsrc          => $dbic_schema->source('Account'),
#pod         ### OR ###
#pod         dbi_connector => $dbix_connector_retry_object,
#pod         table_name    => 'accounts',
#pod
#pod         coderef_hooks => {
#pod             # This is the phase where the DDL is actually run
#pod             before_triggers => \&drop_foobar,
#pod
#pod             # Run other operations right before the swap
#pod             before_swap => \&delete_deprecated_accounts,
#pod         },
#pod
#pod         process_name => 'Dropping foobar from accounts',
#pod
#pod         copy_opts => {
#pod             chunk_size => 5000,
#pod             debug => 1,
#pod         },
#pod     );
#pod
#pod     sub drop_foobar {
#pod         my $oddl  = shift;
#pod         my $name  = $oddl->new_table_name;
#pod         my $qname = $oddl->dbh->quote_identifier($name);
#pod
#pod         # Drop the 'foobar' column, since it is no longer used
#pod         $oddl->dbh_runner_do("ALTER TABLE $qname DROP COLUMN foobar");
#pod     }
#pod
#pod     sub delete_deprecated_accounts {
#pod         my $oddl = shift;
#pod         my $name = $oddl->new_table_name;
#pod         my $dbh  = $oddl->dbh;  # only use for quoting!
#pod
#pod         my $qname = $dbh->quote_identifier($name);
#pod
#pod         DBIx::BatchChunker->construct_and_execute(
#pod             chunk_size  => 5000,
#pod
#pod             debug => 1,
#pod
#pod             process_name     => 'Deleting deprecated accounts',
#pod             process_past_max => 1,
#pod
#pod             dbic_storage => $oddl->rsrc->storage,
#pod             min_stmt => "SELECT MIN(account_id) FROM $qname",
#pod             max_stmt => "SELECT MAX(account_id) FROM $qname",
#pod             stmt     => join("\n",
#pod                 "DELETE FROM $qname",
#pod                 "WHERE",
#pod                 "    account_type = ".$dbh->quote('deprecated')." AND",
#pod                 "    account_id BETWEEN ? AND ?",
#pod             ),
#pod         );
#pod     }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is a database utility class for running DDL operations (like C<ALTER TABLE>) safely
#pod on large tables.  It has a similar scope as L<DBIx::BatchChunker>, but is designed for
#pod DDL, rather than DML.  It also has a similar function to other utilities like
#pod L<pt-online-schema-change|https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html> or
#pod L<gh-ost|https://github.com/github/gh-ost>, but actually works properly with foreign
#pod keys, and is written as a Perl module to hook directly into a DBI handle.
#pod
#pod Like most online schema change tools, this works by creating a new shell table that looks
#pod just like the old table, running the DDL changes (through the L</before_triggers> hook),
#pod copying data to the new table, and swapping the tables.  Triggers are created to keep the
#pod data in sync.  See L</STEP METHODS> for more information.
#pod
#pod The full operation is protected with an L<undo stack|/reversible> via L<Eval::Reversible>.
#pod If any step in the process fails, the undo stack is run to return the DB back to normal.
#pod
#pod This module uses as many of the DBI info methods as possible, along with ANSI SQL in most
#pod places, to be compatible with multiple RDBMS.  So far, it will work with MySQL or SQLite,
#pod but can be expanded to include more systems with a relatively small amount of code
#pod changes.  (See L<DBIx::OnlineDDL::Helper::Base> for details.)
#pod
#pod B<DISCLAIMER:> You should not rely on this class to magically fix any and all locking
#pod problems the DB might experience just because it's being used.  Thorough testing and
#pod best practices are still required.
#pod
#pod =head2 When you shouldn't use this module
#pod
#pod =head3 Online DDL is already available in the RDBMS
#pod
#pod If you're running MySQL 5.6+ without clustering, just use C<LOCK=NONE> for every DDL
#pod statement.  It is seriously simple and guarantees that the table changes you make are not
#pod going to lock the table, or it will fail right away to tell you it's an incompatible
#pod change.
#pod
#pod If you're running something like Galera clusters, this typically wouldn't be an option,
#pod as it would lock up the clusters while the C<ALTER TABLE> statement is running, despite
#pod the C<LOCK=NONE> statement.  (Galera clusters were the prime motivation for writing this
#pod module.)
#pod
#pod Other RDBMSs may have support for online DDL as well.  Check the documentation first.  If
#pod they don't, patches for this tool are welcome!
#pod
#pod =head3 The operation is small
#pod
#pod Does your DDL only take 2 seconds?  Just do it!  Don't bother with trying to swap tables
#pod around, wasting time with full table copies, etc.  It's not worth the time spent or risk.
#pod
#pod =head3 When you actually want to run DML, not DDL
#pod
#pod L<DBIx::BatchChunker> is more appropriate for running DML operations (like C<INSERT>,
#pod C<UPDATE>, C<DELETE>).  If you need to do both, you can use the L</before_triggers> hook
#pod for DDL, and the L</before_swap> hook for DML.  Or just run DBIx::BatchChunker after the
#pod OnlineDDL process is complete.
#pod
#pod =head3 Other online schema change tools fit your needs
#pod
#pod Don't have foreign key constraints and C<gh-ost> is already working for you?  Great!
#pod Keep using it.
#pod
#pod =head1 ATTRIBUTES
#pod
#pod =head2 DBIC Attributes
#pod
#pod =head3 rsrc
#pod
#pod A L<DBIx::Class::ResultSource>.  This will be the source used for all operations, DDL or
#pod otherwise.  Optional, but recommended for DBIC users.
#pod
#pod The DBIC storage handler's C<connect_info> will be tweaked to ensure sane defaults and
#pod proper post-connection details.
#pod
#pod =cut

has rsrc => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::ResultSource'],
    required => 0,
);

#pod =head3 dbic_retry_opts
#pod
#pod A hashref of DBIC retry options.  These options control how retry protection works within
#pod DBIC.  Right now, this is just limited to C<max_attempts>, which controls the number of
#pod times to retry.  The default C<max_attempts> is 20.
#pod
#pod =cut

has dbic_retry_opts => (
    is       => 'ro',
    isa      => HashRef,
    required => 0,
    default  => sub { {} },
);

#pod =head2 DBI Attributes
#pod
#pod =head3 dbi_connector
#pod
#pod A L<DBIx::Connector::Retry> object.  Instead of L<DBI> statement handles, this is the
#pod recommended non-DBIC way for OnlineDDL (and BatchChunker) to interface with the DBI, as
#pod it handles retries on failures.  The connection mode used is whatever default is set
#pod within the object.
#pod
#pod Required, except for DBIC users, who should be setting L</rsrc> above.  It is also
#pod assumed that the correct database is already active.
#pod
#pod The object will be tweaked to ensure sane defaults, proper post-connection details, a
#pod custom C<retry_handler>, and set a default C<max_attempts> of 20, if not already set.
#pod
#pod =cut

has dbi_connector => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Connector::Retry'],
    required => 0,
);

#pod =head3 table_name
#pod
#pod The table name to be copied and eventually replaced.  Required unless L</rsrc> is
#pod specified.
#pod
#pod =cut

has table_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    lazy     => 1,
    default  => sub {
        my $rsrc = shift->rsrc // return;
        $rsrc->from;
    },
);

#pod =head3 new_table_name
#pod
#pod The new table name to be created, copied to, and eventually used as the final table.
#pod Optional.
#pod
#pod If not defined, a name will be created automatically.  This might be the better route,
#pod since the default builder will search for an unused name in the DB right before OnlineDDL
#pod needs it.
#pod
#pod =cut

has new_table_name => (
    is       => 'ro',
    isa      => Str,
    required => 0,
    lazy     => 1,
    builder  => 1,
);

sub _build_new_table_name {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $catalog         = $vars->{catalog};
    my $schema          = $vars->{schema};
    my $orig_table_name = $self->table_name;

    my $escape = $dbh->get_info( $GetInfoType{SQL_SEARCH_PATTERN_ESCAPE} ) // '\\';

    return $self->_find_new_identifier(
        "_${orig_table_name}_new" => set_subname('_new_table_name_finder', sub {
            $dbh = shift;
            my $like_expr = shift;
            $like_expr =~ s/([_%])/$escape$1/g;

            $dbh->table_info($catalog, $schema, $like_expr)->fetchrow_array;
        }),
        'SQL_MAXIMUM_TABLE_NAME_LENGTH',
    );
}

#pod =head2 Progress Bar Attributes
#pod
#pod =head3 progress_bar
#pod
#pod The progress bar used for most of the process.  A different one is used for the actual
#pod table copy with L<DBIx::BatchChunker>, since that step takes longer.
#pod
#pod Optional.  If the progress bar isn't specified, a default one will be created.  If the
#pod terminal isn't interactive, the default L<Term::ProgressBar> will be set to C<silent> to
#pod naturally skip the output.
#pod
#pod =cut

has progress_bar => (
    is       => 'rw',
    isa      => InstanceOf['Term::ProgressBar'],
);

sub _progress_bar_setup {
    my $self = shift;
    my $vars = $self->_vars;

    my $steps = 6 + scalar keys %{ $self->coderef_hooks };

    my $progress = $self->progress_bar || Term::ProgressBar->new({
        name   => $self->progress_name,
        count  => $steps,
        ETA    => 'linear',
        silent => !(-t *STDERR && -t *STDIN),  # STDERR is what {fh} is set to use
    });

    $vars->{progress_bar} = $progress;
}

#pod =head3 progress_name
#pod
#pod A string used to assist in creating a progress bar.  Ignored if L</progress_bar> is
#pod already specified.
#pod
#pod This is the preferred way of customizing the progress bar without having to create one
#pod from scratch.
#pod
#pod =cut

has progress_name => (
    is       => 'rw',
    isa      => Str,
    required => 0,
    lazy     => 1,
    default  => sub {
        my $table_name = shift->table_name;
        'Altering'.($table_name ? " $table_name" : '');
    },
);

#pod =head2 Other Attributes
#pod
#pod =head3 coderef_hooks
#pod
#pod A hashref of coderefs.  Each of these are used in different steps in the process.  All
#pod of these are optional, but it is B<highly recommended> that C<before_triggers> is
#pod specified.  Otherwise, you're not actually running any DDL and the table copy is
#pod essentially a no-op.
#pod
#pod All of these triggers pass the C<DBIx::OnlineDDL> object as the only argument.  The
#pod L</new_table_name> can be acquired from that and used in SQL statements.  The L</dbh_runner>
#pod and L</dbh_runner_do> methods should be used to protect against disconnections or locks.
#pod
#pod There is room to add more hooks here, but only if there's a good reason to do so.
#pod (Running the wrong kind of SQL at the wrong time could be dangerous.)  Create a GitHub
#pod issue if you can think of one.
#pod
#pod =head4 before_triggers
#pod
#pod This is called before the table triggers are applied.  Your DDL should take place here,
#pod for a few reasons:
#pod
#pod     1. The table is empty, so DDL should take no time at all now.
#pod
#pod     2. After this hook, the table is reanalyzed to make sure it has an accurate picture
#pod     of the new columns.  This is critical for the creation of the triggers.
#pod
#pod =head4 before_swap
#pod
#pod This is called after the new table has been analyzed, but before the big table swap.  This
#pod hook might be used if a large DML operation needs to be done while the new table is still
#pod available.  If you use this hook, it's highly recommended that you use something like
#pod L<DBIx::BatchChunker> to make sure the changes are made in a safe and batched manner.
#pod
#pod =cut

has coderef_hooks => (
    is       => 'ro',
    isa      => Dict[
        before_triggers => Optional[CodeRef],
        before_swap     => Optional[CodeRef],
    ],
    required => 0,
    default  => sub { +{} },
);

#pod =head3 copy_opts
#pod
#pod A hashref of different options to pass to L<DBIx::BatchChunker>, which is used in the
#pod L</copy_rows> step.  Some of these are defined automatically.  It's recommended that you
#pod specify at least these options:
#pod
#pod     chunk_size  => 5000,     # or whatever is a reasonable size for that table
#pod     id_name     => 'pk_id',  # especially if there isn't an obvious integer PK
#pod
#pod Specifying L<DBIx::BatchChunker/coderef> is not recommended, since Active DBI Processing
#pod mode will be used.
#pod
#pod These options will be included into the hashref, unless specifically overridden by key
#pod name:
#pod
#pod     id_name      => $first_pk_column,  # will warn if the PK is multi-column
#pod     target_time  => 1,
#pod     sleep        => 0.5,
#pod
#pod     # If using DBIC
#pod     dbic_storage => $rsrc->storage,
#pod     rsc          => $id_rsc,
#pod     dbic_retry_opts => {
#pod         max_attempts  => 20,
#pod         # best not to change this, unless you know what you're doing
#pod         retry_handler => $onlineddl_retry_handler,
#pod     },
#pod
#pod     # If using DBI
#pod     dbi_connector => $oddl->dbi_connector,
#pod     min_stmt      => $min_sql,
#pod     max_stmt      => $max_sql,
#pod
#pod     # For both
#pod     count_stmt    => $count_sql,
#pod     stmt          => $insert_select_sql,
#pod     progress_name => $copying_msg,
#pod
#pod =cut

has copy_opts => (
    is       => 'ro',
    isa      => HashRef,
    required => 0,
    lazy     => 1,
    default  => sub { {} },
);

# This is filled in during copy_rows, since the _column_list call needs to happen after
# the DDL has run.
sub _fill_copy_opts {
    my $self = shift;
    my $rsrc = $self->rsrc;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $copy_opts = $self->copy_opts;
    my $helper    = $self->_helper;

    my $catalog         = $vars->{catalog};
    my $schema          = $vars->{schema};
    my $orig_table_name = $self->table_name;
    my $new_table_name  = $self->new_table_name;

    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);

    # Sane defaults for timing
    $copy_opts->{target_time} //= 1;
    # Copies create lots of rapid I/O, binlog generation, etc. on the primary.
    # Some sleep time gives other servers a chance to catch up:
    $copy_opts->{sleep}       //= 0.5;

    # Figure out what the id_name is going to be
    my $id_name = $copy_opts->{id_name} //= $self->dbh_runner(run => set_subname '_pk_finder', sub {
        $dbh = $_;
        my @ids = $dbh->primary_key($catalog, $schema, $orig_table_name);

        die  "No primary key found for $orig_table_name"                                 unless @ids;
        warn "Using the first column of a multi-column primary key for $orig_table_name" if @ids > 1;

        $ids[0];
    });

    my $id_name_quote = $dbh->quote_identifier($id_name);

    if ($rsrc) {
        $copy_opts->{dbic_storage} //= $rsrc->storage;
        $copy_opts->{rsc} //= $rsrc->resultset->get_column($id_name);

        $copy_opts->{dbic_retry_opts} //= {};
        $copy_opts->{dbic_retry_opts}{max_attempts}  //= $DEFAULT_MAX_ATTEMPTS;
        $copy_opts->{dbic_retry_opts}{retry_handler}   = sub { $self->_retry_handler(@_) };
    }
    else {
        $copy_opts->{dbi_connector} //= $self->dbi_connector;
        $copy_opts->{min_stmt} //= "SELECT MIN($id_name_quote) FROM $orig_table_name_quote";
        $copy_opts->{max_stmt} //= "SELECT MAX($id_name_quote) FROM $orig_table_name_quote";
    }

    my @column_list = $self->_column_list;
    my $column_list_str = join(', ', map { $dbh->quote_identifier($_) } @column_list );

    # The INSERT..SELECT is a bit different depending on the RDBMS used, mostly because
    # of the IGNORE part
    my $insert_select_stmt = $helper->insert_select_stmt($column_list_str);

    $copy_opts->{count_stmt} //= "SELECT COUNT(*) FROM $orig_table_name_quote WHERE $id_name_quote BETWEEN ? AND ?";
    $copy_opts->{stmt}       //= $insert_select_stmt;

    $copy_opts->{progress_name} //= "Copying $orig_table_name" unless $copy_opts->{progress_bar};

    return $copy_opts;
}

#pod =head3 db_timeouts
#pod
#pod A hashref of timeouts used for various DB operations, and usually set at the beginning of
#pod each connection.  Some of these settings may be RDBMS-specific.
#pod
#pod =head4 lock_file
#pod
#pod Amount of time (in seconds) to wait when attempting to acquire filesystem locks (on
#pod filesystems which support locking).  Float or fractional values are allowed.  This
#pod currently only applies to SQLite.
#pod
#pod Default value is 1 second.  The downside is that the SQLite default is actually 0, so
#pod other (non-OnlineDDL) connections should have a setting that is more than that to prevent
#pod lock contention.
#pod
#pod =head4 lock_db
#pod
#pod Amount of time (in whole seconds) to wait when attempting to acquire table and/or database
#pod level locks before falling back to retry.
#pod
#pod Default value is 60 seconds.
#pod
#pod =head4 lock_row
#pod
#pod Amount of time (in whole seconds) to wait when attempting to acquire row-level locks,
#pod which apply to much lower-level operations than L</lock_db>.  At this scope, the lesser
#pod of either of these two settings will take precedence.
#pod
#pod Default value is 2 seconds.  Lower values are preferred for row lock wait timeouts, so
#pod that OnlineDDL is more likely to be the victim of lock contention.  OnlineDDL can simply
#pod retry the connection at that point.
#pod
#pod =head4 session
#pod
#pod Amount of time (in whole seconds) for inactive session timeouts on the database side.
#pod
#pod Default value is 28,800 seconds (8 hours), which is MySQL's default.
#pod
#pod =cut

has db_timeouts => (
    is       => 'ro',
    isa      => Dict[
        lock_file => Optional[PositiveNum],
        lock_db   => Optional[PositiveInt],
        lock_row  => Optional[PositiveInt],
        session   => Optional[PositiveInt],
    ],
    required => 0,
);

#pod =head3 reversible
#pod
#pod A L<Eval::Reversible> object, used for rollbacks.  A default will be created, if not
#pod specified.
#pod
#pod =cut

has reversible => (
    is       => 'rw',
    isa      => InstanceOf['Eval::Reversible'],
    required => 1,
    lazy     => 1,
    default  => sub { Eval::Reversible->new },
);

### Private attributes

has _vars => (
    is       => 'rw',
    isa      => HashRef,
    required => 0,
    init_arg => undef,
    lazy     => 1,
    default  => sub { {} },
);

has _helper => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::OnlineDDL::Helper::Base'],
    required => 0,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_helper',
);

sub _build_helper {
    my $self = shift;

    my $dbh = $self->dbh;

    # Get and store the DBMS_NAME.  This is not the lowercase driver name (ie: mysql),
    # unless the {Driver}{Name} alternative wins out.
    my $dbms_name = $self->_vars->{dbms_name} = $dbh->get_info( $GetInfoType{SQL_DBMS_NAME} ) // $dbh->{Driver}->{Name};

    my $helper_class = "DBIx::OnlineDDL::Helper::$dbms_name";

    # Die if we can't load the RDBMS-specific class, since there's a lot of gaps in Base
    die "OnlineDDL is not designed for $dbms_name systems yet!" unless Class::Load::load_optional_class($helper_class);

    return $helper_class->new( online_ddl => $self );
}

### BUILD methods

around BUILDARGS => sub {
    my $next  = shift;
    my $class = shift;

    my %args = @_ == 1 ? %{ $_[0] } : @_;

    # Quick sanity checks
    die 'A DBIC ResultSource (rsrc) or DBIx::Connector::Retry object (dbi_connector) is required' unless (
        $args{rsrc} || $args{dbi_connector}
    );

    # Defaults for db_timeouts (see POD above).  We set these here, because each
    # individual timeout should be checked to see if it's defined.
    $args{db_timeouts} //= {};
    $args{db_timeouts}{lock_file} //= 1;
    $args{db_timeouts}{lock_db}   //= 60;
    $args{db_timeouts}{lock_row}  //= 2;
    $args{db_timeouts}{session}   //= 28_800;

    $class->$next( %args );
};

sub BUILD {
    my $self = shift;
    my $rsrc = $self->rsrc;

    my $dbh    = $self->dbh;
    my $helper = $self->_helper;

    # Get the current catalog/schema
    my ($catalog, $schema) = $helper->current_catalog_schema;

    $self->_vars->{catalog} = $catalog;
    $self->_vars->{schema}  = $schema;

    # Add in the post-connection details
    my @stmts = $helper->post_connection_stmts;

    if ($rsrc) {
        ### DBIC Storage

        my @post_connection_details = map { [ do_sql => $_ ] } @stmts;

        # XXX: Tapping into a private attribute here, but it's a lot better than parsing
        # $storage->connect_info.  We are also not attaching these details to
        # connect_info, so public introspection won't pick up our changes.  Undecided
        # whether this is good or bad...

        my $storage         = $rsrc->storage;
        my $on_connect_call = $storage->_dbic_connect_attributes->{on_connect_call};

        # Parse on_connect_call to make sure we can add to it
        my $ref = defined $on_connect_call && ref $on_connect_call;
        unless ($on_connect_call) {
            $on_connect_call = \@post_connection_details;
        }
        elsif  (!$ref) {
            $on_connect_call = [ [ do_sql => $on_connect_call ], @post_connection_details ];
        }
        elsif  ($ref eq 'ARRAY') {
            # Double-check that we're not repeating ourselves by inspecting the array for
            # our own statements.
            @$on_connect_call = grep {
                my $e = $_;
                !(  # exclude any of ours
                    $e && ref $e && ref $e eq 'ARRAY' && @$e == 2 &&
                    $e->[0] && !ref $e->[0] && $e->[0] eq 'do_sql' &&
                    $e->[1] && !ref $e->[1] && (any { $e->[1] eq $_ } @stmts)
                );
            } @$on_connect_call;

            my $first_occ = $on_connect_call->[0];
            if ($first_occ && ref $first_occ && ref $first_occ eq 'ARRAY') {
                $on_connect_call = [ @$on_connect_call, @post_connection_details ];
            }
            else {
                $on_connect_call = [ $on_connect_call, @post_connection_details ];
            }
        }
        elsif  ($ref eq 'CODE') {
            $on_connect_call = [ $on_connect_call, @post_connection_details ];
        }
        else {
            die "Illegal reftype $ref for on_connect_call connection attribute!";
        }

        # Set the new options on the relevant attributes that Storage::DBI->connect_info touches.
        $storage->_dbic_connect_attributes->{on_connect_call} = $on_connect_call;
        $storage->on_connect_call($on_connect_call);
    }
    else {
        ### DBIx::Connector::Retry (via DBI Callbacks)

        my $conn      = $self->dbi_connector;
        my $dbi_attrs = $conn->connect_info->[3];

        # Playing with refs, so no need to re-set connect_info
        $conn->connect_info->[3] = $dbi_attrs = {} unless $dbi_attrs;

        # Make sure the basic settings are sane
        $dbi_attrs->{AutoCommit} = 1;
        $dbi_attrs->{RaiseError} = 1;

        # Add the DBI callback
        my $callbacks  = $dbi_attrs->{Callbacks} //= {};
        my $package_re = quotemeta(__PACKAGE__.'::_dbi_connected_callback');

        my $ref = defined $callbacks->{connected} && ref $callbacks->{connected};
        unless ($callbacks->{connected}) {
            $callbacks->{connected} = set_subname '_dbi_connected_callback' => sub {
                shift->do($_) for @stmts;
                return;
            };
        }
        elsif (!$ref || $ref ne 'CODE') {
            die "Illegal reftype $ref for connected DBI Callback!";
        }
        elsif (subname($callbacks->{connected}) =~ /^$package_re/) {  # allow for *_wrapped below
            # This is one of our callbacks; leave it alone!
        }
        else {
            # This is somebody else's callback; wrap around it
            my $old_coderef = $callbacks->{connected};
            $callbacks->{connected} = set_subname '_dbi_connected_callback_wrapped' => sub {
                my $h = shift;
                $old_coderef->($h);
                $h->do($_) for @stmts;
                return;
            };
        }

        # Add a proper retry_handler
        $conn->retry_handler(sub { $self->_retry_handler(@_) });

        # And max_attempts.  XXX: Maybe they actually wanted 10 and not just the default?
        $conn->max_attempts($DEFAULT_MAX_ATTEMPTS) if $conn->max_attempts == 10;
    }

    # Go ahead and run the post-connection statements for this session
    $dbh->{AutoCommit} = 1;
    $dbh->{RaiseError} = 1;
    $dbh->do($_) for @stmts;
}

#pod =head1 CONSTRUCTORS
#pod
#pod See L</ATTRIBUTES> for information on what can be passed into these constructors.
#pod
#pod =head2 new
#pod
#pod     my $online_ddl = DBIx::OnlineDDL->new(...);
#pod
#pod A standard object constructor. If you use this constructor, you will need to manually
#pod call L</execute> to execute the DB changes.
#pod
#pod You'll probably just want to use L</construct_and_execute>.
#pod
#pod =head2 construct_and_execute
#pod
#pod     my $online_ddl = DBIx::OnlineDDL->construct_and_execute(...);
#pod
#pod Constructs a DBIx::OnlineDDL object and automatically calls each method step, including
#pod hooks.  Anything passed to this method will be passed through to the constructor.
#pod
#pod Returns the constructed object, post-execution.  This is typically only useful if you want
#pod to inspect the attributes after the process has finished.  Otherwise, it's safe to just
#pod ignore the return and throw away the object immediately.
#pod
#pod =cut

sub construct_and_execute {
    my $class      = shift;
    my $online_ddl = $class->new(@_);

    $online_ddl->execute;

    return $online_ddl;
}

#pod =head1 METHODS
#pod
#pod =head2 Step Runners
#pod
#pod =head3 execute
#pod
#pod Runs all of the steps as documented in L</STEP METHODS>.  This also includes undo
#pod protection, in case of exceptions.
#pod
#pod =cut

sub execute {
    my $self       = shift;
    my $reversible = $self->reversible;

    $self->_progress_bar_setup;

    $reversible->run_reversibly(set_subname '_execute_part_one', sub {
        $self->create_new_table;
        $self->create_triggers;
        $self->copy_rows;
        $self->swap_tables;
    });
    $reversible->run_reversibly(set_subname '_execute_part_two', sub {
        $self->drop_old_table;
        $self->cleanup_foreign_keys;
    });
}

#pod =head3 fire_hook
#pod
#pod     $online_ddl->fire_hook('before_triggers');
#pod
#pod Fires one of the coderef hooks, if it exists.  This also updates the progress bar.
#pod
#pod See L</coderef_hooks> for more details.
#pod
#pod =cut

sub fire_hook {
    my ($self, $hook_name) = @_;

    my $hooks = $self->coderef_hooks;
    my $vars  = $self->_vars;

    my $progress = $vars->{progress_bar};

    return unless $hooks && $hooks->{$hook_name};

    $progress->message("Firing hook for $hook_name");

    # Fire the hook
    $hooks->{$hook_name}->($self);

    $progress->update;
}

#pod =head2 DBI Helpers
#pod
#pod =head3 dbh
#pod
#pod     $online_ddl->dbh;
#pod
#pod Acquires a database handle, either from L</rsrc> or L</dbi_connector>.  Not recommended
#pod for active work, as it doesn't offer retry protection.  Instead, use L</dbh_runner> or
#pod L</dbh_runner_do>.
#pod
#pod =cut

sub dbh {
    my $self = shift;

    # Even acquiring a $dbh could die (eg: 'USE $db' or other pre-connect commands), so
    # also try to wrap this in our retry handler.
    my $dbh = $self->dbh_runner( run => sub { $_[0] } );
    return $dbh;
}

#pod =head3 dbh_runner
#pod
#pod     my @items = $online_ddl->dbh_runner(run => sub {
#pod         my $dbh = $_;  # or $_[0]
#pod         $dbh->selectall_array(...);
#pod     });
#pod
#pod Runs the C<$coderef>, locally setting C<$_> to and passing in the database handle.  This
#pod is essentially a shortcut interface into either L<dbi_connector> or DBIC's L<BlockRunner|DBIx::Class::Storage::BlockRunner>.
#pod
#pod The first argument can either be C<run> or C<txn>, which controls whether to wrap the
#pod code in a DB transaction or not.  The return is passed directly back, and return context
#pod is honored.
#pod
#pod =cut

sub _retry_handler {
    my ($self, $runner) = @_;
    my $vars = $self->_vars;

    # NOTE: There's a lot of abusing the fact that BlockRunner and DBIx::Connector::Retry
    # (a la $runner) share similar accessor interfaces.

    my $error        = $runner->last_exception;
    my $is_retryable = $self->_helper->is_error_retryable($error);

    if ($is_retryable) {
        my ($failed, $max) = ($runner->failed_attempt_count, $runner->max_attempts);
        my $progress = $vars->{progress_bar};

        # Warn about the last error
        $progress->message("Encountered a recoverable error: $error") if $progress;

        # Pause for an incremental amount of seconds first, to discourage any future locks
        sleep $failed;

        # If retries are escalating, try forcing a disconnect
        if ($failed >= $max / 2) {
            # Finally have some differences between the two classes...
            if ($runner->isa('DBIx::Class::Storage::BlockRunner')) {
                eval { $runner->storage->disconnect };
            }
            else {
                eval { $runner->disconnect };
            }
        }

        $progress->message( sprintf(
            "Attempt %u of %u", $failed, $max
        ) ) if $progress;
    }

    return $is_retryable;
}

sub dbh_runner {
    my ($self, $method, $coderef) = @_;
    my $wantarray = wantarray;

    die "Only 'txn' or 'run' are acceptable run methods" unless $method =~ /^(?:txn|run)$/;

    my @res;
    if (my $rsrc = $self->rsrc) {
        # No need to load BlockRunner, since DBIC loads it in before us if we're using
        # this method.
        my $block_runner = DBIx::Class::Storage::BlockRunner->new(
            # defaults
            max_attempts => $DEFAULT_MAX_ATTEMPTS,

            # never overrides the important ones below
            %{ $self->dbic_retry_opts },

            retry_handler => sub { $self->_retry_handler(@_) },
            storage  => $rsrc->storage,
            wrap_txn => ($method eq 'txn' ? 1 : 0),
        );

        # This wrapping nonsense is necessary because Try::Tiny within BlockRunner has its own
        # localization of $_.  Fortunately, we can pass arguments to avoid closures.
        my $wrapper = set_subname '_dbh_run_blockrunner_wrapper' => sub {
            my ($s, $c) = @_;
            my $dbh = $s->rsrc->storage->dbh;

            local $_ = $dbh;
            $c->($dbh);  # also pass it in, because that's what DBIx::Connector does
        };

        # BlockRunner can still die post-failure, if $storage->ensure_connected (which calls ping
        # and tries to reconnect) dies.  If that's the case, use our retry handler to check the new
        # error message, and throw it back into BlockRunner.
        my $br_method = 'run';
        while ($block_runner->failed_attempt_count < $block_runner->max_attempts) {
            eval {
                unless (defined $wantarray) {           $block_runner->$br_method($wrapper, $self, $coderef) }
                elsif          ($wantarray) { @res    = $block_runner->$br_method($wrapper, $self, $coderef) }
                else                        { $res[0] = $block_runner->$br_method($wrapper, $self, $coderef) }
            };

            # 'run' resets failed_attempt_count, so subsequent attempts must use
            # '_run', which does not
            $br_method = '_run';

            if (my $err = $@) {
                # Time to really die
                die $err if $err =~ /Reached max_attempts amount of / || $block_runner->failed_attempt_count >= $block_runner->max_attempts;

                # See if the retry handler likes it
                push @{ $block_runner->exception_stack }, $err;
                $block_runner->_set_failed_attempt_count( $block_runner->failed_attempt_count + 1 );
                die $err unless $self->_retry_handler($block_runner);
            }
            else {
                last;
            }
        }
    }
    else {
        my $conn = $self->dbi_connector;
        unless (defined $wantarray) {           $conn->$method($coderef) }
        elsif          ($wantarray) { @res    = $conn->$method($coderef) }
        else                        { $res[0] = $conn->$method($coderef) }
    }

    return $wantarray ? @res : $res[0];
}

#pod =head3 dbh_runner_do
#pod
#pod     $online_ddl->dbh_runner_do(
#pod         "ALTER TABLE $table_name ADD COLUMN foobar",
#pod         ["ALTER TABLE ? DROP COLUMN ?", undef, $table_name, 'baz'],
#pod     );
#pod
#pod Runs a list of commands, encapsulating each of them in a L</dbh_runner> coderef with calls
#pod to L<DBI/do>.  This is handy when you want to run a list of DDL commands, which you don't
#pod care about the output of, but don't want to bundle them into a single non-idempotant
#pod repeatable coderef.  Or if you want to save typing on a single do-able SQL command.
#pod
#pod The items can either be a SQL string or an arrayref of options to pass to L<DBI/do>.
#pod
#pod The statement is assumed to be non-transactional.  If you want to run a DB transaction,
#pod you should use L</dbh_runner> instead.
#pod
#pod =cut

sub dbh_runner_do {
    my ($self, @commands) = @_;

    foreach my $command (@commands) {
        my $ref = ref $command;
        die "$ref references not valid in dbh_runner_do" if $ref && $ref ne 'ARRAY';

        $self->dbh_runner(run => set_subname '_dbh_runner_do', sub {
            $_->do( $ref ? @$command : $command );
        });
    }
}

#pod =head1 STEP METHODS
#pod
#pod You can call these methods individually, but using L</construct_and_execute> instead is
#pod highly recommended.  If you do run these yourself, the exception will need to be caught
#pod and the L</reversible> undo stack should be run to get the DB back to normal.
#pod
#pod =head2 create_new_table
#pod
#pod Creates the new table, making sure to preserve as much of the original table properties
#pod as possible.
#pod
#pod =cut

sub create_new_table {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $progress   = $vars->{progress_bar};
    my $reversible = $self->reversible;
    my $helper     = $self->_helper;

    my $orig_table_name = $self->table_name;
    my $new_table_name  = $self->new_table_name;

    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);

    # ANSI quotes could also appear in the statement
    my $orig_table_name_ansi_quote = '"'.$orig_table_name.'"';

    $progress->message("Creating new table $new_table_name");

    my $table_sql = $helper->create_table_sql($orig_table_name);
    die "Table $orig_table_name does not exist in the database!" unless $table_sql;

    $table_sql = $helper->rename_fks_in_table_sql($orig_table_name, $table_sql) if $helper->dbms_uses_global_fk_namespace;

    # Change the old->new table name
    my $orig_table_name_quote_re = '('.join('|',
        quotemeta($orig_table_name_quote), quotemeta($orig_table_name_ansi_quote), quotemeta($orig_table_name)
    ).')';
    $table_sql =~ s/(?<=^CREATE TABLE )$orig_table_name_quote_re/$new_table_name_quote/;

    # NOTE: This SQL will still have the old table name in self-referenced FKs.  This is
    # okay, since no supported RDBMS currently auto-renames the referenced table name
    # during table moves, and the old table is still the definitive point-of-record until
    # the table swap.  Furthermore, pointing the FK to the new table may cause bad FK
    # constraint failures within the triggers, if the referenced ID hasn't been copied to
    # the new table yet.
    #
    # If we ever have a RDBMS that does some sort of auto-renaming of FKs, we'll need to
    # accommodate it.  It's also worth noting that turning FKs on during the session can
    # actually affect this kind of behavior.  For example, both MySQL & SQLite will rename
    # them during table swaps, but only if the FK checks are on.

    # Actually create the table
    $self->dbh_runner_do($table_sql);

    # Undo commands, including a failure warning update
    $reversible->failure_warning("\nDropping the new table and rolling back to start!\n\n");
    $reversible->add_undo(sub { $self->dbh_runner_do("DROP TABLE $new_table_name_quote") });

    $progress->update;
}

#pod =head2 create_triggers
#pod
#pod Creates triggers on the original table to make sure any new changes are captured into the
#pod new table.
#pod
#pod =cut

sub create_triggers {
    my $self = shift;
    my $rsrc = $self->rsrc;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $progress   = $vars->{progress_bar};
    my $reversible = $self->reversible;
    my $helper     = $self->_helper;

    my $catalog         = $vars->{catalog};
    my $schema          = $vars->{schema};
    my $orig_table_name = $self->table_name;
    my $new_table_name  = $self->new_table_name;

    # Fire the before_triggers hook, which would typically include the DDL
    $self->fire_hook('before_triggers');

    $progress->message("Creating triggers");

    # This shouldn't be cached until now, since the actual DDL may change the column list
    my @column_list = $self->_column_list;

    ### Look for a unique ID set

    # We need to find a proper PK or unique constraint for UPDATE/DELETE triggers.
    # Unlike BatchChunker, we can't just rely on part of a PK.
    my @unique_ids;
    my $indexes = $self->_get_idx_hash($orig_table_name);

    my %potential_unique_ids;
    $potential_unique_ids{ $_->{name} } = $_ for grep { $_->{unique} } values %$indexes;

    my %column_set = map { $_ => 1 } @column_list;
    foreach my $index_name ('PRIMARY',
        # sort by the number of columns (asc), though PRIMARY still has top priority
        sort { scalar(@{ $potential_unique_ids{$a}{columns} }) <=> scalar(@{ $potential_unique_ids{$b}{columns} }) }
        grep { $_ ne 'PRIMARY' }
        keys %potential_unique_ids
    ) {
        my @unique_cols = @{ $potential_unique_ids{$index_name}{columns} };
        next unless @unique_cols;

        # Only use this set if all of the columns exist in both tables
        next unless all { $column_set{$_} } @unique_cols;

        @unique_ids = @unique_cols;
    }

    die "Cannot find an appropriate unique index for $orig_table_name!" unless @unique_ids;

    ### Check to make sure existing triggers aren't on the table

    die "Found conflicting triggers on $orig_table_name!  Please remove them first, so that our INSERT/UPDATE/DELETE triggers can be applied."
        if $helper->has_conflicting_triggers_on_table($orig_table_name);

    ### Find a good set of trigger names

    foreach my $trigger_type (qw< INSERT UPDATE DELETE >) {
        my $trigger_name = $helper->find_new_trigger_identifier(
            "${orig_table_name}_onlineddl_".lc($trigger_type)
        );
        $vars->{trigger_names}       {$trigger_type} = $trigger_name;
        $vars->{trigger_names_quoted}{$trigger_type} = $dbh->quote_identifier($trigger_name);
    }

    ### Now create the triggers, with (mostly) ANSI SQL

    my $orig_table_name_quote = $dbh->quote_identifier($orig_table_name);
    my $new_table_name_quote  = $dbh->quote_identifier($new_table_name);

    my $column_list_str     = join(', ', map {        $dbh->quote_identifier($_) } @column_list );
    my $new_column_list_str = join(', ', map { "NEW.".$dbh->quote_identifier($_) } @column_list );

    my $nseo = $helper->null_safe_equals_op;
    my %trigger_dml_stmts;

    # Using REPLACE just in case the row already exists from the copy
    $trigger_dml_stmts{replace} = join("\n",
        "REPLACE INTO $new_table_name_quote",
        "    ($column_list_str)",
        "VALUES",
        "    ($new_column_list_str)",
    );

    my $update_unique_where_str = join(' AND ',
        (map {
            join(
                # Use NULL-safe equals, since unique indexes could be nullable
                " $nseo ",
                "OLD.".$dbh->quote_identifier($_),
                "NEW.".$dbh->quote_identifier($_),
            );
        } @unique_ids)
    );

    my $delete_unique_where_str = join(' AND ',
        (map {
            join(
                # Use NULL-safe equals, since unique indexes could be nullable
                " $nseo ",
                "$new_table_name_quote.".$dbh->quote_identifier($_),
                "OLD.".$dbh->quote_identifier($_),
            );
        } @unique_ids)
    );

    # For the UPDATE trigger, DELETE the row, but only if the unique IDs have been
    # changed.  The "NOT ($update_unique_where_str)" part keeps from deleting rows where
    # the unique ID is untouched.
    $trigger_dml_stmts{delete_for_update} = join("\n",
        "DELETE FROM $new_table_name_quote WHERE",
        "    NOT ($update_unique_where_str) AND",
        "    $delete_unique_where_str"
    );

    $trigger_dml_stmts{delete_for_delete} = join("\n",
        "DELETE FROM $new_table_name_quote WHERE",
        "    $delete_unique_where_str"
    );

    $helper->modify_trigger_dml_stmts( \%trigger_dml_stmts );

    foreach my $trigger_type (qw< INSERT UPDATE DELETE >) {
        my $trigger_header = join(' ',
            "CREATE TRIGGER ".$vars->{trigger_names_quoted}{$trigger_type},
            "AFTER $trigger_type ON $orig_table_name_quote FOR EACH ROW"
        );

        # Even though some of these are just a single SQL statement, not every RDBMS
        # (like SQLite) supports leaving out the BEGIN/END keywords.
        my $trigger_sql = join("\n",
            $trigger_header,
            "BEGIN",
            '',
        );

        if    ($trigger_type eq 'INSERT') {
            # INSERT trigger: Just a REPLACE command
            $trigger_sql .= $trigger_dml_stmts{replace}.';';
        }
        elsif ($trigger_type eq 'UPDATE') {
            # UPDATE trigger: DELETE special unique ID changes, then another REPLACE command.
            $trigger_sql .= join("\n",
                $trigger_dml_stmts{delete_for_update}.';',
                $trigger_dml_stmts{replace}.';',
            );
        }
        elsif ($trigger_type eq 'DELETE') {
            # DELETE trigger: Just a DELETE command
            $trigger_sql .= $trigger_dml_stmts{delete_for_delete}.';';
        }
        $trigger_sql .= "\nEND";

        # DOIT!
        $self->dbh_runner_do($trigger_sql);

        $reversible->add_undo(sub {
            $self->dbh_runner_do( "DROP TRIGGER IF EXISTS ".$self->_vars->{trigger_names_quoted}{$trigger_type} );
        });
    }

    $progress->update;
}

#pod =head2 copy_rows
#pod
#pod Fires up a L<DBIx::BatchChunker> process to copy all of the rows from the old table to
#pod the new.
#pod
#pod =cut

sub copy_rows {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $progress  = $vars->{progress_bar};
    my $copy_opts = $self->_fill_copy_opts;

    $progress->message("Copying all rows to the new table");

    DBIx::BatchChunker->construct_and_execute( %$copy_opts );
    $vars->{new_table_copied} = 1;

    # Analyze the table, since we have a ton of new rows now
    $progress->message("Analyzing table");
    $self->_helper->analyze_table( $self->new_table_name );

    $progress->update;
}

#pod =head2 swap_tables
#pod
#pod With the new table completely modified and set up, this swaps the old/new tables.
#pod
#pod =cut

sub swap_tables {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $progress   = $vars->{progress_bar};
    my $reversible = $self->reversible;
    my $helper     = $self->_helper;

    my $catalog         = $vars->{catalog};
    my $schema          = $vars->{schema};
    my $orig_table_name = $self->table_name;
    my $new_table_name  = $self->new_table_name;

    my $escape = $dbh->get_info( $GetInfoType{SQL_SEARCH_PATTERN_ESCAPE} ) // '\\';

    # Fire the before_swap hook
    $self->fire_hook('before_swap');

    if ($helper->dbms_uses_global_fk_namespace || $helper->child_fks_need_adjusting) {
        # The existing parent/child FK list needs to be captured prior to the swap.  The FKs
        # have already been created, and possibly changed/deleted, from the new table, so we
        # use that as reference.  They have *not* been re-created on the child tables, so
        # the original table is used as reference.
        my $fk_hash = $vars->{foreign_keys}{definitions} //= {};
        $self->dbh_runner(run => set_subname '_fk_parent_info_query', sub {
            $fk_hash->{parent} = $self->_fk_info_to_hash( $helper->foreign_key_info(undef, undef, undef, $catalog, $schema, $new_table_name)  );
        });
        $self->dbh_runner(run => set_subname '_fk_child_info_query', sub {
            $fk_hash->{child}  = $self->_fk_info_to_hash( $helper->foreign_key_info($catalog, $schema, $orig_table_name, undef, undef, undef) );
        });

        # Furthermore, we should capture the indexes from parent/child tables in case the data
        # is needed for FK cleanup
        my $idx_hash = $vars->{indexes}{definitions} //= {};
        if ($dbh->can('statistics_info') && %$fk_hash) {
            foreach my $fk_table_name (
                uniq sort
                grep { defined && $_ ne $orig_table_name && $_ ne $new_table_name }
                map  { ($_->{pk_table_name}, $_->{fk_table_name}) }
                (values %{$fk_hash->{parent}}, values %{$fk_hash->{child}})
            ) {
                $idx_hash->{$fk_table_name} = $self->_get_idx_hash($fk_table_name);
            }
        }
    }

    # Find an "_old" table name first
    my $old_table_name = $vars->{old_table_name} = $self->_find_new_identifier(
        "_${orig_table_name}_old" => set_subname('_old_table_name_finder', sub {
            my ($d, $like_expr) = @_;
            $like_expr =~ s/([_%])/$escape$1/g;

            $d->table_info($catalog, $schema, $like_expr)->fetchrow_array;
        }),
        'SQL_MAXIMUM_TABLE_NAME_LENGTH',
    );
    my $old_table_name_quote = $dbh->quote_identifier($old_table_name);

    $progress->message("Swapping tables ($new_table_name --> $orig_table_name --> $old_table_name)");

    # Let's swap tables!
    $helper->swap_tables($new_table_name, $orig_table_name, $old_table_name);

    # Kill the undo stack now, just in case something weird happens between now and the
    # end of the reversibly block.  We've reached a "mostly successful" state, so rolling
    # back here would be undesirable.
    $reversible->clear_undo;
    $vars->{new_table_swapped} = 1;

    $progress->update;
}

#pod =head2 drop_old_table
#pod
#pod Drops the old table.  This will also remove old foreign keys on child tables.  (Those FKs
#pod are re-applied to the new table in the next step.)
#pod
#pod =cut

sub drop_old_table {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $progress   = $vars->{progress_bar};
    my $reversible = $self->reversible;
    my $helper     = $self->_helper;

    my $old_table_name       = $vars->{old_table_name};
    my $old_table_name_quote = $dbh->quote_identifier($old_table_name);

    $reversible->failure_warning( join "\n",
        '',
        "The new table has been swapped, but since the process was interrupted, foreign keys will",
        "need to be cleaned up, and the old table dropped.",
        '',
    );

    # The RDBMS may complain about dangling non-functional FKs if the DROP happens first,
    # so let's remove those child FKs first, and reapply them later.  We turn off FK
    # checks, so these constraint drops are quick and low risk.
    #
    # SQLite doesn't actually support DROP CONSTRAINT, but it doesn't do any messy business with
    # FK renames, either.  So, SQLite can just skip this step.
    if ($helper->child_fks_need_adjusting) {
        $progress->message("Removing FKs from child tables");

        $self->dbh_runner_do(
            $helper->remove_fks_from_child_tables_stmts
        );
    }

    # Now, the actual DROP
    $progress->message("Dropping old table $old_table_name");

    $self->dbh_runner_do("DROP TABLE $old_table_name_quote");

    $progress->update;
}

#pod =head2 cleanup_foreign_keys
#pod
#pod Clean up foreign keys on both the new and child tables.
#pod
#pod =cut

sub cleanup_foreign_keys {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $progress   = $vars->{progress_bar};
    my $reversible = $self->reversible;
    my $helper     = $self->_helper;

    $reversible->failure_warning( join "\n",
        '',
        "The new table is live, but since the process was interrupted, foreign keys will need to be",
        "cleaned up.",
        '',
    );

    if ($helper->dbms_uses_global_fk_namespace) {
        # The DB has global namespaces for foreign keys, so we are renaming them back to
        # their original names.  The original table has already been dropped, so there's
        # no more risk of bumping into that namespace.
        $progress->message("Renaming parent FKs back to the original constraint names");

        $self->dbh_runner_do(
            $helper->rename_fks_back_to_original_stmts
        );
    }

    if ($helper->child_fks_need_adjusting) {
        # Since we captured the child FK names prior to the swap, they should have the
        # original FK names, even before MySQL's "helpful" changes on "${tbl_name}_ibfk_" FK
        # names.
        $progress->message("Adding FKs back on child tables");

        $self->dbh_runner_do(
            $helper->add_fks_back_to_child_tables_stmts
        );

        # The RDBMS may need some post-FK cleanup
        $progress->message("Post-FK cleanup");

        $self->dbh_runner_do(
            $helper->post_fk_add_cleanup_stmts
        );
    }

    $progress->update;
}

### Private methods

sub _find_new_identifier {
    my ($self, $desired_identifier, $finder_sub, $length_info_str) = @_;
    $length_info_str ||= 'SQL_MAXIMUM_IDENTIFIER_LENGTH';

    state $hash_digits = ['a' .. 'z', '0' .. '9'];

    my $hash = join '', map { $hash_digits->[rand @$hash_digits] } 1 .. 10;

    # Test out some potential names
    my @potential_names = (
        $desired_identifier, "_${desired_identifier}",
        "${desired_identifier}_${hash}", "_${desired_identifier}_${hash}",
        $hash, "_${hash}"
    );

    my $max_len = $self->dbh->get_info( $GetInfoType{$length_info_str} ) || 256;

    my $new_name;
    foreach my $potential_name (@potential_names) {
        $potential_name = substr($potential_name, 0, $max_len);  # avoid the ID name character limit

        my @results = $self->dbh_runner(run => set_subname '_find_new_identifier_dbh_runner', sub {
            $finder_sub->($_, $potential_name);
        });

        # Skip if we found it
        next if @results;

        $new_name = $potential_name;
        last;
    }

    # This really shouldn't happen...
    die "Cannot find a proper identifier name for $desired_identifier!  All of them are taken!" unless defined $new_name;

    return $new_name;
}

sub _column_list {
    my $self = shift;
    my $dbh  = $self->dbh;
    my $vars = $self->_vars;

    my $catalog         = $vars->{catalog};
    my $schema          = $vars->{schema};
    my $orig_table_name = $self->table_name;
    my $new_table_name  = $self->new_table_name;

    my (@old_column_list, @new_column_list);
    $self->dbh_runner(run => set_subname '_column_list_runner', sub {
        $dbh = $_;
        @old_column_list =
            map { $_->{COLUMN_NAME} }
            @{ $dbh->column_info( $catalog, $schema, $orig_table_name, '%' )->fetchall_arrayref({ COLUMN_NAME => 1 }) }
        ;
        @new_column_list =
            map { $_->{COLUMN_NAME} }
            @{ $dbh->column_info( $catalog, $schema, $new_table_name, '%' )->fetchall_arrayref({ COLUMN_NAME => 1 }) }
        ;
    });

    # We only care about columns that exist in both tables.  If a column was added on the
    # new table, there's no data to copy.  If a column was deleted from the new table, we
    # don't care about keeping it.
    my %new_column_set = map { $_ => 1 } @new_column_list;
    return grep { $new_column_set{$_} } @old_column_list;
}

sub _get_idx_hash {
    my ($self, $table_name) = @_;

    my $vars    = $self->_vars;
    my $catalog = $vars->{catalog};
    my $schema  = $vars->{schema};

    my %idxs = (
        PRIMARY => {
            name    => 'PRIMARY',
            columns => [ $self->dbh_runner(run => set_subname '_pk_info_query', sub {
                $_->primary_key($catalog, $schema, $table_name)
            }) ],
            unique  => 1,
        },
    );
    delete $idxs{PRIMARY} unless @{ $idxs{PRIMARY}{columns} };

    return \%idxs unless $self->dbh->can('statistics_info');

    # Sometimes, this still dies, even with the 'can' check (eg: older DBD::mysql drivers)
    my $index_stats = [];
    eval {
        $index_stats = $self->dbh_runner(run => set_subname '_idx_info_query', sub {
            $_->statistics_info($catalog, $schema, $table_name, 0, 1)->fetchall_arrayref({});
        });
    };
    $index_stats = [] if $@;

    foreach my $index_name (uniq map { $_->{INDEX_NAME} } @$index_stats) {
        my $index_stat = first { $_->{INDEX_NAME} eq $index_name } @$index_stats;
        my @cols =
            map  { $_->{COLUMN_NAME} }
            sort { $a->{ORDINAL_POSITION} <=> $b->{ORDINAL_POSITION} }
            grep { $_->{INDEX_NAME} eq $index_name }
            @$index_stats
        ;
        $idxs{$index_name} = {
            name    => $index_name,
            columns => \@cols,
            unique  => !$index_stat->{NON_UNIQUE},
        };
    }

    return \%idxs;
}

sub _fk_info_to_hash {
    my ($self, $fk_sth) = @_;
    my $vars = $self->_vars;
    my $dbh  = $self->dbh;

    # NOTE: Need to account for alternate ODBC names

    my @fk_rows = @{ $fk_sth->fetchall_arrayref({}) };
    @fk_rows = sort {
        # Sort by FK name, then by the column sequence number
        $a->{FK_NAME} cmp $b->{FK_NAME} ||
        ($a->{KEY_SEQ} // $a->{ORDINAL_POSITION}) <=> ($a->{KEY_SEQ} // $a->{ORDINAL_POSITION})
    } @fk_rows;

    my (%fks, %create_table_sql);
    foreach my $row (@fk_rows) {
        # Some of these rows aren't even FKs
        next unless $row->{PKTABLE_NAME} || $row->{UK_TABLE_CAT};
        next unless $row->{FKTABLE_NAME} || $row->{FK_TABLE_NAME};

        my $fk_name       = $row->{FK_NAME}      // $row->{FKCOLUMN_NAME};
        my $fk_table_name = $row->{FKTABLE_NAME} // $row->{FK_TABLE_NAME};

        my $key = join( '.',
            $row->{PKTABLE_NAME} // $row->{UK_TABLE_CAT},
            $fk_name,
        );

        # Since there may be multiple columns per FK, those associated columns are
        # arrayrefs.
        unless ($fks{$key}) {

            $fks{$key} = {
                fk_name       => $fk_name,

                # The table where the original PK exists
                pk_table_name => $row->{PKTABLE_NAME} // $row->{UK_TABLE_CAT},
                pk_columns    => [ $row->{PKCOLUMN_NAME} // $row->{UK_COLUMN_NAME} ],

                # The table where the FK constraint has been declared
                fk_table_name => $fk_table_name,
                fk_columns    => [ $row->{FKCOLUMN_NAME} // $row->{FK_COLUMN_NAME} ],
            };

            # Sadly, foreign_key_info doesn't always fill in all of the details for the FK, so the
            # CREATE TABLE SQL is actually the better record.  Fortunately, this is all ANSI SQL.
            my $create_table_sql = $create_table_sql{$fk_table_name} //= $self->_helper->create_table_sql($fk_table_name);
            my $fk_name_quote_re = '(?:'.join('|',
                quotemeta( $dbh->quote_identifier($fk_name) ), quotemeta('"'.$fk_name.'"'), quotemeta($fk_name)
            ).')';

            if ($create_table_sql =~ m<
                CONSTRAINT \s $fk_name_quote_re \s (      # start capture of full SQL
                    FOREIGN \s KEY \s \( [^\)]+ \) \s     # "FOREIGN KEY" plus column list (which we already have above)
                    REFERENCES \s [^\(]+ \s \( [^\)]+ \)  # "REFERENCES" plus table+column list (again, already captured above)
                    \s? ( [^\)\,]* )                      # ON DELETE/UPDATE, DEFER, MATCH, etc.
                )                                         # end capture of full SQL
            >isx) {
                my ($fk_sql, $extra_sql) = ($1, $2);
                $fk_sql =~ s/^\s+|\s+$//g;

                $fks{$key}{fk_sql}      = $fk_sql;
                $fks{$key}{delete_rule} = $1 if $extra_sql =~ /ON DELETE ((?:SET |NO )?\w+)/i;
                $fks{$key}{update_rule} = $1 if $extra_sql =~ /ON UPDATE ((?:SET |NO )?\w+)/i;
                $fks{$key}{defer}       = $1 if $extra_sql =~ /((?:NOT )?DEFERRABLE(?: INITIALLY \w+)?)/i;
                $fks{$key}{match}       = $1 if $extra_sql =~ /(MATCH \w+)/i;
            }
        }
        else {
            push @{ $fks{$key}{pk_columns} }, $row->{PKCOLUMN_NAME} // $row->{UK_COLUMN_NAME};
            push @{ $fks{$key}{fk_columns} }, $row->{FKCOLUMN_NAME} // $row->{FK_COLUMN_NAME};
        }
    }

    return \%fks;
}

sub _fk_to_sql {
    my ($self, $fk) = @_;
    my $dbh = $self->dbh;

    # Everything after the CONSTRAINT keyword (ANSI SQL)

    if ($fk->{fk_sql}) {
        # Already have most of the SQL
        return join(' ',
            $dbh->quote_identifier($fk->{fk_name}),
            $fk->{fk_sql},
        );
    }

    return join(' ',
        $dbh->quote_identifier($fk->{fk_name}),
        'FOREIGN KEY',
        '('.join(', ', map { $dbh->quote_identifier($_) } @{ $fk->{fk_columns} }).')',
        'REFERENCES',
        $dbh->quote_identifier($fk->{pk_table_name}),
        '('.join(', ', map { $dbh->quote_identifier($_) } @{ $fk->{pk_columns} }).')',
        ( $fk->{match}       ? $fk->{match}                    : () ),
        ( $fk->{delete_rule} ? 'ON DELETE '.$fk->{delete_rule} : () ),
        ( $fk->{update_rule} ? 'ON UPDATE '.$fk->{update_rule} : () ),
        ( $fk->{defer}       ? $fk->{defer}                    : () ),
    );
}

#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item *
#pod
#pod L<Percona's pt-online-schema-change|https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html>
#pod
#pod =item *
#pod
#pod L<GitHub's gh-ost|https://github.com/github/gh-ost>
#pod
#pod =item *
#pod
#pod L<Facebook's OSC|https://www.facebook.com/notes/mysql-at-facebook/online-schema-change-for-mysql/430801045932/>
#pod
#pod =item *
#pod
#pod L<MySQL's Online DDL|https://dev.mysql.com/doc/refman/5.6/en/innodb-online-ddl.html>
#pod
#pod =back
#pod
#pod =head1 WHY YET ANOTHER OSC?
#pod
#pod The biggest reason is that none of the above fully support foreign key constraints.
#pod Percona's C<pt-osc> comes close, but also includes this paragraph:
#pod
#pod     Due to a limitation in MySQL, foreign keys will not have the same names after the ALTER
#pod     that they did prior to it. The tool has to rename the foreign key when it redefines it,
#pod     which adds a leading underscore to the name. In some cases, MySQL also automatically
#pod     renames indexes required for the foreign key.
#pod
#pod So, tables swapped with C<pt-osc> are not exactly what they used to be before the swap.
#pod It also had a number of other quirks that just didn't work out for us, related to FKs and
#pod the amount of switches required to make it (semi-)work.
#pod
#pod Additionally, by making DBIx::OnlineDDL its own Perl module, it's a lot easier to run
#pod Perl-based schema changes along side L<DBIx::BatchChunker> without having to switch
#pod between Perl and CLI.  If other people want to subclass this module for their own
#pod environment-specific quirks, they have the power to do so, too.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::OnlineDDL - Run DDL on online databases safely

=head1 VERSION

version v0.940.0

=head1 SYNOPSIS

    use DBIx::OnlineDDL;
    use DBIx::BatchChunker;

    DBIx::OnlineDDL->construct_and_execute(
        rsrc          => $dbic_schema->source('Account'),
        ### OR ###
        dbi_connector => $dbix_connector_retry_object,
        table_name    => 'accounts',

        coderef_hooks => {
            # This is the phase where the DDL is actually run
            before_triggers => \&drop_foobar,

            # Run other operations right before the swap
            before_swap => \&delete_deprecated_accounts,
        },

        process_name => 'Dropping foobar from accounts',

        copy_opts => {
            chunk_size => 5000,
            debug => 1,
        },
    );

    sub drop_foobar {
        my $oddl  = shift;
        my $name  = $oddl->new_table_name;
        my $qname = $oddl->dbh->quote_identifier($name);

        # Drop the 'foobar' column, since it is no longer used
        $oddl->dbh_runner_do("ALTER TABLE $qname DROP COLUMN foobar");
    }

    sub delete_deprecated_accounts {
        my $oddl = shift;
        my $name = $oddl->new_table_name;
        my $dbh  = $oddl->dbh;  # only use for quoting!

        my $qname = $dbh->quote_identifier($name);

        DBIx::BatchChunker->construct_and_execute(
            chunk_size  => 5000,

            debug => 1,

            process_name     => 'Deleting deprecated accounts',
            process_past_max => 1,

            dbic_storage => $oddl->rsrc->storage,
            min_stmt => "SELECT MIN(account_id) FROM $qname",
            max_stmt => "SELECT MAX(account_id) FROM $qname",
            stmt     => join("\n",
                "DELETE FROM $qname",
                "WHERE",
                "    account_type = ".$dbh->quote('deprecated')." AND",
                "    account_id BETWEEN ? AND ?",
            ),
        );
    }

=head1 DESCRIPTION

This is a database utility class for running DDL operations (like C<ALTER TABLE>) safely
on large tables.  It has a similar scope as L<DBIx::BatchChunker>, but is designed for
DDL, rather than DML.  It also has a similar function to other utilities like
L<pt-online-schema-change|https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html> or
L<gh-ost|https://github.com/github/gh-ost>, but actually works properly with foreign
keys, and is written as a Perl module to hook directly into a DBI handle.

Like most online schema change tools, this works by creating a new shell table that looks
just like the old table, running the DDL changes (through the L</before_triggers> hook),
copying data to the new table, and swapping the tables.  Triggers are created to keep the
data in sync.  See L</STEP METHODS> for more information.

The full operation is protected with an L<undo stack|/reversible> via L<Eval::Reversible>.
If any step in the process fails, the undo stack is run to return the DB back to normal.

This module uses as many of the DBI info methods as possible, along with ANSI SQL in most
places, to be compatible with multiple RDBMS.  So far, it will work with MySQL or SQLite,
but can be expanded to include more systems with a relatively small amount of code
changes.  (See L<DBIx::OnlineDDL::Helper::Base> for details.)

B<DISCLAIMER:> You should not rely on this class to magically fix any and all locking
problems the DB might experience just because it's being used.  Thorough testing and
best practices are still required.

=head2 When you shouldn't use this module

=head3 Online DDL is already available in the RDBMS

If you're running MySQL 5.6+ without clustering, just use C<LOCK=NONE> for every DDL
statement.  It is seriously simple and guarantees that the table changes you make are not
going to lock the table, or it will fail right away to tell you it's an incompatible
change.

If you're running something like Galera clusters, this typically wouldn't be an option,
as it would lock up the clusters while the C<ALTER TABLE> statement is running, despite
the C<LOCK=NONE> statement.  (Galera clusters were the prime motivation for writing this
module.)

Other RDBMSs may have support for online DDL as well.  Check the documentation first.  If
they don't, patches for this tool are welcome!

=head3 The operation is small

Does your DDL only take 2 seconds?  Just do it!  Don't bother with trying to swap tables
around, wasting time with full table copies, etc.  It's not worth the time spent or risk.

=head3 When you actually want to run DML, not DDL

L<DBIx::BatchChunker> is more appropriate for running DML operations (like C<INSERT>,
C<UPDATE>, C<DELETE>).  If you need to do both, you can use the L</before_triggers> hook
for DDL, and the L</before_swap> hook for DML.  Or just run DBIx::BatchChunker after the
OnlineDDL process is complete.

=head3 Other online schema change tools fit your needs

Don't have foreign key constraints and C<gh-ost> is already working for you?  Great!
Keep using it.

=head1 ATTRIBUTES

=head2 DBIC Attributes

=head3 rsrc

A L<DBIx::Class::ResultSource>.  This will be the source used for all operations, DDL or
otherwise.  Optional, but recommended for DBIC users.

The DBIC storage handler's C<connect_info> will be tweaked to ensure sane defaults and
proper post-connection details.

=head3 dbic_retry_opts

A hashref of DBIC retry options.  These options control how retry protection works within
DBIC.  Right now, this is just limited to C<max_attempts>, which controls the number of
times to retry.  The default C<max_attempts> is 20.

=head2 DBI Attributes

=head3 dbi_connector

A L<DBIx::Connector::Retry> object.  Instead of L<DBI> statement handles, this is the
recommended non-DBIC way for OnlineDDL (and BatchChunker) to interface with the DBI, as
it handles retries on failures.  The connection mode used is whatever default is set
within the object.

Required, except for DBIC users, who should be setting L</rsrc> above.  It is also
assumed that the correct database is already active.

The object will be tweaked to ensure sane defaults, proper post-connection details, a
custom C<retry_handler>, and set a default C<max_attempts> of 20, if not already set.

=head3 table_name

The table name to be copied and eventually replaced.  Required unless L</rsrc> is
specified.

=head3 new_table_name

The new table name to be created, copied to, and eventually used as the final table.
Optional.

If not defined, a name will be created automatically.  This might be the better route,
since the default builder will search for an unused name in the DB right before OnlineDDL
needs it.

=head2 Progress Bar Attributes

=head3 progress_bar

The progress bar used for most of the process.  A different one is used for the actual
table copy with L<DBIx::BatchChunker>, since that step takes longer.

Optional.  If the progress bar isn't specified, a default one will be created.  If the
terminal isn't interactive, the default L<Term::ProgressBar> will be set to C<silent> to
naturally skip the output.

=head3 progress_name

A string used to assist in creating a progress bar.  Ignored if L</progress_bar> is
already specified.

This is the preferred way of customizing the progress bar without having to create one
from scratch.

=head2 Other Attributes

=head3 coderef_hooks

A hashref of coderefs.  Each of these are used in different steps in the process.  All
of these are optional, but it is B<highly recommended> that C<before_triggers> is
specified.  Otherwise, you're not actually running any DDL and the table copy is
essentially a no-op.

All of these triggers pass the C<DBIx::OnlineDDL> object as the only argument.  The
L</new_table_name> can be acquired from that and used in SQL statements.  The L</dbh_runner>
and L</dbh_runner_do> methods should be used to protect against disconnections or locks.

There is room to add more hooks here, but only if there's a good reason to do so.
(Running the wrong kind of SQL at the wrong time could be dangerous.)  Create a GitHub
issue if you can think of one.

=head4 before_triggers

This is called before the table triggers are applied.  Your DDL should take place here,
for a few reasons:

    1. The table is empty, so DDL should take no time at all now.

    2. After this hook, the table is reanalyzed to make sure it has an accurate picture
    of the new columns.  This is critical for the creation of the triggers.

=head4 before_swap

This is called after the new table has been analyzed, but before the big table swap.  This
hook might be used if a large DML operation needs to be done while the new table is still
available.  If you use this hook, it's highly recommended that you use something like
L<DBIx::BatchChunker> to make sure the changes are made in a safe and batched manner.

=head3 copy_opts

A hashref of different options to pass to L<DBIx::BatchChunker>, which is used in the
L</copy_rows> step.  Some of these are defined automatically.  It's recommended that you
specify at least these options:

    chunk_size  => 5000,     # or whatever is a reasonable size for that table
    id_name     => 'pk_id',  # especially if there isn't an obvious integer PK

Specifying L<DBIx::BatchChunker/coderef> is not recommended, since Active DBI Processing
mode will be used.

These options will be included into the hashref, unless specifically overridden by key
name:

    id_name      => $first_pk_column,  # will warn if the PK is multi-column
    target_time  => 1,
    sleep        => 0.5,

    # If using DBIC
    dbic_storage => $rsrc->storage,
    rsc          => $id_rsc,
    dbic_retry_opts => {
        max_attempts  => 20,
        # best not to change this, unless you know what you're doing
        retry_handler => $onlineddl_retry_handler,
    },

    # If using DBI
    dbi_connector => $oddl->dbi_connector,
    min_stmt      => $min_sql,
    max_stmt      => $max_sql,

    # For both
    count_stmt    => $count_sql,
    stmt          => $insert_select_sql,
    progress_name => $copying_msg,

=head3 db_timeouts

A hashref of timeouts used for various DB operations, and usually set at the beginning of
each connection.  Some of these settings may be RDBMS-specific.

=head4 lock_file

Amount of time (in seconds) to wait when attempting to acquire filesystem locks (on
filesystems which support locking).  Float or fractional values are allowed.  This
currently only applies to SQLite.

Default value is 1 second.  The downside is that the SQLite default is actually 0, so
other (non-OnlineDDL) connections should have a setting that is more than that to prevent
lock contention.

=head4 lock_db

Amount of time (in whole seconds) to wait when attempting to acquire table and/or database
level locks before falling back to retry.

Default value is 60 seconds.

=head4 lock_row

Amount of time (in whole seconds) to wait when attempting to acquire row-level locks,
which apply to much lower-level operations than L</lock_db>.  At this scope, the lesser
of either of these two settings will take precedence.

Default value is 2 seconds.  Lower values are preferred for row lock wait timeouts, so
that OnlineDDL is more likely to be the victim of lock contention.  OnlineDDL can simply
retry the connection at that point.

=head4 session

Amount of time (in whole seconds) for inactive session timeouts on the database side.

Default value is 28,800 seconds (8 hours), which is MySQL's default.

=head3 reversible

A L<Eval::Reversible> object, used for rollbacks.  A default will be created, if not
specified.

=head1 CONSTRUCTORS

See L</ATTRIBUTES> for information on what can be passed into these constructors.

=head2 new

    my $online_ddl = DBIx::OnlineDDL->new(...);

A standard object constructor. If you use this constructor, you will need to manually
call L</execute> to execute the DB changes.

You'll probably just want to use L</construct_and_execute>.

=head2 construct_and_execute

    my $online_ddl = DBIx::OnlineDDL->construct_and_execute(...);

Constructs a DBIx::OnlineDDL object and automatically calls each method step, including
hooks.  Anything passed to this method will be passed through to the constructor.

Returns the constructed object, post-execution.  This is typically only useful if you want
to inspect the attributes after the process has finished.  Otherwise, it's safe to just
ignore the return and throw away the object immediately.

=head1 METHODS

=head2 Step Runners

=head3 execute

Runs all of the steps as documented in L</STEP METHODS>.  This also includes undo
protection, in case of exceptions.

=head3 fire_hook

    $online_ddl->fire_hook('before_triggers');

Fires one of the coderef hooks, if it exists.  This also updates the progress bar.

See L</coderef_hooks> for more details.

=head2 DBI Helpers

=head3 dbh

    $online_ddl->dbh;

Acquires a database handle, either from L</rsrc> or L</dbi_connector>.  Not recommended
for active work, as it doesn't offer retry protection.  Instead, use L</dbh_runner> or
L</dbh_runner_do>.

=head3 dbh_runner

    my @items = $online_ddl->dbh_runner(run => sub {
        my $dbh = $_;  # or $_[0]
        $dbh->selectall_array(...);
    });

Runs the C<$coderef>, locally setting C<$_> to and passing in the database handle.  This
is essentially a shortcut interface into either L<dbi_connector> or DBIC's L<BlockRunner|DBIx::Class::Storage::BlockRunner>.

The first argument can either be C<run> or C<txn>, which controls whether to wrap the
code in a DB transaction or not.  The return is passed directly back, and return context
is honored.

=head3 dbh_runner_do

    $online_ddl->dbh_runner_do(
        "ALTER TABLE $table_name ADD COLUMN foobar",
        ["ALTER TABLE ? DROP COLUMN ?", undef, $table_name, 'baz'],
    );

Runs a list of commands, encapsulating each of them in a L</dbh_runner> coderef with calls
to L<DBI/do>.  This is handy when you want to run a list of DDL commands, which you don't
care about the output of, but don't want to bundle them into a single non-idempotant
repeatable coderef.  Or if you want to save typing on a single do-able SQL command.

The items can either be a SQL string or an arrayref of options to pass to L<DBI/do>.

The statement is assumed to be non-transactional.  If you want to run a DB transaction,
you should use L</dbh_runner> instead.

=head1 STEP METHODS

You can call these methods individually, but using L</construct_and_execute> instead is
highly recommended.  If you do run these yourself, the exception will need to be caught
and the L</reversible> undo stack should be run to get the DB back to normal.

=head2 create_new_table

Creates the new table, making sure to preserve as much of the original table properties
as possible.

=head2 create_triggers

Creates triggers on the original table to make sure any new changes are captured into the
new table.

=head2 copy_rows

Fires up a L<DBIx::BatchChunker> process to copy all of the rows from the old table to
the new.

=head2 swap_tables

With the new table completely modified and set up, this swaps the old/new tables.

=head2 drop_old_table

Drops the old table.  This will also remove old foreign keys on child tables.  (Those FKs
are re-applied to the new table in the next step.)

=head2 cleanup_foreign_keys

Clean up foreign keys on both the new and child tables.

=head1 SEE ALSO

=over

=item *

L<Percona's pt-online-schema-change|https://www.percona.com/doc/percona-toolkit/LATEST/pt-online-schema-change.html>

=item *

L<GitHub's gh-ost|https://github.com/github/gh-ost>

=item *

L<Facebook's OSC|https://www.facebook.com/notes/mysql-at-facebook/online-schema-change-for-mysql/430801045932/>

=item *

L<MySQL's Online DDL|https://dev.mysql.com/doc/refman/5.6/en/innodb-online-ddl.html>

=back

=head1 WHY YET ANOTHER OSC?

The biggest reason is that none of the above fully support foreign key constraints.
Percona's C<pt-osc> comes close, but also includes this paragraph:

    Due to a limitation in MySQL, foreign keys will not have the same names after the ALTER
    that they did prior to it. The tool has to rename the foreign key when it redefines it,
    which adds a leading underscore to the name. In some cases, MySQL also automatically
    renames indexes required for the foreign key.

So, tables swapped with C<pt-osc> are not exactly what they used to be before the swap.
It also had a number of other quirks that just didn't work out for us, related to FKs and
the amount of switches required to make it (semi-)work.

Additionally, by making DBIx::OnlineDDL its own Perl module, it's a lot easier to run
Perl-based schema changes along side L<DBIx::BatchChunker> without having to switch
between Perl and CLI.  If other people want to subclass this module for their own
environment-specific quirks, they have the power to do so, too.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2021 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
