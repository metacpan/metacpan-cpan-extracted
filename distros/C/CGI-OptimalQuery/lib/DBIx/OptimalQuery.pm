package DBIx::OptimalQuery::sth;

use strict;
use warnings;
no warnings qw( uninitialized once redefine );

use DBI();
use Carp;
use Data::Dumper();

sub Dumper {
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::SortKeys = 1;
  Data::Dumper::Dumper(@_);
}


=comment
 prepare a DBI sth from user defined selects, filters, sorts

 this constructor 'new' is called when a DBIx::OptimalQuery->prepare method 
  call is issued.

  my %opts = (
    show   => []
    filter => ""
    sort   => ""
  );

  $sth = $oq->prepare(%opts);
  - same as -
  $sth = DBIx::OptimalQuery::sth->new($oq,%opts);

  $sth->execute( limit => [0, 10]);
=cut
sub new {
  my $class = shift;
  my $oq = shift;
  my %args = @_;

  #$$oq{error_handler}->("DEBUG: \$sth = $class->new(\$oq,\n".Dumper(\%args).")\n") if $$oq{debug};

  my $sth = bless \%args, $class;
  $sth->{oq} = $oq;
  $sth->_normalize();
  $sth->create_select();
  $sth->create_where();
  $sth->create_order_by();

  return $sth;
}

sub get_lo_rec { $_[0]{limit}[0] }
sub get_hi_rec { $_[0]{limit}[1] }

sub set_limit {
  my ($sth, $limit) = @_;
  $$sth{limit} = $limit;
  return undef;
}

# execute statement
# notice that we can't execute other child cursors
# because their bind params are dependant on
# their parent cursor value
sub execute {
  my ($sth) = @_;
  return undef if $$sth{_already_executed};
  $$sth{_already_executed}=1;

  #$$sth{oq}{error_handler}->("DEBUG: \$sth->execute()\n") if $$sth{oq}{debug};
  return undef if $sth->count()==0;

  local $$sth{oq}{dbh}{LongReadLen};

  # build SQL for main cursor
  { my $c = $sth->{cursors}->[0];
    my @all_deps = (@{$c->{select_deps}}, @{$c->{where_deps}}, @{$c->{order_by_deps}});
    my ($order) = $sth->{oq}->_order_deps(@all_deps); 
    my @from_deps; push @from_deps, @$_ for @$order;

    # create from_sql, from_binds
    # vars prefixed with old_ is used for supported non sql-92 joins
    my ($from_sql, @from_binds, $old_join_sql, @old_join_binds );

    foreach my $from_dep (@from_deps) {
      my ($sql, @binds) = @{ $sth->{oq}->{joins}->{$from_dep}->[1] };
      push @from_binds, @binds if @binds;

      # if this is the driving table join
      if (! $sth->{oq}->{joins}->{$from_dep}->[0]) {

        # alias it if not already aliased in sql
        $from_sql .= $sql.' ';
        $from_sql .= "$from_dep" unless $sql =~ /\b$from_dep\s*$/;
        $from_sql .= "\n";
      }
  
  
      # if SQL-92 type join?
      elsif (! defined $sth->{oq}->{joins}->{$from_dep}->[2]) {
        $from_sql .= $sql."\n";
      }
  
      # old style join
      else {
        $from_sql .= ", ".$sql.' '.$from_dep."\n";
        my ($sql, @binds) = @{ $sth->{oq}->{joins}->{$from_dep}->[2] };
        $old_join_sql .= " AND " if $old_join_sql ne '';
        $old_join_sql .= $sql;
        push @old_join_binds, @binds;
      }
    }
  
  
    # construct where clause
    my $where;
    { my @where;
      push @where, '('.$old_join_sql.') ' if $old_join_sql;
      push @where, '('.$c->{where_sql}.') ' if $c->{where_sql};
      $where = ' WHERE '.join("\nAND ", @where) if @where;
    }
  
    # generate sql and bind params
    $$c{sql} = "SELECT ".join(',', @{ $c->{select_sql} })." FROM $from_sql $where ".
      (($c->{order_by_sql}) ? "ORDER BY ".$c->{order_by_sql} : '');

    my @binds = (@{ $c->{select_binds} }, @from_binds, @old_join_binds,
      @{$c->{where_binds}}, @{$c->{order_by_binds}} );
    $$c{binds} = \@binds;

    # if clobs have been selected, find & set LongReadLen
    if ($$sth{oq}{dbtype} eq 'Oracle' &&
        $$sth{'oq'}{'AutoSetLongReadLen'} &&
        scalar(@{$$c{'selected_lobs'}})) {

      my $maxlenlobsql = "SELECT greatest(".join(',',
          map { "nvl(max(DBMS_LOB.GETLENGTH($_)),0)" } @{$$c{'selected_lobs'}}
        ).") FROM (".$$c{'sql'}.")";

      my ($SetLongReadLen) = $$sth{oq}{dbh}->selectrow_array($maxlenlobsql, undef, @{$$c{'binds'}});

      if (! $$sth{oq}{dbh}{LongReadLen} || $SetLongReadLen > $$sth{oq}{dbh}{LongReadLen}) {
        $$sth{oq}{dbh}{LongReadLen} = $SetLongReadLen;
      }
    }

    $sth->add_limit_sql();
  }


  # build children cursors
  my $cursors = $sth->{cursors};
  foreach my $i (1 .. $#$cursors) {
    my $c = $sth->{cursors}->[$i];
    my $sd = $c->{select_deps};

    # define sql and binds for joins for this child cursor
    # in the following vars
    my ($from_sql, @from_binds, $where_sql, @where_binds );

    # define vars for child cursor driving table
    # these are handled differently since we aren't joining in parent deps
    # they were precomputed in _normalize method when constructing $oq

    ($from_sql, @from_binds) = 
      @{ $sth->{oq}->{joins}->{$sd->[0]}->[3]->{new_cursor}->{sql} };
    $where_sql = $sth->{oq}->{joins}->{$sd->[0]}->[3]->{new_cursor}->{'join'};
    my $order_by_sql = '';
    if ($sth->{oq}->{joins}->{$sd->[0]}->[3]->{new_cursor_order_by}) {
      $order_by_sql = " ORDER BY ".$sth->{oq}->{joins}->{$sd->[0]}->[3]->{new_cursor_order_by};
    }

    $from_sql .= "\n";

    # now join in all other deps normally for this cursor
    foreach my $i (1 .. $#$sd) {
      my $joinAlias = $sd->[$i];

      my ($sql, @binds) = @{ $sth->{oq}->{joins}->{$joinAlias}->[1] };

      # these will NOT be defined for sql-92 type joins
      my ($joinWhereSql, @joinWhereBinds) = 
        @{ $sth->{oq}->{joins}->{$joinAlias}->[2] }
          if defined $sth->{oq}->{joins}->{$joinAlias}->[2];

      # if SQL-92 type join?
      if (! defined $joinWhereSql) {
        $from_sql .= $sql."\n";
        push @from_binds, @binds;
      }

      # old style join
      else {
        $from_sql .= ",\n$sql $joinAlias";
        push @from_binds, @binds;
        if ($joinWhereSql) {
          $where_sql .= " AND " if $where_sql;
          $where_sql .= $joinWhereSql;
        }
        push @where_binds, @joinWhereBinds;
      }
    }

    # build child cursor sql
    $c->{sql} = "
SELECT ".join(',', @{ $c->{select_sql} })."
FROM $from_sql
WHERE $where_sql 
$order_by_sql ";
    $c->{binds} = [ @{ $c->{select_binds} }, @from_binds, @where_binds ]; 

    # if clobs have been selected, find & set LongReadLen
    if ($$sth{oq}{dbtype} eq 'Oracle' &&
        $$sth{'oq'}{'AutoSetLongReadLen'} &&
        scalar(@{$$c{'selected_lobs'}})) {
      my ($SetLongReadLen) = $$sth{oq}{dbh}->selectrow_array("
        SELECT greatest(".join(',',
          map { "nvl(max(DBMS_LOB.GETLENGTH($_)),0)" } @{$$c{'selected_lobs'}}
        ).")
        FROM (".$$c{'sql'}.")", undef, @{$$c{'binds'}});
      if (! $$sth{oq}{dbh}{LongReadLen} || $SetLongReadLen > $$sth{oq}{dbh}{LongReadLen}) {
        $$sth{oq}{dbh}{LongReadLen} = $SetLongReadLen;
      }
    }
  }

  eval {
    my $c;

    # prepare all cursors
    foreach $c (@$cursors) {
      $$sth{oq}->{error_handler}->("SQL:\n".$c->{sql}."\nBINDS:\n".Dumper($c->{binds})."\n") if $$sth{oq}{debug}; 
      $c->{sth} = $sth->{oq}->{dbh}->prepare($c->{sql});
    }
    $c = $$cursors[0];
    $c->{sth}->execute( @{ $c->{binds} } );
    my @fieldnames = @{ $$c{select_field_order} };
    my %rec;
    my @bindcols = \( @rec{ @fieldnames } );
    $c->{sth}->bind_columns(@bindcols);
    $c->{bind_hash} = \%rec;
  };
  if ($@) {
    die "Problem with SQL; $@\n";
  }
  return undef;
}

# function to add limit sql
# $sth->add_limit_sql()
sub add_limit_sql {
  my ($sth) = @_;

  #$$sth{oq}{error_handler}->("DEBUG: \$sth->add_limit_sql()\n") if $$sth{oq}{debug};
  my $lo_limit = $$sth{limit}[0] || 0;
  my $hi_limit = $$sth{limit}[1] || $sth->count();
  my $c = $sth->{cursors}->[0];

  if ($$sth{oq}{dbtype} eq 'Oracle') {
    $c->{sql} = "
SELECT * 
FROM (
  SELECT tablernk1.*, rownum RANK
  FROM (
".$c->{sql}."
  ) tablernk1 
  WHERE rownum <= ?
) tablernk2 
WHERE tablernk2.RANK >= ? ";
    push @{$$c{binds}}, ($hi_limit, $lo_limit);
    push @{$$c{select_field_order}}, "DBIXOQRANK";
  }

  # sqlserver doesn't support limit/offset until Sql Server 2012 (which I don't have to test)
  # the workaround is this ugly hack...
  elsif ($$sth{oq}{dbtype} eq 'Microsoft SQL Server') {
    die "missing required U_ID in select" unless exists $$sth{oq}{select}{U_ID};

    my $sql = $c->{sql};

    # extract order by sql, and binds in order by from sql
    my $orderbysql;
    if ($sql =~ s/\ (ORDER BY\ .*?)$//) {
      $orderbysql = $1;
      my $copy = $orderbysql;
      my $bindCount = $copy =~ tr/,//;
      if ($bindCount > 0) {
        my @newBinds;
        push @newBinds, pop @{$$c{binds}} for 1 .. $bindCount;
        @{$$c{binds}} = (reverse @newBinds, @{$$c{binds}});
      }
      $orderbysql .= ", ".$$sth{oq}{select}{U_ID}[1][0];
    } elsif (exists $$sth{oq}{select}{U_ID}) {
      $orderbysql = " ORDER BY ".$$sth{oq}{select}{U_ID}[1][0];
    }

    # remove first select keyword, and add new one with windowing
    if ($sql =~ s/^(\s*SELECT\s*)//) {
      my $limit = int($hi_limit - $lo_limit + 1);
      my $lo_limit = int($lo_limit);

      # sqlserver doesn't allow placeholders for limit and offset here
      $c->{sql} = "SELECT TOP $limit * FROM (SELECT ROW_NUMBER() OVER ($orderbysql) AS RANK, $sql) tablerank1 WHERE tablerank1.RANK >= $lo_limit";
      unshift @{$$c{select_field_order}}, "DBIXOQRANK";
    }
  }

  elsif ($$sth{oq}{dbtype} eq 'Pg') {
    my $a = $lo_limit - 1;
    my $b = $hi_limit - $lo_limit + 1;
    $c->{sql} .= "\nLIMIT ? OFFSET ?";
    push @{$$c{binds}}, ($b, $a);
  }

  else {
    my $a = $lo_limit - 1;
    my $b = $hi_limit - $lo_limit + 1;
    $c->{sql} .= "\nLIMIT ?,?";
    push @{$$c{binds}}, ($a, $b);
  }

  return undef;
}


# normalize member variables
sub _normalize {
  my $sth = shift;
  #$$sth{oq}{error_handler}->("DEBUG: \$sth->_normalize()\n") if $$sth{oq}{debug};

  # if show is not defined - then define it
  if (! exists $sth->{show}) {
    my @select;
    foreach my $select (@{ $sth->{oq}->{'select'} } ) {
      push @select, $select; 
    }
    $sth->{show} = \@select;
  }

  # define filter & sort if not defined
  $sth->{'filter'} = "" if ! exists $sth->{'filter'};
  $sth->{'sort'}   = "" if ! exists $sth->{'sort'};
  $sth->{'fetch_index'} = 0;
  $sth->{'count'} = undef; 
  $sth->{'cursors'} = undef;

  return undef;
}



# define @select & @select_binds, and add deps
sub create_select {
  my $sth = shift;
  #$$sth{oq}{error_handler}->("DEBUG: \$sth->create_select()\n") if $$sth{oq}{debug};

  
  # find all of the columns that need to be shown
  my %show;

  # find all deps to be used in select including cols marked always_select
  my (@deps, @select_sql, @select_binds);
  { my %deps;

    # add deps, @select, @select_binds for items in show
    foreach my $show (@{ $sth->{show} }) {
      $show{$show} = 1 if exists $sth->{'oq'}->{'select'}->{$show};
      foreach my $dep (@{ $sth->{'oq'}->{'select'}->{$show}->[0] }) {
        $deps{$dep} = 1;
      }
    }

    # add deps used in always_select
    foreach my $colAlias (keys %{ $sth->{'oq'}->{'select'} }) {
      if ($sth->{'oq'}->{'select'}->{$colAlias}->[3]->{always_select} ) {
        $show{$colAlias} = 1;
        $deps{$_} = 1 for @{ $sth->{'oq'}->{'select'}->{$colAlias}->[0] };
      }
    }
    @deps = keys %deps;
  }

  # order and index deps into appropriate cursors
  my ($dep_order, $dep_idx) = $sth->{oq}->_order_deps(@deps);

  # look though select again and add all cols with is_hidden option
  # if all their deps have been fulfilled
  foreach my $colAlias (keys %{ $sth->{'oq'}->{'select'} }) {
    if ($sth->{'oq'}->{'select'}->{$colAlias}->[3]->{is_hidden}) {
      my $deps = $sth->{'oq'}->{'select'}->{$colAlias}->[0];
      my $all_deps_met = 1;
      for (@$deps) {
        if (! exists $dep_idx->{$_}) {
          $all_deps_met = 0;
          last;
        }
      }
      $show{$colAlias} = 1 if $all_deps_met;
    }
  }

  # create main cursor structure & attach deps for main cursor
  $sth->{'cursors'} = [ $sth->_get_main_cursor_template() ];
  $sth->{'cursors'}->[0]->{'select_deps'} = $dep_order->[0];

  # unique counter that is used to uniquely identify cols in parent cursors
  # to their children cursors
  my $parent_bind_tag_idx = 0;

  # create other cursors (if they exist)
  # and define how they join to their parent cursors
  # by defining parent_join, parent_keys
  foreach my $i (1 .. $#$dep_order) {
    push @{ $sth->{'cursors'} }, $sth->_get_sub_cursor_template();
    $sth->{'cursors'}->[$i]->{'select_deps'} = $dep_order->[$i];

    # add parent_join, parent_keys for this child cursor
    my $driving_child_join_alias = $dep_order->[$i]->[0];
    my $cursor_opts = $sth->{'oq'}->{'joins'}->{$driving_child_join_alias}->[3]->{new_cursor};
    foreach my $part (@{ $cursor_opts->{'keys'} } ) {
      my ($dep,$sql) = @$part;
      my $key = 'DBIXOQMJK'.$parent_bind_tag_idx; $parent_bind_tag_idx++;
      my $parent_cursor_idx = $dep_idx->{$dep};
      die "could not find dep: $dep for new cursor" if $parent_cursor_idx eq '';
      push @{ $sth->{'cursors'}->[$parent_cursor_idx]->{select_field_order} }, $key;
      push @{ $sth->{'cursors'}->[$parent_cursor_idx]->{select_sql} }, "$dep.$sql AS $key";
      push @{ $sth->{'cursors'}->[$i]->{'parent_keys'} }, $key;
    }
    $sth->{'cursors'}->[$i]->{'parent_join'} = $cursor_opts->{'join'};
  }
    
  # plug in select_sql, select_binds for cursors
  foreach my $show (keys %show) {
    my $select = $sth->{'oq'}->{'select'}->{$show};
    next if ! $select;

    my $cursor = $sth->{'cursors'}->[$dep_idx->{$select->[0]->[0]}];

    my $select_sql;

    # if type is date then use specified date format
    if (! $$select[3]{select_sql} && $$select[3]{date_format}) {
      my @tmp = @{ $select->[1] }; $select_sql = \ @tmp; # need a real copy cause we are going to mutate it
      if ($$sth{oq}{dbtype} eq 'Oracle' ||
          $$sth{oq}{dbtype} eq 'Pg') {
        $$select_sql[0] = "to_char(".$$select_sql[0].",'".$$select[3]{date_format}."')";
      } elsif ($$sth{oq}{dbtype} eq 'mysql') {
        $$select_sql[0] = "date_format(".$$select_sql[0].",'".$$select[3]{date_format}."')";
      } else {
        die "unsupported DB";
      }
    }

    # else just copy the select
    else {
      $select_sql = $select->[3]->{select_sql} || $select->[1];
    }

    # remember if a lob is selected
    if ($$sth{oq}{dbtype} eq 'Oracle' &&
        $sth->{oq}->get_col_types('select')->{$show} eq 'clob') {
      push @{ $cursor->{selected_lobs} }, $show;
      #$select_sql->[0] = 'to_char('.$select_sql->[0].')';
    }

    if ($select_sql->[0] ne '') {
      push @{ $cursor->{select_field_order} }, $show;
      push @{ $cursor->{select_sql} }, $select_sql->[0].' AS '.$show;
      push @{ $cursor->{select_binds} }, @$select_sql[1 .. $#$select_sql];
    }
  }

  return undef;
}
 



# template for the main cursor
sub _get_main_cursor_template {
  { sth => undef,
    sql => "",
    binds => [],
    selected_lobs => [],
    select_field_order => [],
    select_sql => [],
    select_binds => [],
    select_deps => [],
    where_sql => "",
    where_binds => [],
    where_deps => [],
    where_name => "",
    order_by_sql => "",
    order_by_binds => [],
    order_by_deps => [],
    order_by_name => []
  };
}

# template for explicitly defined additional cursors
sub _get_sub_cursor_template {
  { sth => undef,
    sql => "",
    binds => [],
    selected_lobs => [],
    select_field_order => [],
    select_sql => [],
    select_deps => [],
    select_binds => [],
    parent_join => "",
    parent_keys => [],
  };
}




    
  


# modify cursor and add where clause data
sub create_where { 
  my ($sth) = @_;

  # define cursor where_sql, where_deps, where_name where_binds from parsed filter types
  my $c = $sth->{cursors}->[0];
  foreach my $filterType (qw( filter hiddenFilter forceFilter)) {
    next if $$sth{$filterType} eq '';
    my $filterArray = $$sth{oq}->parseFilter($$sth{$filterType});
    my $filterSQL = $$sth{oq}->generateFilterSQL($filterArray);

    push @{ $$c{where_deps} }, @{ $$filterSQL{deps} };
    if ($$c{where_sql}) {
      $$c{where_sql} .= ' AND ('.$$filterSQL{sql}.')';
    } else {
      $$c{where_sql} = $$filterSQL{sql};
    }
    push @{ $$c{where_binds} }, @{ $$filterSQL{binds} };
    $$c{where_name} = $$filterSQL{name} if $filterType eq 'filter';
  }

  return undef;
}




# modify cursor and add order by data
sub create_order_by {
  my ($sth) = @_;
  my $c = $sth->{cursors}->[0];

  my $s = $$sth{oq}->parseSort($$sth{'sort'});
  $$c{order_by_deps} = $$s{deps};
  $$c{order_by_sql} = join(',', @{ $$s{sql} });
  $$c{order_by_binds} = $$s{binds};
  $$c{order_by_name} = $$s{name};
  return undef;
}









  


# fetch next row or return undef when done
sub fetchrow_hashref {
  my ($sth) = @_;
  return undef unless $sth->count() > 0;
  $sth->execute(); # execute if not already existed

  #$$sth{oq}{error_handler}->("DEBUG: \$sth->fetchrow_hashref()\n") if $$sth{oq}{debug};

  my $cursors = $sth->{cursors};
  my $c = $cursors->[0];

  # bind hash value to column data
  my $rec = $$c{bind_hash};

  # fetch record
  if (my $v = $c->{sth}->fetch()) { 

    foreach my $i (0 .. $#$v) {

      # if col type is decimal auto trim 0s after decimal
      if ($c->{sth}->{TYPE}->[$i] eq '3' && $$v[$i] =~ /\./) {
        $$v[$i] =~ s/0+$//;
        $$v[$i] =~ s/\.$//;
      }
    }
 
    $sth->{'fetch_index'}++;

    # execute other cursors
    foreach my $i (1 .. $#$cursors) {
      $c = $cursors->[$i];

      $c->{sth}->execute( @{ $c->{binds} }, 
        map { $$rec{$_} } @{ $c->{parent_keys} } );

      my $cols = $$c{select_field_order};
      @$rec{ @$cols } = [];

      while (my @vals = $c->{sth}->fetchrow_array()) {
        for (my $i=0; $i <= $#$cols; $i++) {
          push @{ $$rec{$$cols[$i]} }, $vals[$i];
        }
      }
      $c->{sth}->finish();
    }
    return $rec;
  } else {
    return undef;
  }
}

# finish sth
sub finish {
  my ($sth) = @_;
  #$$sth{oq}{error_handler}->("DEBUG: \$sth->finish()\n") if $$sth{oq}{debug};
  foreach my $c (@{$$sth{cursors}}) {
    $$c{sth}->finish() if $$c{sth};
    undef $$c{sth};
  }
  return undef;
}

# get count for sth
sub count {
  my $sth = shift;

  # if count is not already defined, define it
  if (! defined $sth->{count}) {
    #$$sth{oq}{error_handler}->("DEBUG: \$sth->count()\n") if $$sth{oq}{debug};

    my $c = $sth->{cursors}->[0];

    my $drivingTable = $c->{select_deps}->[0];

    # only need to join in driving table with
    # deps used in where clause
    my ($deps) = $sth->{oq}->_order_deps($drivingTable, @{$c->{where_deps}});
    my @from_deps; push @from_deps, @$_ for @$deps;

    # create from_sql, from_binds
    # vars prefixed with old_ is used for supported non sql-92 joins
    my ($from_sql, @from_binds, $old_join_sql, @old_join_binds );
    foreach my $from_dep (@from_deps) {
      my ($sql, @binds) = @{ $sth->{oq}->{joins}->{$from_dep}->[1] };
      push @from_binds, @binds if @binds;

      # if this is the driving table join
      if (! $sth->{oq}->{joins}->{$from_dep}->[0]) {

        # alias it if not already aliased in sql
        $sql .= " $from_dep" unless $sql =~ /\b$from_dep\s*$/;
        $from_sql .= $sql;
      }

      # if SQL-92 type join?
      elsif (! $sth->{oq}->{joins}->{$from_dep}->[2]) {
        $from_sql .= "\n".$sql;
      }

      # old style join
      else {
        $from_sql .= ",\n".$sql.' '.$from_dep;
        my ($sql, @binds) = @{ $sth->{oq}->{joins}->{$from_dep}->[2] };
        if ($sql) {
          $old_join_sql .= " AND " if $old_join_sql ne '';
          $old_join_sql .= $sql;
        }
        push @old_join_binds, @binds;
      }
    }


    # construct where clause
    my $where;
    { my @where;
      push @where, '('.$old_join_sql.') ' if $old_join_sql;
      push @where, '('.$c->{where_sql}.') ' if $c->{where_sql};
      $where = 'WHERE '.join("\nAND ", @where) if @where;
    }

    # generate sql and bind params
    my $sql = "
SELECT count(*)
FROM (
  SELECT $drivingTable.*
  FROM $from_sql
  $where
) cnt_query";
    my @binds = (@from_binds, @old_join_binds, @{$c->{where_binds}});

    eval {
      $$sth{oq}->{error_handler}->("SQL:\n$sql\nBINDS:\n".Dumper(\@binds)."\n") if $$sth{oq}{debug}; 
      ($sth->{count}) = $sth->{oq}->{dbh}->selectrow_array($sql, undef, @binds);
    }; if ($@) {
      die "Problem finding count for SQL:\n$sql\nBINDS:\n".join(',',@binds)."\n\n$@\n";
    }
  }

  return $sth->{count};
}

sub fetch_index { $_->{'fetch_index'} }

sub filter_descr {
  my $sth = shift;
  return $sth->{cursors}->[0]->{'where_name'};
}

sub sort_descr {
  my $sth = shift;
  if (wantarray) {
    return @{ $sth->{cursors}->[0]->{'order_by_name'} };
  } else {
    return join(', ', @{ $sth->{cursors}->[0]->{'order_by_name'} });
  }
}







































package DBIx::OptimalQuery;

=comment

use DBIx::OptimalQuery;
my $oq = DBIx::OptimalQuery->new(
  select   => {
    'alias' => [dep, sql, nice_name, { OPTIONS } ]
  }

  joins => {
    'alias' => [dep, join_sql, where_sql, { OPTIONS } ]
  }

  named_filters => {  
    'name' => [dep, sql, nice]
    'name' => { 
      sql_generator => sub { 
        my %args = @_;
        return [dep, sql, name] 
      } 
      title => "text displayed on interactive filter"
    }
  },

  named_sorts => {
    'name' => [dep, sql, nice]
    'name' => { sql_generator => sub { return [dep, sql, name] } }
  },

  

  debug => 0 | 1
);
=cut

use strict;
use Carp;
use Data::Dumper;
use DBI();

sub new {
  my $class = shift;
  my %args = @_;
  my $oq = bless \%args, $class;

  $$oq{debug} ||= 0;
  #$$oq{error_handler}->("DEBUG: $class->new(".Dumper(\%args).")\n") if $$oq{debug};

  die "BAD_PARAMS - must provide a dbh!"
    unless $oq->{'dbh'};
  die "BAD_PARAMS - must define a select key in call to constructor"
    unless ref($oq->{'select'}) eq 'HASH';
  die "BAD_PARAMS - must define a joins key in call to constructor"
    unless ref($oq->{'joins'}) eq 'HASH';


  $oq->_normalize();

  $$oq{dbtype} = $$oq{dbh}{Driver}{Name};
  $$oq{dbtype} = $$oq{dbh}->get_info(17) if $$oq{dbtype} eq 'ODBC';

  return $oq;
}



# returns [
#  # type 1 - (selectalias operator literal)
#    [1,$numLeftParen,$leftExpSelectAlias,$op,$rightExpLiteral,$numRightParen],
#  # type 2 - (namedfilter, arguments)
#    [2,$numLeftParen,$namedFilter,$argArray,$numRightParen]
#  # type 3 - (selectalias operator selectalias)
#    [3,$numLeftParen,$leftExpSelectAlias,$op,$rightExpSelectAlias,$numRightParen],
#  # logic operator
#    'AND'|'OR'
# ]
sub parseFilter {
  my ($oq, $f) = @_; 
  $f =~ /^\s+/; # trim leading spaces

  my @rv;
  return \@rv if $f eq '';

  my $error;

  my $parenthesis=0;
 
  while (! $error) {
    my $numLeftP=0;
    my $numRightP=0;

    # parse opening parenthesis
    while ($f =~ /\G\(\s*/gc) { $numLeftP++; $parenthesis++;}

    # if this looks like a named filter
    if ($f=~/\G(\w+)\s*\(\s*/gc) {
      my $namedFilter = $1;

      if (! exists $$oq{named_filters}{$namedFilter}) {
        $error = "invalid named filter: $namedFilter";
        next;
      }

      # parse named filter arguments
      my @args;
      while (! $error) {
        if ($f =~ /\G\)\s*/gc) {
          last;
        }
        elsif ($f =~ /\G\'([^\']*)\'\s*\,?\s*/gc ||
               $f =~ /\G\"([^\"]*)\"\s*\,?\s*/gc ||
               $f =~ /\G([^\)\,]*)\s*\,?\s*/gc) {
          push @args, $1;
        } else {
          $error = "could not parse named filter arguments";
        }
      }
      next if $error;

      # parse closing parenthesis
      while ($f =~ /\G\)\s*/gc) {
        if ($parenthesis > 0) {
          $parenthesis--;
          $numRightP++;
        }
      }

      push @rv, [2,$numLeftP,$namedFilter,\@args,$numRightP];
    }

    # else this is an expression
    else {
      my $lexp;
      my $rexp;
      my $typeNum = 1;

      # grab select alias used on the left side of the expression
      if ($f=~/\G\[([^\]]+)\]\s*/gc) { $lexp = $1; }
      elsif ($f=~/\G(\w+)\s*/gc) { $lexp = $1; }
      else {
        $error = "missing left expression";
      }

      # make sure the select alias is valid
      if (! $$oq{select}{$lexp}) {
        $error = "invalid field $lexp";
        next;
      }

      # parse the operator
      my $op;
      if ($f =~ /\G(\!\=|\=|\<\=|\>\=|\<|\>|like|not\ ?like|contains|not\ ?contains)\s*/igc) {
        $op = lc($1);
      }
      else {
        $error = "invalid operator";
        next;
      }

      # if rexp is a select alias
      if ($f=~/\G\[([^\]]+)\]\s*/gc) {
        $rexp = $1;
        $typeNum = 3;
      }

      # else if rexp is a literal
      elsif ($f =~ /\G\'([^\']*)\'\s*/gc  ||
             $f =~ /\G\"([^\"]*)\"\s*/gc) {
        $rexp = $1;
      }

      # else if rexp is a word
      elsif ($f =~ /\G(\S+)\s*/gc) {
        $rexp = $1;

        # is word a col alias?
        if ($$oq{select}{$rexp}) {
          $typeNum = 3;
        }
      }

      else {
        $error = "missing right expression";
        next;
      }

      # parse closing parenthesis
      while ($f =~ /\G\)\s*/gc) {
        if ($parenthesis > 0) {
          $parenthesis--;
          $numRightP++;
        }
      }

      push @rv, [$typeNum, $numLeftP, $lexp, $op, $rexp, $numRightP];
    }

    # parse logic operator
    if ($f =~ /(AND|OR)\s*/gci) {
      push @rv, uc($1);
    }
    else { 
      last;
    }
  }

  if ($error) {
    my $p = pos($f);
    $error .= " at ".substr($f, 0, $p).'<*>'.substr($f, $p);
    die $error."\n";
  }

  return \@rv;
}


# given a filter string, returns { sql => $sql, binds => \@binds, deps => \@deps, name => $name };
sub generateFilterSQL {
  my ($oq, $filterArray) = @_;

  # build an array of sql tokens, bind vals, and used deps
  # also build a formatted name
  my @sql;
  my @binds;
  my %deps;
  my @name;
  my $parenthesis = 0;

  foreach my $exp (@$filterArray) {

    if ($exp eq 'AND') {
      push @sql, "AND";
      push @name, "AND";
    } elsif ($exp eq 'OR') {
      push @sql, "OR";
      push @name, "OR";
    }

    # [COLALIAS] != "literal"
    elsif ($$exp[0]==1) {
      my ($type, $numLeftParen, $leftColAlias, $operatorName, $rval, $numRightParen) = @$exp;
      $parenthesis+=$numLeftParen;
      $parenthesis-=$numRightParen;

      my $operator = uc($operatorName);

      # handle left side of expression
      my ($leftDeps, $leftSql, $leftName, $leftOpts, @leftBinds, $leftType);
      ($leftDeps, $leftSql, $leftName, $leftOpts) = @{ $$oq{select}{$leftColAlias} };
      $leftSql = $$leftOpts{filter_sql} if $$leftOpts{filter_sql};
      ($leftSql, @leftBinds) = @$leftSql if ref($leftSql) eq 'ARRAY';
      $leftType = $oq->get_col_type($leftColAlias, 'filter');
      $leftName ||= $leftColAlias;

      # handle right side of expression
      my ($rightSql, $rightName, @rightBinds);
      
      $rightName = $rval;
      if ($rightName eq '') {
        $rightName = "''";
      } elsif ($rightName =~ /\s/) {
        $rightName = '"'.$rightName.'"';
      }

      $rval = $$leftOpts{db_formatter}->($rval) if $$leftOpts{db_formatter};

      # if empty check
      if ($rval eq '') {
        if ($leftType eq 'char' || $leftType eq 'clob') {
          if ($$oq{dbtype} eq 'Oracle') {
            $leftSql = "COALESCE($leftSql,'_ _')";
            $rightSql = "_ _";
          } else {
            $leftSql = "COALESCE($leftSql,'')";
            $rightSql = "''";
          }
          $operator = ($operator =~ /\!|NOT/i) ? '!=' : '=';
        } else {
          $operator = ($operator =~ /\!|NOT/i) ? 'IS NOT NULL' : 'IS NULL';
        }
      }

      # else check against literal value
      else {
        # if numeric operator
        if ($operator =~ /\=|\<|\>/) {

          # if we are doing a numeric date comparison, parse for the date in common formats
          if ($leftType eq 'date' || $leftType eq 'datetime') {

            # is this a calculated date?
            if ($rval =~ /today\s*([\+\-])\s*(\d+)\s*(minute|hour|day|week|month|year|)s?/i) {
              my $sign = $1;
              my $num = $2;
              my $unit = uc($3) || 'DAY';
              $rightName = "today ".$sign.$num." ".lc($unit);
              $rightName .= 's' if $num != 1;
              $num *= -1 if $sign eq '-';

              if ($$oq{dbtype} eq 'Oracle') {
                my $now = $leftType eq 'datetime' ? 'SYSDATE' : 'TRUNC(SYSDATE)';
                if ($unit eq 'MINUTE') {
                  $rightSql = "$now+($num/1440)"
                } elsif ($unit eq 'HOUR') {
                  $rightSql = "$now+($num/24)"
                } elsif ($unit eq 'DAY') {
                  $rightSql = "$now+$num"
                } elsif ($unit eq 'WEEK') {
                  $rightSql = "$now+($num*7)"
                } elsif ($unit eq 'MONTH') {
                  $rightSql = "ADD_MONTHS($now,$num)";
                } elsif ($unit eq 'YEAR') {
                  $rightSql = "ADD_MONTHS($now,$num*12)";
                }
              } else {
                my $now = $leftType eq 'datetime' ? 'NOW()' : 'CURDATE()';
                $rightSql = "DATE_ADD($now, INTERVAL $num $unit)";
              }
            }

            elsif ($rval =~ /today\s*/i) {
              $rightName = "today";
              if ($$oq{dbtype} eq 'Oracle') {
                $rightSql = $leftType eq 'datetime' ? 'SYSDATE' : 'TRUNC(SYSDATE)';
              } else {
                $rightSql = $leftType eq 'datetime' ? 'NOW()' : 'CURDATE()';
              }
            }

            # else this is a date value
            else {

              my ($y,$m,$d,$h,$mi,$s,$hourType);
              if ($rval =~ /^(\d\d\d\d)[\-\/](\d\d?)[\-\/](\d\d?)/) {
                $y = $1;
                $m = $2;
                $d = $3;
              } elsif ($rval =~ /^(\d\d?)[\-\/](\d\d?)[\-\/](\d\d\d\d)/) {
                $m = $1;
                $d = $2;
                $y = $3;
              } elsif ($rval =~ /^(\d\d?)[\-\/](\d\d?)[\-\/](\d\d)\b/) {
                $m = $1;
                $d = $2;
                $y = int('20'.$3);
              } elsif ($rval =~ /^(\d\d\d\d)[\-\/](\d\d?)/) {
                $y = $1;
                $m = $2;
              }
              elsif ($rval =~ /^(\d\d\d\d)/) {
                $y = $1;
              }
              else {
                die "could not parse date: $rval";
              }

              # extract time component if the type supports it
              if ($leftType eq 'datetime') {
                if ($rval =~ /\b(\d\d?)\:(\d\d?)[\:\.](\d\d?)/) {
                  $h = $1;
                  $mi = $2;
                  $s = $3;
                }
                elsif ($rval =~ /\b(\d\d?)\:(\d\d?)/) {
                  $h = $1;
                  $mi = $2;
                }
                elsif ($rval =~ /\b(\d\d?)\s*(am|pm)/i) {
                  $h = $1;
                  $mi = '00'; 
                }
                if ($rval =~ /A/i) {
                  $hourType='AM';
                } elsif ($rval =~ /P/i) {
                  $hourType='PM';
                }
              }

              # format date expression for mysql
              if ($$oq{dbtype} eq 'mysql') {
                my $format = '%Y';
                my $val = "$y";
                if ($m) {
                  $format .= '-%m';
                  $val .= "-$m";
                  if ($d) {
                    $format .= '-%d';
                    $val .= "-$d";
                
                    if ($mi ne '') {
                      $format .= $hourType ? ' %h' : ' %H';
                      $format .= ':%i';
                      $val .= " $h:$mi";
                      if ($s ne '') {
                        $format .= ':%s';
                        $val .= ":$s";
                      }
                      if ($hourType) {
                        $format .= ' %p';
                        $val    .= " $hourType";
                      }
                    }
                  }
                }
                $rightSql = "STR_TO_DATE(?,'$format')";
                push @rightBinds, $val;
          
                # remove lvalue time if rval doesn't use it
                if ($leftType eq 'datetime' && $mi eq '') {
                  $leftSql = "DATE($leftSql)";
                }
              }

              # format date expression for oracle and postgres (use compatible to_date function)
              else {
                my $format = 'YYYY';
                my $val = $y;
                if ($m) {
                  $format .= "-MM";
                  $val .= "-$m";
                  if ($d) {
                    $format .= "-DD";
                    $val .= "-$d";

                    if ($mi ne '') {
                      $format .= $hourType ? ' HH' : ' HH24';
                      $format .= ':MI';
                      $val .= " $h:$mi";
                      if ($s ne '') {
                        $format .= ':SS';
                        $val .= ":$s";
                      }
                      if ($hourType) {
                        $format .= " $hourType";
                        $val    .= " $hourType";
                      }
                    }
                  }
                }

                $rightSql = "TO_DATE(?,'$format')";
                push @rightBinds, $val;

                # remove lvalue time if rval doesn't use it
                if ($leftType eq 'datetime' && $mi eq '') {
                  $leftSql = "TRUNC($leftSql)";
                }
              }
            }
          }

          # if this is a numeric comparison and rvalue is not a number, convert left side to text
          elsif ($leftType eq 'num' && $rval !~ /^(\-?\d*\.\d+|\-?\d+)$/) {
            if ($$oq{dbtype} eq 'mysql') {
              $leftSql = "CONCAT('',$leftSql)";
              $rightSql = '?';
              push @rightBinds, $rval;
            } else {
              $leftSql = "TO_CHAR($leftSql)";
              $rightSql = '?';
              push @rightBinds, $rval;
            }
          }

          # if numeric operator and field is an oracle clob, convert using to_char
          elsif ($$oq{dbtype} eq 'Oracle' && $leftType eq 'clob') {
            $leftSql = "TO_CHAR($leftSql)";
            $rightSql = '?';
            push @rightBinds, $rval;
          }

          else {
            $rightSql = '?';
            push @rightBinds, $rval;
          }
        }

        # like operator
        else {

          # convert contains operator to like
          if ($operatorName =~ /contains/i) {
            $leftSql = "LOWER($leftSql)" if $leftType eq 'char' || $leftType eq 'clob';
            $operator = $operatorName =~ /not/i ? "NOT LIKE" : "LIKE";
            $rval = '%'.lc($rval).'%';
          }

          # allow * as wildcard
          if ($operator =~ /like/i) {
            $rval =~ s/\*/\%/g;
          }

          # remove redundant wildcards
          $rval =~ s/\%\%+/\%/g;

          # if left side is date, convert to text so like operator works as expected
          if ($$leftOpts{date_format}) {
            if ($$oq{dbtype} eq 'mysql') {
              $leftSql = "DATE_FORMAT($leftSql,'$$leftOpts{date_format}')";
            } else {
              $leftSql = "TO_CHAR($leftSql,'$$leftOpts{date_format}')";
            }
          }

          $rightSql = '?';
          push @rightBinds, $rval;
        }
      }

      # if the leftSql uses a new cursor we need to write an exists expression
      # search dep path to see if a new_cursor is used
      my @path = ($$leftDeps[0]);
      my $i=0;
      while (1) {
        die "infinite dep loop detected" if ++$i==50;
        my $parentDep = $$oq{joins}{$path[-1]}[0][0];
        last unless $parentDep;
        push @path, $parentDep;
      }

      # find the oldest parent new cursor if it exists
      while (@path) {
        if ($$oq{joins}{$path[-1]}[3]{new_cursor}) {
          last;
        } else {
          pop @path; 
        }
      }
      
      # if @path has elements, this uses a new_cursor and we must construct an exists expression
      if (@path) {
        @path = reverse @path;
        my ($preSql, $postSql, @preBinds);
        foreach my $joinDep (@path) {
          my ($fromSql, @fromBinds) = @{ $$oq{joins}{$joinDep}[1] }; 

          # unwrap SQL-92 join and add join to where
          $fromSql =~ s/^\s+//;
          $fromSql =~ s/^LEFT\s*//i;
          $fromSql =~ s/^OUTER\s*//i;
          $fromSql =~ s/^JOIN\s*//i;

          my $corelatedJoin;
          if ($fromSql =~ /^(.*)\bON\s*\((.*)\)\s*$/is) {
            $fromSql = $1;
            $corelatedJoin = $2;
          } else {
            die "could not parse for corelated join\n";
          }

          # in a one2many filter that has a negative operator, we need to use
          # a NOT EXISTS and unnegate the operator
          if ($rightName eq "''") {
            if ($operator eq '=') {
              $preSql .= "NOT ";
              $operator = '!=';
            }
            elsif ($operator eq 'IS NULL') {
              $preSql .= "NOT ";
              $operator = 'IS NOT NULL';
            }
          }
          elsif ($operator eq '!=') {
            $operator = '=';
            $preSql .= "NOT ";
          }
          elsif ($operator =~ s/NOT\ //) {
            $preSql .= "NOT ";
          }
          $preSql .= " EXISTS (\n  SELECT 1\n  FROM $fromSql\n  WHERE ($corelatedJoin)\n  AND ";
          $postSql .= ')';
          push @preBinds, @fromBinds;
        }

        # update left expression deps and binds
        $leftDeps = $$oq{joins}{$path[0]}[0];
        unshift @leftBinds, @preBinds if @preBinds;
        $leftSql = $preSql.$leftSql;
        $rightSql .= $postSql;
      }

      my $sql = '(' x $numLeftParen;
      $sql .= $leftSql;
      $sql .= ' '.$operator;
      $sql .= ' '.$rightSql if $rightSql ne '';
      $sql .= ')' x $numRightParen;

      # glue expression
      push @sql,   $sql;
      push @binds, @leftBinds, @rightBinds;
      push @name, $leftName,  $operatorName;
      push @name, $rightName  if $rightName ne '';
      $deps{$_}=1  for @$leftDeps;
    }


    # namedFilter(args)
    elsif ($$exp[0]==2) {
      my ($type, $numLeftParen,$namedFilterAlias,$argArray,$numRightParen) = @$exp;
      $parenthesis+=$numLeftParen;
      $parenthesis-=$numRightParen;

      # generate filter sql, bind, name 
      my $f = $$oq{named_filters}{$namedFilterAlias};
      my ($filterDeps, $filterSql, @filterBinds, $filterLabel);
      if (ref($f) eq 'ARRAY') {
        ($filterDeps, $filterSql, $filterLabel) = @$f;
      } elsif (ref($f) eq 'HASH') {
        die "could not find sql_generator for named_filter $namedFilterAlias\n"
          unless ref($$f{sql_generator}) eq 'CODE';
        ($filterDeps, $filterSql, $filterLabel) = @{ $$f{sql_generator}->(@$argArray) };
      } else {
        die "invalid named_filter: $namedFilterAlias\n";
      }
      ($filterSql, @filterBinds) = @$filterSql if ref($filterSql) eq 'ARRAY'; 


      my $sql = '(' x $numLeftParen;
      # put expression in parenthesis since it may contain OR expression without parenthesis which will screw up order of operations
      $sql .= '('.$filterSql.')';
      $sql .= ')' x $numRightParen;

      # glue expression
      push @sql,   $sql;
      push @binds, @filterBinds;
      push @name, $filterLabel; 

      if (ref($filterDeps) eq 'ARRAY') {
        $deps{$_}=1 for @$filterDeps;
      } elsif ($filterDeps) {
        $deps{$filterDeps}=1;
      }
    }


    # [COL] != [COL2]
    elsif ($$exp[0]==3) {
      my ($type, $numLeftParen,$leftColAlias,$operatorName,$rightColAlias,$numRightParen) = @$exp;
      $parenthesis+=$numLeftParen;
      $parenthesis-=$numRightParen;

      my $operator = uc($operatorName);

      # handle left side of expression
      my ($leftDeps, $leftSql, $leftName, $leftOpts, @leftBinds, $leftType);
      ($leftDeps, $leftSql, $leftName, $leftOpts) = @{ $$oq{select}{$leftColAlias} };
      $leftSql = $$leftOpts{filter_sql} if $$leftOpts{filter_sql};
      ($leftSql, @leftBinds) = @$leftSql if ref($leftSql) eq 'ARRAY';
      $leftType = $oq->get_col_type($leftColAlias, 'filter');
      $leftName ||= $leftColAlias;

      # handle right side of expression
      my ($rightDeps, $rightSql, $rightName, $rightOpts, @rightBinds, $rightType);
      ($rightDeps, $rightSql, $rightName, $rightOpts) = @{ $$oq{select}{$rightColAlias} };
      $rightSql = $$rightOpts{filter_sql} if $$rightOpts{filter_sql};
      ($rightSql, @rightBinds) = @$rightSql if ref($rightSql) eq 'ARRAY';
      $rightType = $oq->get_col_type($rightColAlias, 'filter');
      $rightName ||= $rightColAlias;

      # do type conversion to ensure types are the same
      if ($leftType ne $rightType) {
        if ($$oq{dbtype} eq 'mysql') {
          $leftSql  = "CONCAT('', $leftSql)"  unless $leftType eq 'char';
          $rightSql = "CONCAT('', $rightSql)" unless $rightType eq 'char';
        } else {
          $leftSql  = "TO_CHAR($leftSql)"  unless $leftType eq 'char';
          $rightSql = "TO_CHAR($rightSql)" unless $rightType eq 'char';
        }
      }

      # if char ensure NULL is turned into empty string so comparison works
      if ($leftType eq 'char') {
        my $nullVal = $$oq{dbtype} eq 'Oracle' ? "'_ _'" : "''";
        $leftSql = "COALESCE($leftSql,$nullVal)";
        $rightSql = "COALESCE($rightSql,$nullVal)";
      }

      # handle case insensitivity
      if ($operatorName =~ /contains/i) {
        $operator = $operatorName =~ /not/i ? "NOT LIKE" : "LIKE";
        $leftSql  = "LOWER($leftSql)";
        $rightSql = "LOWER($rightSql)";
        $rightSql = $$oq{dbtype} eq 'Oracle' || $$oq{dbtype} eq 'SQLite'
          ? "'%'||$leftSql||'%'"
          : "CONCAT('%',$leftSql,'%')";
      }

      my $sql = '(' x $numLeftParen;
      $sql .= "$leftSql $operator $rightSql";
      $sql .= ')' x $numRightParen;

      # glue expression
      push @sql,   $sql;
      push @binds, @leftBinds, @rightBinds;
      push @name, $leftName,  $operatorName, $rightName;
      $deps{$_}=1  for @$leftDeps;
      $deps{$_}=1  for @$rightDeps;
    }
  }

  my @deps  = grep { $_ } keys %deps;
  my $sql   = join(' ', @sql);
  my $name  = join(' ', @name);

  # make sure parenthesis are balanced
  if ($parenthesis > 0) {
    my $p = ')' x $parenthesis;
    $sql .= $p;
    $name .= $p;
  }

  my %rv = ( sql => $sql, binds => \@binds, deps => \@deps, name => $name ); 
  return \%rv;
}


sub parseSort {
  my ($oq, $str) = @_;
  $str =~ /^\s+/;

  my (@sql, @binds, @name, %deps);

  while (1) {

    # parse named sort
    if ($str =~ /\G(\w+)\(\s*/gc) {
      my $namedSortAlias = $1;
      my @args;
      while (1) {
        if ($str =~ /\G\)\s*/gc) {
          last;
        }
        elsif ($str =~ /\G(\-?\d*\.\d+)\s*\,*\s*/gc ||
               $str =~ /\G(\-?\d+)\s*\,*\s*/gc      ||
               $str =~ /\G\'([^\']*)\'\s*\,*\s*/gc  ||
               $str =~ /\G\"([^\"]*)\"\s*\,*\s*/gc  ||
               $str =~ /\G(\w+)\s*\,*\s*/gc) {
          push @args, $1;
        } else {
          die "could not parse named sort arguments\n";
        }
      }
      my ($sortDeps, $sortSql, @sortBinds, $sortLabel);
       
      my $s = $$oq{named_sorts}{$namedSortAlias};
      if (ref($s) eq 'ARRAY') {
        ($sortDeps, $sortSql, $sortLabel) = @$s;
      } elsif (ref($s) eq 'HASH') {
        die "could not find sql_generator for named_srot $namedSortAlias\n"
          unless ref($$s{sql_generator}) eq 'CODE';
        ($sortDeps, $sortSql, $sortLabel) = @{ $$s{sql_generator}->(@args) };
        ($sortSql, @sortBinds) = @$sortSql if ref($sortSql) eq 'ARRAY';
      } else {
        die "invalid named_filter: $namedSortAlias\n";
      }

      push @sql,   $sortSql;
      push @binds, @sortBinds;
      push @name, $sortLabel; 
      $deps{$_} =1 for @$sortDeps;
    }

    # parse named sort
    elsif ($str =~ /\G\[?(\w+)\]?\s*/gc) {
      my $colAlias = $1;
      die "missing sort col: $colAlias\n" unless $$oq{select}{$colAlias};
      my @sortBinds;
      my ($sortDeps, $sortSql, $sortLabel, $opts) = @{ $$oq{select}{$colAlias} };
      $sortSql = $$opts{sort_sql} if $$opts{sort_sql};
      ($sortSql, @sortBinds) = @$sortSql if ref($sortSql) eq 'ARRAY';
      $sortLabel ||= $colAlias;

      if ($str =~ /\Gdesc\s*/gci) {
        $sortSql .= ' DESC';
        $sortLabel .= ' (reverse)';
      }

      push @sql,   $sortSql;
      push @binds, @sortBinds;
      push @name, $sortLabel; 
      $deps{$_} =1 for @$sortDeps;
    }

    elsif ($str =~ /\G$/gc) {
      last;
    }
    elsif ($str =~ /\G\,\s*/gc) {
      next;
    }
    else {
      die "could not parse sort\n";
    }
  }

  my @deps = grep { $_ } keys %deps;

  return { sql => \@sql, binds => \@binds, deps => \@deps, name => \@name };
}


# normalize member variables
sub _normalize {
  my $oq = shift;
  #$$oq{error_handler}->("DEBUG: \$oq->_normalize()\n") if $$oq{debug};

  $oq->{'AutoSetLongReadLen'} = 1 unless exists $oq->{'AutoSetLongReadLen'};

  # make sure all option hash refs exist
  $oq->{'select'}->{$_}->[3] ||= {} for keys %{ $oq->{'select'} };
  $oq->{'joins' }->{$_}->[3] ||= {} for keys %{ $oq->{'joins'}  };


  # since the sql & deps definitions can optionally be entered as arrays
  # turn all into arrays if not already
  for (  # key,   index
         ['select', 0], ['select', 1], 
         ['joins', 0], ['joins', 1], ['joins', 2], 
         ['named_filters', 0], ['named_filters', 1],
         ['named_sorts', 0], ['named_sorts', 1]       ) {
    my ($key, $i) = @$_;
    $oq->{$key} ||= {};
    foreach my $alias (keys %{ $oq->{$key} }) {
      if (ref($oq->{$key}->{$alias}) eq 'ARRAY' &&
          defined $oq->{$key}->{$alias}->[$i]   &&
          ref($oq->{$key}->{$alias}->[$i]) ne 'ARRAY') {
        $oq->{$key}->{$alias}->[$i] = [$oq->{$key}->{$alias}->[$i]]; 
      }
    }
  }

  # make sure the following select options, if they exist are array references
  foreach my $col (keys %{ $oq->{'select'} }) {
    my $opts = $oq->{'select'}->{$col}->[3];
    foreach my $opt (qw( select_sql sort_sql filter_sql )) {
      $opts->{$opt} = [$opts->{$opt}] 
        if exists $opts->{$opt} && ref($opts->{$opt}) ne 'ARRAY';
    }

    # make sure defined deps exist
    foreach my $dep (@{ $$oq{'select'}{$col}[0] }) {
      die "dep $dep for select $col does not exist" 
        if defined $dep && ! exists $$oq{'joins'}{$dep};
    }
  }

  # look for new cursors and define parent child links if not already defined
  foreach my $join (keys %{ $oq->{'joins'} }) {
    my $opts = $oq->{'joins'}->{$join}->[3];
    if (exists $opts->{new_cursor}) {
      if (ref($opts->{new_cursor}) ne 'HASH') {
        $oq->_formulate_new_cursor($join);
      } else {
        die "could not find keys, join, and sql for new cursor in $join"
          unless exists $opts->{new_cursor}->{'keys'} &&
                 exists $opts->{new_cursor}->{'join'} &&
                 exists $opts->{new_cursor}->{'sql'};
      }
    }

    # make sure defined deps exist
    foreach my $dep (@{ $$oq{'joins'}{$join}[0] }) {
      die "dep $dep for join $join does not exist" 
        if defined $dep && ! exists $$oq{'joins'}{$dep};
    }
  }

  # make sure deps for named_sorts exist
  foreach my $named_sort (keys %{ $$oq{'named_sorts'} }) {
    foreach my $dep (@{ $$oq{'named_sorts'}{$named_sort}->[0] }) {
      die "dep $dep for named_sort $named_sort does not exist"
        if defined $dep && ! exists $$oq{'joins'}{$dep};
    }
  }

  # make sure deps for named_filter exist
  foreach my $named_filter (keys %{ $$oq{'named_filters'} }) {
    if (ref($$oq{'named_filters'}{$named_filter}) eq 'ARRAY') {
      foreach my $dep (@{ $$oq{'named_filters'}{$named_filter}->[0] }) {
        die "dep $dep for named_sort $named_filter does not exist"
          if defined $dep && ! exists $$oq{'joins'}{$dep};
      }
    }
  }

  $oq->{'col_types'} = undef;

  return undef;
}







# defines how a child cursor joins to its parent cursor
# by defining keys, join, sql in child cursor
# called from the _normalize method
sub _formulate_new_cursor {
  my $oq = shift;
  my $joinAlias = shift; 

  #$$oq{error_handler}->("DEBUG: \$oq->_formulate_new_cursor('$joinAlias')\n") if $$oq{debug};

  # vars to define
  my (@keys, $join, $sql, @sqlBinds);

  # get join definition
  my ($fromSql,  @fromBinds)  = @{ $oq->{joins}->{$joinAlias}->[1] };

  my ($whereSql, @whereBinds);
  ($whereSql, @whereBinds) = @{ $oq->{joins}->{$joinAlias}->[2] }
    if defined $oq->{joins}->{$joinAlias}->[2];

  # if NOT an SQL-92 type join
  if (defined $whereSql) {
    $whereSql =~ s/\(\+\)/\ /g; # remove outer join notation
    die "BAD_PARAMS - where binds not allowed in 'new_cursor' joins"
      if scalar(@whereBinds);
  } 

  # else is SQL-92 so separate out joins from table definition
  # do this by making it a pre SQL-92 type join
  # by defining $whereSql
  # and removing join sql from $fromSql
  else {
    $_ = $fromSql;
    m/\G\s*left\b/sicg;
    m/\G\s*join\b/sicg;

    # parse inline view
    if (m/\G\s*\(/scg) {
      $fromSql = '(';
      my $p=1;
      my $q;
      while ($p > 0 && m/\G(.)/scg) {
        my $c = $1;
        if ($q) { $q = '' if $c eq $q; } # if end of quote
        elsif ($c eq "'" || $c eq '"') { $q = $c; } # if start of quote
        elsif ($c eq '(') { $p++; } # if left paren
        elsif ($c eq ')') { $p--; } # if right paren
        $fromSql .= $c;
      }
    }

    # parse table name
    elsif (m/\G\s*(\w+)\b/scg) {
      $fromSql = $1;
    }

    else {
      die "could not parse tablename";
    }

    # include alias if it exists
    if (m/\G\s*([\d\w\_]+)\s*/scg && lc($1) ne 'on') {
      $fromSql .= ' '.$1;
      m/\G\s*on\b/cgi;
    }

    # get the whereSql 
    if (m/\G\s*\((.*)\)\s*$/cgs) {
      $whereSql = $1;
    }
  }

  # define sql & sqlBinds
  $sql = $fromSql;
  @sqlBinds = @fromBinds;
    
  # parse $whereSql to create $join, and @keys
  foreach my $part (split /\b([\w\d\_]+\.[\w\d\_]+)\b/,$whereSql) {
    if ($part =~ /\b([\w\d\_]+)\.([\w\d\_]+)\b/) {
      my $dep = $1;
      my $sql = $2;
      if ($dep eq $joinAlias) {
        $join .= $part;
      } else {
        push @keys, [$dep, $sql];
        $join .= '?';
      }
    } else {
      $join .= $part;
    }
  }

  # fill in options
  $oq->{joins}->{$joinAlias}->[3]->{'new_cursor'} = {
    'keys' => \@keys, 'join' => $join, 'sql' => [$sql, @sqlBinds] };

  return undef;
}




# make sure the join counts are the same
# throws exception with error when there is a problem
# this can be an expensive wasteful operation and should not be done in a production env
sub check_join_counts {
  my $oq = shift;

  #$$oq{error_handler}->("DEBUG: \$oq->check_join_counts()\n") if $$oq{debug};


  # since driving table count is computed first this will get set first
  my $drivingTableCount;

  foreach my $join (keys %{ $oq->{joins} }) {
    my ($cursors) = $oq->_order_deps($join);
    my @deps = map { @$_ } @$cursors; # flatten deps in cursors
    my $drivingTable = $deps[0];

    # now create from clause
    my ($fromSql, @fromBinds, @whereSql, @whereBinds);
    foreach my $joinAlias (@deps) {
      my ($sql, @sqlBinds) = @{ $oq->{joins}->{$joinAlias}->[1] };

      # if this is the driving table
      if (! $oq->{joins}->{$joinAlias}->[0]) {
        # alias it if not already aliased in sql
        $fromSql .= " $joinAlias" unless $sql =~ /\b$joinAlias\s*$/;
      }

      # if NOT sql-92 join
      elsif (defined $oq->{joins}->{$joinAlias}->[2]) {
        $fromSql .= ",\n $sql $joinAlias";
        push @fromBinds, @sqlBinds;
        my ($where_sql, @where_sqlBinds) = @{ $oq->{joins}->{$joinAlias}->[2] };
        push @whereSql, $where_sql;
        push @whereBinds, @where_sqlBinds;
      } 

      # else this is an SQL-92 type join
      else {
        $fromSql .= "\n$sql ";
      }
    }

    my $where;
    $where = 'WHERE '.join("\nAND ", @whereSql) if @whereSql;

    my $sql = "
SELECT count(*)
FROM (
  SELECT $drivingTable.*
  FROM $fromSql
  $where 
) OPTIMALQUERYCNTCK ";
    my @binds = (@fromBinds,@whereBinds);
    my $count;
    eval { ($count) = $oq->{dbh}->selectrow_array($sql, undef, @binds); };
    die "Problem executing ERROR: $@\nSQL: $sql\nBINDS: ".join(',', @binds)."\n" if $@;
    $drivingTableCount = $count unless defined $drivingTableCount;
    confess "BAD_JOIN_COUNT - driving table $drivingTable count ".
      "($drivingTableCount) != driving table joined with $join".
      " count ($count)" if $count != $drivingTableCount;
  }

  return undef;
}



=comment
  $oq->get_col_type($alias,$context);
=cut
sub type_map {
  my $oq = shift;
  return {
  -1 => 'char',
  -2 => 'clob',
  -3 => 'clob',
  -4 => 'clob',
  -5 => 'num',
  -6 => 'num',
  -7 => 'num',
  -8 => 'char',
  -9 => 'char',
  0 => 'char',
  1 => 'char',
  2 => 'num',
  3 => 'num',    # is decimal type
  4 => 'num',
  5 => 'num',
  6 => 'num',    # float
  7  => 'num',
  8 => 'num',
  9 => 'date',
  10 => 'char',  # time (no date)
  11 => 'datetime',
  12 => 'char',
  16 => 'date',
  30 => 'clob',
  40 => 'clob',
  91 => 'date',
  93 => 'datetime',
  95 => 'date',
  'TIMESTAMP' => 'datetime',
  'INTEGER' => 'num',
  'TEXT' => 'char',
  'VARCHAR' => 'char',
  'varchar' => 'char'
  };
}

# $type = $oq->get_col_type($alias,$context);
sub get_col_type {
  my $oq = shift;
  my $alias = shift;
  my $context = shift || 'default';
  #$$oq{error_handler}->("DEBUG: \$oq->get_col_type($alias, $context)\n") if $$oq{debug};

  return $oq->{'select'}->{$alias}->[3]->{'col_type'} ||
         $oq->get_col_types($context)->{$alias};
}

#{ ColAlias => Type, .. } = $oq->get_col_types($context)
# where $content in ('default','sort','filter','select')
sub get_col_types {
  my $oq = shift;
  my $context = shift || 'default';
  #$$oq{error_handler}->("DEBUG: \$oq->get_col_types($context)\n") if $$oq{debug};
  return $oq->{'col_types'}->{$context} 
    if defined $oq->{'col_types'};

  $oq->{'col_types'} = { 
    'default' => {}, 'sort' => {}, 
    'filter' => {}, 'select' => {} };

  my (%deps, @selectColTypeOrder, @selectColAliasOrder, @select, @selectBinds, @where);
  foreach my $selectAlias (keys %{ $oq->{'select'} } ) {
    my $s = $oq->{'select'}->{$selectAlias};

    # did user already define this type?
    if (exists $s->[3]->{'col_type'}) {
      $oq->{'col_types'}->{'default'}->{$selectAlias} = $s->[3]->{'col_type'};
      $oq->{'col_types'}->{'select' }->{$selectAlias} = $s->[3]->{'col_type'};
      $oq->{'col_types'}->{'filter' }->{$selectAlias} = $s->[3]->{'col_type'};
      $oq->{'col_types'}->{'sort'   }->{$selectAlias} = $s->[3]->{'col_type'};
    } 

    # else write sql to determine type with context
    else {
      $deps{$_} = 1 for @{ $s->[0] };

      foreach my $type (
           ['default', $s->[1]],
           ['select',  $s->[3]->{'select_sql'}],
           ['filter',  $s->[3]->{'filter_sql'}],
           ['sort',    $s->[3]->{'sort_sql'}]   ) {
        next if ! defined $type->[1];
        push @selectColTypeOrder, $type->[0]; 
        push @selectColAliasOrder, $selectAlias; 
        my ($sql, @binds) = @{ $type->[1] };
        push @select, $sql;
        push @selectBinds, @binds;

        # this next one is needed for oracle so inline views don't get processed
        # kinda stupid if you ask me
        # don't bother though if there is binds
        # this isn't neccessary for mysql since an explicit limit is
        # defined latter
        if ($$oq{dbtype} eq 'Oracle' && $#binds == -1) {
          push @where, "to_char($sql) = NULL";
        }
      }
    }
  }

  # are there unknown deps?
  if (%deps) {

    # order and flatten deps
    my @deps = keys %deps;
    my ($deps) = $oq->_order_deps(@deps);


    @deps = ();
    push @deps, @$_ for @$deps;

    # now create from clause
    my ($fromSql, @fromBinds);
    foreach my $joinAlias (@deps) {
      my ($sql, @sqlBinds) = @{ $oq->{joins}->{$joinAlias}->[1] }; 
      push @fromBinds, @sqlBinds;

      # if this is the driving table join
      if (! $oq->{joins}->{$joinAlias}->[0]) {

        # alias it if not already aliased in sql
        $fromSql .= $sql;
        $fromSql .= " $joinAlias" unless $sql =~ /\b$joinAlias\s*$/;
      }

      # if NOT sql-92 join
      elsif (defined $oq->{joins}->{$joinAlias}->[2]) {
        $fromSql .= ",\n $sql $joinAlias";
      }

      # else this is an SQL-92 type join
      else {
        $fromSql .= "\n$sql ";
      }

    }

    my $where;
    $where .= "\nAND " if $#where > -1;
    $where .= join("\nAND ", @where);

    my @binds = (@selectBinds, @fromBinds); 
    my $sql = "
SELECT ".join(',', @select)."
FROM $fromSql";

    if ($$oq{dbtype} eq 'Oracle' || $$oq{dbtype} eq 'Microsoft SQL Server') {
      $sql .= "
WHERE 1=2
$where ";
    } 

    elsif ($$oq{dbtype} eq 'mysql') {
      $sql .= "
LIMIT 0 ";
    }

    my $sth;
    eval {
      local $oq->{dbh}->{PrintError} = 0;
      local $oq->{dbh}->{RaiseError} = 1;
      $sth = $oq->{dbh}->prepare($sql);
      $sth->execute(@binds);
    }; if ($@) {
      confess "SQL Error in get_col_types:\n$@\n$sql\n(".join(",",@binds).")";
    }

    # read types into col_types cache in object
    my $type_map = $oq->type_map();
    for (my $i=0; $i < scalar(@selectColAliasOrder); $i++) {
      my $name = $selectColAliasOrder[$i];
      my $type_code = $sth->{TYPE}->[$i];

      # remove parenthesis in type_code from sqlite
      $type_code =~ s/\([^\)]*\)//;
 
      my $type = $type_map->{$type_code} or 
        die "could not find type code: $type_code for col $name";
      $oq->{'col_types'}->{$selectColTypeOrder[$i]}->{$name} = $type;

      # set the type for select, filter, and sort to the default
      # unless they are already defined
      if ($selectColTypeOrder[$i] eq 'default') {
        $oq->{'col_types'}->{'select' }->{$name} ||= $type;
        $oq->{'col_types'}->{'filter' }->{$name} ||= $type;
        $oq->{'col_types'}->{'sort'   }->{$name} ||= $type;
      }
    }

    $sth->finish();
  }

  return $oq->{'col_types'}->{$context};
}




# prepare an sth
sub prepare {
  my $oq = shift;
  #$$oq{error_handler}->("DEBUG: \$oq->prepare(".Dumper(\@_).")\n") if $$oq{debug};
  return DBIx::OptimalQuery::sth->new($oq,@_); 
}



# returns ARRAYREF: [order,idx]
# order is [ [dep1,dep2,dep3], [dep4,dep5,dep6] ], # cursor/dep order
# idx is { dep1 => 0, dep4 => 1, .. etc ..  } # index of what cursor dep is in
sub _order_deps {
  my ($oq, @deps) = @_;
  #$$oq{error_handler}->("DEBUG: \$oq->_order_deps(".Dumper(\@_).")\n") if $$oq{debug};

  # add always_join deps
  foreach my $joinAlias (keys %{ $$oq{joins} }) {
    push @deps, $joinAlias if $$oq{joins}{$joinAlias}[3]{always_join};
  }

  # @order is an array of array refs. Where each array ref represents deps
  # for a separate cursor
  # %idx is a hash of scalars where the hash key is the dep name and the
  # hash value is what index into order (which cursor number)
  # where you find the dep
  my (@order, %idx);

  # var to detect infinite recursion
  my $maxRecurse = 1000;

  # recursive function to order deps
  # each dep calls this again on all parent deps until all deps are fulfilled
  # then the dep is added
  # modfies @order & %idx 
  my $place_missing_deps;
  $place_missing_deps = sub {
    my ($dep) = @_;

    # detect infinite recursion
    $maxRecurse--;
    die "BAD_JOINS - could not link joins to meet all deps" if $maxRecurse == 0;

    # recursion to make sure parent deps are added first
    if (defined $oq->{'joins'}->{$dep}->[0]) {
      foreach my $parent_dep (@{ $oq->{'joins'}->{$dep}->[0] } ) {
        $place_missing_deps->($parent_dep) if ! exists $idx{$parent_dep};
      }
    }

    # at this point all parent deps have been added,
    # now add this dep if it has not already been added
    if (! exists $idx{$dep}) {

      # add new cursor if dep is main driving table or has option new_cursor
      if (! defined $oq->{'joins'}->{$dep}->[0] ||
          exists $oq->{'joins'}->{$dep}->[3]->{new_cursor}) {
        push @order, [$dep];
        $idx{$dep} = $#order;
      }

      # place dep in @order & %idx
      # uses the same cursor as its parent dep
      # this is found by looking at the parent_idx
      else {
        my $parent_idx = $idx{$oq->{'joins'}->{$dep}->[0]->[0]} || 0;
        push @{ $order[ $parent_idx ] }, $dep; 
        $idx{$dep} = $parent_idx;
      }
    }
    return undef;
  };

  $place_missing_deps->($_) for @deps;

  return (\@order, \%idx);
}


1;
