package DBD::Avatica;

# ABSTRACT: Driver for Apache Avatica compatible servers

use strict;
use warnings;
use DBI;
use vars qw($VERSION $err $errstr $sqlstate $drh);

$VERSION = '0.2.2';

$drh = undef;

sub driver {
  return $drh if $drh;
  my ($class, $attr) = @_;
  DBI->setup_driver('DBD::Avatica');
  $drh = DBI::_new_drh("${class}::dr", {
    'Name'          => 'Avatica',
    'Version'       => $VERSION,
    'Err'           => \$err,
    'Errstr'        => \$errstr,
    'State'         => \$sqlstate,
    'Attribution'   => "DBD::Avatica $VERSION by skbkontur team"
  });
  return $drh;
}

sub CLONE {
  $drh = undef;
}

# h - some handle, it may be drh, dbh, sth
sub _client {
  my ($h, $method) = (shift, shift);

  my $client = $h->FETCH('avatica_client');
  return unless $client;

  my $connection_id = $h->FETCH('avatica_connection_id');

  local $SIG{PIPE} = "IGNORE";

  my $is_trace = $h->trace();
  $h->trace_msg(join('; ', '--> ', $method, ($connection_id // ()), (map { $_ // 'undef' } @_), "\n")) if $is_trace;

  my ($ret, $response) = $client->$method($connection_id // (), @_);

  $h->trace_msg(join('; ', '<-- ', $method, ($ret ? ref($response)->encode_json($response) : $response), "\n")) if $is_trace;

  unless ($ret) {
    if ($response->{protocol}) {
      my ($err, $msg, $state) =  @{$response->{protocol}}{qw/error_code message sql_state/};
      my $status = $response->{http_status};
      $msg = "http status $status, error code $err, sql state $state" unless $msg;
      $h->set_err($err, $msg, $state);
    } else {
        $h->set_err(1, $response->{message});
    }
  }

  return ($ret, $response);
}

package DBD::Avatica::dr;

our $imp_data_size = 0;

use strict;
use warnings;

use DBI;
use Avatica::Client;

*_client = \&DBD::Avatica::_client;

sub connect {
  my ($drh, $dsn, $user, $pass, $attr) = @_;

  my %dsn = split /[;=]/, $dsn;

  my $adapter_name = ucfirst($dsn{adapter_name} // '');
  return $drh->set_err(1, q{Parameter "adapter_name" is required in dsn}) unless $adapter_name;
  my $adapter_class_path = "DBD/Avatica/Adapter/${adapter_name}.pm";
  my $adapter_class = "DBD::Avatica::Adapter::${adapter_name}";
  return $drh->set_err(1, qq{Adapter for adapter_name param $adapter_name not found}) unless eval { require $adapter_class_path; 1};

  my $url = $dsn{url};
  $url = 'http://' . $dsn{'hostname'} . ':' . $dsn{'port'} if !$url && $dsn{'hostname'} && $dsn{'port'};
  return $drh->set_err(1, q{Missing "url" parameter}) unless $url;

  my %client_params;
  $client_params{ua} = delete $attr->{UserAgent} if $attr->{UserAgent};
  $client_params{max_retries} = delete $attr->{MaxRetries} if $attr->{MaxRetries};

  my $client = Avatica::Client->new(url => $url, %client_params);
  my $connection_id = _random_str();

  $drh->{avatica_client} = $client;
  my ($ret, $response) = _client($drh, 'open_connection', $connection_id);
  $drh->{avatica_client} = undef;

  return unless $ret;

  my ($outer, $dbh) = DBI::_new_dbh($drh, {
    'Name' => $dsn
  });

  my $adapter = $adapter_class->new(dbh => $dbh);
  $dbh->{avatica_adapter} = $adapter;

  $dbh->{avatica_pid} = $$;

  $dbh->STORE(Active => 1);

  $dbh->{avatica_client} = $client;
  $dbh->{avatica_connection_id} = $connection_id;
  my $connections = $drh->{avatica_connections} || [];
  push @$connections, $dbh;
  $drh->{avatica_connections} = $connections;

  for (qw/AutoCommit ReadOnly TransactionIsolation Catalog Schema/) {
    $dbh->{$_} = delete $attr->{$_} if exists $attr->{$_};
  }
  DBD::Avatica::db::_sync_connection_params($dbh);
  DBD::Avatica::db::_load_database_properties($dbh);

  $outer;
}

sub data_sources { }

sub disconnect_all {
  my $drh = shift;
  my $connections = $drh->{avatica_connections};
  return unless $connections && @$connections;

  my ($dbh, $name);
  while ($dbh = shift @$connections) {
    $name = $dbh->{Name};
    $drh->trace_msg("Disconnecting $name\n", 3);
    $dbh->disconnect();
  }
}

sub _random_str {
  my @alpha = ('0' .. '9', 'a' .. 'z');
  return join '', @alpha[ map { rand scalar(@alpha) } 1 .. 30 ];
}

sub STORE {
  my ($drh, $attr, $value) = @_;
  if ($attr =~ m/^avatica_/) {
    $drh->{$attr} = $value;
    return 1;
  }
  return $drh->SUPER::STORE($attr, $value);
}

sub FETCH {
  my ($drh, $attr) = @_;
  if ($attr =~ m/^avatica_/) {
    return $drh->{$attr};
  }
  return $drh->SUPER::FETCH($attr);
}

package DBD::Avatica::db;

our $imp_data_size = 0;

use strict;
use warnings;

use DBI;

*_client = \&DBD::Avatica::_client;

sub prepare {
  my ($dbh, $statement, $attr) = @_;

  my ($ret, $response) = _client($dbh, 'prepare', $statement);
  return unless $ret;

  my $stmt = $response->get_statement;
  my $statement_id = $stmt->get_id;
  my $signature = $stmt->get_signature;

  my ($outer, $sth) = DBI::_new_sth($dbh, {'Statement' => $statement});

  $sth->STORE(NUM_OF_PARAMS => $signature->parameters_size);
  $sth->STORE(NUM_OF_FIELDS => undef);

  $sth->{avatica_client} = $dbh->FETCH('avatica_client');
  $sth->{avatica_connection_id} = $dbh->FETCH('avatica_connection_id');
  $sth->{avatica_statement_id} = $statement_id;
  $sth->{avatica_signature} = $signature;
  $sth->{avatica_params} = $signature->get_parameters_list;
  $sth->{avatica_rows} = -1;
  $sth->{avatica_bind_params} = [];
  $sth->{avatica_data_done} = 1;
  $sth->{avatica_data} = [];

  $outer;
}

sub ping {
  my $dbh = shift;

  my $sth = $dbh->{avatica_cached_stmt_ping};
  if ($sth && !$sth->FETCH('Active')) {
    $sth = $dbh->{avatica_cached_stmt_ping};
  } else {
    my ($ret, $response) = _client($dbh, 'create_statement');
    return unless $ret;

    my $statement_id = $response->get_statement_id;

    (my $outer, $sth) = DBI::_new_sth($dbh, {'Statement' => 'SELECT 1'});
    $sth->{avatica_client} = $dbh->FETCH('avatica_client');
    $sth->{avatica_connection_id} = $dbh->FETCH('avatica_connection_id');
    $sth->{avatica_statement_id} = $statement_id;

    $dbh->{avatica_cached_stmt_ping} = $sth;
  }

  my ($ret, $response) = _client($dbh, 'prepare_and_execute', $sth->{avatica_statement_id}, 'SELECT 1', undef, DBD::Avatica::st->FETCH_SIZE);
  return unless $ret;

  $sth->finish;
  return 1;

  # after fix of CALCITE-4900 code below will be more correct
  # my $sth = $dbh->prepare_cached('SELECT 1') or return 0;
  # $sth->execute or return 0;
  # $sth->finish;
  # return 1;
}

sub begin_work {
  my $dbh = shift;
  $dbh->{avatica_autocommit_at_begin_work} = $dbh->{AutoCommit};
  return 1 unless $dbh->{AutoCommit};
  $dbh->{AutoCommit} = 0;
  return _sync_connection_params($dbh);
}

sub commit {
  my $dbh = shift;
  return 1 if $dbh->{AutoCommit};
  my ($ret, $response) = _client($dbh, 'commit');
  return $ret unless $dbh->{avatica_autocommit_at_begin_work};
  $dbh->{AutoCommit} = 1;
  unless (_sync_connection_params($dbh)) {
    warn 'DBD::Avatica::db commit failed: ' . $dbh->errstr if $dbh->{PrintError};
    # clear errors of setting autocomit = 1, because commit succeed
    $dbh->set_err(undef, undef, '');
  }
  return $ret;
}

sub rollback {
  my $dbh = shift;
  return 1 if $dbh->{AutoCommit};
  my ($ret, $response) = _client($dbh, 'rollback');
  return $ret unless $dbh->{avatica_autocommit_at_begin_work};
  $dbh->{AutoCommit} = 1;
  unless (_sync_connection_params($dbh)) {
    warn 'DBD::Avatica::db rollback failed: ' .  $dbh->errstr if $dbh->{PrintError};
    # clear errors of setting autocomit = 1, because rollback succeed
    $dbh->set_err(undef, undef, '');
  }
  return $ret;
}

sub last_insert_id {
  my $dbh = shift;
  return $dbh->{avatica_adapter}->last_insert_id($dbh, @_);
}

my %get_info_type = (
  ## Driver information:
    6 => ['SQL_DRIVER_NAME',                     'DBD::Avatica'            ],
    7 => ['SQL_DRIVER_VER',                      'DBD_VERSION'             ], # magic word
  14 => ['SQL_SEARCH_PATTERN_ESCAPE',           '\\'                      ],
  ## DBMS Information
  17 => ['SQL_DBMS_NAME',                       'DBMS_NAME'               ], # magic word
  18 => ['SQL_DBMS_VERSION',                    'DBMS_VERSION'            ], # magic word
  ## Data source information
  ## Supported SQL
  114 => ['SQL_CATALOG_LOCATION',                0                         ],
  41 => ['SQL_CATALOG_NAME_SEPARATOR',          ''                        ],
  28 => ['SQL_IDENTIFIER_CASE',                 1                         ], # SQL_IC_UPPER
  29 => ['SQL_IDENTIFIER_QUOTE_CHAR',           q{"}                      ],
  89 => ['SQL_KEYWORDS',                        'SQL_KEYWORDS'            ], # magic word
  ## SQL limits
  ## Scalar function information
  ## Conversion information - all but BIT, LONGVARBINARY, and LONGVARCHAR
);
for (keys %get_info_type) {
  $get_info_type{$get_info_type{$_}->[0]} = $get_info_type{$_};
}

sub get_info {
  my ($dbh, $type) = @_;
  my $res = $get_info_type{$type}[1];

  if (grep { $res eq $_ } 'DBMS_NAME', 'DBMS_VERSION', 'SQL_KEYWORDS') {
    _load_database_properties($dbh) unless $dbh->{avatica_info_type_cache};
    return $dbh->{avatica_info_type_cache}{$res};
  }

  if ($res eq 'DBD_VERSION') {
    my $v = $DBD::Avatica::VERSION;
    $v =~ s/_/./g; # 1.12.3_4 strip trial/dev symbols
    $v =~ s/[^0-9.]//g; # strip trial/dev symbols, a-la "-TRIAL" at the end
    return sprintf '%02d.%02d.%1d%1d%1d%1d', (split(/\./, "${v}.0.0.0.0.0.0"))[0..5];
  }

  return $res;
}

# returned columns:
# TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS, TYPE_NAME, SELF_REFERENCING_COL_NAME,
# REF_GENERATION, INDEX_STATE, IMMUTABLE_ROWS, SALT_BUCKETS, MULTI_TENANT, VIEW_STATEMENT, VIEW_TYPE,
# INDEX_TYPE, TRANSACTIONAL, IS_NAMESPACE_MAPPED, GUIDE_POSTS_WIDTH, TRANSACTION_PROVIDER
sub table_info {
  my $dbh = shift;
  my ($catalog, $schema, $table, $type) = @_;

  # minimum number of columns
  my $cols = ['TABLE_CAT', 'TABLE_SCHEM', 'TABLE_NAME', 'TABLE_TYPE', 'REMARKS'];

  if (
    defined $catalog && $catalog eq '%' &&
    defined $schema && $schema eq '' &&
    defined $table && $table eq ''
  ) {
    # returned columns: TABLE_CAT
    my ($ret, $response) = _client($dbh, 'catalog');
    return unless $ret;
    my $sth = _sth_from_result_set($dbh, 'table_info_catalog', $response);
    my $rows = $sth->fetchall_arrayref;
    push @$_, (undef) x 4 for @$rows; # fill to the minimum number of columns
    return _sth_from_data('table_info_catalog', $rows, $cols);
  }

  if (
    defined $catalog && $catalog eq '' &&
    defined $schema && $schema eq '%' &&
    defined $table && $table eq ''
  ) {
    # returned columns: TABLE_SCHEM, TABLE_CATALOG
    my ($ret, $response) = _client($dbh, 'schemas');
    return unless $ret;
    my $sth = _sth_from_result_set($dbh, 'table_info_schemas', $response);
    my $rows = $sth->fetchall_arrayref;
    $_ = [reverse(@$_), (undef) x 3] for @$rows; # fill to the minimum number of columns
    return _sth_from_data('table_info_schemas', $rows, $cols);
  }

  if (
    defined $catalog && $catalog eq '' &&
    defined $schema && $schema eq '' &&
    defined $table && $table eq '' &&
    defined $type && $type eq '%'
  ) {
    # returned columns: TABLE_TYPE
    my ($ret, $response) = _client($dbh, 'table_types');
    return unless $ret;
    my $sth = _sth_from_result_set($dbh, 'table_info_table_types', $response);
    my $rows = $sth->fetchall_arrayref;
    $_ = [(undef) x 3, @$_, undef] for @$rows; # fill to the minimum number of columns
    return _sth_from_data('table_info_table_types', $rows, $cols);
  }

  my ($ret, $response) = _client($dbh, 'tables', $catalog, $schema, $table, $type);
  return unless $ret;
  return _sth_from_result_set($dbh, 'table_info', $response);
}

# returned columns:
# TABLE_CAT, TABLE_SCHEM, TABLE_NAME, COLUMN_NAME, DATA_TYPE, TYPE_NAME, COLUMN_SIZE, BUFFER_LENGTH,
# DECIMAL_DIGITS, NUM_PREC_RADIX, NULLABLE, REMARKS, COLUMN_DEF, SQL_DATA_TYPE, SQL_DATETIME_SUB,
# CHAR_OCTET_LENGTH, ORDINAL_POSITION, IS_NULLABLE, SCOPE_CATALOG, SCOPE_SCHEMA, SCOPE_TABLE,
# SOURCE_DATA_TYPE, IS_AUTOINCREMENT, ARRAY_SIZE, COLUMN_FAMILY, TYPE_ID, VIEW_CONSTANT, MULTI_TENANT,
# KEY_SEQ
sub column_info {
  my $dbh = shift;
  my ($catalog, $schema, $table, $column) = @_;

  my ($ret, $response) = _client($dbh, 'columns', $catalog, $schema, $table, $column);
  return unless $ret;

  return _sth_from_result_set($dbh, 'column_info', $response);
}

# returned columns:
# TABLE_CAT, TABLE_SCHEM, TABLE_NAME, COLUMN_NAME, KEY_SEQ, PK_NAME,
# ASC_OR_DESC, DATA_TYPE, TYPE_NAME, COLUMN_SIZE, TYPE_ID, VIEW_CONSTANT
sub primary_key_info {
  my ($dbh, $catalog, $schema, $table) = @_;

  my ($ret, $response) = _client($dbh, 'primary_keys', $catalog, $schema, $table);
  return unless $ret;

  # extend signature with database specific columns
  $dbh->{avatica_adapter}->extend_primary_key_info_signature($response->get_signature);

  return _sth_from_result_set($dbh, 'primary_keys', $response);
}

sub foreign_key_info { }

sub statistics_info { }

sub type_info_all { [] }

sub _sth_from_data {
  my ($statement, $rows, $col_names, %attr) = @_;
  my $sponge = DBI->connect('dbi:Sponge:', '', '', { RaiseError => 1 });
  my $sth = $sponge->prepare($statement, { rows=>$rows, NAME=>$col_names, %attr });
  return $sth;
}

sub _sth_from_result_set {
  my ($dbh, $operation, $result_set) = @_;

  my $statement_id = $result_set->get_statement_id;
  my $signature = $result_set->get_signature;
  my $num_columns = $signature->columns_size;

  my ($outer, $sth) = DBI::_new_sth($dbh, {'Statement' => $operation});

  my $frame = $result_set->get_first_frame;
  $sth->{avatica_data_done} = $frame->get_done;
  $sth->{avatica_data} = $frame->get_rows_list;
  $sth->{avatica_rows} = 0;
  $sth->{avatica_client} = $dbh->{avatica_client};
  $sth->{avatica_connection_id} = $dbh->{avatica_connection_id};
  $sth->{avatica_statement_id} = $statement_id;
  $sth->{avatica_signature} = $signature;

  $sth->STORE(NUM_OF_FIELDS => $num_columns);
  $sth->STORE(Active => 1);

  $outer;
}

sub _sync_connection_params {
  my $dbh = shift;
  my %props = map { $_ => $dbh->{$_} }
              grep { exists $dbh->{$_} }
              qw/AutoCommit ReadOnly TransactionIsolation Catalog Schema/;

  my ($ret, $response) = _client($dbh, 'connection_sync', \%props);
  return unless $ret;

  my $props = $response->get_conn_props;
  $dbh->{AutoCommit} = $props->get_auto_commit if $props->has_auto_commit;
  $dbh->{ReadOnly} = $props->get_read_only if $props->has_read_only;
  $dbh->{TransactionIsolation} = $props->get_transaction_isolation;
  $dbh->{Catalog} = $props->get_catalog if $props->get_catalog;
  $dbh->{Schema} = $props->get_schema if $props->get_schema;
  return 1;
}

sub _load_database_properties {
  my $dbh = shift;
  my ($ret, $response) = _client($dbh, 'database_property');
  return unless $ret;
  my $props = $dbh->{avatica_adapter}->map_database_properties($response->get_props_list);
  $dbh->{$_} = $props->{$_} for qw/AVATICA_DRIVER_NAME AVATICA_DRIVER_VERSION/;
  $dbh->{avatica_info_type_cache}{$_} = $props->{$_} for qw/DBMS_NAME DBMS_VERSION SQL_KEYWORDS/;
}

sub disconnect {
  my $dbh = shift;
  return 1 unless $dbh->FETCH('Active');

  delete $dbh->{avatica_cached_stmt_ping};

  $dbh->STORE(Active => 0);

  if ($dbh->{avatica_pid} != $$) {
    $dbh->{avatica_client} = undef;
    return 1;
  }

  my ($ret, $response) = _client($dbh, 'close_connection');
  $dbh->{avatica_client} = undef;

  return $ret;
}

sub STORE {
  my ($dbh, $attr, $value) = @_;
  if (grep { $attr eq $_ } ('AutoCommit', 'ReadOnly', 'TransactionIsolation', 'Catalog', 'Schema')) {
    $dbh->{$attr} = $value;
    _sync_connection_params($dbh);
    return 1;
  }
  if ($attr =~ m/^avatica_/) {
    $dbh->{$attr} = $value;
    return 1;
  }
  # READ ONLY attributes
  return 0 if grep { $attr eq $_ } qw/AVATICA_DRIVER_NAME AVATICA_DRIVER_VERSION/;
  return $dbh->SUPER::STORE($attr, $value);
}

sub FETCH {
  my ($dbh, $attr) = @_;
  if ($attr =~ m/^avatica_/) {
    return $dbh->{$attr};
  }
  if (grep { $attr eq $_ }
    qw/AutoCommit ReadOnly TransactionIsolation Catalog Schema AVATICA_DRIVER_NAME AVATICA_DRIVER_VERSION/) {
    return $dbh->{$attr};
  }
  return $dbh->SUPER::FETCH($attr);
}

sub DESTROY {
  my $dbh = shift;
  return unless $dbh->FETCH('Active');
  return if $dbh->FETCH('InactiveDestroy');
  eval { $dbh->disconnect() };
}

package DBD::Avatica::st;

our $imp_data_size = 0;

use strict;
use warnings;

use DBI;

use constant FETCH_SIZE => 2000;
use constant BATCH_SIZE => 2000;

*_client = \&DBD::Avatica::_client;


sub bind_param {
  my ($sth, $param, $value, $attr) = @_;

  # at the moment the type is not processed because we know type from prepare request
  # my ($type) = (ref $attr) ? $attr->{'TYPE'} : $attr;

  my $params = $sth->{avatica_bind_params};
  $params->[$param - 1] = $value;
  1;
}

sub execute {
  my ($sth, @bind_values) = @_;

  my $bind_params = $sth->{avatica_bind_params};
  @bind_values = @$bind_params if !@bind_values && $bind_params && @$bind_params;

  my $num_params = $sth->FETCH('NUM_OF_PARAMS');
  return $sth->set_err(1, 'Wrong number of parameters') if @bind_values != $num_params;

  my $statement_id = $sth->{avatica_statement_id};
  my $signature = $sth->{avatica_signature};

  my $dbh = $sth->{Database};
  my $mapped_params = $dbh->{avatica_adapter}->row_to_jdbc(\@bind_values, $sth->{avatica_params});

  my ($ret, $response) = _client($sth, 'execute', $statement_id, $signature, $mapped_params, DBD::Avatica::st->FETCH_SIZE);
  unless ($ret) {
    return if $num_params != 0 || index($response->{message}, 'NullPointerException') == -1;

    # https://issues.apache.org/jira/browse/CALCITE-4900
    # so, workaround, if num_params == 0 then need to use create_statement && prepare_and_execute without params

    # clear errors
    $sth->set_err(undef, undef, '');

    my $sql = $sth->FETCH('Statement');

    ($ret, $response) = _client($sth, 'create_statement');
    return unless $ret;

    _avatica_close_statement($sth);
    $statement_id = $sth->{avatica_statement_id} = $response->get_statement_id;

    ($ret, $response) = _client($sth, 'prepare_and_execute', $statement_id, $sql, undef, DBD::Avatica::st->FETCH_SIZE);
    return unless $ret;
  }

  my $result = $response->get_results(0);

  if ($result->get_own_statement) {
    my $new_statement_id = $result->get_statement_id;
    _avatica_close_statement($sth) if $statement_id && $statement_id != $new_statement_id;
    $sth->{avatica_statement_id} = $new_statement_id;
  }

  $signature = $result->get_signature;
  $sth->{avatica_signature} = $signature if $signature;

  my $num_updates = $result->get_update_count;
  $num_updates = -1 if $num_updates == '18446744073709551615'; # max_int

  if ($num_updates >= 0) {
    # DML
    $sth->STORE(Active => 0);
    $sth->STORE(NUM_OF_FIELDS => 0);
    $sth->{avatica_rows} = $num_updates;
    $sth->{avatica_data_done} = 1;
    $sth->{avatica_data} = [];
    return $num_updates == 0 ? '0E0' : $num_updates;
  }

  # SELECT
  my $frame = $result->get_first_frame;
  $sth->{avatica_data_done} = $frame->get_done;
  $sth->{avatica_data} = $frame->get_rows_list;
  $sth->{avatica_rows} = 0;

  my $num_columns = $signature->columns_size;
  $sth->STORE(Active => 1);
  $sth->STORE(NUM_OF_FIELDS => $num_columns);

  return 1;
}

sub _execute_batch {
  my ($sth, $rows) = @_;

  my $statement_id = $sth->{avatica_statement_id};
  my $signature = $sth->{avatica_signature};

  my $dbh = $sth->{Database};
  my $mapped_params = [
    map {
      $dbh->{avatica_adapter}->row_to_jdbc($_, $sth->{avatica_params});
    }
    @$rows
  ];

  my ($ret, $response) = _client($sth, 'execute_batch', $statement_id, $mapped_params);
  return unless $ret;

  my $updates = $response->get_update_counts_list;
  # 18446744073709551615 is max int64
  return [map { $_ == '18446744073709551615' ? -1 : $_ } @$updates]
}

sub execute_for_fetch {
    my ($sth, $fetch_tuple_sub, $tuple_status) = @_;
    # start with empty status array
    ($tuple_status) ? @$tuple_status = () : $tuple_status = [];

    my ($tuples, $rc_total) = (0, 0);
    my $err_count;
    while (1) {
      my ($rows, $rows_count) = ([], 0);

      while (my $tuple = &$fetch_tuple_sub()) {
        push @$rows, $tuple;
        ++$rows_count;
        last if $rows_count >= DBD::Avatica::st->BATCH_SIZE;
      }
      last unless @$rows;

      $tuples += @$rows;

      if ( my $many_rc = _execute_batch($sth, $rows) ) {
        push @$tuple_status, @$many_rc;
        for my $rc (@$many_rc) {
          $rc_total = ($rc >= 0 && $rc_total >= 0) ? $rc_total + $rc : -1;
        }
      } else {
        $err_count += @$rows;
        my $status = [ $sth->err, $sth->errstr, $sth->state ];
        push @$tuple_status, $status for @$rows;
      }

      last if @$rows < DBD::Avatica::st->BATCH_SIZE;
    }

    return $sth->set_err($DBI::stderr, "executing $tuples generated $err_count errors") if $err_count;
    $tuples ||= "0E0";

    return $tuples unless wantarray;
    return ($tuples, $rc_total);
}

sub fetch {
  my ($sth) = @_;

  my $signature = $sth->{avatica_signature};

  my $avatica_rows_list = $sth->{avatica_data};
  my $avatica_rows_done = $sth->{avatica_data_done};

  if ((!$avatica_rows_list || !@$avatica_rows_list) && !$avatica_rows_done) {
    my $statement_id  = $sth->{avatica_statement_id};
    my ($ret, $response) = _client($sth, 'fetch', $statement_id, undef, DBD::Avatica::st->FETCH_SIZE);
    return unless $ret;

    my $frame = $response->get_frame;
    $sth->{avatica_data_done} = $frame->get_done;
    $sth->{avatica_data} = $frame->get_rows_list;

    $avatica_rows_done = $sth->{avatica_data_done};
    $avatica_rows_list = $sth->{avatica_data};
  }

  if ($avatica_rows_list && @$avatica_rows_list) {
    $sth->{avatica_rows} += 1;
    my $dbh = $sth->{Database};
    my $avatica_row = shift @$avatica_rows_list;
    my $values = $avatica_row->get_value_list;
    my $columns = $signature->get_columns_list;
    my $row = $dbh->{avatica_adapter}->row_from_jdbc($values, $columns);
    return $sth->_set_fbav($row);
  }

  $sth->finish;
  return;
}
*fetchrow_arrayref = \&fetch;

sub rows {
  shift->{avatica_rows}
}

# It seems that here need to call _avatica_close_statement method,
# but then such a scenario will not work
# when there are many "execute" commands for one "prepare" command.
# Therefore, we will not do this here.
sub finish {
  my $sth = shift;
  $sth->STORE(Active => 0);
  1;
}

sub STORE {
  my ($sth, $attr, $value) = @_;
  if ($attr =~ m/^avatica_/) {
    $sth->{$attr} = $value;
    return 1;
  }
  return $sth->SUPER::STORE($attr, $value);
}

sub FETCH {
  my ($sth, $attr) = @_;
  if ($attr =~ m/^avatica_/) {
    return $sth->{$attr};
  }
  if ($attr eq 'NAME') {
    return $sth->{avatica_cache_name} ||=
        [map { $_->get_column_name } @{$sth->{avatica_signature}->get_columns_list}];
  }
  if ($attr eq 'TYPE') {
    my $dbh = $sth->{Database};
    return $sth->{avatica_cache_type} ||=
        [map { $dbh->{avatica_adapter}->to_dbi($_->get_type) } @{$sth->{avatica_signature}->get_columns_list}];
  }
  if ($attr eq 'PRECISION') {
    return $sth->{avatica_cache_precision} ||=
        [map { $_->get_display_size } @{$sth->{avatica_signature}->get_columns_list}];
  }
  if ($attr eq 'SCALE') {
    return $sth->{avatica_cache_scale} ||=
        [map { $_->get_scale || undef } @{$sth->{avatica_signature}->get_columns_list}];
  }
  if ($attr eq 'NULLABLE') {
    return $sth->{avatica_cache_nullable} ||=
        [map { $_->get_nullable} @{$sth->{avatica_signature}->get_columns_list}];
  }
  if ($attr eq 'ParamValues') {
    return $sth->{avatica_cache_paramvalues} ||=
        {map { $_ => ($sth->{avatica_bind_params}->[$_ - 1] // undef) } 1 .. @{$sth->{avatica_params} // []}};
  }
  return $sth->SUPER::FETCH($attr);
}

sub _avatica_close_statement {
  my $sth = shift;
  my $statement_id  = $sth->{avatica_statement_id};
  _client($sth, 'close_statement', $statement_id) if $statement_id && $sth->FETCH('Database')->{avatica_pid} == $$;
  $sth->{avatica_statement_id} = undef;
}

sub DESTROY {
  my $sth = shift;
  return if $sth->FETCH('InactiveDestroy');
  return unless $sth->FETCH('Database')->FETCH('Active');
  eval { _avatica_close_statement($sth) };
  $sth->finish;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::Avatica - Driver for Apache Avatica compatible servers

=head1 VERSION

version 0.2.2

=head1 SYNOPSIS

  use DBI;

  # for Apache Phoenix
  $dbh = DBI->connect("dbi:Avatica:adapter_name=phoenix;url=http://127.0.0.1:8765", '', '', {AutoCommit => 0}) or die $DBI::errstr;
  # The AutoCommit attribute should always be explicitly set

  $rows = $dbh->do('UPSERT INTO mytable(a) VALUES (1)') or die $dbh->errstr;

  $sth = $dbh->prepare('UPSERT INTO mytable(a) VALUES (?)') or die $dbh->errstr;
  $sth->execute(2) or die $sth->errstr;

=head1 DESCRIPTION

DBD::Avatica is a Perl module that works with the DBI module to provide access to
databases with Apache Avatica compatible protocol.

=head1 MODULE DOCUMENTATION

This documentation describes driver specific behavior and restrictions. It is
not supposed to be used as the only reference for the user. In any case
consult the B<DBI> documentation first!

L<Latest DBI documentation.|DBI>

=head1 THE DBI CLASS

=head2 DBI Class Methods

=head3 B<connect>

This method creates a database handle by connecting to a database, and is the DBI
equivalent of the "new" method. To connect to a database with a minimum of parameters,
use the following syntax:

  $dbh = DBI->connect("dbi:Avatica:adapter_name=phoenix;url=http://127.0.0.1:8765", '', '', {AutoCommit => 0});

This connects to the database accessed by url C<http://127.0.0.1:8765> without any user authentication.

The following connect statement shows almost all possible parameters:

    $dbh = DBI->connect(
        "dbi:Avatica:adapter_name=phoenix;url=$url;",
        $username,
        $password,
        {
            UserAgent  => HTTP::Tiny->new(),
            AutoCommit => 0,
            RaiseError => 1,
            PrintError => 0,
            MaxRetries => 2,
            TransactionIsolation => 2,
        },
    );

Currently username/password not supported. To set username/password for authentication need to redefine UserAgent attribute.

Your UserAgent must implement C<POST> request with HTTP::Tiny semantics.
So, after some timeouts, network errors UserAgent must return http status 599 and do not retries after failure.
For example, Furl has better performance than HTTP::Tiny.

Attrubute MaxRetries specifies the number of retries to send the request (in case HTTP 500 response). Default value is 0.

Specific for Apache Phoenix:
It is not recommended to use the MaxRetries parameter due to the L<CALCITE-4900|https://issues.apache.org/jira/browse/CALCITE-4900>
error, due to which the phoenix server may return an error which will lead to repeated requests, between which sleep is inserted.
It is guaranteed that the total time spent in sleep among all retries is no more than 1.6 seconds.

=head3 B<connect_cached>

  $dbh = DBI->connect_cached("dbi:Avatica:adapter_name=phoenix;url=$url", $username, $password, \%options);

Implemented by DBI, no driver-specific impact.

=head2 Methods Common To All Handles

For all of the methods below, B<$h> can be either a database handle (B<$dbh>)
or a statement handle (B<$sth>). Note that I<$dbh> and I<$sth> can be replaced with
any variable name you choose: these are just the names most often used. Another
common variable used in this documentation is $I<rv>, which stands for "return value".

=head3 B<err>

  $rv = $h->err;

Returns the error code from the last method called. If the error is generated by the perl module
it will always be 1. If an error was received from the server, then the value will be
Avatica::Client::Protocol::ErrorResponse: error_code, which corresponds to an error in the protobuf protocol.

=head3 B<errstr>

  $str = $h->errstr;

Returns the error message from the last method called.

=head3 B<state>

  $str = $h->state;

Returns a five-character "SQLSTATE" code. Success is indicated by a C<00000> code, which
gets mapped to an empty string by DBI.

=head3 B<trace>

  $h->trace(1);
  $h->trace(1, $trace_filename);
  $trace_settings = $h->trace;

Changes the trace settings on a database or statement handle.
The optional second argument specifies a file to write the
trace information to. If no filename is given, the information
is written to F<STDERR>. Note that tracing can be set globally as
well by setting C<< DBI->trace >>, or by using the environment
variable I<DBI_TRACE>.

=head3 B<trace_msg>

  $h->trace_msg($message_text);
  $h->trace_msg($message_text, $min_level);

Writes a message to the current trace output (as set by the L</trace> method). If a second argument
is given, the message is only written if the current tracing level is equal to or greater than
the C<$min_level>.

=head3 B<parse_trace_flag> and B<parse_trace_flags>

  $h->trace($h->parse_trace_flags('ALL')); # not recommended
  $h->trace($h->parse_trace_flags(1));

  ## Simpler:
  $h->trace('ALL'); # not recommended
  $h->trace('1');

The parse_trace_flags method is used to convert one or more named
flags to a number which can passed to the L</trace> method.

Implemented by DBI, no driver-specific impact.
See the L<DBI section on TRACING|DBI/TRACING> for more information.

=head1 ATTRIBUTES COMMON TO ALL HANDLES

=head3 B<InactiveDestroy> (boolean)

If set to true, then the L</disconnect> and statement close methods will not be automatically
called when the database handle goes out of scope. This is required if you are forking,
and even then you must tread carefully and ensure that either the parent or the child (but not
both!) handles all database calls from that point forwards, so that messages from the
Postgres backend are only handled by one of the processes. The best solution is to either
have the child process reconnect to the database with a fresh database handle, or to
rewrite your application not to use forking.

=head3 B<AutoInactiveDestroy> (boolean)

The InactiveDestroy attribute, described above, needs to be explicitly set in the child
process after a fork. If the code that performs the fork is in a third party module such
as Sys::Syslog, this can present a problem. Use AutoInactiveDestroy to get around this
problem.
DBD::Avatica has additional security, but after the fork you still need to create a new
connection in the child process.

=head3 B<RaiseError> (boolean, inherited)

Forces errors to always raise an exception. Although it defaults to off, it is recommended that this
be turned on, as the alternative is to check the return value of every method (prepare, execute, fetch, etc.)
manually, which is easy to forget to do.

=head3 B<PrintError> (boolean, inherited)

Forces database errors to also generate warnings, which can then be filtered with methods such as
locally redefining I<$SIG{__WARN__}> or using modules such as C<CGI::Carp>. This attribute is on
by default.

=head3 B<ShowErrorStatement> (boolean, inherited)

Appends information about the current statement to error messages. If placeholder information
is available, adds that as well. Defaults to false.

Note that this will not work when using L</do> without any arguments.

=head3 B<Warn> (boolean, inherited)

Enables warnings. This is on by default, and should only be turned off in a local block
for a short a time only when absolutely needed.

=head3 B<Executed> (boolean, read-only)

Indicates if a handle has been executed. For database handles, this value is true after the L</do> method has been called, or
when one of the child statement handles has issued an L</execute>. Issuing a L</commit> or L</rollback> always resets the
attribute to false for database handles. For statement handles, any call to L</execute> or its variants will flip the value to
true for the lifetime of the statement handle.

=head3 B<TraceLevel> (integer, inherited)

Sets the trace level, similar to the L</trace> method. See the sections on
L</trace> and L<parse_trace_flag|/parse_trace_flag and parse_trace_flags> for more details.

=head3 B<Active> (boolean, read-only)

Indicates if a handle is active or not. For database handles, this indicates if the database has
been disconnected or not. For statement handles, it indicates if all the data has been fetched yet
or not. Use of this attribute is not encouraged.

=head3 B<Kids> (integer, read-only)

Returns the number of child processes created for each handle type. For a driver handle, indicates the number
of database handles created. For a database handle, indicates the number of statement handles created. For
statement handles, it always returns zero, because statement handles do not create kids.

=head3 B<ActiveKids> (integer, read-only)

Same as C<Kids>, but only returns those that are active.

=head3 B<CachedKids> (hash ref)

Returns a hashref of handles. If called on a database handle, returns all statement handles created by use of the
C<prepare_cached> method. If called on a driver handle, returns all database handles created by the L</connect_cached>
method.

=head3 B<ChildHandles> (array ref)

Implemented by DBI, no driver-specific impact.
See the L<DBI ChildHandles|DBI/ChildHandles> for more information.

=head3 B<PrintWarn> (boolean, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI PrintWarn|DBI/PrintWarn> for more information.

=head3 B<HandleError> (boolean, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI HandleError|DBI/HandleError> for more information.

=head3 B<HandleSetErr> (code ref, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI HandleSetErr|DBI/HandleSetErr> for more information.

=head3 B<ErrCount> (unsigned integer)

Implemented by DBI, no driver-specific impact.
See the L<DBI ErrCount|DBI/ErrCount> for more information.

=head3 B<FetchHashKeyName> (string, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI FetchHashKeyName|DBI/FetchHashKeyName> for more information.

=head3 B<Taint> (boolean, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI Taint|DBI/Taint> for more information.

=head3 B<TaintIn> (boolean, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI TaintIn|DBI/TaintIn> for more information.

=head3 B<TaintOut> (boolean, inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI TaintOut|DBI/TaintOut> for more information.

=head3 B<Profile> (inherited)

Implemented by DBI, no driver-specific impact.
See the L<DBI Profile|DBI/Profile> for more information.

=head3 B<Type> (scalar)

Returns C<dr> for a driver handle, C<db> for a database handle, and C<st> for a statement handle.

=head1 DBI DATABASE HANDLE OBJECTS

=head2 Database Handle Methods

=head3 B<selectall_arrayref>

  $ary_ref = $dbh->selectall_arrayref($sql);
  $ary_ref = $dbh->selectall_arrayref($sql, \%attr);
  $ary_ref = $dbh->selectall_arrayref($sql, \%attr, @bind_values);

Returns a reference to an array containing the rows returned by preparing and executing the SQL string.
See the L<DBI selectall_arrayref|DBI/selectall_arrayref> for more information.

=head3 B<selectall_hashref>

  $hash_ref = $dbh->selectall_hashref($sql, $key_field);

Returns a reference to a hash containing the rows returned by preparing and executing the SQL string.
See the L<DBI selectall_hashref|DBI/selectall_hashref> for more information.

=head3 B<selectcol_arrayref>

  $ary_ref = $dbh->selectcol_arrayref($sql, \%attr, @bind_values);

Returns a reference to an array containing the first column
from each rows returned by preparing and executing the SQL string. It is possible to specify exactly
which columns to return.
See the L<DBI selectcol_arrayref|DBI/selectcol_arrayref> for more information.

=head3 B<prepare>

  $sth = $dbh->prepare($statement, \%attr);

The prepare method prepares a statement for later execution.

You cannot send more than one command at a time in the same prepare command
(by separating them with semi-colons) when using server-side prepares.

The actual C<PREPARE> is usually not performed until the first execute is called, due
to the fact that information on the data types (provided by L</bind_param>) may
be provided after the prepare but before the execute.

=head4 B<Placeholders>

Driver support placeholders and bind values. Placeholders, also called parameter markers,
are used to indicate values in a database statement that will be supplied later, before
the prepared statement is executed. For example, an application might use the following to
insert a row of data into the SALES table:

  INSERT INTO sales (product_code, qty, price) VALUES (?, ?, ?)

or the following, to select the description for a product:

  SELECT description FROM products WHERE product_code = ?

The C<?> characters are the placeholders. The association of actual values with placeholders
is known as binding, and the values are referred to as bind values. Note that the C<?> is not
enclosed in quotation marks, even when the placeholder represents a string.

In the final statement above, DBI thinks there is only one placeholder, so this
statement will replace placeholder:

  $sth->bind_param(1, 2045);
  $sth->execute;

While a simple execute with no C<bind_param> calls requires only a single argument as well:

  $sth->execute(2045);

See the  documentation for more details.
See the L<DBI Placeholders and Bind Values|DBI/Placeholders and Bind Values> for more information.

=head3 B<prepare_cached>

  $sth = $dbh->prepare_cached($statement, \%attr);

Implemented by DBI, no driver-specific impact.
See the L<DBI prepare_cached|DBI/prepare_cached> for more information.

=head3 B<do>

  $rv = $dbh->do($statement);
  $rv = $dbh->do($statement, \%attr);
  $rv = $dbh->do($statement, \%attr, @bind_values);

Prepare and execute a single statement. Returns the number of rows affected if the
query was successful, returns undef if an error occurred, and returns -1 if the
number of rows is unknown or not available. Note that this method will return B<0E0> instead
of 0 for 'no rows were affected', in order to always return a true value if no error occurred.

=head3 B<last_insert_id>

  $rv = $dbh->last_insert_id(undef, $schema, $table, $column);
  $rv = $dbh->last_insert_id(undef, $schema, $table, $column, {sequence => $seqname});

Attempts to return the id of the last value of sequence to be inserted into a table.
You can either provide a sequence name (preferred) or provide a table
name with optional schema, and DBD::Avatica will attempt to find the sequence itself.

If you do not know the name of the sequence, you can provide a table name and
DBD::Avatica will attempt to return the correct value. To do this, there must be at
least one column in the table which uses a sequence, sequence schema name must be similar
schema table name and sequnce prefix name must contain table name. If there are many sequences
in the table then the sequence prefix must contain table name and column name separated by
an underscore symbol.

Example:

  $dbh->do('CREATE SEQUENCE test_seq;');
  $dbh->do('CREATE TABLE test(id bigint primary key, x varchar)');
  $sth = $dbh->prepare('UPSERT INTO test VALUES (NEXT VALUE FOR test_seq, ?)');
  for (qw(foo bar baz)) {
    $sth->execute($_);
    my $newid = $dbh->last_insert_id(undef, undef, undef, undef, {sequence=>'test_seq'});
    print "Last insert id was $newid\n";
  }

=head3 B<commit>

  $rv = $dbh->commit;

Issues a COMMIT to the server, indicating that the current transaction is finished and that
all changes made will be visible to other processes. If AutoCommit is enabled, then
a warning is given and no COMMIT is issued. Returns true on success, false on error.
See also the section on L</Transactions>.

=head3 B<rollback>

  $rv = $dbh->rollback;

Issues a ROLLBACK to the server, which discards any changes made in the current transaction. If AutoCommit
is enabled, then a warning is given and no ROLLBACK is issued. Returns true on success, and
false on error. See also the the section on L</Transactions>.

=head3 B<begin_work>

This method turns on transactions until the next call to L</commit> or L</rollback>, if L<AutoCommit|/AutoCommit (boolean)> is
currently enabled. If it is not enabled, calling C<begin_work> will do nothing. Note that the
transaction will not actually begin until the first statement after C<begin_work> is called.
Example:

  $dbh->{AutoCommit} = 1;
  $dbh->do('UPSERT INTO foo VALUES (123)'); ## Changes committed immediately
  $dbh->begin_work;
  ## Not in a transaction yet, but AutoCommit is set to 0
  $dbh->do('INSERT INTO foo VALUES (345)');
  $dbh->commit;
  ## AutoCommit is now set to 1 again

=head3 B<disconnect>

  $rv = $dbh->disconnect;

Disconnects from the Postgres database.

If the script exits before disconnect is called (or, more precisely, if the database handle is no longer
referenced by anything), then the database handle's DESTROY method will call the disconnect()
methods automatically. It is best to explicitly disconnect rather than rely on this behavior.

=head3 B<quote>

  $rv = $dbh->quote($value);
  $rv = $dbh->quote($value, $data_type);

Quote a string literal for use as a literal value in an SQL statement, by escaping any special characters
(such as quotation marks) contained within the string and adding the required type of outer quotation marks.

Implemented by DBI, no driver-specific impact.
See the L<DBI quote|DBI/quote> for more information.

=head3 B<quote_identifier>

  $string = $dbh->quote_identifier( $name );
  $string = $dbh->quote_identifier( undef, $schema, $table);

Returns a quoted version of the supplied string, which is commonly a schema,
table, or column name.

Implemented by DBI, no driver-specific impact.
See the L<DBI quote_identifier|DBI/quote_identifier> for more information.

=head3 B<get_info>

  $value = $dbh->get_info($info_type);

Supports a small set of the information types which is reported by the server in the request C<database_property>:

=over 4

=item SQL_DRIVER_NAME

=item SQL_DRIVER_VER

=item SQL_SEARCH_PATTERN_ESCAPE

=item SQL_DBMS_NAME

=item SQL_DBMS_VERSION

=item SQL_CATALOG_LOCATION

=item SQL_CATALOG_NAME_SEPARATOR

=item SQL_IDENTIFIER_CASE

=item SQL_IDENTIFIER_QUOTE_CHAR

=item SQL_KEYWORDS

=back

=head3 B<table_info>

  $sth = $dbh->table_info($catalog, $schema, $table, $type);

Returns all tables and views visible to the current user.

See the L<DBI table_info|DBI/table_info> for more information.

=head3 B<column_info>

  $sth = $dbh->column_info( $catalog, $schema, $table, $column );

Supported by this driver as proposed by DBI.

See the L<DBI column_info|DBI/column_info> for more information.

=head3 B<primary_key_info>

  $sth = $dbh->primary_key_info( $catalog, $schema, $table, \%attr );

Supported by this driver as proposed by DBI.

See the L<DBI primary_key_info|DBI/primary_key_info> for more information.

=head3 B<primary_key>

  @key_column_names = $dbh->primary_key($catalog, $schema, $table);

Simple interface to the L</primary_key_info> method. Returns a list of the column names that
comprise the primary key of the specified table. The list is in primary key column sequence
order. If there is no primary key then an empty list is returned.

=head3 B<tables>

  @names = $dbh->tables( undef, $schema, $table, $type, \%attr );

Supported by this driver as proposed by DBI.

=head3 B<type_info_all>

  $type_info_all = $dbh->type_info_all;

At the moment not supported by DBD::Avatica.

=head3 B<type_info>

  @type_info = $dbh->type_info($data_type);

At the moment not supported by DBD::Avatica.

=head3 B<selectrow_array>

  @row_ary = $dbh->selectrow_array($sql);
  @row_ary = $dbh->selectrow_array($sql, \%attr);
  @row_ary = $dbh->selectrow_array($sql, \%attr, @bind_values);

Returns an array of row information after preparing and executing the provided SQL string. The rows are returned
by calling L</fetchrow_array>. The string can also be a statement handle generated by a previous prepare. Note that
only the first row of data is returned. If called in a scalar context, only the first column of the first row is
returned. Because this is not portable, it is not recommended that you use this method in that way.

=head3 B<selectrow_arrayref>

  $ary_ref = $dbh->selectrow_arrayref($statement);
  $ary_ref = $dbh->selectrow_arrayref($statement, \%attr);
  $ary_ref = $dbh->selectrow_arrayref($statement, \%attr, @bind_values);

Exactly the same as L</selectrow_array>, except that it returns a reference to an array, by internal use of
the L</fetchrow_arrayref> method.

=head3 B<selectrow_hashref>

  $hash_ref = $dbh->selectrow_hashref($sql);
  $hash_ref = $dbh->selectrow_hashref($sql, \%attr);
  $hash_ref = $dbh->selectrow_hashref($sql, \%attr, @bind_values);

Exactly the same as L</selectrow_array>, except that it returns a reference to an hash, by internal use of
the L</fetchrow_hashref> method.

=head3 B<clone>

  $other_dbh = $dbh->clone();

Creates a copy of the database handle by connecting with the same parameters as the original
handle, then trying to merge the attributes.
See the L<DBI clone|DBI/clone> for more information.

=head2 Database Handle Attributes

=head3 B<AutoCommit> (boolean)

Supported by DBD::Avatica as proposed by DBI. Without starting a transaction,
every change to the database becomes immediately permanent. The default of
AutoCommit is on, but this may change in the future, so it is highly recommended
that you explicitly set it when calling L</connect>.
For details see the notes about L</Transactions> elsewhere in this document.

=head3 B<ReadOnly> (boolean)

  $dbh->{ReadOnly} = 1;

Specifies if the current database connection should be in read-only mode or not.

=head3 B<TransactionIsolation> (integer)

  $dbh->{TransactionIsolation} = 2;

Specifies the transaction isolation level.

=over 4

=item '0'

Transactions are not supported

=item '1'

READ UNCOMMITED. Dirty reads, non-repeatable reads and phantom reads may occur.

=item '2'

READ COMMITED. Dirty reads are prevented, but non-repeatable reads and phantom reads may occur.

=item '4'

REPEATABLE READ. Dirty reads and non-repeatable reads are prevented, but phantom reads may occur.

=item '8'

SERIALIZABLE. Dirty reads, non-repeatable reads, and phantom reads are all prevented.

=back

=head3 B<AVATICA_DRIVER_NAME> (string, read-only)

Return avatica driver name.

=head3 B<AVATICA_DRIVER_VERSION> (string, read-only)

Return avatica driver version.

=head3 B<Name> (string, read-only)

Returns the name of the database and the URL to which it is connected.
This is the same as the DSN, without the "dbi:Avatica:" part.

=head1 DBI STATEMENT HANDLE OBJECTS

=head2 Statement Handle Methods

=head3 B<bind_param>

  $rv = $sth->bind_param($param_num, $bind_value);
  $rv = $sth->bind_param($param_num, $bind_value, $bind_type);
  $rv = $sth->bind_param($param_num, $bind_value, \%attr);

Allows the user to bind a value and/or a data type to a placeholder. This is
especially important when using server-side prepares. See the
L</prepare> method for more information.

The value of C<$param_num> is a number of '?' placeholders (starting from 1).

The C<$bind_value> argument is fairly self-explanatory.

The C<$bind_type> and C<%attr> is not supported currently.

=head3 B<bind_param_array>

  $rv = $sth->bind_param_array($param_num, $array_ref_or_value)
  $rv = $sth->bind_param_array($param_num, $array_ref_or_value, $bind_type)
  $rv = $sth->bind_param_array($param_num, $array_ref_or_value, \%attr)

Binds an array of values to a placeholder, so that each is used in turn by a call
to the L</execute_array> method.

=head3 B<execute>

  $rv = $sth->execute(@bind_values);

or

  $sth->bind_param(1, $value1);
  $sth->bind_param(2, $value2);
  $rv = $sth->execute;

Executes a previously prepared statement. In addition to C<UPSERT>, C<DELETE> for which
it returns always the number of affected rows.

=head3 B<execute_array>

  $tuples = $sth->execute_array() or die $sth->errstr;
  $tuples = $sth->execute_array(\%attr) or die $sth->errstr;
  $tuples = $sth->execute_array(\%attr, @bind_values) or die $sth->errstr;

  ($tuples, $rows) = $sth->execute_array(\%attr) or die $sth->errstr;
  ($tuples, $rows) = $sth->execute_array(\%attr, @bind_values) or die $sth->errstr;

Execute a prepared statement once for each item in a passed-in hashref, or items that
were previously bound via the L</bind_param_array> method. See the DBI documentation
for more details.

=head3 B<execute_for_fetch>

  $tuples = $sth->execute_for_fetch($fetch_tuple_sub);
  $tuples = $sth->execute_for_fetch($fetch_tuple_sub, \@tuple_status);

  ($tuples, $rows) = $sth->execute_for_fetch($fetch_tuple_sub);
  ($tuples, $rows) = $sth->execute_for_fetch($fetch_tuple_sub, \@tuple_status);

Used internally by the L</execute_array> method, and rarely used directly. See the
DBI documentation for more details.

=head3 B<fetchrow_arrayref>

  $ary_ref = $sth->fetchrow_arrayref;

Fetches the next row of data from the statement handle, and returns a reference to an array
holding the column values. Any columns that are NULL are returned as undef within the array.

If there are no more rows or if an error occurs, then this method return undef. You should
check C<< $sth->err >> afterwards (or use the L<RaiseError|/RaiseError (boolean, inherited)> attribute) to discover if the undef returned
was due to an error.

Note that the same array reference is returned for each fetch, so don't store the reference and
then use it after a later fetch. Also, the elements of the array are also reused for each row,
so take care if you want to take a reference to an element. See also L</bind_columns>.

=head3 B<fetchrow_array>

  @ary = $sth->fetchrow_array;

Similar to the L</fetchrow_arrayref> method, but returns a list of column information rather than
a reference to a list. Do not use this in a scalar context.

=head3 B<fetchrow_hashref>

  $hash_ref = $sth->fetchrow_hashref;
  $hash_ref = $sth->fetchrow_hashref($name);

Fetches the next row of data and returns a hashref containing the name of the columns as the keys
and the data itself as the values. Any NULL value is returned as an undef value.

If there are no more rows or if an error occurs, then this method return undef. You should
check C<< $sth->err >> afterwards (or use the L<RaiseError|/RaiseError (boolean, inherited)> attribute) to discover if the undef returned
was due to an error.

The optional C<$name> argument should be either C<NAME>, C<NAME_lc> or C<NAME_uc>, and indicates
what sort of transformation to make to the keys in the hash.

=head3 B<fetchall_arrayref>

  $tbl_ary_ref = $sth->fetchall_arrayref();
  $tbl_ary_ref = $sth->fetchall_arrayref( $slice );
  $tbl_ary_ref = $sth->fetchall_arrayref( $slice, $max_rows );

Returns a reference to an array of arrays that contains all the remaining rows to be fetched from the
statement handle. If there are no more rows, an empty arrayref will be returned. If an error occurs,
the data read in so far will be returned. Because of this, you should always check C<< $sth->err >> after
calling this method, unless L<RaiseError|/RaiseError (boolean, inherited)> has been enabled.

If C<$slice> is an array reference, fetchall_arrayref uses the L</fetchrow_arrayref> method to fetch each
row as an array ref. If the C<$slice> array is not empty then it is used as a slice to select individual
columns by perl array index number (starting at 0, unlike column and parameter numbers which start at 1).

With no parameters, or if $slice is undefined, fetchall_arrayref acts as if passed an empty array ref.

If C<$slice> is a hash reference, fetchall_arrayref uses L</fetchrow_hashref> to fetch each row as a hash reference.

See the L<DBI fetchall_arrayref|DBI/fetchall_arrayref> for more information.

=head3 B<fetchall_hashref>

  $hash_ref = $sth->fetchall_hashref( $key_field );

Returns a hashref containing all rows to be fetched from the statement handle.

See the L<DBI fetchall_hashref|DBI/fetchall_hashref> for more information.

=head3 B<finish>

  $rv = $sth->finish;

Indicates to DBI that you are finished with the statement handle and are not going to use it again. Only needed
when you have not fetched all the possible rows.

=head3 B<rows>

  $rv = $sth->rows;

Returns the number of rows returned by the last query. Note that the L</execute> method itself
returns the number of rows itself, which means that this method is rarely needed.

=head3 B<bind_col>

  $rv = $sth->bind_col($column_number, \$var_to_bind);
  $rv = $sth->bind_col($column_number, \$var_to_bind, \%attr );
  $rv = $sth->bind_col($column_number, \$var_to_bind, $bind_type );

Binds a Perl variable and/or some attributes to an output column of a SELECT statement.
Column numbers count up from 1. You do not need to bind output columns in order to fetch data.

See the L<DBI bind_col|DBI/bind_col> for a discussion of the optional parameters C<\%attr> and C<$bind_type>.

=head3 B<bind_columns>

  $rv = $sth->bind_columns(@list_of_refs_to_vars_to_bind);

Calls the L</bind_col> method for each column in the SELECT statement, using the supplied list.

See the L<DBI bind_columns|DBI/bind_columns> for more information.

=head3 B<dump_results>

  $rows = $sth->dump_results($maxlen, $lsep, $fsep, $fh);

Fetches all the rows from the statement handle, calls C<DBI::neat_list> for each row, and
prints the results to C<$fh> (which defaults to F<STDOUT>). Rows are separated by C<$lsep> (which defaults
to a newline). Columns are separated by C<$fsep> (which defaults to a comma). The C<$maxlen> controls
how wide the output can be, and defaults to 35.

This method is designed as a handy utility for prototyping and testing queries. Since it uses
"neat_list" to format and edit the string for reading by humans, it is not recommended
for data transfer applications.

=head3 B<last_insert_id>

  $rv = $sth->last_insert_id(undef, $schema, $table, $column);
  $rv = $sth->last_insert_id(undef, $schema, $table, $column, {sequence => $seqname});

This is simply an alternative way to return the same information as
C<< $dbh->last_insert_id >>.

=head2 Statement Handle Attributes

=head3 B<NUM_OF_FIELDS> (integer, read-only)

Returns the number of columns returned by the current statement. A number will only be returned for
SELECT statements.

=head3 B<NUM_OF_PARAMS> (integer, read-only)

Returns the number of placeholders in the current statement.

=head3 B<NAME> (arrayref, read-only)

Returns an arrayref of column names for the current statement. This
attribute will only work for SELECT statements.

=head3 B<NAME_lc> (arrayref, read-only)

The same as the C<NAME> attribute, except that all column names are forced to lower case.

=head3 B<NAME_uc>  (arrayref, read-only)

The same as the C<NAME> attribute, except that all column names are forced to upper case.

=head3 B<NAME_hash> (hashref, read-only)

Similar to the C<NAME> attribute, but returns a hashref of column names instead of an arrayref. The names of the columns
are the keys of the hash, and the values represent the order in which the columns are returned, starting at 0.

=head3 B<NAME_lc_hash> (hashref, read-only)

The same as the C<NAME_hash> attribute, except that all column names are forced to lower case.

=head3 B<NAME_uc_hash> (hashref, read-only)

The same as the C<NAME_hash> attribute, except that all column names are forced to lower case.

=head3 B<TYPE> (arrayref, read-only)

Returns an arrayref indicating the data type for each column in the statement.

=head3 B<PRECISION> (arrayref, read-only)

Returns an arrayref of integer values for each column returned by the statement.
The number indicates the precision for C<NUMERIC> columns, the expected average size in number
for all other types.

=head3 B<SCALE> (arrayref, read-only)

Returns an arrayref of integer values for each column returned by the statement. The number
indicates the scale of the that column. The only type that will return a value is C<NUMERIC>.

=head3 B<NULLABLE> (arrayref, read-only)

Returns an arrayref of integer values for each column returned by the statement. The number
indicates if the column is nullable or not. 0 = not nullable, 1 = nullable, 2 = unknown.

=head3 B<Database> (dbh, read-only)

Returns the database handle this statement handle was created from.

=head3 B<ParamValues> (hash ref, read-only)

Returns a reference to a hash containing the values currently bound to placeholders.
Starting at one and increasing for every placeholder.

=head3 B<Statement> (string, read-only)

Returns the statement string passed to the most recent "prepare" method called in this database handle, even if that method
failed. This is especially useful where "RaiseError" is enabled and the exception handler checks $@ and sees that a C<prepare>
method call failed.

=head1 FURTHER INFORMATION

=head2 Transactions

Transaction behavior is controlled via the L</AutoCommit> attribute. For a
complete definition of C<AutoCommit> please refer to the DBI documentation.

According to the DBI specification the default for C<AutoCommit> is a true
value.

=head1 AUTHOR

Alexey Stavrov <logioniz@ya.ru>

=head1 CONTRIBUTORS

=for stopwords Denis Ibaev Ivan Putintsev uid66

=over 4

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

uid66 <19481514+uid66@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
