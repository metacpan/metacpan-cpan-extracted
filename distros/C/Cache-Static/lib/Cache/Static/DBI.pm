##
#
#    Copyright 2005-2006, Brian Szymanski
#
#    This file is part of Cache::Static
#
#    Cache::Static is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about Cache::Static, point a web browser at
#    http://chronicle.allafrica.com/scache/ or read the
#    documentation included with the Cache::Static distribution in the
#    doc/ directory
#
##

package Cache::Static::DBI;

use DBI;
use Cache::Static;
use strict;

sub wrap {
	my ($class) = @_;
	return bless { _dbh => $_[1] }, $class;
} 

sub prepare {
	my ($self, $statement) = @_;
	my $dbh_st = $self->{_dbh}->prepare($statement);
	return Cache::Static::DBI_st->wrap($dbh_st, $statement,
		$self->{_dbh}->{Driver}->{Name}.":".$self->{_dbh}->{Name});
} 

##############################
### PASS THROUGH FUNCTIONS ###
##############################

sub selectall_arrayref { my ($s, @r) = @_; $s->{_dbh}->selectall_arrayref(@r); }
sub selectall_hashref { my ($s, @r) = @_; $s->{_dbh}->selectall_hashref(@r); }
sub selectcol_arrayref { my ($s, @r) = @_; $s->{_dbh}->selectcol_arrayref(@r); }
sub selectcol_hashref { my ($s, @r) = @_; $s->{_dbh}->selectcol_hashref(@r); }
sub selectrow_array { my ($s, @r) = @_; $s->{_dbh}->selectrow_array(@r); }
sub selectrow_arrayref { my ($s, @r) = @_; $s->{_dbh}->selectrow_arrayref(@r); }
sub selectrow_hashref { my ($s, @r) = @_; $s->{_dbh}->selectrow_hashref(@r); }
sub quote { my ($s, @r) = @_; $s->{_dbh}->quote(@r); }
sub disconnect { my ($s, @r) = @_; $s->{_dbh}->disconnect(@r); }

######################################
### AS YET UNIMPLEMENTED FUNCTIONS ###
######################################

sub do { die "do unimplemented"; }
sub begin_work { die "begin_work unimplemented"; }
sub commit { die "commit unimplemented"; }
sub rollback { die "rollback unimplemented"; }
sub prepare_cached { die "prepare_cached unimplemented"; }

1;

package Cache::Static::DBI_st;

sub wrap {
	my ($class) = @_;
	return bless {
		_dbi_st => $_[1],
		_prepared_statement => $_[2],
		_dsn => $_[3],
	}, $class;
} 

sub _is_in {
	my ($needle, @haystack) = @_;
	map { return 1 if(lc($needle) eq lc($_)) } @haystack;
	return 0;
}

sub _update_timestamps {
	my $spec = shift;
	print "updating spec: $spec\n";
	print Cache::Static::md5_path($spec)."\n";
	Cache::Static::_write_spec_timestamp($spec);
}

### functions to implement:
sub execute {
	my ($self, @rest) = @_;
	die "execute with arguments unimplemented" if(@rest);

	my $st = $self->{_prepared_statement};
	#TODO: statement parsing should be done in prepare()

	#look for methods that change stuff:
	#TODO (later): LOAD DATA INFILE, REPLACE
	$st =~ s/^\s+//;
	my @words = split(/\s+/, $st);
	my $cmd = shift(@words);
	my $ro = 0;
	my ($table);
	if($cmd =~ /^INSERT$/i) {
		#http://dev.mysql.com/doc/refman/5.0/en/insert.html
		my @prefixes = qw ( LOW_PRIORITY DELAYED HIGH_PRIORITY IGNORE INTO );
		while(_is_in($words[0], @prefixes)) { shift(@words); };
		$table = shift(@words);
		#TODO: deal with ON DUPLICATE KEY UPDATE col_name=expr, ... ]
	} elsif($cmd =~ /^UPDATE$/i) {
		#http://dev.mysql.com/doc/refman/5.0/en/update.html
		my @prefixes = qw ( LOW_PRIORITY IGNORE );
		while(_is_in($words[0], @prefixes)) { shift(@words); };
		$table = shift(@words);
		#TODO: multiple table syntax
	} elsif($cmd =~ /^DELETE$/i) {
		#http://dev.mysql.com/doc/refman/5.0/en/delete.html
		my @prefixes = qw ( LOW_PRIORITY IGNORE QUICK FROM );
		while(_is_in($words[0], @prefixes)) { shift(@words); };
		$table = shift(@words);
		#TODO: multiple table syntax
	} elsif($cmd =~ /^TRUNCATE$/i) {
		#http://dev.mysql.com/doc/refman/5.0/en/truncate.html
		$table = shift(@words);
	} elsif($cmd =~ /^DROP$/i) {
		#http://dev.mysql.com/doc/refman/5.0/en/drop-table.html
		my @prefixes = qw ( TEMPORARY TABLE );
		while(_is_in($words[0], @prefixes)) { shift(@words); };
		$table = shift(@words);
	} elsif($cmd =~ /^CREATE$/i) {
		#http://dev.mysql.com/doc/refman/5.0/en/create-table.html
		my @prefixes = qw ( TEMPORARY TABLE );
		while(_is_in($words[0], @prefixes)) { shift(@words); };
		$table = shift(@words);
	} else {
		Cache::Static::_log(3, "got read only statement: $st");
		$ro = 1;
	}

	unless($ro) {
		_update_timestamps("DBI|db|".$self->{_dsn});
		_update_timestamps("DBI|table|".$self->{_dsn}."|$table") if($table);
	}

	return $self->{_dbi_st}->execute();
}

##############################
### PASS THROUGH FUNCTIONS ###
##############################

sub fetchrow_array { my ($s, @r) = @_; $s->{_dbi_st}->fetchrow_array(@r); }
sub fetchrow_arrayref { my ($s, @r) = @_; $s->{_dbi_st}->fetchrow_arrayref(@r); }
sub fetchrow_hashref { my ($s, @r) = @_; $s->{_dbi_st}->fetchrow_hashref(@r); }
sub fetchall_arrayref { my ($s, @r) = @_; $s->{_dbi_st}->fetchall_arrayref(@r); }
sub fetchall_hashref { my ($s, @r) = @_; $s->{_dbi_st}->fetchall_hashref(@r); }
sub rows { my ($s, @r) = @_; $s->{_dbi_st}->rows(@r); }

######################################
### AS YET UNIMPLEMENTED FUNCTIONS ###
######################################

sub execute_array { die "execute_array unimplemented"; }
sub bind_param { die "bind_param unimplemented"; }
sub bind_col { die "bind_col unimplemented"; }
sub bind_columns { die "bind_columns unimplemented"; }

1;

