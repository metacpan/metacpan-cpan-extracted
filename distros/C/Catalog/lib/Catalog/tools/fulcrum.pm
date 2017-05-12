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
package Catalog::tools::fulcrum;
use strict;

use DBI;
use DBD::Fulcrum;
use Catalog::tools::tools;
use Carp qw(cluck);

sub new {
    my($type) = @_;

    my($self) = {};
    bless($self, $type);
    $self->initialize();
    return $self;
}

sub initialize {
    my($self) = @_;

    my($config) = config_load("fulcrum.conf");

    %$self = ( %$self , %$config );
}

sub quote {
    my($self, $value) = @_;

    $value =~ s/\'/\'\'/g;

    return $value;
}

sub connect {
    my($self) = @_;

    if(!defined($self->{'connection'})) {

	my($base) = $self->{'base'} || error("configuration file does not define base");

	error("configuration file does not define fulcrumdir") if(!defined($self->{'fulcrumdir'}));
	$ENV{'FULCRUM_HOME'} = $self->{'fulcrumdir'};
	my($fulsearch) = $self->{'fulsearch'};
	error("configuration file does not define fulsearch") if(!defined($fulsearch));
	$fulsearch = absolute_path($fulsearch);
	$ENV{'FULSEARCH'} = "$self->{'fulcrumdir'}/fultext:$fulsearch";
	dbg("FULSEARCH = $ENV{'FULSEARCH'}\n", "fulcrum");
	$ENV{'FULCREATE'} = $fulsearch;
	dbg("FULCREATE = $ENV{'FULCREATE'}\n", "fulcrum");
	$ENV{'FULTEMP'} = $self->{'fultemp'};

	dbg("DBI connect $base ", "fulcrum");
	if(!($self->{'connection'} = DBI->connect("dbi:Fulcrum:",
						  '', '', {
						      PrintError => 0,
						      AutoCommit => 0
						      }))) {
	    error("cannot connect to $base $DBI::errstr");
	}
    }
    return $self->{'connection'};
}

sub info_table {
    my($self, $table) = @_;

    if(exists($self->{'info_tables'}) && exists($self->{'info_tables'}->{$table})) {
	return $self->{'info_tables'}->{$table};
    }
    
    my($base) = $self->connect();

    my(%info);
    my($sql) = "select column_name, data_type from columns where table_name = '$table'";
    my($stmt) = $base->prepare($sql);
    error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
    $stmt->execute() or error("cannot execute $sql : " . $base->errstr());
    
    my(%t) = (
	      'LONGVARCHAR' => -1,
	      'CHAR' => 1,
	      'NUMERIC' => 2,
	      'DECIMAL' => 3,
	      'INTEGER' => 4,
	      'SMALLINT' => 5,
	      'FLOAT' => 6,
	      'REAL' => 7,
	      'DOUBLE' => 8,
	      'DATE' => 9,
	      'VARCHAR' => 12,
	      );
    my(@fields);
    my($row);
    while($row = $stmt->fetchrow_hashref()) {
	my(%desc);
	if($row->{'DATA_TYPE'} eq $t{'VARCHAR'} ||
	   $row->{'DATA_TYPE'} eq $t{'CHAR'}) {
	    $desc{'type'} = 'char';
	} elsif($row->{'DATA_TYPE'} eq $t{'INTEGER'} ||
		$row->{'DATA_TYPE'} eq $t{'NUMERIC'}) {
	    $desc{'type'} = 'int';
	} elsif($row->{'DATA_TYPE'} eq $t{'DATE'}) {
	    $desc{'type'} = 'date';
	} elsif($row->{'DATA_TYPE'} eq $t{'LONGVARCHAR'}) {
	    $desc{'type'} = 'external';
	} else {
	    error("$row->{'DATA_TYPE'} is not a known type");
	}
	push(@fields, $row->{'COLUMN_NAME'});
	
	$info{$row->{'COLUMN_NAME'}} = \%desc;
	dbg("fulcrum: field $row->{'COLUMN_NAME'}, type = $desc{'type'}\n", "fulcrum");
    }
    dbg("fulcrum: fields = @fields\n", "fulcrum");
    $info{'_fields_'} = \@fields;

    $self->{'info_tables'}->{$table} = \%info;
#    dbg("$table : " . ostring($self->{'info_tables'}->{$table}), "fulcrum");
    return $self->{'info_tables'}->{$table};
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

sub select {
    my($self, $sql, $index, $length) = @_;

    my($base) = $self->connect();

    $index = 0 if(!defined($index) || $index < 0);
    my($last) = $index + $length;

    my($stmt) = $base->prepare($sql);
    error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
    $stmt->execute() or error("cannot execute $sql : " . $base->errstr());

    my(@result);
    my($ntuples) = 0;
    my($hash_ref);
    while($hash_ref = $stmt->fetchrow_hashref()) {
	$ntuples++;
	next if($ntuples < $index || $ntuples >= $last);
#	dbg("hash_ref = $hash_ref\n", "fulcrum");
#	dbg("keys = " . join(" ", keys(%$hash_ref)) . "\n", "fulcrum");
	push(@result, { %$hash_ref });
    }
    $stmt->finish();

    return (\@result, $ntuples);
}

sub exec_select {
    my($self, $sql, $limit) = @_;

    my($base) = $self->connect();
    dbg("$sql\n", "fulcrum");

    my($stmt) = $base->prepare($sql);
    error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
    $stmt->execute() or error("cannot execute $sql : " . $base->errstr());

    my(@result);
    my($ntuples) = 0;
    my($hash_ref);
    while($hash_ref = $stmt->fetchrow_hashref()) {
#	dbg("hash_ref = $hash_ref\n", "fulcrum");
#	dbg("keys = " . join(" ", keys(%$hash_ref)) . "\n", "fulcrum");
	$ntuples++;
	push(@result, { %$hash_ref });
    }
    $stmt->finish();

    return (\@result, $ntuples);
}

sub insert {
    my($self, $table, %values) = @_;

    my($info) = $self->info_table($table);
    my($fields) = join(" , ", sort(keys(%values)));
    my($values) = join(", ", map {
	my($type) = $info->{uc($_)}->{'type'};
	if($type eq 'date') {
	    "DATE '$values{$_}'";
	} elsif($type eq 'int') {
	    "$values{$_}";
	} else {
	    $values{$_} =~ s/\'/\'\'/g;
	    "'$values{$_}'";
	}
    } sort(keys(%values)));
 
    my($base) = $self->connect();
    my($sql) = "insert into $table ( $fields ) values ( $values )";
    dbg("$sql", "fulcrum");
    my($stmt) = $base->prepare("$sql");
    error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
    $stmt->execute() or error("cannot execute $sql: " . $base->errstr());
    $self->{'insertid'} = $stmt->{'ful_last_row_id'};
    $stmt->finish();
    return $self->{'insertid'};
}

sub update {
    my($self, $table, $where, %values) = @_;

    my($set) = join(", ", map { $values{$_} =~ s/\'/\'\'/g; "$_ = '$values{$_}'"; } sort(keys(%values)));
    my($sql) = "update $table set $set where $where";
    dbg($sql, "fulcrum");
    my($base) = $self->connect();
    my($stmt) = $base->prepare("$sql");
    error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
    $stmt->execute() or error("cannot execute $sql: " . $base->errstr());
    $stmt->finish();
}

sub exec {
    my($self, $sql) = @_;
    my($base) = $self->connect();
    if($::opt_fake) {
	print "$sql;\n";
    } else {
	dbg("$sql\n", "fulcrum");
	my($stmt) = $base->prepare("$sql");
	error("cannot prepare $sql : " . $base->errstr()) if(!defined($stmt));
	$stmt->execute() or error("cannot execute $sql: " . $base->errstr());
	$self->{'insertid'} = $stmt->{'ful_last_row_id'};
	$stmt->finish();
	return $self->{'insertid'};
    }
}

sub logoff {
    my($self) = @_;

    if($self->{'connection'}) {
	$self->{'connection'}->disconnect();
	undef($self->{'connection'});
    }
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
