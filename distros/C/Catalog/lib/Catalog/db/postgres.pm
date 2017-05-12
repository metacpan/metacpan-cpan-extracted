package chezlib;

use strict vars;
use strict subs;

use MD5;			# thy 23jun98
use POSIX;			# thy 18may99
use DB_File;			# thy 18may99
use Pg;
use perltools;
use cgitools;
require Mail::Address;
#require Mail::Send;
require Net::Domain;
require Net::SMTP;

@chezlib::ISA = qw(Exporter);
@chezlib::EXPORT = qw(pg_user pg_user_dir pg_user_dir_from_passwd pg_select pg_insert pg_update pg_walk
		      pg_user_check pg_exec_select pg_exec_select_one pg_exec
		      pg_disconnect pg_quote

		      );

#
# Postgres access functions
#

sub pg_connect {
    if(!$chezlib::pg_connection) {
	my($dbmain) = need_env('CHEZDBMAIN', '@CHEZDBMAIN@');

#	my($dbhost) = need_env('MAIN_SITE', '@MAIN_SITE@');

# thy 11mar98
#	my($dbhost) = need_env('MAIN_SITE', 'aube');
	my($dbhost) = need_env('DB_SITE', '@DB_SITE@');
# thy
	dbg("postgress connect ... ", "postgres");
	my($c) = Pg::setdb($dbhost, '', '', '', $dbmain);
	if($c->status ne PGRES_CONNECTION_OK) {
	    error("cannot connect to $dbhost, $dbmain (" . $c->status() . ")");
	}
	dbg("done\n", "postgres");
	$chezlib::pg_connection = $c;
    }
    return $chezlib::pg_connection;
}

# loic 09mar98
sub pg_disconnect {
    if(defined($chezlib::pg_connection)) {
	undef($chezlib::pg_connection);
    }
}

# loic 09mar98
sub pg_quote {
    my($value) = @_;

    $value =~ s/\'/\'\'/g;

    return $value;
}

sub pg_insert {
    my($table, %values) = @_;

    my($fields) = join(" , ", keys(%values));
    my($values) = join(" , ", map("'$_'", values(%values)));
    my($c) = pg_connect();
    my($request) = "INSERT INTO $table ( $fields ) values ( $values );";
    dbg("$request\n", "normal");
    my($result) = $c->exec($request);
    if($result->resultStatus ne PGRES_COMMAND_OK) {
	error("$request failed : " . $result->resultStatus . "," . $result->cmdStatus);
    }
}

sub pg_update {
    my($table, $where, %values) = @_;

    my($set) = join(", ", map("$_ = '$values{$_}'", keys(%values)));
    my($c) = pg_connect();
    my($request) = "update $table set $set where $where;";
    dbg("$request\n", "normal");
    my($result) = $c->exec($request);
    if($result->resultStatus ne PGRES_COMMAND_OK) {
	error("$request failed : " . $result->resultStatus . "," . $result->cmdStatus);
    }
}

sub pg_exec {
    my($request) = @_;
    my($c) = pg_connect();
    my($result) = $c->exec($request);
    if($result->resultStatus ne PGRES_COMMAND_OK) {
	error("$request failed : " . $result->resultStatus . "," . $result->cmdStatus);
    }
}

sub pg_select {
    my($table, $where, $index, $length) = @_;

    my($c) = pg_connect();
    my($request) = "SELECT * FROM $table WHERE $where;";
    my($result) = $c->exec($request);
    if($result->resultStatus ne PGRES_TUPLES_OK) {
	error("$request failed : " . $result->resultStatus . "," . $result->cmdStatus);
    }

    if($result->ntuples() == 0) {
	return undef;
    }

    #
    # Default window is huge
    #
    if(!defined($index) || !defined($length)) {
	$index = 0;
	$length = 100000000;
    } 

    $index = 0 if($index < 0);
    if($index + $length > $result->ntuples()) {
	$length = $result->ntuples() - $index;
    }
    my($max) = $index + $length;
    
    my(@result);
    my($k);
    for($k = $index; $k < $max; $k++) {
	my(%row);
	my($l);
	for ($l = 0; $l < $result->nfields; $l++) {
	    # thy 08may98
	    my $tmp = $result->getvalue($k, $l);
	    $tmp =~ s/\s+$//o;
	    $row{$result->fname($l)} = $tmp;
	}
	$row{'index'} = $k;
	push(@result, \%row);
    }
    return (\@result, $result->ntuples());
}

sub pg_exec_select_one {
    my($result) = pg_exec_select(@_, 1);
    if($result) {
	return $result->[0];
    } else {
	return undef;
    }
}

sub pg_exec_select {
    my($request, $limit) = @_;

    my($c) = pg_connect();
    my($result) = $c->exec($request);
#    dbg("exec_select $request\n", "normal");
    if($result->resultStatus ne PGRES_TUPLES_OK) {
	error("$request failed : " . $result->resultStatus . "," . $result->cmdStatus);
    }

    if($result->ntuples() == 0) {
	return undef;
    }

    if(!defined($limit)) {
	$limit = $result->ntuples();
    } else {
	$limit = $limit > $result->ntuples() ? $result->ntuples() : $limit;
    }
    my(@result);
    my($k);
    for($k = 0; $k < $limit; $k++) {
	my(%row);
	my($l);
	for ($l = 0; $l < $result->nfields; $l++) {
#	    dbg($result->fname($l) . " = " . $result->getvalue($k, $l) . " \n", "normal");

	    # $row{$result->fname($l)} = $result->getvalue($k, $l);
	    # thy 08may98
	    my $tmp = $result->getvalue($k, $l);
	    $tmp =~ s/\s+$//o;
	    $row{$result->fname($l)} = $tmp;
	}
	push(@result, \%row);
    }
    return (\@result, $limit);
}

sub pg_walk {
    my($request, $callback) = @_;

    my($c) = pg_connect();
    my($result) = $c->exec($request);
    if($result->resultStatus ne PGRES_TUPLES_OK) {
	error("$request failed : " . $result->resultStatus . "," . $result->cmdStatus);
    }

    if($result->ntuples() == 0) {
	return undef;
    }

    my(@result);
    my($max) = $result->ntuples();
    my($k);
    for($k = 0; $k < $max; $k++) {
	my(%row);
	my($l);
	for ($l = 0; $l < $result->nfields; $l++) {
	    # $row{$result->fname($l)} = $result->getvalue($k, $l);
	    # thy 08may98
	    my $tmp = $result->getvalue($k, $l);
	    $tmp =~ s/\s+$//o;
	    $row{$result->fname($l)} = $tmp;
	}
	my($result) = &$callback(\%row);
	push(@result, $result);
    }
    return \@result;
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
