package Database::Async::ORM::Schema;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

use Database::Async::ORM::Type;

sub new {
    my ($class) = shift;
    bless { @_ }, $class
}

sub name { shift->{name} }
sub defined_in { shift->{defined_in} }
sub description { shift->{description} }
sub tables { (shift->{tables} // [])->@* }
sub types { (shift->{types} // [])->@* }

sub table_by_name {
    my ($self, $name) = @_;
    (grep { $_->name eq $name } (shift->{tables} // [])->@*)[0]
}

sub add_table {
    my ($self, $table) = @_;
    push @{$self->{tables}}, $table;
    $self;
}

sub add_type {
    my ($self, $type) = @_;
    push @{$self->{types}}, $type;
    $self;
}

my %predefined_types = map {
    $_ => Database::Async::ORM::Type->new(
        defined_in  => 'postgres',
        name        => $_,
        schema      => undef,
        type        => $_,
        description => $_,
        is_builtin  => 1,
    )
} qw(
    serial
    bigserial
    bigint
    int
    boolean
    bool
    bytea
    char
    name
    int8
    int2
    int2vector
    int4
    regproc
    text
    oid
    tid
    xid
    cid
    oidvector
    pg_type
    pg_attribute
    pg_proc
    pg_class
    json
    xml
    _xml
    _json
    pg_node_tree
    pg_ndistinct
    pg_dependencies
    pg_ddl_command
    smgr
    point
    lseg
    path
    box
    polygon
    line
    _line
    float4
    float8
    double
    abstime
    reltime
    tinterval
    unknown
    circle
    _circle
    money
    _money
    macaddr
    inet
    cidr
    macaddr8
    _bool
    _bytea
    _char
    _name
    _int2
    _int2vector
    _int4
    _regproc
    _text
    _oid
    _tid
    _xid
    _cid
    _oidvector
    _bpchar
    _varchar
    _int8
    _point
    _lseg
    _path
    _box
    _float4
    _float8
    _abstime
    _reltime
    _tinterval
    _polygon
    aclitem
    _aclitem
    _macaddr
    _macaddr8
    _inet
    _cidr
    _cstring
    bpchar
    varchar
    date
    time
    timestamp
    _timestamp
    _date
    _time
    timestamptz
    _timestamptz
    interval
    _interval
    _numeric
    timetz
    _timetz
    bit
    _bit
    varbit
    _varbit
    numeric
    refcursor
    _refcursor
    regprocedure
    regoper
    regoperator
    regclass
    regtype
    regrole
    regnamespace
    _regprocedure
    _regoper
    _regoperator
    _regclass
    _regtype
    _regrole
    _regnamespace
    uuid
    _uuid
    pg_lsn
    _pg_lsn
    tsvector
    gtsvector
    tsquery
    regconfig
    regdictionary
    _tsvector
    _gtsvector
    _tsquery
    _regconfig
    _regdictionary
    jsonb
    _jsonb
    txid_snapshot
    _txid_snapshot
    int4range
    _int4range
    numrange
    _numrange
    tsrange
    _tsrange
    tstzrange
    _tstzrange
    daterange
    _daterange
    int8range
    _int8range
    record
    _record
    cstring
    any
    anyarray
    void
    trigger
    event_trigger
    language_handler
    internal
    opaque
    anyelement
    anynonarray
    anyenum
    fdw_handler
    index_am_handler
    tsm_handler
    anyrange
    pg_attrdef
    pg_constraint
    pg_inherits
    pg_index
    pg_operator
    pg_opfamily
    pg_opclass
    pg_am
    pg_amop
    pg_amproc
    pg_language
    pg_largeobject_metadata
    pg_largeobject
    pg_aggregate
    pg_statistic_ext
    pg_statistic
    pg_rewrite
    pg_trigger
    pg_event_trigger
    pg_description
    pg_cast
    pg_enum
    pg_namespace
    pg_conversion
    pg_depend
    pg_database
    pg_db_role_setting
    pg_tablespace
    pg_pltemplate
    pg_authid
    pg_auth_members
    pg_shdepend
    pg_shdescription
    pg_ts_config
    pg_ts_config_map
    pg_ts_dict
    pg_ts_parser
    pg_ts_template
    pg_extension
    pg_foreign_data_wrapper
    pg_foreign_server
    pg_user_mapping
    pg_foreign_table
    pg_policy
    pg_replication_origin
    pg_default_acl
    pg_init_privs
    pg_seclabel
    pg_shseclabel
    pg_collation
    pg_partitioned_table
    pg_range
    pg_transform
    pg_sequence
    pg_publication
    pg_publication_rel
    pg_subscription
    pg_subscription_rel
    pg_roles
    pg_shadow
    pg_group
    pg_user
    pg_policies
    pg_rules
    pg_views
    pg_tables
    pg_matviews
    pg_indexes
    pg_sequences
    pg_stats
    pg_publication_tables
    pg_locks
    pg_cursors
    pg_available_extensions
    pg_available_extension_versions
    pg_prepared_xacts
    pg_prepared_statements
    pg_seclabels
    pg_settings
    pg_file_settings
    pg_hba_file_rules
    pg_timezone_abbrevs
    pg_timezone_names
    pg_config
    pg_stat_all_tables
    pg_stat_xact_all_tables
    pg_stat_sys_tables
    pg_stat_xact_sys_tables
    pg_stat_user_tables
    pg_stat_xact_user_tables
    pg_statio_all_tables
    pg_statio_sys_tables
    pg_statio_user_tables
    pg_stat_all_indexes
    pg_stat_sys_indexes
    pg_stat_user_indexes
    pg_statio_all_indexes
    pg_statio_sys_indexes
    pg_statio_user_indexes
    pg_statio_all_sequences
    pg_statio_sys_sequences
    pg_statio_user_sequences
    pg_stat_activity
    pg_stat_replication
    pg_stat_wal_receiver
    pg_stat_subscription
    pg_stat_ssl
    pg_replication_slots
    pg_stat_database
    pg_stat_database_conflicts
    pg_stat_user_functions
    pg_stat_xact_user_functions
    pg_stat_archiver
    pg_stat_bgwriter
    pg_stat_progress_vacuum
    pg_user_mappings
    pg_replication_origin_status
    hstore
    integer
);

sub type_by_name {
    my ($self, $name) = @_;
    return $predefined_types{$name} if $predefined_types{$name};
    my ($type) = grep {
        $_->{name} eq $name
    } $self->{types}->@* or die 'cannot find type ' . $name;
    return $type;
}

1;

