package  # hide from PAUSE
  CellBIS::SQL::Abstract::Table;
use Mojo::Base -base;

use Scalar::Util qw(blessed);
use Mojo::Util qw(trim);
use Hash::MultiValue;

# For Foreign Key Validator:
# ------------------------------------------------------------------------
sub fk_validator {
  my ($table_attr, $col_attr) = @_;
  my %fk_attr = (
    name         => 0,
    col_name     => 0,
    table_target => 0,
    col_target   => 0,
  );
  
  my $fk = $table_attr->{fk};
  if (exists $fk->{name} && $fk->{name} ne '') {
    $fk_attr{name} = 1;
  }
  if (exists $fk->{col_name} && $fk->{col_name} ne '') {
    $fk_attr{col_name} = 1;
  }
  
  if (exists $fk->{table_target} && $fk->{table_target} ne '') {
    $fk_attr{table_target} = 1;
  }
  
  if (exists $fk->{col_target} && $fk->{col_target} ne '') {
    $fk_attr{col_target} = 1;
  }
  my @r_val = grep {!$_} values %fk_attr;
  my $size_result = scalar @r_val;
  
  if ($size_result >= 1) {
    my $new_TableAttr = Hash::MultiValue->new(%{$table_attr});
    $new_TableAttr->remove('fk');
    $table_attr = $new_TableAttr->as_hashref;
  }
  else {
    unless (exists $col_attr->{$fk->{col_name}}) {
      my $new_TableAttr = Hash::MultiValue->new(%{$table_attr});
      $new_TableAttr->remove('fk');
      $table_attr = $new_TableAttr->as_hashref;
    }
  }
  return $table_attr;
}

# For Foreign key attribute :
# ------------------------------------------------------------------------
sub fk_attr_validator {
  my ($fk_table) = @_;
  my $data = '';
  my %ondelup = (
    'cascade' => 'CASCADE',
    'null'    => 'SET NULL',
    'default' => 'SET DEFAULT'
  );
  my %data_fk = (
    'ondel' => 0,
  );
  if (exists $fk_table->{ondelete}) {
    if (exists $ondelup{(lc $fk_table->{ondelete})}) {
      $data_fk{'ondel'} = 1;
      $data .= 'ON DELETE ' . $ondelup{(lc $fk_table->{ondelete})};
    }
  }
  
  if (exists $fk_table->{onupdate}) {
    if (exists $ondelup{(lc $fk_table->{onupdate})}) {
      $data .= ' ' if $data_fk{'ondel'} == 1;
      $data .= 'ON UPDATE ' . $ondelup{(lc $fk_table->{onupdate})};
    }
  }
  $data = trim($data);
  return $data;
}

# For Table Attribute Validator :
# ------------------------------------------------------------------------
sub table_attr_val {
  my $self = shift;
  my ($col_attr, $table_attr) = @_;
  my $new_tblAttr = {};
  my $attrib_table = '';
  
  if (exists $table_attr->{fk}) {
    $table_attr = fk_validator($table_attr, $col_attr);
    my $table_fk = '';
    if (exists $table_attr->{fk}) {
      my $fk_table = $table_attr->{fk};
      my $fk_name = $fk_table->{name};
      my $col_name = $fk_table->{col_name};
      my $table_target = $fk_table->{table_target};
      my $col_target = $fk_table->{col_target};
      my $fk_attr = '';
      if ($fk_table->{attr}) {
        $fk_attr = fk_attr_validator($fk_table->{attr});
      }
      $table_fk .= "\tKEY " . $fk_name . " ($col_name), \n";
      $table_fk .= "\tCONSTRAINT $fk_name ";
      $table_fk .= "FOREIGN KEY ($col_name) ";
      $table_fk .= "REFERENCES $table_target ($col_target)\n" if $fk_attr eq '';
      $table_fk .= "REFERENCES $table_target ($col_target) \n\t$fk_attr\n" unless $fk_attr eq '';
      
      my $new_attrTbl = Hash::MultiValue->new(%{$table_attr});
      $new_attrTbl->set(fk => $table_fk);
      $table_attr = $new_attrTbl->as_hashref;
    }
  }
  if (exists $table_attr->{index}) {
    if (ref($table_attr->{index}) eq "ARRAY" and (scalar @{$table_attr->{index}}) > 0) {
      my $table_index = join ',', @{$table_attr->{index}};
      $table_index = 'INDEX (' . $table_index . ')';
      my $new_attrTbl = Hash::MultiValue->new(%{$table_attr});
      $new_attrTbl->set(index => $table_index);
      $table_attr = $new_attrTbl->as_hashref;
    }
  }
  my %tbl_attr = (
    engine => 0,
  );
  if (exists $table_attr->{engine}) {
    $tbl_attr{engine} = 1;
    my $r_engine = check_engine($table_attr->{engine});
    $attrib_table .= 'ENGINE=' . $r_engine;
  }
  if (exists $table_attr->{charset}) {
    $attrib_table .= ' ' if ($tbl_attr{engine} == 1);
    $attrib_table .= 'DEFAULT CHARSET=' . $table_attr->{charset};
  }
  $new_tblAttr = Hash::MultiValue->new(%{$table_attr});
  $new_tblAttr->set(attr => $attrib_table);
  $table_attr = $new_tblAttr->as_hashref;
  
  return $table_attr;
}

# For Column Attribute validator :
# ------------------------------------------------------------------------
sub table_col_attr_val {
  my $self = shift;
  my ($col_list, $col_attr) = @_;
  
  if (ref($col_attr) eq "HASH") {
    my $i = 0;
    my $until = scalar @{$col_list};
    my @pk_list = ();
    my @ai_list = ();
    my $size_pk = 0;
    my $size_ai = 0;
    my $col_name = '';
    my $curr_colAttr = {};
    my $new_colAttr = Hash::MultiValue->new(%{$col_attr});
    while ($i < $until) {
      $col_name = $col_attr->{$col_list->[$i]};
      if (exists $col_name->{'is_autoincre'}) {
        $size_ai = ($size_ai + 1);
        push @ai_list, $col_list->[$i];
        $curr_colAttr = Hash::MultiValue->new(%{$col_name});
        $curr_colAttr->remove('is_autoincre');
        
        $new_colAttr->set($col_list->[$i] => $curr_colAttr->as_hashref);
      }
      $i++;
    }
    $col_attr = $new_colAttr->as_hashref;
    
    $i = 0;
    while ($i < $until) {
      $col_name = $col_attr->{$col_list->[$i]};
      if (exists $col_name->{'is_primarykey'}) {
        $size_pk = ($size_pk + 1);
        push @pk_list, $col_list->[$i];
        $curr_colAttr = Hash::MultiValue->new(%{$col_name});
        $curr_colAttr->remove('is_primarykey');
        
        $new_colAttr->set($col_list->[$i] => $curr_colAttr->as_hashref);
      }
      $i++;
    }
    
    if ($size_pk >= 1) {
      my $r_colAttr = $new_colAttr->as_hashref;
      my $pk_table = $r_colAttr->{$pk_list[0]};
      
      $curr_colAttr = Hash::MultiValue->new(%{$pk_table});
      $curr_colAttr->set('is_primarykey' => 1);
      
      $col_attr = Hash::MultiValue->new(%{$r_colAttr});
      $col_attr->set($pk_list[0] => $curr_colAttr->as_hashref);
      $col_attr = $col_attr->as_hashref;
    }
    
    if ($size_ai >= 1) {
      my $pk_table = $col_attr->{$pk_list[0]};
      
      $curr_colAttr = Hash::MultiValue->new(%{$pk_table});
      $curr_colAttr->set('is_autoincre' => 1);
      
      $col_attr = Hash::MultiValue->new(%{$col_attr});
      $col_attr->set($pk_list[0] => $curr_colAttr->as_hashref);
      $col_attr = $col_attr->as_hashref;
    }
    
    $i = 0;
    $new_colAttr = Hash::MultiValue->new();
    while ($i < $until) {
      $col_name = $col_attr->{$col_list->[$i]};
      
      $new_colAttr->add($col_list->[$i] => $col_name);
      $i++;
    }
    $col_attr = $new_colAttr->as_hashref;
  }
  return $col_attr;
}

# For Default field table :
# ------------------------------------------------------------------------
sub default_field_tbl_val {
  my ($type, $attr) = @_;
  my $data = '';
  if ($type eq 'datetime') {
    if ($attr == 1) {
      $data = "CURRENT_TIMESTAMP";
    }
    if ($attr eq 'yes') {
      $data = "CURRENT_TIMESTAMP";
    }
  }
  return $data;
}

# For Create Column Attr :
# ------------------------------------------------------------------------
sub create_colAttr {
  my $self = shift;
  my ($col_name, $attr, $db_type) = @_;
  my $data = $col_name . ' ';
  
  if (exists $attr->{type}) {
    $data .= (uc $attr->{type}->{name}) . '' if (exists $attr->{type}->{name});
    $data .= 'col1' unless (exists $attr->{type}->{name});
    
    $data .= '(' . $attr->{type}->{size} . ') ' if (exists $attr->{type}->{size});
    $data .= ' ' unless (exists $attr->{type}->{size});
  }
  
  unless (exists $attr->{custom}) {
    if (exists $attr->{default} and $attr->{default} ne '') {
      if (exists $attr->{onupdate} and $attr->{onupdate} ne '') {
        my $field_default_val = default_field_tbl_val($attr->{type}->{name}, $attr->{onupdate});
        $data .= "ON UPDATE $field_default_val ";
      }
      else {
        $data .= "DEFAULT $attr->{default} ";
      }
    }
    
    if (exists $attr->{onupdate} and $attr->{onupdate} ne '') {
      my $field_default_val = default_field_tbl_val($attr->{type}->{name}, $attr->{onupdate});
      $data .= "ON UPDATE $field_default_val ";
    }
    
    if (exists $attr->{is_null}) {
      $data .= 'NOT NULL ' if $attr->{is_null} eq 0;
      $data .= 'NULL ' if $attr->{is_null} eq 1;
    }
    else {
      $data .= 'NOT NULL ';
    }
    
    if (exists $attr->{is_primarykey} and $attr->{is_primarykey} == 1) {
      $data .= 'PRIMARY KEY ';
    }
    
    if (exists $attr->{is_autoincre} and $attr->{is_autoincre} == 1) {
      if ($db_type eq 'sqlite') {
        $data .= 'AUTOINCREMENT ';
      }
      else {
        $data .= 'AUTO_INCREMENT ';
      }
    }
  }
  else {
    $data .= $attr->{custom};
  }
  $data = trim($data);
  $data = "\t$data";
  return $data;
}

# For create query table :
# ------------------------------------------------------------------------
sub create_query_table {
  my $self = shift;
  my $arg_len = scalar @_;
  my ($table_name, $col_list, $col_attr, $table_attr, $db_type);
  my $data = '';
  my $size_tblAttr = 0;
  $db_type = 'mysql';
  
  if ($arg_len == 3) {
    ($table_name, $col_list, $col_attr) = @_;
  }
  
  if ($arg_len == 4) {
    ($table_name, $col_list, $col_attr, $table_attr) = @_;
    if (ref($table_attr) eq "HASH") {
      $size_tblAttr = scalar keys %{$table_attr};
    } else {
      $table_attr = {};
    }
  }
  
  if ($arg_len >= 5) {
    ($table_name, $col_list, $col_attr, $table_attr, $db_type) = @_;
    $size_tblAttr = scalar keys %{$table_attr};
  }
  
  $col_attr = $self->table_col_attr_val($col_list, $col_attr);
  $table_attr = $self->table_attr_val($col_attr, $table_attr);
  
  my $size_col = scalar @{$col_list};
  my $i = 0;
  my @list_col = ();
  while ($i < $size_col) {
    if ($db_type ne '') {
      push @list_col, $self->create_colAttr($col_list->[$i], $col_attr->{$col_list->[$i]}, $db_type);
    }
    else {
      push @list_col, $self->create_colAttr($col_list->[$i], $col_attr->{$col_list->[$i]}, 'mysql');
    }
    $i++;
  }
  my $list_column = join ",\n", @list_col;
  my $fk_table = '';
  my $index_table = '';
  my $attr_table = '';
  
  $data .= "CREATE TABLE IF NOT EXISTS $table_name(\n";
  
  if ($size_tblAttr != 0) {
    $data .= "$list_column";
    my $size_fk = 0;
    if (exists $table_attr->{fk}) {
      $size_fk = 1;
      $fk_table = $table_attr->{fk};
      $data .= ",\n$fk_table";
    }
    if (exists $table_attr->{index}) {
      $index_table = $table_attr->{index};
      $data .= ",\n$index_table";
    }
    if (exists $table_attr->{attr} and $table_attr->{attr} ne '') {
      if ($size_fk == 1) {
        $attr_table = $table_attr->{attr};
        $data .= ") $attr_table";
      }
      else {
        $data .= $db_type eq 'sqlite' ? ")" : ") ENGINE=InnoDB DEFAULT CHARSET=utf8";
      }
    }
    else {
      $data .= $db_type eq 'sqlite' ? ")" : ") ENGINE=InnoDB DEFAULT CHARSET=utf8";
    }
    
  }
  else {
    $data .= "$list_column\n";
    $data .= $db_type eq 'sqlite' ? ")" : ") ENGINE=InnoDB DEFAULT CHARSET=utf8";
  }
  return $data;
}

#######################################################################################
# FOR Helper
#######################################################################################

# For check engine :
# ------------------------------------------------------------------------
sub check_engine {
  my ($engine) = @_;
  $engine = lc $engine;
  my %list_engine = (
    'myisam' => 'MyISAM',
    'innodb' => 'InnoDB',
  );
  
  if (exists $list_engine{$engine}) {
    return $list_engine{$engine};
  }
  else {
    return $list_engine{'innodb'};
  }
}

1;
