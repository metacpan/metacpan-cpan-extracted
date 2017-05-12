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
package Catalog::db::mysql;
use strict;

use DBI;
use Carp qw(carp cluck croak confess);
use Catalog::tools::tools;

sub new {
    my($type) = @_;

    my($self) = {};
    bless($self, $type);
    $self->initialize();
    return $self;
}

sub initialize {
    my($self) = @_;

    my($config) = config_load("mysql.conf");
    error("missing mysql.conf") if(!defined($config));
    %$self = ( %$self , %$config );

    if(defined($self->{'hook'})) {
	$self->hook($self->{'hook'});
    }
    $self->parse_relations();
}

sub hook {
    my($self, $hook_class) = @_;

    eval "package Catalog::db::mysql::_firesafe; require $hook_class";
    if ($@) {
	my($advice) = "";
	if($@ =~ /Can't find loadable object/) {
	    $advice = "Perhaps $hook_class was statically linked into a new perl binary."
		 ."\nIn which case you need to use that new perl binary."
		 ."\nOr perhaps only the .pm file was installed but not the shared object file."
	} elsif ($@ =~ /Can't locate.*?.pm/) {
	    $advice = "Perhaps the $hook_class perl module hasn't been installed\n";
	}
	error("$hook_class failed: $@$advice\n");
    }
    my($hook);
    $hook = eval { $hook_class->new() };
    error("$@") if(!defined($hook));

    $hook->mysql($self);

    $self->{'hook'} = $hook;
}

sub quote {
    my($self, $value) = @_;

    $value =~ s/\'/\'\'/g;

    return $value;
}

sub date {
    my($self, $time) = @_;

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $mon++;

    if($year < 60) {
	$year += 2000;
    } else {
	$year += 1900;
    }

    return sprintf("%04d-%02d-%02d", $year, $mon, $mday);
}

sub datetime {
    my($self, $time) = @_;

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    $mon++;
    if($year < 60) {
	$year += 2000;
    } else {
	$year += 1900;
    }
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
}

sub connect {
    my($self) = @_;

    my($connection);

    if($self->{'connect_error_handler'}) {
	eval {
	    $connection = $self->connect_1();
	};
	if($@) {
	    my($error) = $@;
	    my($handler) = $self->{'connect_error_handler'};
	    &$handler('mysql', $error);
	}
    } else {
	$connection = $self->connect_1();
    }
    return $connection;
}

sub connect_1 {
    my($self) = @_;

    if(!defined($self->{'connection'})) {

	my($base) = $self->{'base'} || error("configuration file does not define base");

	my($info) = '';
	$info .= ";host=$self->{'host'}" if($self->{'host'});
	$info .= ";port=$self->{'port'}" if($self->{'port'});
	$info .= ";mysql_socket=$self->{'unix_port'}" if($self->{'unix_port'});

	my($user) = $self->{'user'} || '';
	my($passwd) = $self->{'passwd'} || '';
	dbg("DBI connect $info ($user/$passwd)", "mysql");
	if(!($self->{'connection'} = DBI->connect("dbi:mysql:$base$info", $user, $passwd))) {
	    error("cannot connect to $base $DBI::errstr");
	}
    }
    return $self->{'connection'};
}

sub logoff {
    my($self) = @_;

    if($self->{'connection'}) {
	$self->{'connection'}->disconnect();
	undef($self->{'connection'});
	undef($self->{'info_tables'});
    }
    if($self->{'hook'}) {
	$self->{'hook'}->logoff();
	undef($self->{'hook'});
    }
}

sub insert {
    my($self, $table, %values) = @_;

    my($info) = $self->info_table($table);
    if($self->{'auto_created'} && !exists($values{'created'})) {
	if(exists($info->{'created'})) {
	    $values{'created'} = $self->datetime(time());
	}
    }
    my(%dict);
    my(@fields);
    my($values) = join(', ', map {
	#
	# Remove external dict with multiple values and memorize for
	# later update.
	#
	if($info->{$_}->{'type'} eq 'set' &&
	   exists($info->{$_}->{'dict'})) {
	    $dict{$_} = $values{$_};
	    ();
	} else {
	    $values{$_} =~ s/\\/\\\\/go;
	    $values{$_} =~ s/\'/\'\'/go;
	    $values{$_} =~ s/\000/\\0/go;
	    push(@fields, $_);
	    "'$values{$_}'";
	}
    } sort(keys(%values)));
    my($fields) = join(', ', @fields);

    my($sql) = "insert into $table ( $fields ) values ( $values )";
    if($::opt_fake) {
	dbg($sql, "normal");
	return 1;
    }
    my($base) = $self->connect();
    dbg("$sql", "mysql");
    my($stmt) = $base->prepare("$sql") or error("cannot prepare $sql : " . $base->errstr());
    $stmt->execute() or error("cannot execute $sql: " . $base->errstr());
    my $insertid = $stmt->{'mysql_insertid'};
    $insertid = $stmt->{'insertid'} unless defined $insertid; # old DBD::mysql
    $self->{'insertid'} = $insertid;
    if (%dict) {
	$self->dict_update($table, \%dict, $insertid);
    }
    if ($self->{'hook'}) {
	$self->{'hook'}->hook_insert($table, $insertid);
    }
    return $insertid;
}

sub dict_update {
    my($self, $table, $row, $primary) = @_;

    return if(!defined($row));

    my($info) = $self->info_table($table);
    my($field);
    foreach $field (@{$info->{'_set_dict_'}}) {
	#
	# undef => do not touch
	# empty string => reset to empty set
	# coma separated list of rowids => update set
	#
	next if(!exists($row->{$field}));

	#
	# Extract info
	#
	my($desc) = $info->{$field};
	my($dict) = $desc->{'dict'};
	my($map_table) = $dict->{'map'};
	my($map_field_dict) = $dict->{'map_field_dict'};
	my($map_field_table) = $dict->{'map_field_table'};
	#
	# Delete existing records
	#
	$self->mdelete($map_table, "$map_field_table = $primary");
	#
	# Create new records
	#
	if(defined($row->{$field}) && $row->{$field} !~ /^\s*$/) {
	    my(@rowids) = split(',', $row->{$field});
	    my($rowid);
	    foreach $rowid (@rowids) {
		$self->insert($map_table,
			      $map_field_dict => $rowid,
			      $map_field_table => $primary);
	    }
	}
    }
}

sub mdelete {
    my($self, $table, $where) = @_;

    my($info) = $self->info_table($table);

    my($primary_values);
    if(exists($info->{'_set_dict_'}) || defined($self->{'hook'})) {
	my($primary_key) = $info->{'_primary_'};
	my($rows) = $self->exec_select("select $primary_key from $table where $where");
	@$primary_values = map { $_->{$primary_key} } @$rows;

	my($primary_value);
	foreach $primary_value (@$primary_values) {
	    $self->dict_update($table, undef, $primary_value);
	}
    }

    if(defined($self->{'hook'})) {
	my($hook) = $self->{'hook'};
	$hook->hook_delete($table, $primary_values);
    }

    my($base) = $self->connect();
    my($sql) = "delete from $table where $where";
    dbg($sql, "mysql");
    my($stmt) = $base->prepare("$sql");
    error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
    $stmt->execute() or error("cannot execute $sql: " . $base->errstr());
    $stmt->finish();
}

sub update {
    my($self, $table, $where, %values) = @_;

    if(defined($where) && $where ne '') {
	$where = " where $where ";
    }
    my($info) = $self->info_table($table);
    my(%dict);
    my($set) = join(", ", map {
	#
	# Remove external dict with multiple values and memorize for
	# later update.
	#
	my($increment) = $_ =~ /^\+=\s+(.*)$/o;
	if(!$increment &&
	   $info->{$_}->{'type'} eq 'set' &&
	   exists($info->{$_}->{'dict'})) {
	    $dict{$_} = $values{$_};
	    ();
	} else {
	    if($increment) {
		"$1 = $1 $values{$_}";
	    } else {
		$values{$_} =~ s/\\/\\\\/go;
		$values{$_} =~ s/\'/\'\'/go;
		$values{$_} =~ s/\000/\\0/go;
		"$_ = '$values{$_}'";
	    }
	}
    } sort(keys(%values)));

    if($::opt_fake) {
	my($sql) = "update $table set $set $where";
	dbg($sql, "normal");
	return 1;
    }
    #
    # Update the dictionaries before data changes so that the $where clause
    # is still valid.
    #
    my($primary_values);
    if(keys(%dict) || defined($self->{'hook'})) {
	my($primary_key) = $info->{'_primary_'};
	my($rows) = $self->exec_select("select $primary_key from $table $where");
	@$primary_values = map { $_->{$primary_key} } @$rows;

	my($primary_value);
	foreach $primary_value (@$primary_values) {
	    $self->dict_update($table, \%dict, $primary_value);
	}
    }

    my($ret) = 0;
    if($set !~ /^\s*$/o) {
	my($sql) = "update $table set $set $where";
	dbg($sql, "mysql");
	my($base) = $self->connect();
	my($stmt) = $base->prepare("$sql") or error("cannot prepare $sql : " . $base->errstr());
	my $affected = $stmt->execute() or error("cannot execute $sql: " . $base->errstr());
	#
	# Return 1 if update occured at least on a row, even
	# if nothing was modified in that row.
	#
	$ret = 1 unless $affected == 0 and $self->exec_info() =~ /^[^:]+: 0 /;
    }

    if(defined($self->{'hook'})) {
	my($hook) = $self->{'hook'};
	$hook->hook_update($table, $primary_values);
    }

    return $ret;
}

sub tables {
    my($self) = @_;

    if(!exists($self->{'_table_list_'})) {
	my($base) = $self->connect();
	my($rows) = $self->exec_select("show tables");
	my($row) = $rows->[0];
	my($field) = keys(%$row);
	$self->{'_table_list_'} = [ map { $_->{$field} } @$rows ];
    }
    return $self->{'_table_list_'};
}

sub table_exists {
    my($self, $table) = @_;

    my($tables) = $self->tables();
    return grep { $_ eq $table } @$tables;
}

sub databases {
    my($self) = @_;

    my($base) = $self->connect();
    my($rows) = $self->exec_select("show databases");
    my($row) = $rows->[0];
    my($field) = keys(%$row);
    return [ map { $_->{$field} } @$rows ];
}

sub exec_info {
    my($self) = @_;

    my($base) = $self->connect();
    dbg("sqllib_exec_info: $base->{'info'}\n", "mysql");
    return ($base->{'info'} || '');
}

sub exec {
    my($self, $sql) = @_;
    my($base) = $self->connect();
    if($::opt_fake) {
	dbg($sql, "normal");
    } else {
	dbg("$sql\n", "mysql");
	my($stmt) = $base->prepare("$sql") or error("cannot prepare $sql : " . $base->errstr());
	$stmt->execute() or error("cannot execute $sql: " . $base->errstr());
	$self->{'insertid'} = $stmt->{'mysql_insertid'};
	$self->{'insertid'} = $stmt->{'insertid'} unless defined $self->{'insertid'};
	if(defined($base->{'info'}) && $base->{'info'} =~ /Warnings: [1-9]/) {
	    error("request $sql issued warnings : " . $self->exec_info());
	}
	if($sql =~ /create\s+table/soi || $sql =~ /drop\s+table/soi) {
	    delete($self->{'_table_list_'}) if(exists($self->{'_table_list_'}));
	    delete($self->{'info_tables'}) if(exists($self->{'info_tables'}));
	}
	return $self->{'insertid'};
    }
}

sub select {
    my($self, $sql, $index, $length, $sql_total) = @_;

    my($base) = $self->connect();

    #
    # Default window is huge
    #
    my($limit);
    if(!defined($index) || !defined($length)) {
	$limit = "";
    } else {
	if(!defined($index)) {
	    $limit = " limit $length ";
	} elsif(!defined($length)) {
	    $limit = " limit $index,100000000 ";
	} else {
	    $limit = " limit $index,$length ";
	}
    }

    dbg("$sql$limit\n", "mysql");
    my($stmt) = $base->prepare("$sql$limit")
		or error("cannot prepare $sql$limit: " . $base->errstr());
    $stmt->execute()
		or error("cannot execute $sql$limit: " . $base->errstr());

    my(@result);
    my($hash_ref);
    while($hash_ref = $stmt->fetchrow_hashref('NAME_lc')) {
	push(@result, { %$hash_ref });
    }
    $stmt->finish();

    my $ntuples;
    if ($limit) {
	if(!$sql_total) {
	    $sql_total = $sql;
	    $sql_total =~ s/select\s+.*?\s+from\s/select count(*) from /i;
	}
	$stmt = $base->prepare("$sql_total")
		or error("cannot prepare $sql_total : " . $base->errstr());
	$stmt->execute()
		or error("cannot execute $sql_total: " . $base->errstr());
	$ntuples = $stmt->fetchrow_array();
	$stmt->finish();
    }
    else {
	$ntuples = scalar @result;
    }
    
    return (\@result, $ntuples);
}

sub exec_select_one {
    my($self) = shift;
    my($result) = $self->exec_select(@_, 1);
    if(@$result > 0) {
	return $result->[0];
    } else {
	return undef;
    }
}

sub table_schema {
    my($self, $table) = @_;

    my($opts) = '';
    $opts .= " --host=$self->{'host'} " if($self->{'host'});
    $opts .= " --port=$self->{'port'} " if($self->{'port'});
    $opts .= " --socket=$self->{'unix_port'} " if($self->{'unix_port'});
    $opts .= " --user=$self->{'user'} " if($self->{'user'});
    $opts .= " --password=$self->{'passwd'} " if($self->{'passwd'});

    my($base) = $self->{'base'};

    my($cmd) = "$self->{'home'}/bin/mysqldump $opts --no-data $base $table";
    my($schema);
    $schema = `$cmd`;
    if($? != 0) {
	error("$cmd: high = " . (($? >> 8) & 0xff) . " low = " . ($? & 0xff) . "\n");
    }

    $schema =~ s/^\#.*//mg;
    $schema =~ s/\);/\)/s;
    return $schema;
}

sub info_table {
    my($self, $table) = @_;

    if(exists($self->{'info_tables'}) && exists($self->{'info_tables'}->{$table})) {
#	dbg("$table : " . ostring($self->{'info_tables'}->{$table}), "mysql");
	return $self->{'info_tables'}->{$table};
    }

    my($rows) = $self->exec_select("show tables like '$table'");
    return undef if(@$rows == 0);

    my($base) = $self->connect();

    my(%info);
    my($sql) = "show columns from $table";
    my($stmt) = $base->prepare($sql) or error("cannot prepare $sql : " . $base->errstr());
    $stmt->execute() or error("cannot execute $sql : " . $base->errstr());
    
    my(@fields);
    my($row);
    while($row = $stmt->fetchrow_hashref()) {
	my(%desc);
	if($row->{'Type'} =~ /^(set|enum)/) {
	    $desc{'type'} = $1;
	    $row->{'Type'} =~ s/^[a-z]+//;
	    my(@values);
	    #
	    # Type looks like ('val','val'), suited for eval
	    #
		my $type = $row->{'Type'};
		$type = $1 if $type =~ /^(.*)$/; # untaint
	    eval "\@values = ($type)";
	    croak("Evaluating type list '$type': $@") if $@;
	    $desc{'size'} = length($row->{'Type'});
	    $desc{'values'} = { map { $_ => $_ } @values };
	} elsif($row->{'Type'} =~ /(varchar|text|char)/) {
	    if($row->{'Type'} =~ /char\((\d+)\)/) {
		$desc{'size'} = $1;
	    } elsif($row->{'Type'} =~ /(text)/) {
		$desc{'size'} = 32000;
	    }
	    $desc{'type'} = 'char';
	} elsif($row->{'Type'} =~ /(blob)/) {
	    $desc{'type'} = 'blob';
	} elsif($row->{'Type'} =~ /(int)/) {
	    $desc{'type'} = 'int';
	} elsif($row->{'Type'} =~ /(time)/) {
	    $desc{'type'} = 'time';
	} elsif($row->{'Type'} =~ /(date)/) {
	    $desc{'type'} = 'date';
	} else {
	    warn("$row->{'Type'} is not a known type");
	}
	$desc{'default'} = $row->{'Default'} if(defined($row->{'Default'}));
	if($row->{'Key'} eq 'PRI') {
	    dbg("found primary for $table : $row->{'Field'}", "mysql");
	    if(exists($info{'_primary_'})) {
		$info{'_primary_'} .= ',';
	    } else {
		$info{'_primary_'} = '';
	    }
	    $info{'_primary_'} .= $row->{'Field'};
	}
	push(@fields, $row->{'Field'});
	
	$info{$row->{'Field'}} = \%desc;
	dbg("mysql: field $row->{'Field'}, type = $desc{'type'}\n", "mysql");
    }
    dbg("mysql: fields = @fields\n", "mysql");
    $info{'_fields_'} = \@fields;

    $self->{'info_tables'}->{$table} = \%info;
#    dbg("$table : " . ostring($self->{'info_tables'}->{$table}), "mysql");
    return $self->{'info_tables'}->{$table};
}

sub exec_select {
    my($self, $sql, $limit) = @_;

    my($base) = $self->connect();
    dbg("$sql\n", "sqlutil", "mysql");

    if(defined($limit)) {
	$limit = " limit $limit ";
	$sql .= $limit;
    }

    dbg("$sql\n", "mysql");
    my($stmt) = $base->prepare($sql) or error("cannot prepare $sql : " . $base->errstr());
    $stmt->execute() or error("cannot execute $sql : " . $base->errstr());

    my(@result);
    my($ntuples) = 0;
    my($hash_ref);
    while($hash_ref = $stmt->fetchrow_hashref()) {
#	dbg("hash_ref = $hash_ref\n", "mysql");
	$ntuples++;
	push(@result, { %$hash_ref });
    }
    $stmt->finish();

    return (\@result, $ntuples);
}

sub sexec_select {
    my($self, $table, $sql) = @_;
    
    return $self->dict_select_fix($table, $self->exec_select($sql));
}

sub sexec_select_one {
    my($self, $table, $sql) = @_;
    
    my($row) = $self->exec_select_one($sql);
    if(defined($row)) {
	my($rows) = $self->dict_select_fix($table, [ $row ]);
	return $rows->[0];
    } else {
	return undef;
    }
}

sub sselect {
    my($self, $table, $sql, $index, $length) = @_;

    my($rows, $rows_total) = $self->select($sql, $index, $length);
    $rows = $self->dict_select_fix($table, $rows);
    return ($rows, $rows_total);
}

sub walk {
    my($self, $sql, $callback) = @_;

    my($base) = $self->connect();

    dbg("$sql\n", "mysql");
    my($stmt) = $base->prepare($sql) or error("cannot prepare $sql : " . $base->errstr());
    $stmt->execute() or error("cannot execute $sql : " . $base->errstr());

    my(@result);
    $self->{'walk'} = 1;
    my($hash_ref);
    while($hash_ref = $stmt->fetchrow_hashref()) {
	my($result) = &$callback($hash_ref);
	push(@result, $result);
    }
    $stmt->finish();
    $self->{'walk'} = 0;

    return \@result;
}

#
# Relations handling
#
sub parse_relations {
    my($self) = @_;

    # read the relations file
    my($base) = $self->{'base'};
    my($spec_file) = locate_file("relations_$base.spec", $ENV{'CONFIG_DIR'}) || locate_file("relations.spec", $ENV{'CONFIG_DIR'});
    if(!defined($spec_file) || ! -r $spec_file) {
	dbg("relations file does not exist or is not readable, ignored\n", "mysql");
	return;
    }
    my(%code2type) = (
		      'L' => 'enum',
		      'M' => 'set',
		      '' => 'normal'
		      );
    my($relations) = {};
    open(RELATIONS, "<$spec_file") or error("Can not open $spec_file for reading, $!");
    my($line);
    my($count) = 0;
    my($match);
    while($line = <RELATIONS>) {
	$count++;
	next if($line =~ /^\s*\#/);
	if($line =~ /^\s*(\S+):(\S+)\s+(\S+):(\S+)\s+(M)\s+(\S+):(\S+)\s+(\S+)\s*$/o ||
	   $line =~ /^\s*(\S+):(\S+)\s+(\S+):(\S+)\s+(L)\s+(\S+):(\S+)\s*$/o ||
	   $line =~ /^\s*(\S+):(\S+)\s+(\S+):(\S+)\s*$/o) {
	    $match++;
	    my($table1, $field1) = ($1, $2);
	    my($table2, $field2) = ($3, $4);
	    my($type) = $code2type{$5 || ''};
	    my($dict_table, $dict_field) = ($6, $7);
	    my($dict_map) = $8;
#	    warn("line $count: $table1:$field1 $table2:$field2 $type $dict_table:$dict_field");

	    if(!defined($self->info_table($table1)) ||
	       !defined($self->info_table($table2)) ||
	       (defined($dict_map) && !defined($self->info_table($table2)))) {
		dbg("line $count: missing tables in base, skip relation file", "mysql");
		return undef;
	    }
	    my($relation1) = {
		'key' => $field1,
		'field' => $field2,
		'type' => $type,
	    };
	    $relations->{$table1}->{$table2} = $relation1;

	    my($relation2) = {
		'key' => $field2,
		'field' => $field1,
		'type' => 'normal',
	    };
	    $relations->{$table2}->{$table1} = $relation2;

	    #
	    # table : field => dict : dict_rowid : label
	    # dict->{'dict'}->{'label'} = some field containing label
	    # dict->{'dict'}->{'primary'} = some field containing primary key
	    # table->{field}->{'dict'}->{'table'} = dict
	    # table->{field}->{'dict'}->{'field'} = some field containing label
	    #
	    if($type eq 'set' || $type eq 'enum') {
		my($info) = $self->info_table($dict_table);
		error("line $count: no info for dict $dict_table") if(!defined($info));
		my($default);
		if(exists($info->{$dict_field}->{'default'})) {
		    $default = $info->{$dict_field}->{'default'};
		}
		if(!exists($info->{'dict'})) {
		    $info->{'dict'} = {
			'primary' => ($table1 eq $dict_table ? $field1 : $field2),
			'label' => $dict_field,
		    };
		}
		my($table) = $table1 eq $dict_table ? $table2 : $table1;
		my($field) = $table1 eq $dict_table ? $field2 : $field1;
		$info = $self->info_table($table);
		error("line $count: no info for table $table") if(!defined($info));
		my(%map);
		if($type eq 'set') {
		    error("line $count: missing dict map") if(!defined($dict_map));
		    #
		    # We assume that the fields of the map between the table
		    # and the dictionnary have the same names as the dictionary
		    # and the table.
		    #
		    %map = (
			    'map' => $dict_map,
			    'map_field_dict' => $dict_table,
			    'map_field_table' => $table,
			    );
		    if(exists($info->{$field})) {
			error("line $count: $field must be a fake field, not an existing one");
		    }
		    push(@{$info->{'_fields_'}}, $field);
		    #
		    # Build a list of set based on external tables
		    #
		    push(@{$info->{'_set_dict_'}}, $field);
		}
		$info->{$field}->{'type'} = $type;
		$info->{$field}->{'dict'} = {
		    'table' => $dict_table,
		    'field' => $dict_field,
		    %map,
		};
		dbg("found dict for $table $field => $dict_table $dict_field", "mysql");
	    }
	} else {
	    carp("parse_relations: line $count: fails to match $line\n");
	}
    }
    close (RELATIONS);

    if($match) {
	dbg("parse_relations: matched $match relations", "mysql");
	$self->{'relations'} = $relations;
    } else {
	dbg("parse_relations: matched no relations", "mysql");
    }
}

#
# Get the list of values from the dictionary if not loaded
# and if the field is linked to a dictionary.
#
sub dict_link {
    my($self, $desc, $table, $field) = @_;

    dbg("$table $field", "mysql");
    return if(exists($desc->{'values'}) || !exists($desc->{'dict'}));
    dbg("found", "mysql");

    return $desc->{'values'} = $self->dict_expand($desc->{'dict'}->{'table'});
}

sub dict_add {
    my($self, $table, $value) = @_;

    my($info) = $self->info_table($table);

    my($dict) = $info->{'dict'};
    if(!defined($dict)) {
	warn("not dict info found for $table ? ");
	return {};
    }

    my($label) = $dict->{'label'};

    my($primary) = $self->insert($table,
				 $label => $value);

    #
    # Will not work perfectly : should reload the dictionnary completely
    # without changing the $info->{'values'} pointer because other fields
    # refer to it.
    #
    $info->{'values'}->{$value} = $primary;

    return $primary;
}

sub dict_value2string {
    my($self, $dict, $value, $type) = @_;

    return if(!defined($value));

    my($values) = $self->dict_expand($dict->{'table'}, 'reverse');

    if($type eq 'enum') {
	return $values->{$value};
    } elsif($type eq 'set') {
	return join(',', map { $values->{$_} } split(',', $value));
    } else {
	error("unknown type $type");
    }
}
#
# Retrieve and cache dictionary values, if $table is a dictionary.
#
sub dict_expand {
    my($self, $table, $order) = @_;

    my($info) = $self->info_table($table);

    my($dict) = $info->{'dict'};
    if(!defined($dict)) {
	warn("not dict info found for $table ? ");
	return {};
    }
    
    my($values) = $info->{'values'};

    #
    # Load if not in cache
    #
    if(!defined($values)) {
	#
	# Load the dictionary values
	#
	my($primary) = $dict->{'primary'};
	my($label) = $dict->{'label'};
	my($where) = '';
	my($order) = '';
	if(defined($self->{'dictionaries'}) &&
	   defined($self->{'dictionaries'}->{$table})) {
	    my($spec) = $self->{'dictionaries'}->{$table};
	    if(defined($spec->{'where'})) {
		$where = "where $spec->{'where'}";
	    }
	    if(defined($spec->{'order'})) {
		$order = "order by $spec->{'order'}";
	    }
	}
	#
	# Get all the possible values
	#
	my($rows) = $self->exec_select("select $primary,$label from $table $order");
	$values = { map { $_->{$label} => $_->{$primary} } @$rows };
	#
	# Get the restricted list, if any
	#
	if($where) {
	    ($rows) = $self->exec_select("select $primary from $table $where $order");
	}
	
	$values->{'_order_'} = [ map { $_->{$primary} } @$rows ];
	if(exists($info->{$label}->{'default'})) {
	    $values->{'_default_'} = $info->{$label}->{'default'};
	}
	
	$info->{'values'} = $values;
    }

    if(defined($order) && $order eq 'reverse') {
	return { map { $values->{$_} => $_ } keys(%$values) };
    } else {
	return $values;
    }
}

sub dict_select_fix {
    my($self, $table, $rows) = @_;
    my($info) = $self->info_table($table);

    if(defined($rows)) {
	#
	# Forge fields for external dictionaries so that they look like
	# ordinary sets.
	#
	if(exists($info->{'_set_dict_'})) {
	    my($primary) = $info->{'_primary_'};
	    error("cannot expand dict set without primary FIELD for $table") if(!defined($primary));
	    my($row);
	    foreach $row (@$rows) {
		my($rowid) = $row->{$primary};
		croak("cannot expand dict set without primary VALUE for $table") if(!defined($rowid));

		my($field);
		foreach $field (@{$info->{'_set_dict_'}}) {
		    my($dict) = $info->{$field}->{'dict'};
		    my($map_table) = $dict->{'map'};
		    my($map_field_dict) = $dict->{'map_field_dict'};
		    my($map_field_table) = $dict->{'map_field_table'};
		    my($rows_dict) = $self->exec_select("select $map_field_dict from $map_table where $map_field_table = $rowid");
		    $row->{$field} = join(',', map { $_->{$map_field_dict} } @$rows_dict);
		}
	    }
	}

	#
	# Convert rowids to strings
	#
	my($row);
	foreach $row (@$rows) {
	    my($field);
	    foreach $field (keys(%$row)) {
		my($dict) = $info->{$field}->{'dict'};
		if(defined($dict)) {
		    $row->{$field} = $self->dict_value2string($dict, $row->{$field}, $info->{$field}->{'type'});
		}
	    }
	}
    }    
    return $rows;
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
