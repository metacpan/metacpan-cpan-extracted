#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#
package SQL::Amazon::Tables::Table;

use DBI qw(:sql_types);
use strict;

use constant AMZN_CACHE_TIME_LIMIT => 1800;

sub get_time_limit { return AMZN_CACHE_TIME_LIMIT; }

sub new {
	my ($class, $metadata) = @_;
	my $obj = $metadata ? { %$metadata } : {};
	$obj->{_rows} = {};
	$obj->{_readonly} = 1;
	$obj->{_request_map} = {};

	if ($metadata) {
		$obj->{col_names} = $obj->{NAME};
		my %colnums = ();
		$colnums{$obj->{NAME}[$_]} = $_
			foreach (0..$#{$obj->{NAME}});

		$obj->{col_nums} = \%colnums;
	}
	$obj->{_key_cols} = [ $obj->{col_nums}{ASIN} ];
	
	bless $obj, $class;
	return $obj;
}
sub name {
	my $obj = shift;

	return (ref $obj=~/.+::(\S+)$/) ? $1 : undef;	
}

sub is_readonly { return shift->{_readonly}; }
sub is_cacheonly { return shift->{_cache_only}; }
sub is_local { return shift->{_local}; }
sub debug { shift->{_debug} = shift; }

sub commit {
	my ($obj, $sql, $table) = @_;
	1;
}

sub rollback {
	my ($obj, $sql, $table) = @_;
	1;
}

sub trim { 
	my $x = shift; 
	$x =~ s/^\s+//; 
	$x =~ s/\s+$//; 
	$x; 
}
sub get_metadata {
	my $obj = shift;
	
	return {
		NAME => $obj->{NAME}, 
		TYPE => $obj->{TYPE}, 
		PRECISION => $obj->{PRECISION}, 
		SCALE => $obj->{SCALE},
		NULLABLE => $obj->{NULLABLE}
	};
}
sub fetch {
    my($obj, $key) = @_;

	return undef 
		unless exists $obj->{_rows}{$key};
	unless (ref $obj->{_rows}{$key}) {
		$key .= "\0" . '1';
		return undef 
			unless exists $obj->{_rows}{$key};
	}

	return $obj->{_rows}{$key}[0] > time() ?
		$obj->{_rows}{$key}[1] : undef;
}
sub fetch_all {
    my ($obj, $reqids) = @_;

	my $rows = $obj->{_rows};
	my $reqmap = $obj->{_request_map};
	$reqids = { %$reqmap } 
		unless defined($reqids);

	my %keys = ();
	foreach my $reqid (keys %$reqids) {
		my $reqkeys = $reqmap->{$reqid};
		foreach (keys %$reqkeys) {
			delete $reqkeys->{$_},
			next 
				unless defined($rows->{$_});

			next 
				unless (ref $rows->{$_});

			$keys{$_} = 1,
			next
				if ($rows->{$_}[0] > time());

			delete $rows->{$_};
			delete $reqkeys->{$_};# its timed out, get rid of it
		}
	}
	my @keys = keys %keys;
	return \@keys;
}
sub format_date {
	my $date = shift;
	$date = shift
		if ref $date;
	
	return '****-**-**' 
		unless ($date=~/^(\d{4})-(\d{1,2})(-(\d{1,2}))?$/);
	my ($yr, $mo, $da) = ($1, $2, $4);
	$mo = '0' . $mo 
		unless (length($mo) > 1);
	$da = defined($da) ? 
		(length($da) < 2) ? '0' . $da : $da : 
		'01';
	return '****-**-**'
		unless (($mo < 13) && ($da < 32));

	return join('-', $yr, $mo, $da);
}
sub format_money {
	my $amt = shift;
	$amt = shift
		if ref $amt;

	return '*********.**'
		unless ($amt=~/^-?[0-9]+$/);
	$amt = '0' x (3 - length($amt)) . $amt
		if (length($amt) < 3);

	substr($amt, -2, 0) = '.';
	return $amt;
}

sub insert {
	my ($obj, $item, $reqid) = @_;
	my $names = $obj->{NAME};
	my $types = $obj->{TYPE};
	my @row = ();

	$row[$_] = exists $item->{$names->[$_]} ?
		(($types->[$_] == SQL_DATE) ? 
			format_date($item->{$names->[$_]}) :
		($types->[$_] == SQL_DECIMAL) ?
			format_money($item->{$names->[$_]}) :
			$item->{$names->[$_]}) : 
		undef
		foreach (0..$#$names);
	
	return $obj->save_row(\@row, $item, $reqid);
}
sub save_row {
	my ($obj, $row, $item, $reqid) = @_;
	my @keyvals = ();
	push @keyvals, (defined($row->[$_]) ? $row->[$_] : '')
		foreach (@{$obj->{_key_cols}});

	my $key = join("\0", @keyvals);
	my $expires = $obj->{_local} ? 
		0x7FFFFFFF :
		time() + AMZN_CACHE_TIME_LIMIT;
	my $rows = $obj->{_rows};
	if ($rows->{$key}) {
		if (ref $rows->{$key}) {
			if (row_equals($row, $rows->{$key})) {
				$rows->{$key}[0] = $expires;
			}
			else {
				my $oldkey = $key . "\0" . '1';
				$rows->{$oldkey} = $rows->{$key};
				$rows->{$key} = 2;

				$key .= "\0" . '2';
				$rows->{$key} = [ $expires, $row ];
			}
		}
		else {
			my $uniquifier = $rows->{$key} + 1;
			$rows->{$key} = $uniquifier;
			$key .= "\0$uniquifier";
			$rows->{$key} = [ $expires, $row ];
		}
	}
	else {
		$rows->{$key} = [ $expires, $row ];
	}
	$obj->{_request_map}{$reqid}{$key} = 1; 
	$obj->trace_insert($row, $item)
		if $obj->{_debug} && defined($item);

	return $row;
}

sub trace_insert {
	my ($obj, $row, $item) = @_;
	my $names = $obj->{NAME};

	my ($tblname) = (ref $obj=~/::(\w+)$/);
	foreach (@$names) {
		warn "[SQL::Amazon::Tables::insert] Column $_ not supplied for table $tblname\n"
			unless $row->{$_};
	}
	foreach (keys %$item) {
		warn "[SQL::Amazon::Tables::insert] Column $_ (value '$row->{$_}') not recognized for table $tblname\n"
			unless defined($obj->{col_nums}{$_});
	}
	return $obj;
}
sub compute_key {
	my ($obj, $row) = @_;
	
	my @keys = ();
	push @keys, uc (defined($row->[$_]) ? $row->[$_] : '')
		foreach (@{$obj->{_key_cols}});
	return join("\0", @keys);
}

sub is_key_column {
	my ($obj, $colname) = @_;
	
	unless ($colname=~/^[0-9]+$/) {
		$colname = $obj->{col_nums}{$colname};
		return undef
			unless defined($colname);
	}

	my $keycols = $obj->{_key_cols};
	foreach (@$keycols) {
		return $obj 
			if ($_ == $colname);
	}
	return undef;
}

sub spoil {
	my ($obj, $id) = @_;
	
	delete $obj->{_rows}{$id};
	return $obj;
}

sub spoil_all {
	my $obj = shift;
	
	$obj->{_rows} = {};
	return $obj;
}
sub row ($;$) {
    my($obj, $row) = @_;
    if (@_ == 2) {
		$obj->{row} = $row;
    } 
    else {
    	$obj->{row} = undef,
    	return undef
    		if ($obj->{_rows}{_currkey}[0] < time());
		return $obj->{row};
    }
}

sub column ($$;$) {
    my($self, $column, $val) = @_;
    if (@_ == 3) {
		$self->{row}[$self->{col_nums}{$column}] = $val;
    } else {
		$self->{row}[$self->{col_nums}{$column}];
    }
}

sub column_num ($$) {
    my($self, $col) = @_;
    $self->{col_nums}{$col};
}

sub col_names ($) {
    shift->{col_names};
}

sub col_nums ($) {
    shift->{col_nums};
}
sub fetch_row ($$$) {
    my($obj, $handle, $row) = @_;
    return undef;
}

sub push_names ($$$) {
    my($obj, $data, $names) = @_;

    return 1;
}

sub push_row ($$$) {
    my($obj, $data, $fields) = @_;

	return undef if $obj->{_readonly};
	my $col_num = $obj->{col_nums};
	my @keyvals = ();
	push @keyvals, ($fields->[$col_num->{$_}] || '')
		foreach (@{$obj->{_key_cols}});

	$obj->{_rows}{join("\0", @keyvals)}[1] = $fields;		
    1;
}

sub seek ($$$$) {
    my($obj, $data, $pos, $whence) = @_;
	return 1;
}

sub drop ($$) {
    my($obj, $data) = @_;
    return undef;
}

sub truncate ($$) {
    my ($obj, $data) = @_;
    
    return undef if $obj->{_readonly};
    
    my $rowcnt = scalar keys %{$obj->{_rows}};
    $obj->{_rows} = {};
    return $rowcnt;
}
sub purge_requests {
	my ($obj, $reqids) = @_;
	
	my $reqmap = $obj->{_request_map};
	delete $reqmap->{$_}
		foreach (keys %$reqids);
	return $obj;
}
sub row_equals {
	my ($row1, $row2) = @_;
	
	return undef unless ($#$row1 == $#$row2);
	foreach (0..$#$row1) {
		return undef
			unless (
				(defined($row1->[$_]) && 
					defined($row2->[$_]) &&
					($row1->[$_] eq $row1->[$_])
				) ||
				(!defined($row1->[$_]) && 
					!defined($row2->[$_])
				)
			);
	}
	return 1;
}
sub DESTROY { undef; }

1;

