#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
package Catalog::tools::hook_fulcrum;
use vars qw(@ISA $MAXCHAR $MAXFIELD);
use strict;

#
# Maximum length of a varchar type
#
$MAXCHAR = 32767;
#
# Maximum length of a field name
#
$MAXFIELD = 18;

use Catalog::tools::fulcrum;
use Catalog::tools::cgi;
use Catalog::tools::tools;

@ISA = qw(Catalog::tools::fulcrum);

sub initialize {
    my($self) = @_;

    $self->Catalog::tools::fulcrum::initialize();

    my($config) = config_load("hook_fulcrum.conf");
    error("missing hook_fulcrum.conf") if(!defined($config));
    %$self = ( %$self , %$config );
    $config = config_load("ecila.conf");
    error("missing ecila.conf") if(!defined($config));
    %$self = ( %$self , %$config );
}

sub mysql {
    my($self, $mysql) = @_;
    $self->{'mysql'} = $mysql;
}

sub hook_delete {
    my($self, $table, $primary_values) = @_;
    my($mysql) = $self->{'mysql'};

    my($spec) = $self->{$mysql->{'base'}};
    return if(!exists($spec->{'tables'}->{$table}));

    my($fulcrum_table) = $spec->{'params'}->{'table'};

    my($count) = 0;
    my($chunksize) = $self->{'chunksize'};
    my($chunk);
    while(@$primary_values) {
	my(@chunk) = splice(@$primary_values, $count, $chunksize);
	$count += scalar(@chunk);
	my($list) = join(',', @chunk);
	$self->exec("delete from $fulcrum_table where r_$table in ($list)");
    }
}

#
# Since fulcrum reindexes everything each time we change
# a field in a row, don't bother to make an update. Just 
# delete and insert again.
#
sub hook_update {
    my($self, $table, $primary_values) = @_;
    my($mysql) = $self->{'mysql'};

    my($spec) = $self->{$mysql->{'base'}};
    my($fulcrum_table) = $spec->{'params'}->{'table'};
    return if(!exists($spec->{'tables'}->{$table}));

    my($count) = 0;
    my($chunksize) = $self->{'chunksize'};
    my($chunk);
    while(@$primary_values) {
	my(@chunk) = splice(@$primary_values, $count, $chunksize);
	$count += scalar(@chunk);
	my($list) = join(',', @chunk);
	$self->exec("delete from $fulcrum_table where r_$table in ($list)");
	my($primary_value);
	foreach $primary_value (@chunk) {
	    $self->hook_insert($table, $primary_value);
	}
    }
}

sub hook_insert_prepare {
    my($self, $table, $primary_value, $fields_limit) = @_;
    my($mysql) = $self->{'mysql'};

    #
    # General information
    #
    my($spec) = $self->{$mysql->{'base'}};
    return if(!exists($spec->{'tables'}->{$table}));
    my($info) = $mysql->info_table($table);
    my($primary_key) = $info->{'_primary_'};
    my($spec_params) = $spec->{'tables'}->{$table}->{'params'};
    #
    # Extract row
    #
    my($where) = $spec_params->{'where'};
    if(defined($where)) {
	$where = "and ( $where )";
    } else {
	$where = '';
    }
    my($sql) = "select $primary_key from $table where $primary_key = $primary_value $where";
    my($row) = $mysql->exec_select_one($sql);
    #
    # If the row does not match the constraint, do nothing
    #
    dbg($sql, "hook_fulcrum");
    return if(!defined($row));
    #
    # Build the list of fields with appropriate format conversion
    #
    my($spec_fields) = $spec->{'tables'}->{$table}->{'fields'};
    my(@fields);
    my($field, $spec_field);
    while(($field, $spec_field) = each(%$spec_fields)) {
	next if(defined($fields_limit) && !exists($fields_limit->{$field}));
	my($type) = $info->{$field}->{'type'};
	if($type eq 'time' || $type eq 'date') {
	    push(@fields, "date_format($field, 'Y-m-d') as $field");
	} elsif($type eq 'set' && defined($info->{$field}->{'dict'})) {
	    #
	    # Do nothing, will be added magically by sexec_select
	    #
	} else {
	    push(@fields, "$field");
	}
    }
    error("unexpected empty field list for $table") if(!@fields);
    #
    # Extract data
    #
    my($fields) = join(',', @fields);
    $row = $mysql->sexec_select_one($table, "select $primary_key,$fields from $table where $table.$primary_key = $primary_value $where");

    return $row;
}

sub hook_insert {
    my($self, $table, $primary_value) = @_;
    my($mysql) = $self->{'mysql'};

    my($spec) = $self->{$mysql->{'base'}};
    return if(!exists($spec->{'tables'}->{$table}));
    my($info) = $mysql->info_table($table);
    my($primary_key) = $info->{'_primary_'};
    my($params) = $spec->{'params'};

    my($row) = $self->hook_insert_prepare($table, $primary_value);
    return if(!defined($row));
    #
    # Build an insert for fulcrum from Mysql values
    #
    my(%insert);
    $insert{"r_$table"} = $primary_value;
    my($spec_fields) = $spec->{'tables'}->{$table}->{'fields'};
    my($field, $spec_field);
    while(($field, $spec_field) = each(%$spec_fields)) {
	my($fulcrum_field) = $spec_field->{'field'};
	$insert{$fulcrum_field} = $row->{$field} if(defined($row->{$field}));
    }
    my($spec_params) = $spec->{'tables'}->{$table}->{'params'};
    if(exists($spec_params->{'merge'})) {
	my($merge) = $spec_params->{'merge'};
	my($other_table) = $merge->{'table'};
	if(!defined($other_table)) {
	    error("missing table name for merge for $table");
	}
	my($other_fields) = $merge->{'fields'};
	if(!defined($other_fields)) {
	    error("missing fields for merge for $table");
	}
	my(%fields) = map { $_ => 1 } split(',', $other_fields);
	my($relation) = $mysql->{'relations'}->{$table};
	error("missing relation for $table") if(!defined($relation));
	$relation = $relation->{$other_table};
	error("missing relation from $table to $other_table") if(!defined($relation));
	my($row) = $mysql->exec_select_one("select $relation->{'key'} from $table where $primary_key = $primary_value");
	my($other_primary_value) = $row->{$relation->{'key'}};
	error("missing primary key value (field $relation->{'key'}) in record from $table for relation to $other_table thru field $relation->{'field'}") if(!defined($other_primary_value));
	$row = $self->hook_insert_prepare($other_table, $other_primary_value, \%fields);
	my($spec_fields) = $spec->{'tables'}->{$other_table}->{'fields'};
	my($field);
	foreach $field (split(',', $other_fields)) {
	    my($spec_field) = $spec_fields->{$field};
	    my($fulcrum_field) = $spec_field->{'field'};
	    error("$field is not mapped for $other_table when merging for $table") if(!defined($fulcrum_field));
	    $insert{$fulcrum_field} = $row->{$field} if(defined($row->{$field}));
	    dbg("added $row->{$field} for $primary_value", "hook_fulcrum");
	}
    }
    my($ft_cid) = $self->insert($params->{'table'},
				%insert);
    #
    # Fill hookid field in the Mysql base with the newly inserted ft_cid,
    # use exec to prevent activating the hook.
    #
    $mysql->exec("update $table set hookid = $ft_cid where $primary_key = $primary_value");
}

sub hook_select {
    my($self, $relevance, $where, $order, $sql, $index, $length) = @_;

    my($rows_id, $rows_total) = $self->select($sql, $index, $length);

    return (undef, 0) if(!@$rows_id);

    my($mysql) = $self->{'mysql'};

    my($spec) = $self->{$mysql->{'base'}};
    my($query_params) = $spec->{'query'}->{'params'};

    my(@ids) = map { $_->{'FT_CID'} } @$rows_id;

    $where = '' if(!defined($where));
    if($where !~ /^\s*$/o) {
	$where = "and ( $where )";
    }
    my($ids) = join(',', @ids);
    $sql = "select $relevance,$query_params->{'extract'} from $query_params->{'table'} where ft_cid in ($ids) $where $order";
    dbg("hook_select: $sql", "hook_fulcrum");
    my($rows) = $self->exec_select($sql);

    #
    # Relevance factor get fucked up by ft_cid in ($ids) :-(
    #
#    my($nrows) = scalar(@ids);
#    my($i);
#    for($i = 0; $i < $nrows; $i++) {
#	$rows->[$i]->{'REL'} = $rows_id->[$i]->{'REL'};
#    }

    return ($rows, $rows_total);
}

sub schema_build {
    my($self) = @_;
    my($mysql) = $self->{'mysql'};
    
    my($spec) = $self->{$mysql->{'base'}};

    my($dir) = $self->{'fulsearch'};
    if(! -d $dir) {
	mkdir($dir, 0777) or error("cannot create directory $dir : $!");
    }
    #
    # Compute schema
    #
    my($definitions) = '';
    my(%fulcrum_fields);
    my($serial) = $self->{'serial'};
    my($table, $spec_table);
    while(($table, $spec_table) = each(%{$spec->{'tables'}})) {

	my($info_table) = $mysql->info_table($table);
	#
	# Special handling for the primary key
	#
	error("$table has no primary key") if(!defined($info_table->{'_primary_'}));
	$definitions .= "\tr_$table\tINTEGER\t$serial, -- PRIMARY KEY for $table\n";
	$serial++;
	$fulcrum_fields{$info_table->{'_primary_'}} = '';
	error("$table must have a hookid field of type int") if(!defined($info_table->{'hookid'}) || $info_table->{'hookid'}->{'type'} ne 'int');
	#
	# Handle all other fields according to specifications
	#
	my($field, $spec_field);
	while(($field, $spec_field) = each(%{$spec_table->{'fields'}})) {
	    my($fulcrum_field) = $spec_field->{'field'};
	    error("$fulcrum_field appear twice") if(exists($fulcrum_fields{$fulcrum_field}));
	    $fulcrum_fields{$fulcrum_field} = '';
	    error("missing fulcrum field name for table $table, field $field") if(!defined($spec_field->{'field'}));
	    my($info_field) = $info_table->{$field};
	    error("fulcrum field name must not be longer than $MAXFIELD characters") if(length($fulcrum_field) > $MAXFIELD);
	    error("field $field not found in table $table") if(!defined($info_field));
	    $definitions .= "\t$fulcrum_field\t";
	    my($type) = $info_field->{'type'};
	    my($size) = $info_field->{'size'};
	    if(($type eq 'set' || $type eq 'enum')) {
		if(exists($info_field->{'dict'})) {
		    my($dict_table) = $info_field->{'dict'}->{'table'};
		    my($dict_label) = $info_field->{'dict'}->{'field'};
		    my($dict_info) = $mysql->info_table($dict_table);
		    $type = $dict_info->{$dict_label}->{'type'};
		    $size = $dict_info->{$dict_label}->{'size'};
		    if(exists($spec_field->{'factor'})) {
			$size *= $spec_field->{'factor'};
		    }
		    dbg("mute $field to $type($size) because dict $dict_table $dict_label", "hook_fulcrum");
		} else {
		    $type = 'char';
		}
	    }
	    if($type eq 'char') {
		error("in table $table, $field char($size) longer than $MAXCHAR") if($size > $MAXCHAR);
		my($type) = $size < 32 ? 'CHAR' : 'VARCHAR';
		$definitions .= "${type}($size)";
	    } elsif($type eq 'int') {
		$definitions .= "INTEGER";
	    } elsif($type eq 'time' || $type eq 'date') {
		$definitions .= "DATE";
	    } 
	    $definitions .= "\t$serial, -- $table $field\n";
	    $serial++;
	}
    }

    #
    # Get the defined schema and insert modifications
    #
    my($schema) = readfile("$self->{'eciladb'}/create.fte");
    $schema =~ s/-+\s+additional\s+hook_fulcrum\s+fields\s+-+/$definitions/is;
    $schema =~ s/_BASE_/$spec->{'params'}->{'table'}/g;
    $schema =~ s/_FULCRUM_DIR_/$self->{'fulcrumdir'}/g;
    $schema =~ s/_TMP_DIR_/$self->{'fulsearch'}/g;
    $schema =~ s/PERIODIC//g;

    #
    # Build & save the database
    #
    writefile("$self->{'fulsearch'}/$spec->{'params'}->{'table'}.fte", $schema);
    $self->exec($schema);
}

sub now {
    my($self) = @_;
    my($mysql) = $self->{'mysql'};

    return "DATE '" . $mysql->Catalog::db::date(time()) . "'";
}

sub query2sql {
    my($self, $params) = @_;
    my($mysql) = $self->{'mysql'};

    my($spec) = $self->{$mysql->{'base'}};
    my($query_params) = $spec->{'query'}->{'params'};
    my($sql);
    my($stop) = $self->{'stop'};
    my($questions);
    if(defined($params->{'text'}) && $params->{'text'} !~ /^\s*$/o) {
	$_ = unaccent_8859($params->{'text'});
	s/(\w)\'(\w)/$1QoT$2/g;
	s/[\'\"]/./g;
	s/QoT/\'\'/g;
	s/^\s*//;
	s/\s*$//;
	s/\s+/ /;
	my($text) = $_;
	my(@words) = split(' ', $text);
	my(@full_words) = grep(!$stop->{$_}, split(' ', $text));
	my($groups) = $spec->{'query'}->{'groups'};
	my($divide_or) = $query_params->{'divide_or'};
	my($now) = $self->now();
	my($name);
	my(@tmp);
	foreach $name (sort { $a <=> $b } keys(%$groups)) {
	    my(@questions);
	    my($group) = $groups->{$name};
	    #
	    # Prepare constraints
	    #
	    my($constraint) = '';
	    my(@constraints);
	    if(exists($group->{'constraint'})) {
		my($re) = "^" . $group->{'constraint'} . "\$";
		my($weight) = $query_params->{'constraint_weight'} || 100;
		my($tag);
		foreach $tag (grep(/^field_/, keys(%$params))) {
		    next if($params->{$tag} =~ /^\s*$/o);
		    my($field) = $tag =~ /^field_(.*)/o;
		    my($value) = $self->quote($params->{$tag});
		    #
		    # If the field name is valid for this group, apply 
		    # constraint.
		    #
		    if($field =~ /$re/) {
			$constraint .= " and $field contains '$value' weight $weight";
		    } else {
			#
			# If the field name is not valid for this group,
			# keep the value associated with it. At least
			# one field of this group will be forced to contain
			# this value.
			#
			push(@constraints, $value);
		    }
		}
		$constraint =~ s/^ and //;
		@constraints = sortu(@constraints) if(defined(@constraints));
	    }

	    my($weight) = $group->{'weight'};
	    my($weight_or);
	    if(defined($divide_or)) {
		$weight_or = $group->{'weight'} / $divide_or;
	    } else {
		$weight_or = 3;
	    }
	    my($field);
	    foreach $field (split(',', $group->{'fields'})) {
		my($sql);
		if(!defined($params->{'expand'}) || $params->{'expand'} =~ /^\s*$/) {
		    if(@words == 1) {
			$sql .= " $field contains '@words' weight $weight";
		    } else {
			$sql .= " $field contains '@words' weight $weight or ";
			$sql .= " $field contains ('" . join("' weight 0 & '", @full_words) . "' weight $weight) or ";
			$sql .= " $field contains ('" . join("' weight $weight_or | '", @full_words) . "' weight $weight_or) ";
		    }
		} elsif($params->{'expand'} eq 'and') {
		    $sql .= " $field contains ('" . join("' weight 0 & '", @full_words) . "' weight $weight) ";
		} elsif($params->{'expand'} eq 'or') {
		    $sql .= " $field contains ('" . join("' weight $weight_or | '", @full_words) . "' weight $weight_or) ";
		} elsif($params->{'expand'} eq 'phrase') {
		    $sql .= " $field contains '@words' weight $weight ";
		} else {
		    error("unknown expand directive $params->{'expand'}");
		}
		push(@questions, $sql);
	    }
	    my($tmp) = join(' or ', @questions);
	    if(@constraints) {
		my(@questions);
		foreach $field (split(',', $group->{'fields'})) {
		    my($sql) = " $field contains ('" . join("' weight 0 | '", @constraints) . "' weight 0) ";
		    push(@questions, $sql);
		}
		$constraint = join(' or ', @questions);
		$tmp = " ( ( $tmp ) and ( $constraint ) ) ";
	    }
	    if(exists($group->{'where'})) {
		$group->{'where'} =~ s/now\(\)/$now/g;
		$tmp = " ( ( $tmp ) and ( $group->{'where'} ) ) ";
	    }
	    if($constraint ne '') {
		$tmp = " ( ( $tmp ) and ( $constraint )) ";
	    }
	    push(@tmp, $tmp);
	}
	$questions = join(' or ', @tmp);
    } else {
	#
	# No query : only apply constraints
	#
	my(@questions);

	my($tag);
	foreach $tag (grep(/^field_/, keys(%$params))) {
	    next if($params->{$tag} =~ /^\s*$/o);
	    my($field) = $tag =~ /^field_(.*)/o;
	    my($sql);
	    my($value) = $self->quote($params->{$tag});
	    $sql = " $field like '$value' ";
	    push(@questions, $sql);
	}

	if(!defined($params->{'expand'}) ||
	   $params->{'expand'} =~ /^\s*$/ ||
	   $params->{'expand'} eq 'or') {
	    $questions .= join(' or ', @questions);
	} elsif($params->{'expand'} eq 'and' ||
		$params->{'expand'} eq 'phrase') {
	    $questions .= join(' and ', @questions);
	}
    }

    my($where) = '';
    if(defined($questions)) {
	$where = "where $questions";
    }
	   

    my($order) = '';
    if(defined($query_params->{'order'})) {
	$order = "order by $query_params->{'order'}";
    }

    my($flexion);
    if(!defined($params->{'flexion'}) || $params->{'flexion'} eq 'none') {
	$flexion = "SET TERM_GENERATOR ''";
    } elsif($params->{'flexion'} eq 'french') {
	$flexion = "SET TERM_GENERATOR 'word!ftelp/lang=french/inflect'";
    } else {
	error("unknown flexion mode $params->{'flexion'}");
    }
    dbg("flexion : $flexion", "hook_fulcrum");
    $self->exec($flexion);
    
    $sql = "select $query_params->{'relevance'},ft_cid from $spec->{'query'}->{'params'}->{'table'} $where $order";

#    dbg("query = $sql", "hook_fulcrum");
    return ($sql, $query_params->{'relevance'}, $questions, $order);
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
