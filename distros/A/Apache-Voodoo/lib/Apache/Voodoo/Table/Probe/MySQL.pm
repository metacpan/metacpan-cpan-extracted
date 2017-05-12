################################################################################
#
# Apache::Voodoo::Table::Probe::mysql
#
# Probes a MySQL database to get information about various tables.
#
# This is old and crufty and not for public use
#
################################################################################
package Apache::Voodoo::Table::Probe::MySQL;

$VERSION = "3.0200";

use strict;
use warnings;

use DBI;
use Tie::Hash::Indexed;

our $DEBUG = 0;

sub new {
	my $class = shift;
	my $self = {};

	$self->{'dbh'} = shift;

	bless $self, $class;
	return $self;
}

sub list_tables {
	my $self = shift;

	my $res = $self->{'dbh'}->selectall_arrayref("show tables") || die $DBI::errstr;

	return map { $_->[0] } @{$res};
}

sub probe_table {
	my $self = shift;

	my $table = shift;

	my $dbh = $self->{'dbh'};

	tie my %data, 'Tie::Hash::Indexed';

	$data{table} = $table;
	$data{primary_key} = '';

	tie my %columns, 'Tie::Hash::Indexed';
	$data{columns} = \%columns;

	# get foreign key infomation about the given table
	my $db_name = $dbh->{'Name'};
	$db_name =~ s/:.*//;
	my $sth = $dbh->foreign_key_info(undef,undef,undef,undef,$db_name,$table) || die DBI->errstr;
	my %foreign_keys;
	foreach (@{$sth->fetchall_arrayref()}) {
		next unless $_->[2];	# not a foreign key
		$foreign_keys{$_->[7]} = [ $_->[2], $_->[3] ];
	}

	# Sadly the column_info method doesn't tell us if the column is auto increment or not.
	# So we're going after the column info using ye olde explain.
	my $table_info = $dbh->selectall_arrayref("explain $table") || return { 'ERRORS' => [ "explain of table $table failed. $DBI::errstr" ] };
	foreach my $row (@{$table_info}) {
		my $name = $row->[0];

		tie my %column, 'Tie::Hash::Indexed';

		#
		# figure out the column type
		#
		my $type = $row->[1];
		my ($size) = ($type =~ /\(([\d,]+)\)/);

		$type =~ s/[,\d\(\) ]+/_/g;
		$type =~ s/_$//g;

		if ($self->can($type)) {
			$self->$type(\%column,$size);
		}
		else {
			push(@{$data{'ERRORS'}},"unsupported type $row->[1]");
		}

		# is this param required for add / edit (does the column allow nulls)
		$column{'required'} = 1 unless $row->[2] eq "YES";

		if ($row->[3] eq "PRI") {
			# primary key.  NOTE THAT CLUSTERED PRIMARY KEYS ARE NOT SUPPORTED
			$data{'primary_key'} = $name;

			# is the primary key user supplied
			unless ($row->[5] eq "auto_increment") {
				$data{'pkey_user_supplied'} = 1;
			}
		}
		elsif ($row->[3] eq "UNI") {
			# unique index.
			$column{'unique'} = 1;
		}

		#
		# figure out foreign keys
		#
		my $ref_table = '';
		my $ref_id    = '';
		if (scalar(%foreign_keys)) {
			# there are foreign keys defined for this table
			if (defined($foreign_keys{$name})) {
				# this column is a foreign key
				($ref_table,$ref_id) = @{$foreign_keys{$name}};
			}
		}
		elsif ($name =~ /^(\w+)_id$/) {
			# this column follows the standard naming convention
			# let's assume that it's supposed to be a foreign key.
			$ref_table = $1;
		}

		if ($ref_table) {
			my $ref_table_info = $dbh->selectall_arrayref("explain $ref_table");
			if (ref($ref_table_info)) {
				# figure out table structure

				my $ref_data = $self->probe_table($ref_table);

				tie my %ref_info, 'Tie::Hash::Indexed';
				%ref_info = (
					'table'          => $ref_table,
					'primary_key'    => $ref_id || $ref_data->{'primary_key'},
					'select_label'   => $ref_table,
					'select_default' => $row->[4],
					'columns'        => [
						grep { $ref_data->{'columns'}->{$_}->{'type'} eq "varchar" }
						keys %{$ref_data->{'columns'}}
					]
				);

				$column{'references'} = \%ref_info;
			}
			else {
				warn("No such table $ref_table: $DBI::errstr");
			}
		}

		$data{'columns'}->{$name} = \%column;
	}

	if (defined($data{'ERRORS'})) {
		print STDERR join("\n",@{$data{'ERRORS'}});
		print "\n";
		exit;
	}

	return \%data;
}

sub tinyint_unsigned   { shift()->int_handler_unsigned(@_,1); }
sub smallint_unsigned  { shift()->int_handler_unsigned(@_,2); }
sub mediumint_unsigned { shift()->int_handler_unsigned(@_,3); }
sub int_unsigned       { shift()->int_handler_unsigned(@_,4); }
sub integer_unsigned   { shift()->int_handler_unsigned(@_,4); }
sub bigint_unsigned    { shift()->int_handler_unsigned(@_,8); }

sub int_handler_unsigned {
	my ($self,$column,$size,$bytes) = @_;

	$column->{'type'}  = 'unsigned_int';
	$column->{'bytes'} = $bytes;
}

sub tinyint   { shift()->int_handler(@_,1); }
sub smallint  { shift()->int_handler(@_,2); }
sub mediumint { shift()->int_handler(@_,3); }
sub int       { shift()->int_handler(@_,4); }
sub integer   { shift()->int_handler(@_,4); }
sub bigint    { shift()->int_handler(@_,8); }

sub int_handler {
	my ($self,$column,$size,$bytes) = @_;

	$column->{'type'}  = 'signed_int';
	$column->{'bytes'} = $bytes;
}

sub text {
	my ($self,$column,$size) = @_;
	$column->{'type'} = 'text';
}

sub char {
	my $self = shift;
	$self->varchar(@_);
}

sub varchar {
	my ($self,$column,$size) = @_;

	$column->{'type'} = 'varchar';
	$column->{'length'} = $size;
}

sub decimal_unsigned {
	my ($self,$column,$size) = @_;

	my ($l,$r) = split(/,/,$size);

	$column->{'type'}   = 'unsigned_decimal';
	$column->{'left'}   = $l - $r;
	$column->{'right'}  = $r;
	$column->{'length'} = $r+$l+1;
}

sub decimal {
	my ($self,$column,$size) = @_;

	my ($l,$r) = split(/,/,$size);

	$column->{'type'}   = 'signed_decimal';
	$column->{'left'}   = $l - $r;
	$column->{'right'}  = $r;
	$column->{'length'} = $r+$l+2;
}

sub date {
	my ($self,$column,$size) = @_;

	$column->{'type'} = 'date';
}

sub time {
	my ($self,$column,$size) = @_;

	$column->{'type'} = 'time';
}

sub datetime {
	my ($self,$column,$size) = @_;

	$column->{'type'} = 'datetime';
}

sub timestamp {
	# timestamp is a 'magically' updated column that we don't touch
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
