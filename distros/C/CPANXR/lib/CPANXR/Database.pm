# $Id: Database.pm,v 1.37 2003/10/07 19:53:17 clajac Exp $

package CPANXR::Database;
use CPANXR::Config;
use Carp qw(carp croak);
use DBI;
use strict;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = ();
our @EXPORT_OK = qw($Dbh);
our %EXPORT_TAGS = (
		    all => [@EXPORT_OK]
		    );

our $Dbh = undef;

sub connect {
  return if(defined $Dbh);

  my $db_name     = CPANXR::Config->get("DbName");
  my $db_host     = CPANXR::Config->get("DbHost");
  my $db_user     = CPANXR::Config->get("DbUser");
  my $db_password = CPANXR::Config->get("DbPassword");

  my $dsn = "DBI:mysql:database=${db_name};host=${db_host}";

  $Dbh = DBI->connect($dsn, $db_user, $db_password);
}

sub connection {
  my $self = shift;
  $self->connect();
  return $Dbh;
}

{
  my %IndexTables = ( 
		     file => 'SELECT id FROM files WHERE path = ?',
		     distribution => 'SELECT id FROM distributions WHERE path = ?', 
		     like_distribution => 'SELECT id, path FROM distributions WHERE path like ?'
		    );
  
  sub indexed {
    my ($self, $table, $path) = @_;
    
    $self->connect();

    croak("No entry for '$table'") unless(exists $IndexTables{$table});

    my $result = $Dbh->selectall_arrayref($IndexTables{$table}, {}, $path);
    return "" if(@$result == 0);
    croak("Database is inconsistent, multiple file or distribution entries") if(@$result > 1);
    return $result->[0];
  }
}

{
  my %InsertPathTable = ( file => 'INSERT INTO files (path, dist_id, symbol_id, type) VALUES(?,?,?,?)',
			  distribution => 'INSERT INTO distributions (path) VALUES(?)', );

  sub insert_path {
    my ($self, $table, @param) = @_;
    
    $self->connect();

    croak("No entry for '$table'") unless(exists $InsertPathTable{$table});
    $Dbh->do($InsertPathTable{$table}, {}, @param);
    return $Dbh->{mysql_insertid};
  }
}

sub set_loc {
  my ($self, $file_id, $loc) = @_;

  $self->connect();
  $Dbh->do("UPDATE files SET loc = ? WHERE id = ?", {}, $loc, $file_id);

  1;
}

{
  my %Symbol_cache;
  sub insert_symbol {
    my ($self, $symbol) = @_;
    
    croak("Symbol is undefined") if(!defined $symbol || $symbol =~ /^\s+$/s);

    # Check if symbol is in cache
    return $Symbol_cache{$symbol} if(exists $Symbol_cache{$symbol});

    $self->connect();
  
    my ($package, $file, $line) = caller;

    my $entry = $Dbh->selectall_arrayref("SELECT id FROM symbols WHERE symbol = ?", {}, $symbol);
    if (@$entry) {   
      croak("Database inconsistency for symbol '$symbol'") if(@$entry > 1);
      $Symbol_cache{$symbol} = $entry->[0]->[0];
      return $entry->[0]->[0];
    }
  
    $Dbh->do("INSERT INTO symbols (symbol) VALUES(?)", {}, $symbol);
    return $Dbh->{mysql_insertid};
  }
}

sub insert_package {
  my ($self, $symbol_id, $file_id, $line_no, $symbol_offset) = @_;

  $self->connect();
  $Dbh->do("INSERT INTO packages (symbol_id, file_id, line_no, symbol_offset) VALUES(?,?,?,?)", {}, $symbol_id, $file_id, $line_no, $symbol_offset);
}

sub insert_declaration {
  my ($self, $symbol_id, $file_id, $line_no, $package_id) = @_;

  $self->connect();
  $Dbh->do("INSERT INTO declarations (symbol_id, file_id, line_no, package_id) VALUES(?,?,?,?)", {}, $symbol_id, $file_id, $line_no, $package_id);
}

sub insert_connection {
  my ($self, $symbol_id, $file_id, $line_no, $symbol_offset, $package_id, $caller_id, $caller_sub_id, $type) = @_;

  $self->connect();

  $Dbh->do("INSERT INTO connections (symbol_id, file_id, line_no, symbol_offset, package_id, caller_id, caller_sub_id, type) VALUES(?,?,?,?,?,?,?,?)", {}, $symbol_id, $file_id, $line_no, $symbol_offset, $package_id, $caller_id, $caller_sub_id, $type);
}

sub select_distributions {
  my ($self, %args) = @_;

  $self->connect();

  # Create search SQL string
  my $sql = "SELECT id, path, ts FROM distributions";
  my $param_sql = "";

  # Create from search qritera
  my @params;

  if (exists $args{id} && $args{id}) {
    $param_sql .= "id = ?";
    push(@params, $args{id});
  }
  
  if (exists $args{by_name} && $args{by_name}) {
    $param_sql .= "path like ?";
    push @params, $args{by_name};
  }

  if ($param_sql) {
    $sql .= " WHERE $param_sql";
  }

  # Always order by path
  $sql .= " ORDER BY path ASC";

  my $dists = $Dbh->selectall_arrayref($sql, {}, @params);

  return $dists;
}

sub select_files {
  my ($self, %args) = @_;

  $self->connect();
  
  my $sql = "SELECT id, dist_id, path, ts, loc FROM files";
  my $param_sql = "";
  my @params;

  if (exists $args{dist_id} && $args{dist_id}) {
    $param_sql .= "dist_id = ?";
    push @params, $args{dist_id};
  } elsif (exists $args{file_id} && $args{file_id}) {
    $param_sql .= "id = ?";
    push @params, $args{file_id};
  } elsif (exists $args{match}) {
    $param_sql .= "path like ?";
    push @params, $args{match};
  } elsif (exists $args{symbol_id}) {
    $param_sql .= "symbol_id = ?";
    push @params, $args{symbol_id};
  }

  if ($param_sql) {
    $sql .= " WHERE $param_sql";
  }
  
  $sql .= " ORDER BY path ASC";
  
  my $result = $Dbh->selectall_arrayref($sql, {}, @params);
  if (defined $result && @$result) {
    return $result;
  }
  return [];
}

sub select_connections {
  my ($self, %args) = @_;
  
  $self->connect();
  
  my $sql = q/
    SELECT symbols.id, symbols.symbol,
           connections.line_no, connections.symbol_offset, 
           files.path, connections.file_id, 
	   connections.package_id, connections.type, connections.caller_id,
           files.dist_id
      FROM connections 
 LEFT JOIN symbols ON connections.symbol_id = symbols.id 
 LEFT JOIN files   ON connections.file_id = files.id
/;

  my $param_sql = "";
  my @params;
  
  if (exists $args{file_id} && defined $args{file_id}) {
    $param_sql .= " AND file_id = ?";
    push @params, $args{file_id};
  }

  if (exists $args{symbol_id} && defined $args{symbol_id}) {
    $param_sql .= " AND connections.symbol_id = ?";
    push @params, $args{symbol_id};
  }

  if (exists $args{package_id} && defined $args{package_id}) {
    $param_sql .= " AND package_id = ?";
    push @params, $args{package_id};
  }

  if (exists $args{caller_id} && defined $args{caller_id}) {
    $param_sql .= " AND caller_id = ?";
    push @params, $args{caller_id};
  }

  if (exists $args{caller_sub_id} && defined $args{caller_sub_id}) {
    $param_sql .= " AND caller_sub_id = ?";
    push @params, $args{caller_sub_id};
  }

  if (exists $args{limit_types}) {
    if(ref $args{limit_types} eq 'ARRAY') {
      $param_sql .= " AND connections.type IN(" . join(",", @{$args{limit_types}}) . ")";
    }
  }

  if ($param_sql) {
    $sql .= " WHERE 1 = 1 $param_sql";
  }


  $sql .= " ORDER BY connections.type ASC, files.path ASC, line_no ASC, symbol_offset ASC";

  my $result = $Dbh->selectall_arrayref($sql, {}, @params);

  if (defined $result && @$result) {
    return $result;
  }

  return [];
}

sub select_declarations {
  my ($self, %args) = @_;
  
  $self->connect();
  
  my $sql = "SELECT symbols.id, symbol, line_no, files.path, file_id FROM declarations LEFT JOIN symbols ON declarations.symbol_id = symbols.id LEFT JOIN files ON declarations.file_id = files.id";

  my $param_sql = "";
  my @params;

  if (exists $args{file_id} && defined $args{file_id}) {
    $param_sql .= "file_id = ?";
    push @params, $args{file_id};
  } elsif (exists $args{symbol_id} && defined $args{symbol_id}) {
    $param_sql .= "symbol_id = ?";
    push @params, $args{symbol_id};
  }

  if ($param_sql) {
    $sql .= " WHERE $param_sql";
  }

  $sql .= " ORDER BY line_no ASC";

  my $result = $Dbh->selectall_arrayref($sql, {}, @params);

  if (defined $result && @$result) {
    return $result;
  }

  return [];
}

# Subroutines related to symbol lookup
sub select_symbol {
  my ($self, $symbol_id) = @_;

  $self->connect();
  
  my $result = $Dbh->selectall_arrayref("SELECT symbol FROM symbols WHERE id = ?", {}, $symbol_id);
  if (defined $result && @$result) {
    return $result;
  }

  return [[""]];
}

sub select_symbol_by_name {
  my ($self, $symbol_name) = @_;

  $self->connect();
  
  my $result = $Dbh->selectall_arrayref("SELECT id, symbol FROM symbols WHERE symbol like ? ORDER BY symbol ASC", {}, $symbol_name);
  if (defined $result && @$result) {
    return $result;
  }

  return [[0, ""]];
}

sub select_package {
  my ($self, $symbol_id) = @_;

  $self->connect();

  my $result = $Dbh->selectall_arrayref("SELECT files.path, files.id, line_no FROM packages LEFT JOIN files ON files.id = packages.file_id WHERE symbol_id = ?", {}, $symbol_id);
  
  if (defined $result && @$result) {
    return $result;
  }

  return [];
}

# Delete routines
sub delete_distribution {
  my ($self, %args) = @_;

  $self->connect();

  my $dist_ids = [];

  if (exists $args{dist_id} && defined $args{dist_id}) {
    $dist_ids = ref $args{dist_id} eq 'ARRAY' ? $args{dist_id} : [$args{dist_id}];
  } elsif (exists $args{path} && defined $args{path}) {
    my $dists = $Dbh->selectall_arrayref("SELECT id FROM distributions WHERE path = ?", {}, $args{path});
    if (defined $dists && @$dists) {
      push @$dist_ids, $_->[0] for(@$dists);
    }
  }

  foreach my $dist_id (@$dist_ids) {
    my $files = $Dbh->selectall_arrayref("SELECT id FROM files WHERE dist_id = ?", {}, $dist_id);
    if (defined $files && @$files) {
      foreach my $file (@$files) {
	$Dbh->do("DELETE FROM connections WHERE file_id = ?", {}, $file->[0]);
      }
    }
    $Dbh->do("DELETE FROM files WHERE dist_id = ?", {}, $dist_id);
    $Dbh->do("DELETE FROM distributions WHERE id = ?", {}, $dist_id);
  }
}

1;
