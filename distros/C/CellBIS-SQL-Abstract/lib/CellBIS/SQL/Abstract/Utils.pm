package  # hide from PAUSE
  CellBIS::SQL::Abstract::Utils;

use Mojo::Base -base;
use Mojo::Util 'dumper';

# For "column" with "value" :
# ------------------------------------------------------------------------
sub col_with_val {
  my $self = shift;
  my ($column, $value) = @_;
  
  my @data_col = @{$column};
  my @data_val = @{$value};
  my @data = map {$data_col[$_] . '=' . $data_val[$_]} 0 .. $#data_col;
  return @data;
}

# For onjoin clause :
# ------------------------------------------------------------------------
sub for_onjoin {
  my $self = shift;
  my ($options, $table_name) = @_;
  my $data = "FROM " . $table_name->[0]->{name};
  
  my %type = %{$options->{typejoin}};
  my $join = $options->{join};
  my $size_join = @{$join};
  
  my @table_list = @{$table_name};
  my %list_table = map {$_->{name} => $_} @{$table_name};
  my @get_primaryTbl = grep {$_->{primary} && $_->{primary} == 1} @table_list;
  @get_primaryTbl = @get_primaryTbl ? @get_primaryTbl : ($table_list[0]);
  
  # Check IF founded primary table :
  if (@get_primaryTbl) {
    my $tbl_name = '';
    my $tbl_alias = '';
    my $get_table_data = '';
    
    # For "FROM TABLE"
    $data = "FROM $get_primaryTbl[0]->{name}";
    if (exists $get_primaryTbl[0]->{alias}) {
      $data = "FROM $get_primaryTbl[0]->{name} AS $get_primaryTbl[0]->{alias}";
    }
    
    my $i = 0;
    my $table_join = '';
    my $type_join = '';
    while ($i < $size_join) {
      my $get_table = $join->[$i];
      $tbl_name = $get_table->{name};
      $table_join = $get_table->{onjoin};
      $get_table_data = $list_table{$tbl_name};
      $type_join = $self->type_join($type{$tbl_name});
      
      if (exists $get_table_data->{alias}) {
        $tbl_alias = $get_table_data->{alias};
        $data .= " $type_join $tbl_name AS $tbl_alias ";
        $data .= 'ON ' if ($i > 1 or $i <= ($size_join - 1));
        $data .= join " = ", @$table_join;
      }
      else {
        $data .= " $type_join $tbl_name ";
        $data .= 'ON ' if ($i > 1 or $i <= ($size_join - 1));
        $data .= join " = ", @$table_join;
      }
      
      $i++;
    }
  }
  return $data;
}

# For create clause query :
# ------------------------------------------------------------------------
sub create_clause {
  my ($self, $clause) = @_;
  my $data = '';
  if (exists $clause->{'where'}) {
    $data .= ' WHERE ' . $clause->{'where'};
  }
  if (exists $clause->{'orderby'} and not exists $clause->{'groupby'}) {
    $data .= ' ORDER BY ' . $clause->{'orderby'};
  }
  if (exists $clause->{'orderby'} and exists $clause->{'groupby'}) {
    $data .= ' GROUP BY ' . $clause->{'groupby'} . ' ORDER BY ' . $clause->{'orderby'};
  }
  if (exists $clause->{'order'} and exists $clause->{orderby}) {
    $data .= ' ' . (uc $clause->{'order'});
  }
  if (exists $clause->{'limit'}) {
    $data .= ' LIMIT ' . $clause->{'limit'};
  }
  return $data;
}

# for Type Join :
# ------------------------------------------------------------------------
sub type_join {
  my ($self, $type) = @_;
  
  my %data_type = (
    'left'  => 'LEFT JOIN',
    'inner' => 'INNER JOIN',
  );
  return $data_type{$type} if exists $data_type{$type};
}

# For replace data values "insert" :
# ------------------------------------------------------------------------
sub replace_data_value_insert {
  my $self = shift;
  my ($data_value) = @_;
  
  my @data = @{$data_value};
  my @result = map {$_ eq 'NOW()' ? 'NOW()' : '?'} @data;
  @result = grep (defined, @result);
  return @result;
}

1;
