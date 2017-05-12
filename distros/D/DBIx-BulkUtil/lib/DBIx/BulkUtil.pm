package DBIx::BulkUtil;

use DBI;
use Carp qw(confess);

use strict;
use warnings;

our $VERSION = '0.05';

# Override this
sub passwd {
  return '';
}

# Override this
sub user {
  return '';
}

{
my @connect_options = qw(
  Server
  Database
  Env
  Type
  User
  Password
  DataDir
  ConnectMethod
  RetryCount
  RetryMinutes
  BulkLogin
  NoBlankNull
  Silent
  NoCharset
  NoServer
  Dsl
  DslOptions
  DateFormat
  DatetimeFormat
  DatetimeTzFormat
);
my %is_valid;
$is_valid{$_}++ for @connect_options;

sub _options_valid {
  my $class = shift;
  my %opts = @_;
  for my $opt (keys %opts) {
    return $opt if !$is_valid{$opt};
  }
  return;
}
}

# Override this to set server, db, env, type based on whatever
sub env2db {
  my ($self,$args) = @_;

  $args->{Type} ||= (!$args->{Server} && $args->{Database} ) ? 'Oracle' : 'Sybase';
  if ( $args->{Type} eq 'SybaseIQ' ) {
    $args->{IsIQ}++;
    $args->{Type} = 'Sybase'
  }
}

sub connect {
  my $class = shift;

  # Use HandleError sub instead of more straightforward RaiseError
  # attribute because Sybase 1.09 does not include line numbers in its
  # RaiseError die messages. And a stacktrace is usually more helpful
  # anyway.
  my $dbi_opts = {
    ChopBlanks  => 1,
    AutoCommit  => 1,
    PrintError  => 0,
    RaiseError  => 1,
    LongReadLen => 1_024 * 1_024,
  };

  if ( @_ and ref($_[-1]) ) {
    my $tmp_opts = pop @_;
    @$dbi_opts{keys %$tmp_opts} = values %$tmp_opts;
  }
  my $bad_opt = $class->_options_valid(@_);
  die "Invalid option $bad_opt to ${class}->connect" if $bad_opt;

  # TODO: Log or Output option?
  my %args = @_;
  my $fh;
  open($fh, ">", "/dev/null") if $args{Silent};
  my $stdout = $args{Silent} ? $fh : \*STDOUT;
  local *STDOUT = $stdout;

  my $connect = $args{ConnectMethod} || 'connect';

  $class->env2db( \%args );

  my @dsl_args = $args{Dsl}
  ?  ref($args{Dsl}) ? @{$args{Dsl}} : $args{Dsl}
  : ();

  my $type     = $args{Type};
  my $database = $args{Database};
  my $server   = $args{Server} || '';

  if (!@dsl_args) {
    if ( $type eq 'Sybase' ) {
      # Server-side charset is iso, need to specify it as client-side charset
      # or else we get utf8 to iso charset conversion error when database handle is cloned
      # (which happens automatically when you need multiple active statement handles).
      push @dsl_args, "server=$server" unless $args{NoServer};
      push @dsl_args, 'charset=iso_1' unless $args{NoCharset};
      push @dsl_args, 'bulkLogin=1' if $args{BulkLogin};
    } elsif ( $type eq 'Oracle' ) {
      push @dsl_args, $database unless $args{NoServer};
    } else {
      die "Unable to connect to database type $type";
    }
  }

  # For Xtra Dsl options
  push @dsl_args, ref($args{DslOptions})
    ? @{$args{DslOptions}} : $args{DslOptions}
  if $args{DslOptions};

  my $dsl = "dbi:$type:";
  $dsl .= join( ";", @dsl_args );

  my $user     = $args{User}     || $class->user(\%args);
  my $passwd   = $args{Password} || $class->passwd(\%args);

  my $dbh;
  my $retry = int($args{RetryCount} || 0);

  my $retry_seconds = 60 * ($args{RetryMinutes} || 10);
  $retry_seconds    = 60 * 10 if $retry_seconds < 0;

  my $conn_name = ($type eq 'Sybase') ? $server : $database;
  while (1) {

    print "Connecting to $conn_name\n";
    $dbh = eval { DBI->$connect($dsl, $user, $passwd, $dbi_opts) };
    my $err = $@;
    unless ($dbh) {
      die $err unless $retry-- > 0;
      print "Unable to connect to $conn_name. Will retry in $retry_seconds seconds";
      sleep $retry_seconds;
      redo;
    }

    # Make selected Sybase database the current database
    # And make date formats consistent
    if ( $type eq 'Sybase' ) {
      # Switch database after connect so that we get a helpful error message
      # and an error instead of a warning
      if ($database) {
        print "Using $database database\n";
        my $result = eval { $dbh->do("USE $database") };
        my $err = $@;
        unless ($result) {
          die $err unless $retry-- > 0;
          $dbh->disconnect();
          print "Unable to use database $database on $server. Will retry in $retry_seconds seconds\n";
          sleep $retry_seconds;
          redo;
        }
      };
      $dbh->{syb_date_fmt} = $args{DateFormat} || 'ISO';

      $dbh->do("set temporary option Load_ZeroLength_AsNULL = 'ON'") if $args{IsIQ} and !$args{NoBlankNull};
    } elsif ( $type eq 'Oracle' ) {
      # Fractions on Oracle "DATE" format not allowed
      my $date_fmt        = $args{DateFormat}       || 'YYYY-MM-DD HH24:MI:SS';
      my $datetime_fmt    = $args{DatetimeFormat}   || 'YYYY-MM-DD HH24:MI:SS.FF';
      my $datetime_tz_fmt = $args{DatetimeTzFormat} || $args{DatetimeFormat} || $datetime_fmt;
      $_ = $dbh->quote($_) for $date_fmt, $datetime_fmt, $datetime_tz_fmt;
      $dbh->do("alter session set nls_date_format=$date_fmt");
      $dbh->do("alter session set nls_timestamp_format=$datetime_fmt");
      $dbh->do("alter session set nls_timestamp_tz_format=$datetime_tz_fmt");
    }
    last;
  }

  # We do not want stack trace on connect so that we do not expose password
  # But everywhere else it is useful
  $dbh->{RaiseError} = 0;
  $dbh->{HandleError} = sub { confess $_[0] };
  return $dbh unless wantarray;
  my $util = DBIx::BulkUtil::Obj->new($dbh, $passwd, \%args);
  return $dbh, $util;
}

# Just set the connect method and call connect()
sub connect_cached {
  my $class = shift;
  my @args = $class->override({ConnectMethod => 'connect_cached'}, @_);
  $class->connect(@args);
}

sub syb_connect {
  my $class = shift;
  my @args = $class->override({ Type => 'Sybase' }, @_);
  return $class->connect(@args);
}

sub syb_connect_cached {
  my $class = shift;
  my @args = $class->override({ Type => 'Sybase' }, @_);
  return $class->connect_cached(@args);
}

sub ora_connect {
  my $class = shift;
  my @args = $class->override({ Type => 'Oracle' }, @_);
  return $class->connect(@args);
}

sub ora_connect_cached {
  my $class = shift;
  my @args = $class->override({ Type => 'Oracle' }, @_);
  return $class->connect_cached(@args);
}

sub iq_connect {
  my $class = shift;
  my @args = $class->override({ Type => 'SybaseIQ' }, @_);
  return $class->connect(@args);
}

sub iq_connect_cached {
  my $class = shift;
  my @args = $class->override({ Type => 'SybaseIQ' }, @_);
  return $class->connect_cached(@args);
}


# Overriden connect args need to be spliced in before any dbi options
sub override {
  my $self = shift;
  my ($ovr, @args) = @_;
  if ( (@args % 2) == 0 ) {
    return @args, %$ovr;
  }
  my $dbi_opts = pop @args;
  die "Last argument to connect must be hash reference" unless $dbi_opts and ref($dbi_opts);
  return @args, %$ovr, $dbi_opts;
}

package DBIx::BulkUtil::Obj;

our $BCP_DELIMITER = '|';

use Memoize qw(memoize);
use Carp qw(confess);

sub new {
  my ( $class, $dbh, $passwd, $args ) = @_;
  my $type = $dbh->{Driver}{Name};
  if ($type eq 'Sybase') {
    (my $version = $dbh->{syb_server_version_string}) =~ s|/.*||;
    $type = 'SybaseIQ' if $version =~ /IQ/;
  }
  $class =~ s/::Obj$// or die "Invalid class $class";

  $class .= "::" . $type;
  return $class->util($dbh, $passwd, $args);
}

sub util {
  my $class = shift;
  my ($dbh, $pw, $args) = @_;
  confess "Must use subclass of this package" if __PACKAGE__ eq $class;
  my %util_args;

  if ( $args and ref($args) ) {
    $util_args{NoBlankNull} = 1 if $args->{NoBlankNull};
  }

  # Prevent dbh from disconnecting after fork in child processes
  my $dbh_pid = $$;
  my $release = DBIx::BulkUtil::Release->new(sub { $dbh->{InactiveDestroy} = 1 if $dbh_pid != $$ });
  bless { DBH => $dbh, PASSWORD => $pw, DELIMITER => $BCP_DELIMITER, RELEASE => $release, %util_args }, $class;
}

sub dbh { $_[0]->{DBH} }

sub get {
  my $self = shift;
  my $select = shift;
  my $dbh = $self->{DBH};
  my @result = $dbh->selectrow_array( $self->row_select($select) );
  return $result[0] if @result == 1;
  return @result;
}

sub exec_sp {
  my $self = shift;
  my $dbh = $self->{DBH};
  $dbh->do($self->sp_sql(@_));
}

sub bcp_out {
  my $self = shift;
  my $opts = {};
  if (ref $_[-1]) {
    $opts = pop @_;
  }
  my ( $table, $file ) = @_;
  $file ||= "$table.bcp";

  my $delimiter = $opts->{Delimiter}  || $self->{DELIMITER};
  my $row_delim = $opts->{RowDelimiter} || $/;
  my @esc       = ( escape_char => $opts->{EscapeChar} ) if $opts->{EscapeChar};

  # Default to no quote char to be more compatible w/Sybase
  my @quote_char = $opts->{QuoteFields} ? () : ( quote_char => undef, escape_char => undef );

  # TODO: Give up on Text::CSV ??
  my $csv;
  if ( length($delimiter) == 1 ) {
    require Text::CSV_XS;
    $csv = Text::CSV_XS->new({
      binary => 1,
      eol => $row_delim,
      sep_char => $delimiter,
      @esc,
      @quote_char,
    });
  }

  my $col_list = $opts->{Columns} ? $opts->{Columns} : "*";

  # Only for HP?
  #local $ENV{NLS_LANG} = "AMERICAN_AMERICA.WE8ROMAN8";

  my $enc_opt = $opts->{Encoding} || '';
  my $db_type = $self->type();
  if ( $db_type eq 'Oracle' ) {

    my $partition = ( $table =~ s/:(\w+)$// ) ? $1 : '';
    my $nls_lang = $ENV{NLS_LANG} || '';
    if ( $nls_lang =~ /utf8/i ) {
      $enc_opt ||= 'utf8';
    }
    if ( $col_list eq '*' ) {
      my @col_list;
      my $col_info = $self->column_info($table);
      my $list = $col_info->{LIST};
      my $col_map = $col_info->{MAP};
      my $xml_cnt;
      for my $col (@$list) {
        if ( $col_map->{$col}{TYPE_NAME} eq 'XMLTYPE' ) {
          $xml_cnt++;
          push @col_list, "XMLType.getclobval($col)";
          next;
        }
        push @col_list, $col;
      }
      if ($xml_cnt) {
        $col_list = join(",", @col_list);
      }
    }
    $table = "$table PARTITION ($partition)" if $partition;
  }
  my $enc = $enc_opt ? ":encoding($enc_opt)" : '';

  open(my $fh, ">$enc", $file) or confess "Can not write to $file: $!";
  my $sql = "SELECT $col_list FROM $table\n";
  $sql .= $opts->{Filter} if $opts->{Filter};

  my $dbh = $self->{DBH};
  my $sth = $dbh->prepare($sql);
  $sth->{ChopBlanks} = 0 unless $opts->{TrimBlanks};
  $sth->execute();
  if ($opts->{Header}) {
    if ($csv) {
      $csv->print($fh, $sth->{NAME_lc});
    } else {
      print $fh join( $delimiter, @{$sth->{NAME_lc}} ), $row_delim;
    }
  }

  my $cnt = 0;
  while ( my $row = $sth->fetchrow_arrayref() ) {
    no warnings 'uninitialized';
    if ($csv) {
      $csv->print($fh, $row);
    } else {
      print $fh join($delimiter, @$row), $row_delim;
    }
    $cnt++;
  }
  close $fh;
  return $cnt;
}

{
no warnings 'once';
*select2file = \&bcp_out;
}

sub bcp_file {
  my ($self, $file_in, $file_out) = @_;
  my $opts = {};
  if (ref $_[-1]) {
    $opts = pop @_;
  }

  my $delimiter = $opts->{Delimiter}  || $self->{DELIMITER};
  my $esc       = $opts->{EscapeChar} || "\\";

  my @quote_char = $opts->{QuoteFields} ? () : ( quote_char => undef );
  require Text::CSV_XS;
  my $csv = Text::CSV_XS->new({
    binary => 1,
    eol => $/,
    sep_char => $delimiter,
    escape_char => $esc,
    @quote_char,
  });

  open(my $in_fh,  "<", $file_in)  or die "Err: $!";
  open(my $out_fh, ">", $file_out) or die "Err: $!";
  my $hdr = $csv->getline($in_fh);
  $csv->column_names($hdr);
  my @drop_cols = $opts->{DropCols} ? @{$opts->{DropCols}} : ();
  my %drop; $drop{$_}++ for @drop_cols;

  my @cols =
    $opts->{KeepCols} ? @{$opts->{KeepCols}}
  : @drop_cols        ? grep !$drop{$_}, @$hdr
  : @$hdr;
  my %hdr_idx; @hdr_idx{@$hdr} = 0..$#$hdr;

  $csv->print($out_fh, [@$hdr[@hdr_idx{@cols}]]) if $opts->{Header};
  while ( my $row = $csv->getline_hr($in_fh) ) {
    $csv->print($out_fh, [@$row{@cols}]);
  }
  close $in_fh;
  close $out_fh;
}

sub add_header {
  my ($self, $table, $file, $opts) = @_;
  $opts ||= {};

  my $cols;
  if ( $opts->{Header} || $opts->{Columns} ) {
    my $sel_str =
      $opts->{Columns}
      ?  ref($opts->{Columns})
        ? join(",", @{$opts->{Columns}})
        : $opts->{Columns}
      : '*';
    my $sth = $self->{DBH}->prepare("SELECT $sel_str FROM $table WHERE 1=0");
    $sth->execute();
    $cols = $sth->{NAME_lc};
    $sth->finish();
  }

  return $self->add_quotes($table, $file, $cols, $opts) if $opts->{QuoteFields};

  # If quotes are not required, this is more efficient
  # I doubt anyone uses either option anyway
  # but highly doubt anyone uses the quoting
  require File::Copy;
  my $d = $opts->{Delimiter} || $self->{DELIMITER};
  local $/ = $opts->{RowDelimiter} || "\n";

  open(my $fh, ">", "$file.bak") or die "Failed to open $file.bak: $!";

  # Unbuffer the filehandle for printing header
  # because File::Copy uses unbuffered syswrite
  # $fh->flush() after the print would also work depending on
  # version of perl and whether IO::Handle is loaded
  for ( select $fh ) { $| = 1; select $_ }
  print $fh join($d, @$cols), $/;

  File::Copy::copy($file, $fh) or die "Failed to copy $file to $file.bak: $!";
  close $fh;

  return "$file.bak";
}

sub add_quotes {
  my ($self, $table, $file, $cols, $opts) = @_;
  my $d = $opts->{Delimiter} || $self->{DELIMITER};
  my $dre = quotemeta($d);

  local ($_, $., $ARGV, *ARGV);
  local ( $^I, @ARGV ) = ( '.bak', $file );
  local $/ = $opts->{RowDelimiter} || "\n";
  my $done;
  while ( <> ) {
    print join($d, @$cols), $/ if !$done++ && $opts->{Header};

    if ($opts->{QuoteFields}) {
      chomp;
      my @fields = split /$dre/;
      /\s/ and $_ = qq("$_") for @fields;
      $_ = join($d, @fields) . $/;
    }
    print;
  }
  return "$file.bak";
}

sub type {
  my $self = shift;
  return $self->{DBH}{Driver}{Name};
}

# Because of Sybase and its stupid mixed case column names,
# we need to be able to find the actual cased name for a given
# uncased column name.
# Just pray that there are not two columns with the same name
# in the same table that are differently cased.
memoize('column_info');

sub column_info {
  my $self = shift;
  my $table = shift;

  my $schema;
  my $dbtype = $self->type();
  my ($tmp_db, $curr_db) = (undef,'');
  my $dbh = $self->{DBH};
  my %col_dflt;
  if ( $dbtype eq 'Oracle' ) {
    $table = uc($table);
    if ( $table =~ /^(\w+)\.(\w+)$/ ) {
      ($schema, $table) = ($1,$2);
    } else { $schema = $self->curr_schema() }
  } elsif ( $dbtype eq 'Sybase' ) {

    $tmp_db = $curr_db = $self->curr_db();

    if ( $table =~ /^#/ ) {
      $table = $self->temp_table_name($table);
    }

    if ( $table =~ /^(?:(\w+)\.)?(\w*)\.(#?\w+)$/ ) {
      ($tmp_db, $schema, $table) = ($1,$2,$3);
      $schema ||= undef;

      # We can only get column info on the current database
      $dbh->do("USE $tmp_db") if defined($tmp_db) and $tmp_db ne $curr_db;
    }

    $schema ||= '%';

    # Sybase gets metadata through a (under the DBD hood) stored proc, but does not return defaults.
    # So get defaults here.
    my $sth = $dbh->prepare( sprintf( $self->default_sql(), $table ) );
    $sth->execute();
    $sth->bind_columns( \my ( $col_name, $default ) );
    while ( $sth->fetch ) {
      $col_dflt{$col_name} .= $default;
    }
  }

  my $sth = $self->{DBH}->column_info($tmp_db, $schema, $table, '%');
  my @names = @{$sth->{NAME_uc}};
  my %row; $sth->bind_columns(\@row{@names});
  my @list;
  my %col_map;
  my $col_cnt = 0;
  while ( $sth->fetch() ) {

    # Data is probably in order, but we are not guaranteed
    # So assign by index instead of pushing to array if possible
    # IQ does not have ORDINAL_POSITION so fall back to select order
    my $idx = defined($row{ORDINAL_POSITION}) ? $row{ORDINAL_POSITION}-1 : $col_cnt;
    $col_cnt++;

    my $name = lc($row{COLUMN_NAME});
    $list[$idx] = $name;
    ($row{COLUMN_DEF} = $col_dflt{$name}) =~ s/^default\s*//i if defined($col_dflt{$name}) and !defined($row{COLUMN_DEF});
    $col_map{$name} = { %row };
  }
  $dbh->do("USE $curr_db") if defined($tmp_db) and $tmp_db ne $curr_db;

  return unless $col_cnt;
  my %col_info = (
    LIST => \@list,
    MAP  => \%col_map,
  );
  return \%col_info;
}

sub last_chg_list {
  my $self = shift;
  my ($table, $columns) = @_;

  # Determine if last_chg_user, last_chg_date need to be updated
  my %chg_field = (last_chg_user => 1, last_chg_date => 1);
  delete $chg_field{$_} for map lc, @$columns;
  my %chg_cols;
  if (%chg_field) {
    # Are chg columns in table
    my $col_info = $self->column_info($table);
    my $col_map = $col_info->{MAP};
    for my $c (keys %chg_field) {
      $chg_cols{$c} = $col_map->{$c}{COLUMN_SIZE} if $col_map->{$c};
    }
  }

  return %chg_cols;
}

sub key_columns {
  my ($self, $table) = @_;

  my $pk = $self->primary_key($table);
  return $pk if $pk;

  my $idx = $self->index_info($table);
  return unless $idx;

  # Look for unique indexes with suffixes uk, pk, or key
  my ($pk_name) = sort grep /(?i)(?:[pu]k|key)\d*$/, keys %$idx;
  return $idx->{$pk_name} if $pk_name;

  my ($idx_name) = sort keys %$idx;
  return $idx->{$idx_name};
}

sub upd_columns {
  my ($self, $table, $key_cols) = @_;

  my $col_data = $self->column_info($table)->{LIST};
  $key_cols ||= $self->key_columns($table);
  return unless $key_cols;

  my %is_key_col; $is_key_col{$_}++ for @$key_cols;
  return [ grep !$is_key_col{$_}, @$col_data ];
}

sub delete {
  my ($self, $table, $where) = @_;

  my $dbh = $self->{DBH};
  my $sql = "DELETE FROM $table";
  $sql .= " WHERE $where" if $where;

  my $rows = $dbh->do($sql) + 0;

  print "$rows rows deleted\n";
  return $rows;
}

# Execute sql with retry on deadlocks
sub execute {
  my ($self,$sth,@args) = @_;

  # We can pass a sql statement or a sth
  $sth = $self->{DBH}->prepare($sth) if !ref($sth);

  my $retry = 5;
  for (1..$retry) { 
    my $status = eval { $sth->execute(@args) };
    return $status if $status;
    confess $@ unless $@ =~ /deadlock/i;
    print "Deadlock detected on retry $_ of 5\n";
    sleep 2 if $_ < $retry;
  }
  confess $@;
}

sub ora_date_fmt {

  # Not very OO-ish but allow calling the Oracle date mask routine
  # From any generic utility object
  my $self = shift;
  DBIx::BulkUtil::Oracle->date_mask(@_);

}

sub strptime_fmt {
  my ($class, $str, $fmt) = @_;
  $fmt ||= DBIx::BulkUtil::Oracle->date_mask($str);
  return undef unless $fmt;
  for ($fmt) {
    s/MONTH/%B/;
    s/MON/%b/;
    s/MM/%m/;
    s/DD/%d/;
    s/YYYY/%Y/;
    s/YY/%y/;
    s/RRRR/%Y/;
    s/RR/%y/;
    s/HH24/%H/;
    s/HH(?:12)?/%I/;
    s/MI/%M/;
    s/SS/%S/;
    s/AM/%p/;
    s/DY/%a/;
    s/DAY/%a/;
    s/TZD/%Z/;
    s/TZH.TZD/%z/;
    s/"(.)"/$1/g;
  }
  return $fmt;
}

sub blk_prepare {
  my ($self, $table, %args) = @_;
  my $blk_opts = $args{BlkOpts} || {};
  my $commit   = $args{CommitSize} || 1000;
  my $con      = $args{Constants};

  my $col_info = $self->column_info($table) or confess "Table $table does not exist";
  my @col_list = @{$col_info->{LIST}};
  my $arg_len = @col_list;

  my $col_cnt = @col_list;
  my $sql = "INSERT INTO $table VALUES (" . join(",", ("?") x $col_cnt) . ")";
  my $type = $self->type();
  my @blk_opts = ($type eq 'Sybase')
    ? { syb_bcp_attribs => $blk_opts }
    : ();

  my $dbh = $self->{DBH};
  my $sth = $dbh->prepare($sql, @blk_opts);

  my ($exec_f,$commit_f,$finish_f);
  my @ex_arg_list = (undef) x @col_list;
  my $cnt = 0;
  if ($con) {
    my %const  = %$con;
    my @c_list   = keys %const;

    my %col_pos;
    @col_pos{@col_list} = 0..$#col_list;
    my %const_pos;
    @const_pos{@c_list} = delete @col_pos{@c_list};
    $arg_len = keys %col_pos;

    # Create arg array for execute method
    # Set constants and create sub for all but constant args
    @ex_arg_list[@const_pos{@c_list}] = @const{@c_list};
    my @non_const = sort { $a <=> $b } values %col_pos;
    $sth->{HandleError} = undef if $type eq 'Oracle';

    if ($type eq 'Sybase') {
      $exec_f   = sub { @ex_arg_list[@non_const] = @_; $sth->execute(@ex_arg_list) };
      $commit_f = sub { $dbh->commit() };
      $finish_f = sub { $dbh->commit(); $sth->finish(); $sth = undef };
    } else {
      $exec_f   = sub { my $i=0; push @{$ex_arg_list[$_]}, $_[$i++] for @non_const };
      $commit_f = sub {
        my ($t,$r) = $sth->execute_array({ ArrayTupleStatus => \my @status }, @ex_arg_list);
        unless (defined $t) {
          for my $i (0..$#status) {
            next unless ref $status[$i];
            my @row = map { ref($ex_arg_list[$_]) ? qq('$ex_arg_list[$_][$i]') : $ex_arg_list[$_] } 0..$#ex_arg_list;
            confess "Error: [$status[$i][1]] inserting [".join(",", @row)."]";
          }
        }
        $_ = [] for @ex_arg_list[@non_const];
        $r;
      };
      $finish_f = sub { $commit_f->() if $cnt > 0 };
    }
  } else {
    if ($type eq 'Sybase') {
      $exec_f   = sub { $sth->execute(@_); '0E0' };
      $commit_f = sub { $dbh->commit(); $cnt };
      $finish_f = sub { $dbh->commit(); $sth->finish(); $sth = undef; ( $cnt > 0 ) ? $cnt : '0E0' };
    } else {
      $exec_f   = sub { my $i=0; push @{$ex_arg_list[$_]}, $_[$_] for 0..$#ex_arg_list; return '0E0' };
      $commit_f = sub {
        my ($t,$r) = $sth->execute_array({ ArrayTupleStatus => \my @status }, @ex_arg_list);
        unless (defined $t) {
          for my $i (0..$#status) {
            next unless ref $status[$i];
            my @row = map { qq('$ex_arg_list[$_][$i]') } 0..$#ex_arg_list;
            confess "Error: [$status[$i][1]] inserting [".join(",", @row)."]";
          }
        }
        $_ = [] for @ex_arg_list;
        $r;
      };
      $finish_f = sub { ( $cnt > 0 ) ? $commit_f->() : '0E0' };
    }
  }

  bless {
    CNT => \$cnt,
    COMMIT_SIZE => $commit,
    EXEC_FUNC   => $exec_f,
    COMMIT_FUNC => $commit_f,
    FINISH_FUNC => $finish_f,
    ARG_LEN     => $arg_len,
  }, "DBIx::BulkUtil::BLK";
}

sub prepare {
  my $self = shift;
  my %opt = @_;
  my $table = $opt{Table};
  my $sql   = $opt{Sql};
  my $columns = $opt{Columns};
  my $href   = $opt{BindHash};
  my $aref   = $opt{BindArray};
  my $by_name =
    defined($opt{ByName})        ? $opt{ByName}
  : ( !$href && !$aref )         ? 0
  : ($self->type() eq 'Sybase' ) ? 0
  : 1;
  confess "Can not supply both BindHash and BindArray" if $href && $aref;
  confess "Can not use BindHash or BindArray without ByName" if ( $href || $aref ) && !$by_name;

  confess "Must supply Table or Sql to prepare" unless $table || $sql;
  confess "Can not supply both Table and Sql to prepare" if $table && $sql;

  my $dflt_col = eval {
    $columns ||= $self->column_info($table)->{LIST} if $table;
    1;
  };
  confess "Table $table not found in datbase" unless $dflt_col;

  if ( $columns && @$columns ) {

    # A little overkill to get a nicely formatted SQL statement
    my $c_sep  = ( @$columns > 5 ) ? "\n" : '';
    my $cnt;
    my $c_ind  = ( @$columns > 5 ) ? sub { ' ' } : sub { $cnt++ ? ' ' : '' };

    my $h_cnt;
    my $h_ind  = ( @$columns > 5 ) ? sub { ' ' } : sub { $h_cnt++ ? ' ' : '' };

    my $v_sep  = $by_name ? ( @$columns > 5 ) ? "\n" : '' : '';
    my $hold   = $by_name ? sub { $h_ind->() . ":$_" } : sub { "?" };

    $sql ||= sprintf("INSERT INTO $table ($c_sep%s$c_sep) VALUES ($v_sep%s$v_sep)",
      join(",$c_sep", map $c_ind->() . $_, @$columns),
      join(",$v_sep", map $hold->(), @$columns),
    );
  }
  print "Preparing: $sql\n";
  my $sth = $self->dbh->prepare($sql);

  if ($href) {
    $sth->bind_param_inout( ":$_" => \$href->{$_}, 0 ) for @$columns;
  } elsif ($aref) {
    $sth->bind_param_inout( ":$columns->[$_]" => \$aref->[$_], 0 ) for 0..$#$columns;
  }

  return $sth;

}

sub prepare_upd {

  my $self = shift;

  my %args = @_;

  my $table = $args{Table} || die "Must supply Table option";

  my $col_info = $self->column_info($table);
  my $col_list = $args{Columns} || $col_info->{LIST};

  my $key_cols = $args{KeyCols} || $self->key_columns($table);
  my $upd_cols = $args{UpdCols} || $self->upd_columns($table);

  my $sql = <<SQL;
UPDATE $table
SET
  @{[ join( ",\n  ", map "$_ = ?", @$upd_cols )]}
WHERE
  @{[ join( " AND\n  ", map "$_ = ?", @$key_cols )]}
SQL
  print "Preparing: $sql\n";
  my $sth = $self->{DBH}->prepare($sql);

  my %col_pos;
  my $cnt = 0;
  $col_pos{$_} = $cnt++ for @$col_list;

  my @sth_pos;
  push @sth_pos, $col_pos{$_} for @$upd_cols, @$key_cols;

  return sub {
    unless (@_) {
      $sth->finish();
      undef $sth;
      undef @sth_pos;
      return;
    }
    $sth->execute(@_[@sth_pos]);
  }
}

sub is_iq { 0 }

package DBIx::BulkUtil::BLK;

use Carp qw(confess);

sub execute {
  my $self = shift;
  unless (@_ == $self->{ARG_LEN}) {
    my $arg_cnt = @_;
    confess "Execute argument count $arg_cnt must be $self->{ARG_LEN}";
  }
  my $f = $self->{ARG_FUNC};
  my $rows = $self->{EXEC_FUNC}->(@_);
  my $cnt = $self->{CNT};
  if ( ++$$cnt >= $self->{COMMIT_SIZE} ) {
    $rows = $self->{COMMIT_FUNC}->();
    $$cnt = 0;
  }
  return $rows;
}

sub finish {
  my $self = shift;
  $self->{FINISH_FUNC}->();
}

package DBIx::BulkUtil::Sybase;

use Carp qw(confess);

our @ISA = qw(DBIx::BulkUtil::Obj);

sub now { 'getdate()' };

sub add {
  my $self = shift;
  my $date = shift;
  my $n = shift;
  my $unit = shift;
  my $new_date = "dateadd( $unit, $n, $date)";
  return $new_date unless @_;
  return $self->add( $new_date, @_ );
}

sub diff {
  my $self = shift;
  my $date1 = shift;
  my $date2 = shift;
  my $unit = shift;
  my $new_date = "datediff( $unit, $date1, $date2)";
  return $new_date;
}

sub row_select {
  my $self = shift;
  my $sel = shift;
  return "select $sel";
}

sub sp_sth {
  my $self = shift;
  my $sth = $self->{DBH}->prepare($self->sp_sql(@_));
  $sth->execute();
  return $sth;
}

sub sp_sql {
  my $self = shift;
  my ($stored_proc, @args) = @_;
  return "exec " . join(" ", $stored_proc, join(",", map {$self->{DBH}->quote($_)} grep !/^:cursor$/, @args));
}

# This is trivial in Sybase, but a necessary function for Oracle
# and so makes this portably compatible
sub to_datetime {
  my $self = shift;
  my $date = shift;

  return "'$date'";
}

sub bcp_in {
  my $self = shift;
  my $optref = (ref $_[-1]) ? pop @_ : {};
  my %opts = %$optref;

  my ( $table, $file, $dir ) = @_;
  my $partition = ( $table =~ s/(:\d+)$// ) ? $1 : '';

  $file ||= "$table.bcp";
  $dir  ||= 'in';

  my $dbh = $self->{DBH};
  my $db = $dbh->{Name};
  $db =~ /server=(\w+)/ or confess "Can't determine server for bcp";
  my $server = $1;
  my $database = $self->curr_db();

  my $user      = $dbh->{Username};
  my $delimiter = $opts{Delimiter} || $self->{DELIMITER};
  my $row_delimiter = $opts{RowDelimiter} || "\n";
  my $commit_size   = $opts{CommitSize} || 1000;

  my $bcp_table =
    (!$database or $table =~ /^\w+\.\w*\.\w+$/) ? $table
  : ($table =~ /^\w+$/)                         ? "$database..$table"
  : ($table =~ /^\w*\.\w+$/)                    ? "$database.$table"
  : confess "Can not determine database for bcp";

  $bcp_table .= $partition;

  # Simulate Oracle sqlldr Append/Replace/Truncate
  my $id_cnt;
  if ( $dir eq 'in' ) {
    my $mode = $opts{Action} || "A";
    if ( $mode eq 'T' ) {
      my $sql = "TRUNCATE TABLE $bcp_table";
      print "Executing: $sql\n";
      $dbh->do($sql);
    } elsif ($mode eq 'R') {
      $self->delete($bcp_table, '', $commit_size);
    }
    confess "BCP file $file does not exist" unless -f $file;

    # Save some work
    # checking underscore ok, we just did -f above
    unless ( -s _ ) {
      print "$file is empty. Skipping bcp\n";

      # Make any log file parsers happy
      print "0 rows copied\n";
      return 0;
    }

    # All this to decide whether or not to use '-E'
    # Only use '-E' if there is an identity column
    # And GenerateId is false
    unless ( $opts{GenerateId} ) {
      my $col_info = $self->column_info($table);
      my $col_map = $col_info->{MAP};
      if ($col_map) {
        for my $c ( values %$col_map ) {
          ++$id_cnt and last if $c->{TYPE_NAME} =~ /identity/;
        }
      }
    }
  }

  my ($action,$to_from) = ($dir eq 'in') ? ('Loading', 'from') : ('Exporting', 'to');
  print "$action $server/$bcp_table $to_from $file\n";

  my (@max_err_opt, @commit_opt, @header_opt, @id_opt);
  my $max_err_cnt = $opts{MaxErrors} || 0;
  if ( $dir eq 'in' ) {
    @max_err_opt = (-m => $max_err_cnt);
    @commit_opt  = (-b => $commit_size);
    @header_opt  = (-F => $opts{Header}+1) if $opts{Header};
    @id_opt = "-E" if $id_cnt;
  }

  my $keep_temp = $opts{KeepTempFiles} || $opts{Debug};
  my $in_temp_dir = $opts{TempDir}     || $opts{Debug};
  my $temp_dir;
  $temp_dir = $opts{TempDir} || "." if $in_temp_dir;

  require File::Temp;
  my @temp_dir = $in_temp_dir ? (DIR => $temp_dir) : ();
  my @unlink  = $keep_temp ? (UNLINK => 0) : ();
  my $error_file = File::Temp->new(
    TEMPLATE => "${table}_XXXXX",
    SUFFIX   => ".err",
    @temp_dir, @unlink,
  );
  chmod(0664, $error_file->filename());
  $error_file->close();

  my @packet_size = $opts{PacketSize} ? ( -A => $opts{PacketSize} ) : ();
  my @passthru    = $opts{PassThru}   ? @{$opts{PassThru}} : ();

  my ( $fmt_file, $tmp_fmt_file );
  if ( $opts{FormatFile} ) {
    $fmt_file = $opts{FormatFile};
  } elsif ( ( $opts{ColumnList} && $opts{ColumnList} ) || ( $opts{Filler} && @{$opts{Filler}} ) ) {
    ($tmp_fmt_file,$fmt_file) = $self->mk_fmt_file(
      Table          => $table,
      Delimiter      => $delimiter,
      RowDelimiter   => $row_delimiter,
      ColumnList     => $opts{ColumnList},
      Filler         => $opts{Filler},
      TempDir        => $opts{TempDir},
      FormatFileName => $opts{FormatFileName},
      KeepTempFiles  => $keep_temp,
    );
  }
  my @fmt_file_opt = $fmt_file ? ( -f => $fmt_file ) : '-c';

  # UTF-8 doesn't work on HP - default is roman8 on HP
  # Should probably make '-J' some kind of option, with maybe
  # a map of OS types and default values. But leave that for
  # a later date.
  my @cmd = ( bcp => $bcp_table, $dir, $file,
    -U => $user,
    #-J => "utf8",
    -S => $server,
    -t => $delimiter,
    -r => $row_delimiter,
    -e => $error_file->filename(),
    @header_opt,
    @id_opt,
    @commit_opt,
    @max_err_opt,
    @packet_size,
    @passthru,
    @fmt_file_opt,
  );
  print "Executing: @cmd\n";
  push @cmd, -P => $self->{PASSWORD};
  open(my $fh, "-|", @cmd) or confess "Can't exec bcp: $!";

  my ($rows, $failed, $partially_failed);
  local ($_, $.);

  my $err_cnt = my $c_lib_err_cnt = my $srvr_err_cnt = 0;
  while (<$fh>) {
    print;
    if ( /^(Server|C[TS]LIB) Message/ ) {
      my $msg_type = $1;
      if ( $msg_type eq 'CSLIB' ) {
        if ( m|/N(\d+)| ) {
          # Sybase says truncation is not an error, so we will too
          # Or else we might get > 1 error on the same row
          unless ( $1 == 36 ) {
            $err_cnt++;
            $c_lib_err_cnt++;
          }
        }
      } elsif ( $msg_type eq 'CTLIB' ) {
        $err_cnt++;
        $c_lib_err_cnt++;
      } else {
        # On server errors the whole batch is an error
        if ( /\s(\d+)/ ) {
          # Ignore 'slow bcp' warning
          unless ( $1 == 4852 ) {
            $err_cnt += $commit_size;
            $srvr_err_cnt += $commit_size;
          }
        } else {
          $err_cnt += $commit_size;
          $srvr_err_cnt += $commit_size;
        }
      }
    }
    $rows = $1 if /^(\d+) rows copied/;

    # failed or partially failed
    if ( /^bcp copy in ((?:partially )?)failed/ ) {
      $partially_failed++ if $1;
      $failed++;
    }
  }

  # "NaN" (literally "NaN") to numeric errors
  # do not show up on STDOUT.
  # So we may as well search the err file to count
  # all CSLIB and CTLIB errors.
  # Truncation errors do not show up in file, so we
  # don't have to filter them out as we would if we
  # were parsing STDOUT.
  my $err_file_cnt = 0;
  open(my $err_h, "<", $error_file->filename()) or die "Failed to open $error_file: $!";
  while (<$err_h>) {
    $err_file_cnt++ if /^#@ Row \d+: Not transferred/;
  }
  close $err_h;

  if ( $err_file_cnt > $c_lib_err_cnt ) {
    $err_cnt += $err_file_cnt - $c_lib_err_cnt;
  }

  # BCP 11.x,12.x returns meaningful exit status
  # 10.x does not (returns 0 even on errors)
  my $close_success = close $fh;

  unless ($close_success) {
    my $exit_stat = $? >> 8;
    my $exit_sig  = $? & 127;
    my $exit_core = $? & 128;

    # bcp will exit with non-zero status on any 'Server' error,
    # but not on 'CSLIB' errors unless 'CSLIB' error count exceeds max.
    if ( $exit_stat != 0 ) {
      if ( $dir eq 'in' ) {

        # Some of this may seem unneccessary, but Sybase bcp is
        # horribly inconsistent.

        # Exceeded the error count
        confess "BCP error - max error count ($max_err_cnt) exceeded - bcp returned status $exit_stat: $!"
          if $err_cnt > $max_err_cnt;

        # The load was aborted before bcp indicated that it finished
        confess "BCP error - bcp aborted [$exit_stat]: $!"
          if !defined($rows) and !$failed;

        # BCP failed - even if we allow some errors on a small file, if zero rows are copied
        # then call it a total failure.
        confess "BCP error - bcp failed [$exit_stat]: $!"
          if $failed and !$partially_failed;

      } else {
        confess "BCP error - bcp returned status $exit_stat: $!";
      }
    }

    confess "BCP error - bcp recieved signal $exit_sig"      if $exit_sig > 0;
    confess "BCP error - bcp coredumped"                     if $exit_core;
  }

  # Will miss error count exceeded error on 10.x
  # But will catch other errors if load is aborted
  # Or no rows are loaded.
  confess "BCP error - no rows copied" if !defined($rows);

  # CTLIB errors do not cause non-zero exit - so catch them here
  confess "BCP error - max error count ($max_err_cnt) exceeded" if $err_cnt > $max_err_cnt;
  $rows ||= 0;
  return $rows;
}

{
no warnings 'once';
*bcp = \&bcp_in;
}

sub mk_fmt_file {
  my $self = shift;
  my %opts = @_;

  my $table = $opts{Table} || die "Table required for mk_fmt_file";
  my $col_info = $self->column_info($table);
  my $db_col_list = $col_info->{LIST};
  my %is_db_column;
  $is_db_column{$_}++ for @$db_col_list;
  my %is_filler;
  if ( $opts{Filler} ) {
    $is_filler{lc($_)}++ for @{$opts{Filler}};
  }

  my ($tmp_fmt_file,$fmt_file);
  if ( $opts{FormatFileName} ) {
    $fmt_file = $opts{FormatFileName};
  } else {
    require File::Temp;
    my $keep_temp = $opts{KeepTempFiles} || $opts{Debug};
    my $in_temp_dir = $opts{TempDir}     || $opts{Debug};
    my $temp_dir;

    $temp_dir = $opts{TempDir} || "." if $in_temp_dir;
    my @temp_dir = $in_temp_dir ? (DIR => $temp_dir) : ();
    my @unlink  = ( $keep_temp || !defined(wantarray) ) ? (UNLINK => 0) : ();
    $tmp_fmt_file = File::Temp->new(
      TEMPLATE => "${table}_XXXXX",
      SUFFIX   => ".fmt",
      @temp_dir, @unlink,
    );
    $fmt_file = $tmp_fmt_file->filename();
    chmod(0664, $tmp_fmt_file);
    $tmp_fmt_file->close();
  }

  my $delim = $opts{Delimiter} || "|";
  my $row_delim = $opts{RowDelimiter} || "\n";

  # Need escaped text in fmt file
  # for CR/LF
  for ($delim,$row_delim) {
    s/\n/\\n/g;
    s/\r/\\r/g;
  }

  my @col_list = ( $opts{ColumnList} && @{$opts{ColumnList}} )
    ? @{$opts{ColumnList}}
    : @{$col_info->{LIST}};

  my $ncols = @col_list;
  open( my $fh, ">", $fmt_file ) or confess "Failed to open $fmt_file: $!";
  print $fh "10.0\n";
  print $fh "$ncols\n";

  my $col_map = $col_info->{MAP};
  for my $i (1..$ncols) {
    my $name = $col_list[$i-1];
    my $d = ( $i == $ncols ) ? $row_delim : $delim;
    my @row = ($i, 'SYBCHAR', 0);
    if ($is_filler{lc($name)}) {
      push @row, 0, qq["$d"], 0;
    } elsif ($is_db_column{lc($name)}) {
      my $info = $col_map->{lc($name)};

      # Native Sybase date format size is 26 though metadata says 23
      # For numbers, add extra for decimal
      my $size =
        ( $info->{TYPE_NAME} =~ /date/ ) ? 26
      : ( $info->{TYPE_NAME} =~ /char|text/ ) ? $info->{COLUMN_SIZE}
      : $info->{COLUMN_SIZE} + 1;
      push @row, $size, qq["$d"], $info->{ORDINAL_POSITION}, $name;
    } else { confess "$name is neither a db nor filler column" }
    print $fh join("\t", @row), "\n";
  }

  close $fh;


  # Also return temp object so it will not be cleaned up yet
  return
    wantarray ?  ($tmp_fmt_file, $fmt_file)
  : $tmp_fmt_file ? $tmp_fmt_file
  : $fmt_file;

}

sub bcp_out {
  my $self = shift;
  my @opts;
  if (ref $_[-1]) {
    @opts = pop @_;
  }
  my ($table, $file) = @_;
  $file ||= "$table.bcp";

  my $scratchdb = @opts ? $opts[0]{TempDb} || 'scratchdb' : 'scratchdb';

  # Sybase rounds money columns, need to bcp a view of it
  # if any exist.
  my $dbh = $self->{DBH};

  # Need to save current db in case view is created
  my $curr_db = $self->curr_db();
  my $view = $self->mk_view($table, @opts);

  my $rows = eval { $self->bcp($view || $table, $file, 'out', @opts) };
  unless (defined $rows) {
    my $err = $@;
    if ($view) {
      warn "BCP error detected - dropping view $view\n";
      my $result = eval { $dbh->do("DROP VIEW $view") };
      warn "Unable to drop view $view: $@" unless $result;
      $dbh->do("USE $curr_db") if !$self->is_iq() and $curr_db;
    }
    confess $err;
  }

  if ($view) {
    print "Dropping view $view\n";
    $dbh->do("DROP VIEW $view");
    $dbh->do("USE $curr_db") if !$self->is_iq() and $curr_db;
  }
  if ( !@opts or !$opts[0]{NoFix} ) {
    my $bak = eval { $self->fix_bcp_file($file, @opts) };
    if ( $bak ) {
      unlink $bak;
    } else {
      warn "Error processing $file. BCP file in $file.bak: $@\n";
      return;
    }
  }
  if ( @opts and ( $opts[0]{Header} || $opts[0]{QuoteFields} ) ) {
    my $bak = eval { $self->add_header($table, $file, @opts) };
    if ( $bak ) {
      unlink $bak;
    } else {
      warn "Error post processing $file. BCP file in $file.bak: $@\n";
      return;
    }
  }
  return $rows;
}

sub mk_view {

  my ($self,$table) = @_;
  my @opts;
  @opts = pop @_ if ref $_[-1];
  my $scratchdb = @opts ? $opts[0]{TempDb} || 'scratchdb' : 'scratchdb';

  # Sybase rounds money columns, need to bcp a view of it
  # if any exist.
  my $dbh = $self->{DBH};

  my $col_info = $self->column_info($table);

  # Columns might be a string from a SELECT clause
  # Or it might be an arrayref of columns
  my $col_list = ( @opts && $opts[0]{Columns} )
    ? $opts[0]{Columns}
    : $col_info->{LIST};

  my $col_map  = $col_info->{MAP};

  my @columns;
  my $money_cnt = 0;

  my $column_str;
  if ( ref $col_list ) {
    for my $name (@$col_list) {
      my $col_name = $name;
      if ( my $info = $col_map->{$name} ) {
        my $type = $info->{TYPE_NAME};
        $col_name = $info->{COLUMN_NAME};
        if ($type =~ /money/) {
          $money_cnt++;
          my $len = ($type =~ /small/) ? 10 : 19;
          $col_name = "convert(decimal($len,4), $col_name) $col_name";
        }
      }
      push @columns, $col_name;
    }
    $column_str = join ",", @columns;
  } else {
    $column_str = $col_list;
  }

  return if $money_cnt==0 and !$opts[0]{Filter} and !$opts[0]{Columns};

  my ($view, $db_view);

  my $curr_db = $self->curr_db();
  if ( !$curr_db and $table =~ /^(\w+)\.\w*\.\w+$/ ) {
    $curr_db = $1;
  }
  confess "Can not determine database" unless $curr_db;

  my $base_table =
    (!$curr_db or $table =~ /^\w+\.\w*\.\w+$/)  ? $table
  : ($table =~ /^\w+$/)                         ? "$curr_db..$table"
  : ($table =~ /^\w*\.\w+$/)                    ? "$curr_db.$table"
  : confess "Can not determine database for view";

  ( my $tmp_view = $base_table ) =~ s/.*\.//;
  $tmp_view = substr($tmp_view, 0, 19) if length($tmp_view) > 19;

  $dbh->do("USE $scratchdb") unless $self->is_iq();

  my $cnt;
  while (1) {
    my ($sec, $min, $hr) = localtime;
    my $id = sprintf("%05d%02d%02d%02d", $$, $hr, $min, $sec);

    $view = "${tmp_view}${id}";
    $db_view = $self->is_iq() ? $view : "$scratchdb..$view";
    my $sql = sprintf(
      "CREATE VIEW %s AS SELECT %s FROM %s",
      $view,
      $column_str,
      $base_table,
    );
    $sql .= " $opts[0]{Filter}" if @opts && $opts[0]{Filter};
    print "Creating view $db_view\n";
    print "Executing: $sql\n";
    my $result = eval { $dbh->do($sql) };
    return $view if $result;
    confess $@ unless $@ =~ /already an object/;
    $cnt++;
    confess "Too many retries trying to create view $db_view. Aborting"
      if $cnt > 20;
    print "View $db_view already exists, retrying #$cnt...";
    sleep 2;
  }

}

# Fix native date format from Sybase bcp out
{   my %mons = qw( Jan 1 Feb 2 Mar 3 Apr 4 May 5 Jun 6 Jul 7 Aug 8 Sep 9 Oct 10 Nov 11 Dec 12 );
    my $mon_str = join '|', keys %mons;
    my $mon_re = qr/$mon_str/;

    sub fix_bcp_file {
        my ( $self, $file ) = @_;
        my $opts = {};
        if (ref $_[-1]) {
          $opts = pop @_;
        }
        my $delimiter = $opts->{Delimiter} || $self->{DELIMITER} || '|';
        my $dre = quotemeta($delimiter);
        local ($_, $., $ARGV, *ARGV);
        local ( $^I, @ARGV ) = ( '.bak', $file );
        local $/ = $opts->{RowDelimiter} || $/;
        while ( <> ) {
            1 while s!(^|$dre)($mon_re)\s{1,2}(\d{1,2})\s(\d{4})\s\s?(\d\d?):(\d\d):(\d\d):(\d{3})([AP])M($dre|$/)!
              $1 .
              sprintf( '%04d-%02d-%02d %02d:%02d:%02d.%03d',
                $4,
                $mons{ $2 },
                $3,
                ( $9 eq 'P' && $5 < 12) ? $5 + 12 : ( $9 eq 'A' && $5 == 12 ) ? 0 : $5,
                $6,
                $7,
                $8 ) .
              $10
            !eg;
            1 while s!(^|$dre)($mon_re)\s{1,2}(\d{1,2})\s(\d{4})\s\s?(\d\d?):(\d\d)([AP])M($dre|$/)!
              $1 .
              sprintf( '%04d-%02d-%02d %02d:%02d',
                $4,
                $mons{ $2 },
                $3,
                ( $7 eq 'P' && $5 < 12) ? $5 + 12 : ( $7 eq 'A' && $5 == 12 ) ? 0 : $5,
                $6 ) .
              $8
            !eg;
            1 while s!(^|$dre)($mon_re)\s{1,2}(\d{1,2})\s(\d{4})($dre|$/)!
              $1 .
              sprintf( '%04d-%02d-%02d',
                $4,
                $mons{ $2 },
                $3 ) .
              $5
            !eg;
            print;
        }
        return "$file.bak";
    }
}

{
my %type_map = ( 'V' => 'V', 'P' => 'P', 'U' => 'T' );

sub obj_type {
  my ( $self, $name ) = @_;
  my $dbh = $self->{DBH};
  my $qname = $dbh->quote($name);
  my ( $type ) = $dbh->selectrow_array("select type from sysobjects where name = $qname");
  return unless $type;
  return $type_map{$type} || confess "Don't know about type $type for object $name";
}
}

sub curr_db { 
  my $self = shift;

  $self->get('db_name()');
}

sub curr_schema { undef }

{

# Can get errors in some databases if you don't add dbo to everything
my $sql_t = <<SQL;
SELECT
  dbo.sysindexes.name,
  index_col(object_name(dbo.sysindexes.id), dbo.sysindexes.indid, dbo.syscolumns.colid) col_name
FROM dbo.sysindexes, dbo.syscolumns
WHERE dbo.sysindexes.id = dbo.syscolumns.id
  AND dbo.syscolumns.colid <= dbo.sysindexes.keycnt
  AND dbo.sysindexes.id = object_id(%s)
SQL

sub index_info {
  my ( $self, $table, $all_indexes ) = @_;

  my ($tmp_db, $curr_db) = (undef,'');
  my $dbh = $self->{DBH};

  my $schema = '';
  $tmp_db = $curr_db = $self->curr_db();

  if ( $table =~ /^(?:(\w+)\.)?(\w*)\.(\w+)$/ ) {
    ($tmp_db, $schema, $table) = ($1,$2,$3);
    $table = "$schema.$table";

    # We can only get info on the current database
    if ( defined($tmp_db) and $tmp_db ne $curr_db ) {
      $dbh->do("USE $tmp_db");
    }
  }

  my $sql = sprintf $sql_t, $dbh->quote($table);
  $sql .= "AND dbo.sysindexes.status & 2 = 2\n" unless $all_indexes;
  $sql .= "ORDER BY dbo.syscolumns.colid\n";
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my @col_names = @{$sth->{NAME_lc}};
  my %row; $sth->bind_columns(\@row{@col_names});
  my %ind;
  while ($sth->fetch()) {
    if ( $row{col_name} ) {
      push @{$ind{$row{name}}}, lc($row{col_name});
    }
  }

  $dbh->do("USE $curr_db") if defined($tmp_db) and $tmp_db ne $curr_db;

  return unless %ind;
  return \%ind;
}

}

sub primary_key {
  my ( $self, $table ) = @_;
  my $schema;
  my ($tmp_db, $curr_db) = (undef,'');
  my $dbh = $self->{DBH};

  $tmp_db = $curr_db = $self->curr_db();

  if ( $table =~ /^(?:(\w+)\.)?(\w*)\.(\w+)$/ ) {
    ($tmp_db, $schema, $table) = ($1,$2,$3);
    $schema ||= undef;

    # We can only get column info on the current database
    $dbh->do("USE $tmp_db") if defined($tmp_db) and $tmp_db ne $curr_db;
  }

  my @pk = $self->{DBH}->primary_key($tmp_db, $schema, $table);

  $dbh->do("USE $curr_db") if defined($tmp_db) and $tmp_db ne $curr_db;

  return unless @pk;

  return \@pk;
}

{

my $del_sql = <<SQL;
DELETE %s
FROM %s d, %s s
WHERE %s
SQL

my $ins_sql = <<SQL;
SELECT %s
FROM %s
SQL

sub merge {
  my $self = shift;
  my %args = @_;
  my $dbh = $self->{DBH};

  my $table     = lc($args{Table});
  my $stg_table = lc($args{StgTable});

  my $tbl_info = $self->column_info($table);
  my $tbl_map  = $tbl_info->{MAP};

  my $stg_info = $self->column_info($stg_table);
  my $stg_map  = $stg_info->{MAP};

  my %stg_has; $stg_has{$_}++ for @{$stg_info->{LIST}};

  my $key_col_ref = ($args{KeyCols} && @{$args{KeyCols}}) ? $args{KeyCols} : $self->key_columns($table);
  my $upd_col_ref = ($args{UpdCols} && @{$args{UpdCols}}) ? $args{UpdCols} : $self->upd_columns($table, $key_col_ref);

  my @key_cols = map $tbl_map->{lc($_)}{COLUMN_NAME}, @$key_col_ref;
  my %is_key_col;
  $is_key_col{$_}++ for map lc, @$key_col_ref;
  my @upd_cols = map $tbl_map->{lc($_)}{COLUMN_NAME}, @$upd_col_ref;
  my %is_upd_col;
  $is_upd_col{$_}++ for map lc, @$upd_col_ref;

  my %tmp_col_map;
  %tmp_col_map = map lc, %{$args{ColMap}} if $args{ColMap};

  # Column map for upd statement, which must map the correct case
  # to the correct case.
  my %col_map = map {( $_ => (
    $tmp_col_map{lc($_)}
      ? $stg_map->{lc($tmp_col_map{lc($_)})}{COLUMN_NAME}
      : $stg_map->{lc($_)}{COLUMN_NAME}
  ))} @key_cols, @upd_cols;

  # Correctly cased field list for bcp select from stage table statement
  # Either it's in the explicit column map, or it's a key or upd column
  # with the same name as the target table,
  # or it can be last_chg_user or date
  my @fields   = map {
      ($_ eq 'last_chg_user' && !$stg_has{last_chg_user}) ? 'suser_name()'
    : ($_ eq 'last_chg_date' && !$stg_has{last_chg_date}) ? 'getdate()'
    : $tmp_col_map{$_} ? $stg_has{$tmp_col_map{$_}} ? $stg_map->{$tmp_col_map{$_}}{COLUMN_NAME} : $tmp_col_map{$_}
    : ( $is_key_col{$_} || $is_upd_col{$_} ) ? $stg_has{$_} ? $stg_map->{$_}{COLUMN_NAME} : ()
    : $stg_map->{$_} ? $stg_map->{$_}{COLUMN_NAME}
    : confess "Failed to map target column $table.$_"
  } @{$tbl_info->{LIST}};
  my $field_str     = join(",", @fields);

  my $key_col_str  = join("\nAND ", map "d.$_=s.".($col_map{$_}||$_), @key_cols);

  my $del_merge_sql = sprintf($del_sql,
    $table,
    $table, $stg_table,
    $key_col_str,
  );
  print("Executing: $del_merge_sql\n");

  unless ($args{NoExec}) {
    my $del_rows = $dbh->do($del_merge_sql) + 0;
    print("$del_rows rows deleted from $table\n\n");
  }

  my $ins_merge_sql = sprintf($ins_sql,
    $field_str,
    $stg_table,
  );
  print("Inserting to $table: $ins_merge_sql\n");

  return 1 if $args{NoExec};

  my $ins_rows = ( $args{NoBCP} or ($stg_table =~ /^#/) )
    ? $dbh->do("INSERT INTO $table\n$ins_merge_sql") + 0
    : $self->bcp_sql($table, $ins_merge_sql) + 0;
  print("$ins_rows rows inserted to $table\n\n");

  return 1;
}
}

# This merge is destructive to the staging table
# Only 'new' rows will be left in the staging table
{

my $upd_sql = <<SQL;
UPDATE %s
SET %s
FROM %s d,%s s
WHERE %s
SQL

my $del_sql = <<SQL;
DELETE %s
FROM %s s, %s d
WHERE %s
SQL

my $ins_sql = <<SQL;
SELECT %s
FROM %s
SQL

sub merge2 {
  my $self = shift;
  my %args = @_;
  my $dbh = $self->{DBH};

  my $table     = lc($args{Table});
  my $stg_table = lc($args{StgTable});

  my $tbl_info = $self->column_info($table);
  my $tbl_map  = $tbl_info->{MAP};

  my $stg_info = $self->column_info($stg_table);
  my $stg_map  = $stg_info->{MAP};
  my %stg_has; $stg_has{$_}++ for @{$stg_info->{LIST}};

  my $key_col_ref = ($args{KeyCols} && @{$args{KeyCols}}) ? $args{KeyCols} : $self->key_columns($table);
  my $upd_col_ref = ($args{UpdCols} && @{$args{UpdCols}}) ? $args{UpdCols} : $self->upd_columns($table);

  my @key_cols = map $tbl_map->{lc($_)}{COLUMN_NAME}, @$key_col_ref;
  my %is_key_col;
  $is_key_col{$_}++ for map lc, @$key_col_ref;
  my @upd_cols = map $tbl_map->{lc($_)}{COLUMN_NAME}, @$upd_col_ref;
  my %is_upd_col;
  $is_upd_col{$_}++ for map lc, @$upd_col_ref;

  my %tmp_col_map;
  %tmp_col_map = map lc, %{$args{ColMap}} if $args{ColMap};

  # Column map for upd statement, which must map the correct case
  # to the correct case.
  my %col_map = map {( $_ => (
    $tmp_col_map{lc($_)}
      ? $stg_map->{lc($tmp_col_map{lc($_)})}{COLUMN_NAME}
      : $stg_map->{lc($_)}{COLUMN_NAME}
  ))} @key_cols, @upd_cols;

  # Correctly cased field list for bcp select from stage table statement
  # Either it's in the explicit column map, or it's a key or upd column
  # with the same name as the target table,
  # or it can be last_chg_user or date
  my @fields   = map {
      ($_ eq 'last_chg_user' && !$stg_has{last_chg_user}) ? 'suser_name()'
    : ($_ eq 'last_chg_date' && !$stg_has{last_chg_date}) ? 'getdate()'
    : $tmp_col_map{$_} ? $stg_map->{$tmp_col_map{$_}}{COLUMN_NAME}
    : ( $is_key_col{$_} || $is_upd_col{$_} ) ? $stg_map->{$_}{COLUMN_NAME}
    : $stg_map->{$_}   ? $stg_map->{$_}{COLUMN_NAME}
    : confess "Failed to map target column $table.$_"
  } @{$tbl_info->{LIST}};
  my $field_str     = join(",", @fields);

  my $key_col_str  = join("\nAND ", map "d.$_=s.".($col_map{$_}||$_), @key_cols);
  my $upd_col_str  = join(",", map "$_=s.".($col_map{$_}||$_), @upd_cols);

  # Determine if last_chg_user, last_chg_date need to be updated
  my %chg_col = $self->last_chg_list($table, \@fields);
  for my $col ( sort { $b cmp $a } keys %chg_col ) {
    $upd_col_str .= ",$col=".( ($col eq 'last_chg_user') ? 'suser_name()' : 'getdate()');
  }

  unless ($args{InsertOnly}) {
    my $upd_merge_sql = sprintf($upd_sql,
      $table,
      $upd_col_str,
      $table, $stg_table,
      $key_col_str,
    );
    print("Executing: $upd_merge_sql\n");

    unless ($args{NoExec}) {
      my $upd_rows = $dbh->do($upd_merge_sql) + 0;
      print("$upd_rows rows updated in $table\n\n");
    }
  }

  my $del_merge_sql = sprintf($del_sql,
    $stg_table,
    $stg_table, $table,
    $key_col_str,
  );
  print("Executing: $del_merge_sql\n");

  unless ($args{NoExec}) {
    my $del_rows = $dbh->do($del_merge_sql) + 0;
    print("$del_rows rows deleted from $stg_table\n\n");
  }

  my $ins_merge_sql = sprintf($ins_sql,
    $field_str,
    $stg_table,
  );
  print("Inserting to $table: $ins_merge_sql\n");

  return 1 if $args{NoExec};
  my $ins_rows = $self->bcp_sql($table, $ins_merge_sql) + 0;
  print("$ins_rows rows inserted to $table\n\n");

  return 1;
}
}

# BCP (via sqsh) the results of a sql select statement into a table
sub bcp_sql {
  my $self = shift;
  my ($table,$sql) = @_;

  my $dbh = $self->{DBH};
  my $db = $dbh->{Name};
  $db =~ /server=(\w+)/ or confess "Can't determine server for bcp";
  my $server = $1;
  my $database = $self->curr_db();

  my $user      = $dbh->{Username};
  my $bcp_table =
    (!$database or $table =~ /^\w+\.\w*\.\w+$/) ? $table
  : ($table =~ /^\w+$/)                         ? "$database..$table"
  : ($table =~ /^\w*\.\w+$/)                    ? "$database.$table"
  : confess "Can not determine database for sqsh/bcp";

  local $ENV{SQSH} = "-U $dbh->{Username} -P $self->{PASSWORD}";
  my $pid = open(my $fh, "-|");
  confess "Can't fork: $!" unless defined $pid;
  unless ($pid) {

    # sqsh needs library path set - make sure it is set
    # Don't know where it is in generic environment, or best way
    # to universally set this, or even if this is necessary in general...
    # local $ENV{LD_LIBRARY_PATH} = '/path/to/sybase/OCS-12_5/lib';
    my @cmd = (sqsh => -S => $server, -D => $database);
    my $sqsh_fh;

    # sqsh outputs to stderr
    open(STDERR, ">&STDOUT");
    unless ( open($sqsh_fh, "|-", @cmd) ) {
      warn "Unable to exec @cmd: $!";
      exit(1);
    }
    print $sqsh_fh "$sql\n";
    print $sqsh_fh "\\bcp -b 1000 $bcp_table\n";

    my $status = close $sqsh_fh;
    exit($status ? 0 : 1);
  }
  my $rows;
  local ($_, $.);
  my $cnt;
  while (<$fh>) {
    if (/^Batch successfully bulk-copied/) {
      $cnt += 1000;
      print "$cnt: $_" unless $cnt % 10_000;
      next;
    }
    print;
    $rows = $1 if /^\s*(\d+) rows copied/;
  }
  my $close_status = close $fh;
  confess "SQSH BCP error - no rows copied"    unless defined $rows;
  confess "SQSH BCP error - $rows rows copied" unless $close_status;

  # Return true value
  return $rows;
}

# SQL to return table column defaults
{
my $sql = <<SQL;
SELECT c.name, d.text
FROM dbo.syscolumns c, dbo.syscomments d
WHERE c.id = object_id('%s')
AND c.cdefault = d.id
AND d.texttype = 0
SQL

sub default_sql { return $sql }
}

# Changed for Sybase v12 and multiple tempdbs
sub temp_table_name {
  my ($self, $name) = @_;

  my $dbh = $self->{DBH};
  my ($spid) = $dbh->selectrow_array('select @@spid');
  print "SPid: $spid\n";
  my $who = $dbh->selectrow_hashref("exec sp_who '$spid'");
  my $tempdb = $who->{tempdbname} || 'tempdb';
  print "TempDb: $tempdb\n";
  my ($id) = $dbh->selectrow_array("select object_id('$tempdb..$name')");
  print "ID: $id\n";
  my ($real_name) = $dbh->selectrow_array("select object_name($id, db_id('$tempdb'))");
  print "RealName: $real_name\n";
  return "$tempdb..$real_name";
}

sub delete {
  my ($self, $table, $where, $limit) = @_;

  my $dbh = $self->{DBH};
  $dbh->{syb_rowcount} = $limit || 1000;

  my $sql = "DELETE FROM $table";
  $sql .= " WHERE $where" if $where;

  my ($rows, $tot_rows);
  my ($err, $err_msg);

  print "Executing: $sql\n";
  do {

    $rows = eval { $dbh->do($sql) };
    unless ($rows) {
      $err_msg = $@;
      $err++;
      $rows = 0;
    }

    $tot_rows += $rows;
    print "Deleted $tot_rows rows\n" if $rows > 0;

  } while $rows > 0;

  $dbh->{syb_rowcount} = 0;

  confess $err_msg if $err;

  print "$tot_rows rows deleted from $table\n";
  return $tot_rows;
}


package DBIx::BulkUtil::SybaseIQ;

use Carp qw(confess);
use Cwd qw(abs_path);

our @ISA = qw(DBIx::BulkUtil::Sybase);

{

my $sql = <<SQL;
LOAD TABLE %s
(
%s
)
FROM
  %s
QUOTES OFF
ESCAPES OFF
SQL

sub bcp_in {
  my $self  = shift;
  my $table = shift;

  my $opts = (ref $_[-1]) ? pop @_ : {};

  my @files = @_;

  push @files, "$table.bcp" unless @files;

  my $dbh = $self->{DBH};

  my $delimiter = $opts->{Delimiter} || $self->{DELIMITER};
  my $row_delimiter = $opts->{RowDelimiter} || "\n";

  my $id_cnt;
  my $mode = $opts->{Action} || "A";
  if ( $mode eq 'T' ) {
    my $sql = "TRUNCATE TABLE $table";
    print "Executing: $sql\n";
    $dbh->do($sql);
  } elsif ($mode eq 'R') {
    my $sql = "DELETE FROM $table";
    print "Executing: $sql\n";
    $dbh->do($sql);
  }

  my @bcp_list;
  for my $file (@files) {
    confess "BCP file $file does not exist" unless -f $file;
    unless ( -s _ ) {
      print "$file is empty. Skipping ...\n";
      next;
    }
    push @bcp_list, $file;
  }

  unless ( @bcp_list ) {
    print "All files are empty. Skipping bcp of $table\n";

    # Make any log file parsers happy
    print "0 rows copied\n";
    return 0;
  }

  my $info = $self->column_info($table);
  my $col_list = ( $opts->{ColumnList} && @{$opts->{ColumnList}} ) ? $opts->{ColumnList} : $info->{LIST};
  my @filler = $opts->{Filler} ? @{$opts->{Filler}} : ();
  my %is_filler;
  $is_filler{$_}++ for @filler;

  # Convert empty string to NULL
  # Should be default but we don't want to break existing apps
  my $null_blanks = $self->{NoBlankNull} ? ' NULL(BLANKS)' : '';

  # Columns that we will let default to the schema default
  my $dflt = $opts->{Default} || [];
  my %dflt; $dflt{$_}++ for @$dflt;

  my $constant = $opts->{Constants} || {};

  my @list = grep !defined($constant->{$_})&&!$dflt{$_}, @$col_list;
  my $last_col = $list[-1];

  # It is best to explicitly put the row delimiter on the last column
  my $load_sql = sprintf(
    $sql,
    $table,
    join( ",\n", map {
      defined($constant->{$_}) ? qq( [$_] DEFAULT '$constant->{$_}')
    : ( $_ ne $last_col )
      ? $is_filler{$_} ? qq( FILLER('$delimiter')) : qq( [$_] '$delimiter'$null_blanks)
    : ( $opts->{TrailingDelimiter} )
      ? $is_filler{$_} ? qq( FILLER('$delimiter$row_delimiter')) : qq( [$_] '$delimiter$row_delimiter'$null_blanks)
    : $is_filler{$_} ? qq( FILLER('$row_delimiter')) : qq( [$_] '$row_delimiter'$null_blanks)
    } grep !$dflt{$_}, @$col_list),
    join( ",\n  ", map { "'". abs_path($_) . "'" } @bcp_list),
  );

  $load_sql .= "SKIP $opts->{Header}\n" if $opts->{Header};

  # '0' indicates unlimited errors to IQ, but will be skipped here since '0' is false
  # That's okay, '00' might work (it is 'true' and == 0).
  $load_sql .= "IGNORE CONSTRAINT ALL $opts->{MaxErrors}\n" if $opts->{MaxErrors};

  my $db = $dbh->{Name};
  $db =~ /server=(\w+)/ or confess "Can't determine server for bcp";
  my $server = $1;
  my $database = $self->curr_db();

  print "Loading $server/$database/$table\n";
  print "Executing: $load_sql\n";
  my $rows = $dbh->do($load_sql) + 0;
  print "$rows rows copied\n";
  return $rows;
}
}

{
my $sql = <<SQL;
SELECT cname, default_value
FROM sys.syscolumns
WHERE tname = '%s'
AND default_value IS NOT NULL
SQL

sub default_sql { return $sql }
}

# Because SybaseIQ can not do sqsh
sub bcp_sql {
  my ($self, $table, $sql) = @_;
  my $do_sql = "INSERT INTO $table\n$sql";
  $self->{DBH}->do("INSERT INTO $table\n$sql");
}

sub is_iq {1}

sub index_info {
  my ( $self, $table, $all_indexes ) = @_;

  my $dbh = $self->{DBH};

  my $sql = "exec sp_iqindex [$table]";
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my @col_names = @{$sth->{NAME_lc}};
  my %row; $sth->bind_columns(\@row{@col_names});
  my %ind;
  while ($sth->fetch()) {
    next if !$all_indexes and $row{unique_index} ne 'Y';
    $ind{$row{index_name}} = [ split /,/, $row{column_name} ];
  }

  return unless %ind;
  return \%ind;
}

package DBIx::BulkUtil::Oracle;

use Carp qw(confess);
use Cwd  qw(abs_path);

our @ISA = qw(DBIx::BulkUtil::Obj);

sub now { 'systimestamp' }

sub add {
  my $self = shift;
  my $date = shift;
  while (my ( $n, $unit ) = splice( @_, 0, 2 ) ) {
    $date .= " + numtodsinterval( $n, '$unit' )";
  }
  return $date;
}

{
my %intervals = (
  year   => '/ 365',
  month  => '/ 30',
  hour   => '* 24',
  minute => '* 24 * 60',
  second => '* 24 * 60 * 60',
);

sub diff {
  my $self = shift;
  my $date1 = shift;
  my $date2 = shift;
  my $unit = shift;
  my $diff_str = "$date2 - $date1";
  if (my $str = $intervals{$unit}) {
    $diff_str = "($diff_str) $str";
  }
  return "trunc($diff_str)";
}
}

# This is necessary when you want to use a literal
# date in a datetime calculation
sub to_datetime {
  my $self = shift;
  my $date = shift;

  return "to_timestamp('$date', 'YYYY-MM-DD HH24:MI:SS.FF')";
}

# Don't need this with new version of DBI/DBD
#sub to_char {
#  my $self = shift;
#  my $date = shift;
#  return "to_char($date, 'YYYY-MM-DD HH24:MI:SS')";
#}
#
#sub fmt { return $_[1] }

sub row_select {
  my $self = shift;
  my $sel = shift;
  return "select $sel from dual";
}

sub sp_sth {
  my $self = shift;
  my $sth = $self->{DBH}->prepare($self->sp_sql(@_));
  $sth->bind_param_inout(":cursor", \my $sth2, 0, { ora_type => DBD::Oracle::ORA_RSET() });
  $sth->execute();
  return $sth2;
}

sub sp_sql {
  my $self = shift;
  my ($stored_proc, @args) = @_;
  return
    "BEGIN\n$stored_proc(" .
    join(",", map { /^:cursor$/ ? $_ : $self->{DBH}->quote($_) } @args) .
    ");\nEND;\n";
}

{

my %action_map = (
  A => "APPEND",
  R => "REPLACE",
  T => "TRUNCATE",
);

sub bcp_in {
  my $self = shift;
  my $opts = {};
  if (ref $_[-1]) {
    $opts = pop @_;
  }
  my $action_opt = uc($opts->{Action} || "A");

  my ( $table, @files ) = @_;

  my $partition = ( $table =~ s/:(\w+)$// ) ? $1 : '';

  my $dbh = $self->{DBH};

  my $stdin = $opts->{Stdin};
  @files = "$table.bcp" if !@files && !$stdin;

  my $has_stdin;
  for my $file (@files) {
    if ( $file eq "-" ) {
      $has_stdin++;
      next;
    }
    confess "BCP file $file does not exist" unless -f $file;
  }

  if ( $has_stdin && !$stdin ) {
    $stdin = \*STDIN;
  } elsif ( $stdin && !$has_stdin ) {
    push @files, "-";
  }

  # Save some work, skip load on empty file
  # Let sqlldr do a heavy handed truncate or delete
  # if that is the chosen action
  my @bcp_files = grep { $_ eq "-" or -s } @files;

  if ( !@bcp_files ) {
    if ( $action_opt eq 'A') {
      print "$files[0],... is empty. Skipping sqlldr\n";

      # Make any log file parsers happy
      print "0 Rows successfully loaded\n";
      return 0;
    }

    # Need some files if we run sqlldr
    @bcp_files = @files;
  }
  require File::Temp;

  my $constants = $opts->{Constants} || {};
  my %const = map { uc($_) => $constants->{$_} } keys %$constants;

  my $sizes = $opts->{CharSizes} || {};
  my %char_sizes = map { uc($_) => $sizes->{$_} } keys %$sizes;

  my $keep_temp = $opts->{KeepTempFiles} || $opts->{Debug};
  my $in_temp_dir = $opts->{TempDir}     || $opts->{Debug};
  my $temp_dir;
  $temp_dir = $opts->{TempDir} || "." if $in_temp_dir;

  my @temp_dir = $in_temp_dir ? (DIR => $temp_dir) : ();
  my @unlink  = $keep_temp ? (UNLINK => 0) : ();
  my $ctl_fh = File::Temp->new(
    TEMPLATE => "${table}_XXXXX",
    SUFFIX   => ".ctl",
    @temp_dir, @unlink,
  );
  chmod(0664, $ctl_fh->filename());
  my $bad_fh = File::Temp->new(
    TEMPLATE => "${table}_XXXXX",
    SUFFIX   => ".bad",
    @temp_dir, @unlink,
  );
  chmod(0664, $bad_fh->filename());
  my $log_fh = File::Temp->new(
    TEMPLATE => "${table}_XXXXX",
    SUFFIX   => ".log",
    @temp_dir, @unlink,
  );
  chmod(0664, $log_fh->filename());
  my $prm_fh = $stdin ? File::Temp->new(
    TEMPLATE => "${table}_XXXXX",
    SUFFIX   => ".prm",
    @temp_dir,
  ) : undef;

  # NLS date format env variable does not work
  # for sqlldr.
  # So we must determine date fields and
  # specify the format in the control file.
  my $db = $self->{DBH}->{Name};
  my $user = $dbh->{Username};
  my ($schema, $tbl_name) = split /\./, uc($table);
  if (!$tbl_name) {
    $tbl_name = $schema;
    $schema = $self->curr_schema();
  }

  my $sth = $dbh->column_info(undef, $schema, $tbl_name, undef);
  my @info_names = @{$sth->{NAME_uc}};
  my %row; $sth->bind_columns(\@row{@info_names});
  my (@columns, %is_date, %char_sz, %is_lob);
  print "ColumnName  Type Size\n" if $opts->{Debug};
  print "----------------\n" if $opts->{Debug};
  while ($sth->fetch()) {
    push @columns, $row{COLUMN_NAME};
    print "$row{COLUMN_NAME}\t$row{TYPE_NAME}\t$row{COLUMN_SIZE}\n" if $opts->{Debug};
    $char_sz{$row{COLUMN_NAME}} = exists($char_sizes{$row{COLUMN_NAME}}) ? $char_sizes{$row{COLUMN_NAME}} : $row{COLUMN_SIZE} if $row{TYPE_NAME} =~ /CHAR/;
    $char_sz{$row{COLUMN_NAME}} = exists($char_sizes{$row{COLUMN_NAME}}) ? $char_sizes{$row{COLUMN_NAME}} : 20_000_000, $is_lob{$row{COLUMN_NAME}} = 1 if $row{TYPE_NAME} =~ /TEXT|LOB|XML/;
    $is_date{$row{COLUMN_NAME}} = $1 if $row{TYPE_NAME} =~ /(DATE|TIMESTAMP)/;
  }
  confess("Table $schema.$tbl_name not found in database $db") unless @columns;

  # Find date formats in file, remove constants from column list
  my %date_fmt;
  my @file_columns = grep !defined($const{$_}),
    ( ( $opts->{ColumnList} && @{$opts->{ColumnList}} ) ? ( map uc, @{$opts->{ColumnList}} ) : @columns );
  if (%is_date) {
    # We don't want to sample rows from stdin
    my @real_files = grep { $_ ne "-" } @files;
    %date_fmt = $self->date_masks_from_file( \@real_files, \@file_columns, \%is_date, $opts)
      if @real_files;
  }

  my $row_delim_str = $opts->{RowDelimiter} ? qq("str '$opts->{RowDelimiter}'"\n) : '';

  my $delimiter = $opts->{Delimiter} || $self->{DELIMITER};
  my $action = $action_map{$action_opt} || "APPEND";
  my $direct_load_pre  = '';
  my $direct_load_post = '';

  my $sqlldr_opts = '';
  my $max_errors = $opts->{MaxErrors} || 0;
  $sqlldr_opts .= "ERRORS=$max_errors";
  $sqlldr_opts .= ", SKIP=$opts->{Header}" if $opts->{Header};

  if ($opts->{DirectPath}) {
    my $parallel = ( uc($opts->{DirectPath}) eq 'P' ) ?  ", PARALLEL=TRUE" : '';
    $direct_load_pre = "OPTIONS(DIRECT=TRUE$parallel, ROWS=1000000, $sqlldr_opts)\nUNRECOVERABLE\n";
    $direct_load_post = "REENABLE DISABLED_CONSTRAINTS\n";
  } else {
    my $commit_rows = $opts->{CommitSize} || 2000;
    $direct_load_pre = "OPTIONS (ROWS=$commit_rows, BINDSIZE=5000000, READSIZE=20970000, $sqlldr_opts)\n";
  }
  my $default_date_fmt =
      $opts->{SybaseDateFmt} ? 'MON DD YYYY HH12:MI:SS:FF3AM'
    : $opts->{DateFormat}    ? $opts->{DateFormat}
    : 'YYYY-MM-DD HH24:MI:SS.FF3'
  ;
  for ( keys %is_date ) {
    $date_fmt{$_} ||= $default_date_fmt;
    $is_date{$_} = 'TIMESTAMP' if $date_fmt{$_} =~ /FF|TZ[DHMR]/;
  }
  my $quote_str = $opts->{QuoteFields}
    ? qq( OPTIONALLY ENCLOSED BY '"')
    : ''
  ;
  if ( $opts->{LoadWhen} ) {
    $direct_load_post .= "WHEN $opts->{LoadWhen}\n";
  }

  my $nls_str = '';
  $nls_str  = "CHARACTERSET $opts->{NLSLang}" if $opts->{NLSLang};
  $nls_str .= " LENGTH SEMANTICS $opts->{Semantics}" if $opts->{Semantics};
  $nls_str .= "\n" if $nls_str;

  my %sybase_type;
  @sybase_type{@file_columns} = @{$opts->{SybaseTypes}} if $opts->{SybaseTypes};
  # Logic for trimming or preserving blanks on char/varchar columns
  my $blank_control = sub {
    my $size = $char_sz{$_};
    return "  $_ CHAR($size) PRESERVE BLANKS"
      if $opts->{PreserveBlanks} or $size == 1;
    if ( $opts->{SybaseTypes} ) {
      # On the off chance a Sybase char column becomes an Oracle BLOB
      return qq[  $_ CHAR($size)] if $is_lob{$_};
      return qq[  $_ CHAR($size) "NVL(RTRIM(:$_),' ')"] if $sybase_type{$_} eq 'char';
    } else {
      return qq[  $_ CHAR($size)] if $is_lob{$_};
      return qq[  $_ CHAR($size) "NVL(RTRIM(:$_),' ')"] if $opts->{TrimBlanks};
    }
    return "  $_ CHAR($size)";
  };

  my $field_ref = $opts->{FieldRef}  || {};
  my %field_ref = map {
    my $col = $_;
    my $tmp = $field_ref->{$col};
    my $v = ( $tmp =~ s/^~// ) ? "POSITION $tmp" : qq("$tmp");
    uc($col) => $v;
  } keys %$field_ref;

  # Field ref columns that don't reference themselves
  # will be considered similar to constant columns, but they must come
  # last, otherwise column alignment will be off
  my %field_ref_const;
  for ( keys %field_ref ) {
    next if $field_ref{$_} =~ /:$_\b/i;
    $field_ref_const{$_}++;
  }
  @columns = ( $opts->{ColumnList} && @{$opts->{ColumnList}} ) ? map uc($_), @{$opts->{ColumnList}} : (
    (grep !$field_ref_const{$_}, @columns),
    keys %field_ref_const,
  );
  my %is_filler;
  if ( $opts->{Filler} ) {
    $is_filler{uc($_)}++ for @{$opts->{Filler}};
  }

  my $file_str = join(",", @bcp_files);
  my $sqlldr_file_str = join("\n", map "INFILE '$_'", @bcp_files);
  my $disp_table = my $sqlldr_table = $table;

  if ($partition) {
    $sqlldr_table .= " PARTITION ($partition)";
    $disp_table   .= ":$partition";
  }

  # Default charset is roman8 on HP
  # Must set it here
  printf $ctl_fh
    $direct_load_pre.
    "LOAD DATA\n".
    #"CHARACTERSET WE8ROMAN8\n".
    $nls_str.
    "%s\n".
    $row_delim_str.
    "INTO TABLE %s %s\n".
    $direct_load_post.
    qq(FIELDS TERMINATED BY '$delimiter'$quote_str\n).
    "TRAILING NULLCOLS\n".
    "(\n%s\n)\n",
    $sqlldr_file_str,
    $sqlldr_table,
    $action,
    join(",\n", map {
      (
        exists($const{$_}) ? qq[  $_ CONSTANT '$const{$_}']
      : exists($is_filler{$_}) ? qq[  $_ FILLER]
      : exists($field_ref{$_}) ? qq[  $_ $field_ref{$_}]
      : $is_date{$_} ? "  $_ $is_date{$_} '$date_fmt{$_}'"
      : $char_sz{$_} ? $blank_control->()
      : "  $_"
      )
    } @columns);
  if ($prm_fh) {
    print $prm_fh "userid=$user/$self->{PASSWORD}\@$db\n";
    close $prm_fh;
  }

  $_->close() for $ctl_fh, $bad_fh, $log_fh;

  print "Loading $db..$disp_table from $file_str\n";

  my $ctl_file = $ctl_fh->filename();
  my $bad_file = $bad_fh->filename();
  my $log_file = $log_fh->filename();
  my $prm_file = $prm_fh ? $prm_fh->filename() : undef;
  if ($keep_temp) {
    print "SqlldrControlFile: ", abs_path($ctl_file), "\n";
    print "SqlldrBadRowFile : ", abs_path($bad_file), "\n";
    print "SqlldrLogFile    : ", abs_path($log_file), "\n";
  }
  local $ENV{NLS_DATE_FORMAT} = 'YYYY-MM-DD HH24:MI:SS';
  local $ENV{NLS_TIMESTAMP_FORMAT} = 'YYYY-MM-DD HH24:MI:SS.FF';
  local $ENV{NLS_TIMESTAMP_TZ_FORMAT} = 'YYYY-MM-DD HH24:MI:SS.FF';

  my @prm_opt;
  @prm_opt = "parfile=$prm_file" if $prm_file;
  my @cmd = (
    sqlldr =>
    "control=$ctl_file",
    "log=$log_file",
    "bad=$bad_file",
    @prm_opt,
    "silent=(header,discards,feedback,partitions)",
  );
  print "Executing: @cmd\n" if $opts->{Debug} || $opts->{NoExec};
  return "@cmd" if $opts->{NoExec};

  my $close_success;

  # We could do this either way with IPC::Run
  # But lets not require it unless necessary.
  if ($stdin) {
    require IPC::Run;

    $close_success = IPC::Run::run( \@cmd, '<', $stdin );
  } else {
    # Hide user/passwd from ps
    open(my $cmd_fh, "|-", @cmd) or confess "Could not exec sqlldr: $!";
    print $cmd_fh "$user/$self->{PASSWORD}\@$db\n";

    # We don't want to exit right away on failure
    # We want to see the log file and bad record if any
    $close_success = close $cmd_fh;
  }

  # We don't want to exit right away on failure
  # We want to see the log file and bad record if any
  my $exit_stat = $? >> 8;
  my $exit_sig  = $? & 127;
  my $exit_core = $? & 128;

  # We have a limit of one rejected row. If we have a bad row
  # we'll just include it in the error.
  # Oops thats no longer true now that we have a MaxErrors option
  # Just show the first bad row if we allow > 1 error
  my $bad_row;
  if ( -s $bad_file ) {
    if ( $max_errors > 0 ) {
      local ($_, $.);
      local $/ = $opts->{RowDelimiter} || "\n";
      open(my $fh, "<", $bad_file) or confess "Can't open sqlldr reject file $bad_file: $!";
      $bad_row = <$fh>;
      close $fh;
    } else {
      warn "sqlldr error loading $file_str into $disp_table on row:\n";
      $bad_row = `cat $bad_file`;
    }
  }
  open(my $fh, "<", $log_file) or confess "Can't open sqlldr log $log_file: $!";
  print "Opened $log_file\n";
  local ($_, $.);
  my ( $rows, $error_rows, $failed_rows, $null_rows, $error_msg, $discontinued, $dp_errors );

  # Only save first 1000 errors
  my $err_cnt = 0;
  while (<$fh>) {
    print;
    if ( /^\s*(\d+)/ ) {
      my $tmp_rows = $1;
      $rows        = $tmp_rows if /successfully loaded/;
      $error_rows  = $tmp_rows if /not loaded due to data errors/;
      $failed_rows = $tmp_rows if /not loaded because all WHEN clauses/;
      $null_rows   = $tmp_rows if /not loaded because all fields were null/;
      next;
    }
    if ( /^Record \d+: Rejected/ ) {
      $error_msg .= $_ if $err_cnt < 1000;
      next;
    }
    if ( /^(?:SQL\*Loader|ORA)-\d+:/ ) {
      $error_msg .= $_ if ++$err_cnt <= 1000;
      $discontinued++ if /discontinued|aborted/;
      next;
    }

    # Catch direct path errors
    if ( /was not re-(?:enabled|validated)/ ) {
      # These errors do not cause non-zero exit status
      $dp_errors++;
      $error_msg .= $_ if $err_cnt < 1000;
      next;
    }
    if ( /^index \S+ was made unusable/ ) {
      $dp_errors++;
      $error_msg .= $_ if ++$err_cnt <= 1000;
      next;
    }

  }
  close $fh;

  if (!$close_success or $dp_errors) {
    $error_msg ||= '';
    if ( $exit_stat != 0 or $dp_errors ) {
      if ( $exit_stat == 2 or $dp_errors ) {
        # Exit status 2 is just a warning
        # But we should consider it an error if we exceeded the max errors allowed
        # Or if load was discontinued for any reason
        # Or for any direct path errors
        my $first = ($max_errors > 0) ? 'first ' : '';
        confess "sqlldr exited with status $exit_stat [$error_msg]" if $dp_errors;
        confess "sqlldr exited with status $exit_stat [$error_msg] - ${first}rejected record:[$bad_row]" if $error_rows > $max_errors;
        confess "sqlldr exited with status $exit_stat [$error_msg]" if $discontinued;
      } else {
        confess "sqlldr exited with status $exit_stat [$error_msg]";
      }
    }
    confess "sqlldr received signal $exit_sig [$error_msg]" if $exit_sig > 0;
    confess "sqlldr coredumped [$error_msg]"                if $exit_core;
  }
  return $rows;
}
}

# Dummy method for compatibility with Sybase
sub mk_view { }

sub date_masks_from_file {
  my $self = shift;
  my ($files, $columns, $is_date, $opts) = @_;

  return unless $is_date and %$is_date;

  $opts ||= {};

  my $sample_rows = $opts->{DateSampleRows} || 1000;
  my $d = $opts->{Delimiter} || $self->{DELIMITER};
  my $rd = $opts->{RowDelimiter};
  my $year_mask = $opts->{Year2Mask} || 'YY';

  local ($., $_, $ARGV, *ARGV);
  local $/ = $rd if $rd;
  local @ARGV = @$files;

  my $row_cnt;
  my (%remaining, %got);
  $remaining{$_}++ for keys %$is_date;

  my %fmt;
  my $dc_fmt = $opts->{DateColumnFmt} || {};
  for my $col ( keys %$dc_fmt ) {
    my $c = uc($col);
    $fmt{$c} = $dc_fmt->{$col};
    delete $remaining{$c}
  }

  my %row;
  while (<>) {
    next if $opts->{Header} and $. <= $opts->{Header};
    chomp;
    @row{@$columns} = $opts->{QuoteFields} ? split_quoted( $_, $d ) : split /\Q$d/;
    for (keys %remaining) {
      if ( $row{$_} ) {
        delete $remaining{$_};
        $got{$_} = $row{$_};
        last if !%remaining;
      }
    }

    # If we haven't found values by now, give up
    last if ++$row_cnt >= $sample_rows;
  }

  $fmt{$_} = $self->date_mask($got{$_}, $year_mask) for keys %got;

  return %fmt;
}

# If we allow quoted fields, need to split correctly and
# handle embedded quotes and delimiters
sub split_quoted {
  my ($line,$d) = @_;
  my @result;
  while ( $line =~ s/\A("?)((?:""|.)*?)\1(\Q$d\E|\z)//s ) {
    my ( $q, $s,$got_d ) = ( $1, $2, $3 );
    $s =~ s/""/"/g if $q;
    push @result, $s;
    last if length($got_d) == 0;
  }
  return @result;
}

{

my @mon    =  qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $mon_str = join("|", @mon);
my $mon_re = qr/(?i)$mon_str/;
my @months =  qw( January February March April May June July August September October November December );
my $month_str = join("|", @months);
my $month_re = qr/(?i)$month_str/;
my @days = qw( Mon Tue Wed Thu Fri Sat Sun );
my $day_str = join("|", @days);
my $day_re  = qr/(?i)$day_str/;

sub date_mask {
  my ($self, $str, $year2mask) = @_;
  return unless $str;
  local $_ = $str;

  my $fmt = '';
  $year2mask ||= 'YY';

  # YYYY-MM-DD or YYYYMMDD
  if ( s/^\d{4}(\D?)\d\d(\D?)\d\d// ) {
    $fmt .= "YYYY${1}MM${2}DD";
    $fmt .= time_mask();
    #die "Can not determine date mask for $str ($fmt)" if length($_);
    return if length($_);
    return $fmt;
  }

  # Allow day abbreviation (Mon Tue etc.)
  $fmt .= "DY " if s/^$day_re\s+//;

  # Jan 23 2010
  if ( s/^$mon_re\s+\d+// ) {
    my $end_year;
    $fmt .= "MON DD";
    if ( s/^\s\d{4}// ) {
      $fmt .= " YYYY";
    } elsif ( s/\s+\d{4}$// ) {
      $end_year++;
    } else {
      #die "Can not determine date mask for $str ($fmt)";
      return;
    }
    $fmt .= time_mask();

    #die "Can not determine date mask for $str ($fmt)" if length($_);
    return if length($_);
    $fmt .= " YYYY" if $end_year;
    return $fmt;
  }

  # January 23, 2010
  if ( s/^$month_re\s+\d+// ) {
    my $end_year;
    $fmt .= "MONTH DD";
    if ( s/^(\W?)\s\d{4}// ) {
      my $comma = $1;
      $fmt .= "$comma YYYY";
    } elsif ( s/\s+\d{4}$// ) {
      $end_year++;
    } else {
      #die "Can not determine date mask for $str ($fmt)";
      return;
    }
    $fmt .= time_mask();

    #die "Can not determine date mask for $str ($fmt)" if length($_);
    return if length($_);
    $fmt .= " YYYY" if $end_year;
    return $fmt;
  }

  # 02-Jan-2010
  if ( s/^\d\d?(\D?)$mon_re(\D?)\d{4}// ) {
    $fmt .= "DD${1}MON${2}YYYY";
    $fmt .= time_mask();
    #die "Can not determine date mask for $str ($fmt)" if length($_);
    return if length($_);
    return $fmt;
  }

  # 02-Jan-10
  if ( s/^\d\d?(\D?)$mon_re(\D?)\d\d?// ) {
    $fmt .= "DD${1}MON${2}$year2mask";
    $fmt .= time_mask();
    #die "Can not determine date mask for $str ($fmt)" if length($_);
    return if length($_);
    return $fmt;
  }

  # MM/DD/YYYY
  if ( s|^\d\d?(\D)\d\d?(\D)\d{4}|| ) {
    $fmt .= "MM${1}DD${2}YYYY";
    $fmt .= time_mask();
    #die "Can not determine date mask for $str ($fmt)" if length($_);
    return if length($_);
    return $fmt;
  }

  #die "Failure to determine date mask for $str";
  return;
}
}

# Operates on and modifies current $_
sub time_mask {
  my $fmt = '';
  if ( s/^(\D?)[\s\d]\d// ) {
    my $sep = $1;
    $sep = qq("$sep") if $sep =~ /\S/;
    $fmt .= "${sep}HH";
    $fmt .= /[AP]M\b/i ? "12" : "24";
    if ( s/^(\D)\d\d// ) {
      $fmt .= "${1}MI";
      if ( s/^(\D)\d\d// ) {
        $fmt .= "${1}SS";
        if ( s/^(\D)(\d+)// ) {
          $fmt .= $1 . "FF" . length($2);
        }
      }
    }
    if ( s/^(\s?)[AP]M// ) {
      $fmt .= "${1}AM";
    }
    if ( s/^(\s*)\w{2,3}T//i ) {
      $fmt .= "${1}TZD";
    }
    if ( s/^\s[+-]\d\d(\D)\d\d// ) {
      $fmt .= " TZH${1}TZM";
    }
  }
  return $fmt;
}

{
my %type_map = ( TABLE => 'T', VIEW => 'V', PROCEDURE => 'P' );

sub obj_type {
  my ( $self, $name ) = @_;
  $name = uc($name);
  my $type;
  if ( $name =~ /^([^.]+)\.(.+)/ ) {
    my ($schema, $table) = ($1, $2);
    $type = $self->{DBH}->selectrow_array(
      "select object_type from all_objects where owner = ? and object_name = ?",
      undef,
      $schema,
      $table,
    );
  } else {
    $type = $self->{DBH}->selectrow_array(
      "select object_type from user_objects where object_name = ?",
      undef,
      $name
    );
  }
  return unless $type;
  return $type_map{$type} || confess "Don't know about type $type for object $name";
}
}

sub curr_schema {
  my $self = shift;
  return $self->get("sys_context('USERENV', 'SESSION_SCHEMA')");
}

{
my $sql_t = <<SQL;
SELECT
  b.index_name,
  b.column_name
FROM all_indexes a, all_ind_columns b
WHERE a.owner = b.index_owner
  AND a.index_name = b.index_name
  AND a.table_owner = %s
  AND a.table_name = %s
SQL


sub index_info {
  my ( $self, $table, $all_indexes ) = @_;

  my $dbh = $self->{DBH};
  my ( $schema, $tbl ) = split /\./, uc($table);
  if ( !$tbl ) {
    $tbl = $schema;
    $schema = $self->curr_schema();
  }
  my $sql = sprintf $sql_t, $dbh->quote($schema), $dbh->quote($tbl);
  $sql .= "and a.uniqueness = 'UNIQUE'\n" unless $all_indexes;
  $sql .= "ORDER BY b.column_position\n";
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my @col_names = @{$sth->{NAME_lc}};
  my %row; $sth->bind_columns(\@row{@col_names});
  my %ind;
  while ($sth->fetch()) {
    push @{$ind{$row{index_name}}}, lc($row{column_name});
  }
  return unless %ind;
  return \%ind;
}
}

sub primary_key {
  my ($self, $table) = @_;
  $table = uc($table);
  my ($schema, $tbl) = split /\./, $table;
  if ( !$tbl ) {
    $tbl = $schema;
    $schema = $self->curr_schema();
  }
  my @pk = map lc, $self->{DBH}->primary_key(undef, $schema, $tbl);
  return unless @pk;
  return \@pk;
}

{

my $sql = <<SQL;
MERGE %s INTO %s d
USING %s s
ON (%s)
WHEN MATCHED THEN UPDATE SET %s
WHEN NOT MATCHED THEN INSERT (%s)
  VALUES (%s)
SQL

sub merge {
  my $self = shift;
  my %args = @_;

  my $dbh       = $self->{DBH};
  my $table     = $args{Table};
  my $stg_table = $args{StgTable};

  my $stg_info = $self->column_info($stg_table);
  my $stg_map  = $stg_info->{MAP};
  my %stg_has; $stg_has{$_}++ for @{$stg_info->{LIST}};

  my $key_col_ref = ($args{KeyCols} && @{$args{KeyCols}}) ? $args{KeyCols} : $self->key_columns($table);
  my $upd_col_ref = ($args{UpdCols} && @{$args{UpdCols}}) ? $args{UpdCols} : $self->upd_columns($table);

  # Normalize all columns and maps to lowercase
  my @key_cols = map lc, @$key_col_ref;
  my @upd_cols = map lc, @$upd_col_ref;
  my @fields = (@key_cols, @upd_cols);
  my %col_map = $args{ColMap}
    ? map lc, %{$args{ColMap}}
    : ();

  my $upd_col_str = join(",", map {
    $col_map{$_} ? $stg_has{$col_map{$_}} ? "d.$_=s.$col_map{$_}" : "d.$_=$col_map{$_}"
  : $stg_has{$_} ? "d.$_=s.$_" : ()
  } @upd_cols),

  # Determine if last_chg_user, last_chg_date need to be updated
  # If staging table does not have the columns, and the target table does
  # Then default the values
  my %chg_col = $self->last_chg_list($table, \@fields);
  delete $chg_col{$_} for grep $stg_has{$_}, qw(last_chg_user last_chg_date);
  for my $col ( sort { $b cmp $a } keys %chg_col ) {
    $upd_col_str .= ",$col=".( ($col eq 'last_chg_user')
      ? "'".uc(substr($dbh->{Username}, 0, $chg_col{$col}))."'"
      : 'SYSTIMESTAMP'
    );
  }

  my $parallel = $args{Parallel} ? '/* parallel(8) append */' : '';

  my $merge_sql = sprintf($sql,
    $parallel,
    $table,
    $args{MergeFilter} ? "$args{StgTable} WHERE $args{MergeFilter}": $args{StgTable},
    join(" AND ", map "d.$_=s.".($col_map{$_}||$_), @key_cols),
    $upd_col_str,
    join(",", @fields),
    join(",", map {
      $col_map{$_} ? $stg_has{$col_map{$_}} ? "s.$col_map{$_}" : $col_map{$_}
    : $stg_has{$_} ? "s.$_" : "NULL"
    } @fields),
  );

  # No update if no update columns
  $merge_sql =~ s/^WHEN MATCHED.*\n//m unless @upd_cols;
  print("Executing: $merge_sql\n");
  return 1 if $args{NoExec};

  $dbh->do("ALTER SESSION ENABLE PARALLEL DML") if $args{Parallel};

  my $rows = $dbh->do($merge_sql) + 0;
  print("$rows rows updated/inserted\n\n");
  return $rows;

}
}

# #!!!UNFINISHED!!!
# Static block for mk_ext_table
{

my $sql = <<SQL;
CREATE TABLE %s (
%s
)
ORGANIZATION EXTERNAL (
 TYPE oracle_loader
 DEFAULT DIRECTORY %s
 ACCESS PARAMETERS
 (
   RECORDS DELIMITED BY NEWLINE
   LOGFILE 'TEST.log'
   FIELDS TERMINATED BY '%s'
 )
 LOCATION ('%s')
)
SQL

sub mk_ext_table {
  my $self = shift;

  my %args = @_;

  my $table = $args{Table} or confess "Need table prototype for external table";

  my $ext_table = $args{Name} || "ext_${table}$$";
  my $dir  = $args{Dir}  or confess "Need directory for external table $table";
  my $file = $args{File} or confess "Need file for external table $table";

  my $cols = $self->column_info($table);
  my $cmap = $cols->{MAP};

  my @col_list;
  for my $col (@{$cols->{LIST}}) {
    my $col_str = $col;

    my $cdata = $cmap->{$col};
    my $type = $cdata->{TYPE_NAME};
    my $dec  = $cdata->{DECIMAL_DIGITS};

    $col_str .= " $type";
    my $size = $cdata->{COLUMN_SIZE};

    for ($type) {
      $col_str .=
        /CHAR/   ? "($size)"
      : /NUMBER/ ? (defined $dec) ? "($size,$dec)" : ''
      : '';
    }

    #$col_str .= " DEFAULT $cdata->{COLUMN_DEF}" if defined $cdata->{COLUMN_DEF};
    #$col_str =~ s/\s+$//;
    #$col_str .= " NOT NULL" unless $cdata->{NULLABLE};

    push @col_list, $col_str;
  }

  my $create_sql = sprintf($sql,
    $ext_table,
    join(",\n", @col_list ),
    $dir,
    #$args{RowDelimiter} || "\\n",
    $args{Delimiter} || "|",
    $file,
  );

  $self->{DBH}->do($create_sql);

  return $ext_table;
}
}

package DBIx::BulkUtil::Release;

sub new {
  my ($class, $f) = @_;
  bless $f, $class;
}

sub DESTROY { $_[0]->() }

1;

__END__

=head1 NAME

DBIx::BulkUtil - Sybase/SybaseIQ/Oracle bulk load and other utilities

=head1 SYNOPSIS

    use DBIx::BulkUtil;

    # Return just the regular DBI handle
    my $dbh = DBIx::BulkUtil->connect(%options, \%dbi_options);

    # Or return a DBI handle and a 'Utility' object.

    # syb_connect,ora_connect, and iq_connect methods are also provided
    # to directly specify database type
    my ($dbh, $db_util) = DBIx::BulkUtil->connect(%options, \%dbi_options);

    # Wrappers for Sybase bcp, Oracle sqlldr, IQ 'load table'
    $db_util->bcp_in($table,  [$file], [\%options]);
    $db_util->bcp_out($table, [$file], [\%options]);

    $column_info = $db_util->column_info($table);

    $insert_sth = $db_util->prepare(%options);

    $cnt = $db_util->merge(%options);

    $blk_sth = $db_util->blk_prepare($table, %options);
    $blk_sth->execute(@args);
    $blk_sth->finish();

    $index_info  = $db_util->index_info($table, [$all_indexes]);
    $primary_key = $db_util->primary_key($table);

    $stored_proc_sql = $db_util->sp_sql($stored_proc, @args);
    $stored_proc_sth = $db_util->sp_sth($stored_proc, @args);

    my $passwd = DBIx::BulkUtil->passwd();

    $object_type = $db_util->obj_type($object_name);

    $current_date_function = $db_util->now();
    $date_function_str     = $db_util->add($date, $amount, $units);
    $one_row_no_table_sql  = $db_util->row_select($select_clause);
    @no_table_results      = $db_util->get($select_clause)
    $ten_minutes_from_now  = $db_util->get( $db_util->add( $db_util->now(), 10, 'minute' ) );

=head1 DESCRIPTION

Provide easy to use bulk load and other utility methods.

=head1 CLASS METHODS

=over 4

=item connect()

Returns a DBI database handle. In list context, returns a database handle
and a database utility object. The default connection attribute values for the
database handle are:

    ChopBlanks => 1,
    AutoCommit => 1,
    PrintError => 0,
    RaiseError => 1,

If the last argument to connect() is a hash reference, then you can either
override these attributes or set other attributes on connect.
(Note: The connect is made using RaiseError => 1, but after the connection
is successful, HandleError is set to a subroutine that calls Carp::confess
which gives a stack trace when DBI throws an exception).

The first argument to connect is a hash with the following keys:

=over 4

=item Server

The database server to connect to. If no server or database is provided, then
it is defaulted to the value of environment variable DSQUERY.

=item Database

The database to connect to. If a database but no server is provided, then
it is assumed to be an Oracle database. If no server or database is provided,
then the default is the pm database.

=item Type

The database type (Oracle, Sybase, or SybaseIQ). The default depends on what
combination of Server and Database is provided.

=item User

The user to connect to the database as. Defaults to calling the user() method.

=item DataDir

Meant to be a data directory to keep config info in, to be used
in the env2db method in any way you see fit.

=item Password

The password to use to login to the database.
Default is to call the passwd method.

=item RetryCount

Will retry connection to the database this many times.

=item RetryMinutes

Will wait this many minutes before trying to connect to the database again.

=item BulkLogin

For Sybase, enables the use of the blk_prepare method on the utility
handle for bulk inserts (i.e. the syb_bcp_attribs attribute on insert
statements).

=item NoBlankNull

For SybaseIQ, when loading a file via bcp_in, will not convert blank
columns to null values.

=item Dsl

A string or arrayref of connect options to use as the dsl connect string
instead of using the Server or Database after 'dbi:$db_type:'

=item DslOptions

A string or arrayref of connect options to add to the dsl connect string.
E.g.:

  DBIx::BulkUtil->connect(
    Server => $server,
    DslOptions => [ 'interfaces=/my/interfaces_file', 'port=1234' ],
  );

Will result in the connect string:

  'dbi:Sybase:server=<server_name>;interfaces=/my/interfaces_file;port=1234'

=item NoServer

For Sybase, will not add the 'server=...' argument to the DSL connect string.
For Oracle will not add the database name to the DSL string. The DslOptions
option is necessary if this option is used.

=back

=item connect_cached()

Same as connect method, but calls the DBI connect_cached method to make
the actual database connection, and will return the same database handle
previously returned for the same database, user, and DBI options.

=item syb_connect()

Same as connect method, but calls the DBIx::BulkUtil connect method with the Type option set to 'Sybase'

=item ora_connect()

Same as connect method, but calls the DBIx::BulkUtil connect method with the Type option set to 'Oracle'

=item ora_connect_cached()

Same as connect method, but calls the DBIx::BulkUtil connect_cached method with the Type option set to 'Oracle'

=item iq_connect()

Same as connect method, but calls the DBIx::BulkUtil connect method with the Type option set to 'SybaseIQ'

=item iq_connect_cached()

Same as connect method, but calls the DBIx::BulkUtil connect_cached method with the Type option set to 'SybaseIQ'

=item passwd()

Dummy function to override for determining password.

=back

=head1 UTILITY OBJECT METHODS

Methods that may be called on the utility object that is optionally returned
from the connect or connect_cached DBIX::BulkUtil class methods. These methods
provide convenience and/or make some operations between Oracle and Sybase
databases more transparent.

=over 4

=item now

Returns sql that will return the current date/time of the database (e.g.
to be used as a column in a select statement).

=item add

Returns sql that will add some unit of time to a datetime expression.
E.g. $util->add($util->now(), 10, 'hour') adds 10 hours to the current time.

=item row_select

Given just a select clause (the part after the "SELECT" keyword),
returns sql to select a row from no table (e.g. for fetching the
current time from the database).

=item get

Fetches the row from a select clause with no table. E.g.
$ect_util->get($ect_util->now()) returns the current database date/time.

=item obj_type

Returns T/V/P depending on whether the given object is a Table, View, or
Procedure.

=item sp_sql

Returns sql to execute a given stored procedure with arguments. If
one of the arguments is ":cursor", then for Sybase it is filtered out,
for Oracle we assume it is a parameter name and not a literal
string to be bound.

Sybase stored procedures can return multiple result sets, and also
a list of output parameters. Oracle does not return result sets, but
you can pass in a cursor as an output parameter. When you pass in a
parameter ":cursor", we assume its an output parameter that will
hold a statement handle, so you can return a single result set in a
nearly "backwards compatible" way. But we don't handle "multiple" result
sets (yet), we don't deal with other output parameters, and so this
this method is not meant to be completely transparent for
all stored procedures.

=item sp_sth

Prepares and executes a stored procedure with arguments, and returns
a statement handle for fetching. If one of the arguments is ":cursor",
then we assume for Oracle it is a cursor type output parameter, and the
statement handle for the cursor is returned. For Sybase, we ignore any
":cursor" argument.

=item bcp_in

For Sybase, uses BCP, for Oracle, SQL Loader, to load a pipe-delimited file
into a database table. If the last argument is a hash reference, then
additional options may be specified. Current options are:

=over 8

=item Delimiter

Specifies the delimiter in the bcp file (default: "|").

=item RowDelimiter

Specifies the record terminator in the bcp file (default: "\n").

=item Header

For bcp_in, the number of rows to ignore at the start of the file.
For bcp_out, if true, the first row will be the column names of the table.

=item DirectPath

For Oracle only, if true, does Direct path instead of conventional load.
If value is 'P', also does parallel load. For parallel loads, indexes
are not rebuilt after the load.

=item Constants

(Oracle and SybaseIQ only). A hashref of column names and constant values to
set the columns to which are not in the file.

=item FieldRef

(Oracle only). A hashref of column names and sqlldr expressions to specify the
value of the column. If the expression includes the column itself (e.g. ':column_name'),
then the field will appear in the same position in the control file corresponding
to its position in the table. If it does not (e.g. "to_date('2014-02-01','YYYY-MM-DD')"),
then the column appears at the end of the control file field list (i.e. it assumes the
column is not in the file).

Also, if the expression begins with "~", then assume the expression is position
information for a fixed width file.

=item Filler

Generally used with the ColumnList option, a list of column names
in the file which are filler and not loaded into the database.

=item Default

(SybaseIQ only). A reference to an array of column names not in the
file, which will be set to their default values.

=item Stdin

(Oracle only). A file handle, subroutine, or reference to a scalar to supply data to sqlldr through stdin.
If it is a subroutine, return values will be used as input until it returns undef.
If this option is used, and none of the files supplied to bcp_in is named '-', then '-' is automatically added to the list.
If one of the files is named '-', and this option is not used, then this option is
assumed to be the *STDIN filehandle.

=item TrailingDelimiter

(SybaseIQ only). Boolean flag which indicates that the last column
of each record has a trailing column delimiter.

=item DateFormat

(Oracle only). Sets the default date format mask for sqlldr. By default, the
process will try to determine the date format for each date column from the
input file. If the format can not be determined, then this format will be used.

=item SybaseDateFmt

(Oracle only). Sets the default DateFormat to 'MON DD YYYY HH12:MI:SS:FF3AM'.

=item QuoteFields

(Oracle only). Allows fields in bcp file to be quoted, thereby allowing
delimiters within the field.

=item NLSLang

(Oracle only). Sets the characterset option set for sqlldr.

=item Semantics

(Oracle only). Sets the 'LENGTH SEMANTICS' in the control file.
Allowable values are CHAR or BYTE.

=item Action

Sets sqlldr mode to APPEND, REPLACE, or TRUNCATE (valid values are
A, R, or T, default is A). Simulates same thing for Sybase through
truncate or delete sql statements for T and R.
Replace does not replace individual rows, it deletes all rows first.

=item SybaseTypes

(Oracle only). An array of the Sybase data types being loaded. When the type
is 'char' (not 'varchar'), then PRESERVE BLANKS is added in the control file for
char(1) columns, and trim logic for char > 1 columns.

=item Debug

(Oracle only). Displays the sqlldr command line executed, and does not remove
the sqlldr control, log, and bad record files.

=item NoExec

(Oracle only). Displays and returns but does not execute the sqlldr command line
that would be executed.

=item CommitSize

The number of rows loaded before committing each batch (default: 1000).

=item MaxErrors

The maximum number of errors allowed before aborting the load (default: 0).

=item LoadWhen

(Oracle only). Adds this text to a WHEN clause in the sqlldr control file
which determines which rows in the data file are loaded.

=item ColumnList

List of ordered column names in bcp file.

=item PacketSize

(Sybase only). Sets network packet size for bcp.

=item PassThru

(Sybase only). Allows an arbitrary list of arguments to be passed to the bcp command line.

=back

If the file is not provided, it is assumed to be the table name with
a ".bcp" extension.

Sybase bcp is broken. If you have delimiter characters in your data, there
is no way to escape them. If your fields are quoted as in csv files,
Sybase bcp will complain.  For bcp_in, unquote fields and
convert your file to a format with a new delimiter that does not appear
in your data. For bcp_out, choose a delimiter that does not appear in your data.

=item bcp_out

For Sybase uses BCP, for Oracle, just select and print (Oracle has no
"bcp out" type functionality) to export a database table to a file.
See bcp_in for options.

If the file is not provided, it is assumed to be the table name with
a ".bcp" extension.

For Sybase, if there are any money columns, or if the Filter option is
used, then a view is temporarily created to bcp from. Money columns
are converted to decimal so that they are not truncated.

Sybase bcp_out is broken. It does not escape delimiter characters. If
you have delimiter characters in your data, you can call the select2file
method, although bcp_in will not load the resulting file. See bcp_in.

If the last argument is a hash reference, then
additional options may be specified. Current options are:

=over

=item Delimiter

Same as bcp_in.

=item RowDelimiter

Same as bcp_in.

=item Header

Same as bcp_in.

=item NoFix

When using Sybase native bcp out, the default is to transform the dates into
ANSI standard format (which historically used to be the only reason to use this
library). This option, if true, disables that transformation,
and can save time on large transfers.

=item Filter

Appends additional SQL clauses to the SELECT * statement, e.g.
"WHERE asof_date > '2011-01-01'".

=item Columns

Comma separated list of columns to select from table.

=back

=item blk_prepare

Prepares an insert statement for bulk insert into a table.
For Sybase, the BulkLogin option must have been supplied with a true value
on connect, or else this method will fail.
Returns a statement handle that will insert arguments into the table.
E.g.:

  my $sth = $db_util->blk_prepare('some_table');
  while (<FH>) {
    chomp;
    my @data = split /,/;
    $sth->execute(@data);
  }
  $sth->finish();

Inserts are batched, and so the finish() method must be called to commit 
the final batch. The execute() method must be called with a list of
arguments corresponding to the list of columns from the table (excluding
any columns in the Constant option below).
The first argument is the table name. The following optional arguments
are key/value pairs with the following keys:

=over

=item Constants

A hash reference of column name and constant value pairs that will be inserted
on every execute call. Values for these columns should not be included in the
list of arguments in the call to execute().

=item CommitSize

The number of inserts per batch (default: 1000).

=item BlkOpts

A hash reference of options to pass to the Sybase syb_bcp_attribs options.
Needed if inserting to identity columns. See L<DBD::Sybase> for these options.

=back

=item bcp_sql

(Sybase only). Given a table name and a sql statement, uses sqsh to execute a
sql statement and bcp the results into a table.

=item select2file

Calls the non-Sybase version of bcp_out which just selects from a table
and saves to a delimited file.  Accepts an optional hashref as the last
argument with the same options as bcp_out. Also accepts the option
Filter which appends additional SQL clauses to the SELECT * statement.
Include any additional keywords (e.g. "WHERE", "GROUP BY", etc.) in
the Filter option.

Returns the number of rows selected.

=item bcp_file

Modifies a bcp_file that contains a header row. Arguments are
($input_file, output_file, {%options}), with available options
KeepCols and DropCols. KeepCols is a list of column
names to keep from the input file (and the order in which they will appear in the
output file), DropCols is a list of columns to drop from the
input file. KeepCols overrides DropCols. Also accepts the following same
options as bcp_out: Delimiter.

=item merge

Merges data from a staging table into a target table. For Oracle, issues a
MERGE statement, for Sybase, it deletes from the target table corresponding
rows from the staging table, then inserts records from the staging to
the target table. Columns last_chg_user and last_chg_date are appropriately
updated in the target table. Accepts a hash with the following keys as its
argument:

=over

=item Table

The target table.

=item StgTable

The staging table.

=item KeyCols

A list of the key columns in the target table. Defaults to the
columns in the first unique index found on the table.

=item UpdCols

A list of the columns to update in the target table. Defaults to
all columns in the target table not in the list of key columns.
Ignored in Sybase since rows are deleted and inserted, not updated.

=item ColMap

A hashref of target to staging table column name mappings.

=item NoExec

Display but do not execute SQL.

=back

=item column_info

Given a table name, returns a hash reference with keys LIST and MAP. LIST
will contain a list of all columns in the table lowercased. MAP contains
a hash reference with the lowercase column names as keys, and the value
is a hash reference with keys NAME and PRECISION. NAME is the column name
in the actual (upper/lower/mixed) case in the database, and PRECISION is the
size of the column.

=item index_info

Given a table name, returns a hash reference of the names of any indexes
on the table and an array reference of the column names in the index.
If the optional second argument is true, returns all indexes, otherwise
returns only unique indexes.

=item key_columns

Given a table name, returns a reference to an array of column names that
are in the primary_key, or if no primary_key exists, returns the columns
in the first unique index found on the table.

=item upd_columns

Given a table name, returns a reference to an array of all of the column names
in a table that are not the key columns of a table.

=item primary_key

Returns an array reference of the column names in the primary key of a table.

=item strptime_fmt

Given a date string, returns a template suitable for passing to strptime.
Returns an undefined value if the format can not be determined.

=item ora_date_fmt

Given a date string, returns an Oracle date format string.
Returns an undefined value if the format can not be determined.

=item prepare

Prepares a SQL statement, optionally binds a reference to a
hash or array to its input parameters, and
returns a statement handle.

Example:

  my $sth = $dbu->prepare(
    Table => 'eqa_own.some_table',
    Columns => [qw(column1 column2)]
    BindHash => \my %href,
  );
  $href{column1} = 'Col1Value';

  $href{column2} = 'Col2Value1';
  $sth->execute();

  $href{column2} = 'Col2Value2';
  $sth->execute();

Accepts as arguments a hash with the following keys:

=over 8

=item Table

Table name. If provided, will construct an insert statement for this table.
(Required if Sql not provided).

=item Sql

Sql statement. Prepares this SQL statement.
(Required if Table not provided).

=item Columns

List of column names. If Table is provided, must be names of columns
in the table. (default: all columns in Table if Table is provided).

=item BindHash

(Oracle only). Reference to hash. Placeholders in SQL statement will be bound to
this hash reference. (May not be used with BindArray).

=item BindArray

(Oracle only). Reference to array. Placeholders in SQL statement will be bound to
this array reference. (May not be used with BindHash).

=item ByName

If true, use ":column_name" type placeholders in SQL statement and in binding to hash or array.
If false (but defined), use "?" as placeholders. "?" placeholders may not be used with
BindHash or BindArray. (default: Oracle true, Sybase false).

=back

=back

=cut
