package AutoSQL::SQLGenerator;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
our $category_scale_map = {
    c => {
        8=>'CHAR',
        16=>'TEXT',
        24=>'MEDIUMTEXT',
        32=>'LONGTEXT',
    },
    v=>{8=>'VARCHAR'},
    
    i=>{
        8=>'TINYINT',
        16=>'SMALLINT',                                       
        24=>'MEDIUMINT',                                      
        32=>'INT',                                            
        64=>'BIGINT'
    },           
    f=>{                                                      
        24=>'FLOAT',
        53=>'DOUBLE'
    },                                                        
    t=>{                                                      
        1=>'TIME',                                            
        2=>'DATE',                                            
        3=>'DATETIME',                                        
        4=>'TIMESTAMP'                                        
    },                                                        
};  

sub _initialize { }


sub generate_table_sql {
    my $self=shift;
    my $schema=shift;
    my %tables=$self->_get_tables_from_schema($schema);
    my @sql;
    foreach my $table (sort keys %tables){
        my %table=%{$tables{$table}};
        my @column_sql;
        push @column_sql , "${table}_id INT UNSIGNED NOT NULL AUTO_INCREMENT";
        my @fks;

        foreach my $column (keys %table){
            local $_ = $table{$column};
            if(s/^!//g){
                push @fks, ($column. ((length)?'':'_id'));
            }
            push @column_sql,
                (length)?"$column $_":"${column}_id INT UNSIGNED NOT NULL";
        }

        push @column_sql, "PRIMARY KEY (${table}_id)";
        push @column_sql, map{"KEY ($_)"}@fks;
        my $sql = join(",\n", map{ ' 'x4 . $_} @column_sql); # s/\n/\n    /g;
        $sql = "CREATE TABLE $table (\n".$sql;                
        $sql .="\n)\n";                               
        push @sql, $sql;
    } 
    # Make the joint tables
    foreach my $friend (sort $schema->get_friends){
        $friend =~ s/;$//;
        my @columns = split /;/, $friend;
        my @pair=split /-/, shift @columns;

    }
    return @sql;                                              
}

sub _get_tables_from_schema {
    my ($self, $schema)=@_;
    my %tables;
    foreach my $type($schema->get_all_types){
        my $module = $schema->get_table_model($type);
        next if $module->get_directive_attribute('$tablized') == -1;
        my $table_name=$module->table_name;
#        $self->throw("$table_name has existed")if exists $tables{$table_name};
        $tables{$table_name}={} unless exists $tables{$table_name};
        foreach($module->get_scalar_attributes){
            my ($context, $kind, $content, $required) =
                $module->_classify_value_attribute($_);
            if($kind eq'M'){
                # This is 1-to-0-or-1 parent-child relationship.
                # Child table should have a parent_id.
                # $datatype_sql='!';
                my $ref_table=$schema->get_table_model($content)->table_name;
                $tables{$ref_table}={} unless exists $tables{$ref_table};
                $tables{$ref_table}->{$table_name}='!';
            }else{
                my $datatype_sql;
                if($kind eq'P'){
                    $datatype_sql = $self->_translate_datatype($content);
                }elsif($kind eq'E'){
                    $datatype_sql=$self->_translate_enum($content);
                }
            
                $tables{$table_name}->{$_}=
                    $datatype_sql .($required?' NOT NULL':'');
            }
        }
        foreach my $attr ($module->get_array_attributes){
            my ($context, $kind, $content, $required) =
                $module->_classify_value_attribute($attr);
            if($kind eq 'P'){
                my $joint_table="$table_name\_$attr";
                $tables{$joint_table}={};
                $tables{$joint_table}->{$table_name}='!';
                $tables{$joint_table}->{$attr}=
                    $self->_translate_datatype($content);
            }elsif($kind eq 'M'){
                my $ref_table= $schema->get_table_model($content)->table_name;
                $tables{$ref_table}={} unless exists $tables{$ref_table};
                $tables{$ref_table}->{$table_name}='!';
                
            }
        }
    } # foreach $type

    foreach my $friendship ($schema->get_friendships){
        my @peers = $friendship->get_peers;
        my @peer_names=map{$schema->get_table_model($_)->table_name;}@peers;
        my $table_name=join '_', @peer_names;
        my %friendship_table;
#        $friendship_table{$table_name}='!';
        map{$friendship_table{"$_\_id"}='!';}@peer_names;
        
        $friendship_table{'junkSeeSQLGenerator'.__LINE__}='INT';
        $tables{$table_name}=\%friendship_table;
        
    }
    
    return %tables;
}

sub _translate_enum {
    my ($self, $enum)=@_;
    return 'ENUM('. join(', ', map {"'$_'"} split "\s", $enum) .')';
}

sub _translate_datatype {
    my ($self, $datatype)=@_;
    $self->throw("[$datatype] does not match the pattern")
        unless my ($category, undef, $precision, $scale, $unsigned) = 
            $datatype =~ /^([CVIDFTcvidft])(([\+\^]?[\d]+)(\.\d+)?)?([U|u]?)$/;
    $self->throw("cvt should not come with u")
        if($category =~ /[cvt]/ and $unsigned);
    return $self->__translate_time_datatype($precision) if $category eq 't';
    if ($precision){
        $precision=~s/^\^/2**/;
        $precision=~s/^\+/10**/;
        $precision = eval $precision;
    }else{
        $precision=8;
    }
    my $precision_scale = log($precision)/log(2);
    $precision_scale = $self->_floor($precision_scale);

    $self->throw("[$category,$precision_scale] does not exists")
    unless exists $category_scale_map->{$category}->{$precision_scale};
    my $type = $category_scale_map->{$category}->{$precision_scale};
    if($type eq 'CHAR'){$type .= "($precision)";}
    if($type eq 'VARCHAR'){$type .="($precision)";}
    return $type . ($unsigned?' UNSIGNED':'');
}

sub __translate_time_datatype {
    my ($self, $precision)=@_;
    $precision ||= 3;
    return $category_scale_map->{t}->{$precision};
}

sub _floor {
    my ($self, $v)=@_;
    if($v<8){$v=8;}
    elsif($v<16){$v=16;}
    elsif($v<24){$v=24;}
    elsif($v<32){$v=32;}
    elsif($v<64){$v=64;}
    return $v;
}

sub _precision_scale_2_prefix {
    my ($self, $scale, $category)=@_;
    my $prefix;
    if($scale <8){ $prefix ='TINY';
    }elsif($scale<16){ $prefix = 'SMALL';
    }elsif($scale<24){$prefix='MEDIUM';
    }elsif($scale<32){$prefix='';
    }elsif($scale<64){$prefix=($category eq'C')?'LONG':'BIG';
    }else{ $self->throw('scale is bigger than 64'); }
    return $prefix;
}

1;

