# Import.pm - Easy to Use DBI import interface

# Copyright (C) 2004-2012 Stefan Hornburg (Racke) <racke@linuxia.de>

# Authors: Stefan Hornburg (Racke) <racke@linuxia.de>
# Maintainer: Stefan Hornburg (Racke) <racke@linuxia.de>
# Version: 0.19

# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any
# later version.

# This file is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this file; see the file COPYING.  If not, write to the Free
# Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

package DBIx::Easy::Import;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);

# Public variables
$VERSION = '0.19';

use DBI;
use DBIx::Easy;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {driver => shift, database => shift};

	bless ($self, $class);
}

sub update {
	my ($self, %params) = @_;

	$self->_do_import(%params);
}

sub initialize {
	my ($self, $file, $format) = @_;
	my ($sep_char);
	
	$format = uc($format);

	if ($format =~ /^CSV/) {
		$format = 'CSV';
		if ($') {
			$sep_char = $';
			$sep_char =~ s/^\s+//;
			$sep_char =~ s/\s+$//;
		}
		eval {
			require Text::CSV_XS;
		};
		if ($@) {
			die "$0: couldn't load module Text::CSV_XS\n";
		}
		$self->{func} = \&get_columns_csv;
		$self->{parser} = new Text::CSV_XS ({'binary' => 1, 'sep_char' => $sep_char});
	} elsif ($format eq 'XLS') {
		eval {
			require Spreadsheet::ParseExcel;
		};
		if ($@) {
			die "$0: couldn't load module Spreadsheet::ParseExcel\n";
		}
		$self->{parser} = new Spreadsheet::ParseExcel;
	} elsif ($format eq 'TAB') {
		$self->{func} = \&get_columns_tab;
	} else {
		die qq{$0: unknown format "$format"}, "\n";
	}

	if ($file) {
		# read input from file
		require IO::File;
		$self->{fd_input} = new IO::File;
		$self->{fd_input}->open($file)
			|| die "$0: couldn't open $file: $!\n";
	} else {
		# read input from standard input
		require IO::Handle;
		$self->{fd_input} = new IO::Handle;
		$self->{fd_input}->fdopen(fileno(STDIN),'r');
	}

}

sub _do_import {
	my ($self, %params) = @_;
	my ($format, $sep_char, %colmap, %hcolmap);

	$self->{colflag} = 1;

	$self->initialize($params{file}, $params{'format'});
	
	my @columns;

	if ($params{'columns'}) {
		$self->{colflag} = ! ($params{'columns'} =~ s/\s*[\!^]//);
		
		# setup positive/negative list for columns
		for (split(/\s*,\s*/, $params{'columns'})) {
			$self->{usecol}->{$_} = $self->{colflag};
		}
	}

	if (ref($params{'map'}) eq 'HASH') {
		%colmap = %{$params{'map'}};
	} elsif ($params{'map'}) {
		# parse column name mapping
		my ($head, $name);
		foreach (split (/;/, $params{'map'})) {
			($head, $name) = split /=/;
			$colmap{$head} = $name;
		}
	}

	if (1) {
		my %hcolmap;
		my @columns;

		if ($self->{func}->($self, \@columns) <= 0)  {
			die "$0: couldn't find headline\n";
		}

		if ($params{'map_filter'} eq 'lc') {
			@columns = map {lc($_)} @columns;
		}

		# remove whitespace from column names and mark them
		map {s/^\s+//; s/\s+$//; $hcolmap{$_} = 1;} @columns;

		if ($params{'map'}) {
			my @newcolumns;
        
			# filter column names
			foreach (@columns) {
				if (exists $colmap{$_}) {
					push (@newcolumns, $colmap{$_});
					$hcolmap{$colmap{$_}} = 1;
				} else {
					push (@newcolumns, $_);
				}
			}
			@columns = @newcolumns;
		}

		# add any other columns explicitly selected
		for (sort (keys %{$self->{usecol}})) {
			next if $hcolmap{$_};
			next unless exists $self->{usecol}->{$_};
			next unless $self->{usecol}->{$_};
			push (@columns, $_);
		}

		$self->{fieldmap}->{$params{table}} = \@columns;
	}
	
	# database access
	my $dbif = $self->{dbif} = new DBIx::Easy ($self->{driver} || $params{driver},
							   $self->{database} || $params{database});
	# determine column names
    my @names = $self->column_names ($params{table});
    my $fieldnames = \@names;
	my @values;

	while ($self->{func}->($self, \@columns))  {
		my (@data);
		
		@values = @columns;
		
		# sanity checks on input data
		my $typeref = $dbif -> typemap ($params{table});
		my $sizeref = $dbif -> sizemap ($params{table});

		for (my $i = 0; $i <= $#$fieldnames; $i++) {
			# check for column exclusion
			if (keys %{$self->{usecol}}) {
				# note: we do not check the actual value !!
				if ($self->{colflag} && ! exists $self->{usecol}->{$$fieldnames[$i]}) {
					next;
				}
				if (! $self->{colflag} && exists $self->{usecol}->{$$fieldnames[$i]}) {
					next;
				}
			}
			
			# expand newlines and tabulators
			if (defined $values[$i]) {
				$values[$i] =~ s/\\n/\n/g;
				$values[$i] =~ s/\\t/\t/g;
			}
        
			# check if input exceeds column capacity
			unless (exists $$typeref{$$fieldnames[$i]}) {
				warn ("$0: No type information for column $$fieldnames[$i] found\n");
				next;
			}
			unless (exists $$sizeref{$$fieldnames[$i]}) {
				warn ("$0: No size information for column $$fieldnames[$i] found\n");
				next;
			}
			if ($$typeref{$$fieldnames[$i]} == DBI::SQL_CHAR) {
				if (defined $values[$i]) {
					if (length($values[$i]) > $$sizeref{$$fieldnames[$i]}) {
						warn ("$0: Data for field $$fieldnames[$i] truncated: $values[$i]\n");
						$values[$i] = substr($values[$i], 0,
											 $$sizeref{$$fieldnames[$i]});
					}
				} else {
					# avoid insertion of NULL values
					$values[$i] = '';
				}	
			} elsif ($$typeref{$$fieldnames[$i]} == DBI::SQL_VARCHAR) {
				if (defined $values[$i]) {
					if (length($values[$i]) > $$sizeref{$$fieldnames[$i]}) {
						warn ("$0: Data for field $$fieldnames[$i] truncated: $values[$i]\n");
						$values[$i] = substr($values[$i], 0,
											 $$sizeref{$$fieldnames[$i]});
					}
				} else {
					# avoid insertion of NULL values
					$values[$i] = '';
				}
			}
#        push (@data, $$fieldnames[$i], $values[$i]);
		}
		
		# check if record exists
		my %keymap = $self->key_names ($params{table}, $params{'keys'} || 1, 1);
		my @keys = (keys(%keymap));
		my @terms = map {$_ . ' = ' . $dbif->quote($values[$keymap{$_}])}
			(@keys);
		my $sth = $dbif -> process ('SELECT ' . join(', ', @keys)
								 . " FROM $params{table} WHERE "
								 . join (' AND ', @terms));
		while ($sth -> fetch) {}
		
		if ($sth -> rows () > 1) {
			$" = ', ';
			die ("$0: duplicate key(s) @keys in table $params{table}\n");
		}

		my $update = $sth -> rows ();
		$sth -> finish ();
    
		# generate SQL statement
		for (my $i = 0; $i <= $#$fieldnames; $i++) {
			# check for column exclusion
			if (keys %{$self->{usecol}}) {
				# note: we do not check the actual value !!
				if ($self->{colflag} && ! exists $self->{usecol}->{$$fieldnames[$i]}) {
					next;
				}
				if (! $self->{colflag} && exists $self->{usecol}->{$$fieldnames[$i]}) {
					next;
				}
			}
			# expand newlines
			if (defined $values[$i]) {
				$values[$i] =~ s/\\n/\n/g;
			}
			push (@data, $$fieldnames[$i], $values[$i]);
		}

		if ($update) {
			$dbif -> update ($params{table}, join (' AND ', @terms), @data);
		} else {
			if ($params{'update_only'}) {
				$" = ', ';
				die ("$0: key(s) @keys not found\n");
			}
			$dbif -> insert ($params{table}, @data);
		}
	}
}

# -------------------------------------------------
# FUNCTION: column_names DBIF TABLE [START]
#
# Returns array with column names from table TABLE
# using database connection DBIF.
# Optional parameter START specifies column where
# the array should start with.
# -------------------------------------------------

sub column_names {
    my ($self, $table, $start) = @_;    
    my ($names, $sth);

    $start = 0 unless $start;
    
    if (exists $self->{fieldmap}->{$table}) {
        $names = $self->{fieldmap}->{$table};
    } else {
        $sth = $self->{dbif}-> process ("SELECT * FROM $table WHERE 0 = 1");
        $names = $self->{fieldmap}->{$table} = $sth -> {NAME};
        $sth -> finish ();
    }

    @$names[$start .. $#$names];
}


# --------------------------------------------------
# FUNCTION: key_names DBIF TABLE KEYSPEC [HASH]
#
# Returns array with key names for table TABLE.
# Database connection DBIF may be used to
# retrieve necessary information.
# KEYSPEC contains desired keys, either a numeric
# value or a comma-separated list of keys.
# If HASH is set, a mapping between key name
# and position is returned.
# --------------------------------------------------

sub key_names () {
    my ($self, $table, $keyspec, $hash) = @_;
    
    my ($numkeysleft, $i);
    my @columns = $self->column_names ($table);
    my (@keys, %kmap);
    
    $keyspec =~ s/^\s+//; $keyspec =~ s/\s+$//;

    if ($keyspec =~ /^\d+$/) {
        #
        # passed keys are numeric, figure out the names
        #

        $numkeysleft = $keyspec;

        for ($i = 0; $i < $numkeysleft && $i < @columns; $i++) {
            if (keys %{$self->{usecol}}) {
                # note: we do not check the actual value !!
                if ($self->{colflag} && ! exists $self->{usecol}->{$columns[$i]}) {
                    $numkeysleft++;
                    next;
                }
                if (! $self->{colflag} && exists $self->{usecol}->{$columns[$i]}) {
                    $numkeysleft++;
                    next;
                }
            }
            if ($hash) {
                $kmap{$columns[$i]} = $i;
            } else {
                push (@keys, $columns[$i]);
            }
        }
	} else {
        #
        # key names are passed explicitly
        #

        my %colmap;
        
        for ($i = 0; $i < @columns; $i++) {
            $colmap{$columns[$i]} = $i;
        }
        
        for (split (/\s*,\s*/, $keyspec)) {
            # sanity check
            unless (exists $colmap{$_}) {
                die "$0: key \"$_\" appears not in column list\n";
            }
            
            if ($hash) {
                $kmap{$_} = $colmap{$_};
            } else {
                push (@keys, $_);
            }
        }
    }

    return $hash ? %kmap : @keys;
}

# FUNCTION: get_columns_csv IREF FD COLREF

sub get_columns_csv {
	my ($self, $colref) = @_;
	my $line;
	my $msg;
	my $fd = $self->{fd_input};
	
	while (defined ($line = <$fd>)) {
		if ($self->{parser}->parse($line)) {
			# csv line completed, delete buffer
			@$colref = $self->{parser}->fields();
			$self->{buffer} = '';
			return @$colref;
		} else {
			if (($line =~ tr/"/"/) % 2) {
			# odd number of quotes, try again with next line
				$self->{buffer} = $line;
			} else {
				$msg = "$0: $.: line not in CSV format: " . $self->{parser}->error_input() . "\n";
				die ($msg);
			}
		}
	}
}

# ----------------------------------------
# FUNCTION: get_columns_tab IREF FD COLREF
#
# Get columns from a tab separated file.
# ----------------------------------------

sub get_columns_tab {
	my ($self, $colref) = @_;
	my $line;
	my $fd = $self->{fd_input};
	
	while (defined ($line = <$fd>)) {
		# skip empty/blank/comment lines
		next if $line =~ /^\#/; next if $line =~ /^\s*$/;
		# remove newlines and carriage returns
		chomp ($line);
		$line =~ s/\r$//;

		@$colref = split (/\t/, $line);
		return @$colref;
	}
}

# ----------------------------------------
# FUNCTION: get_columns_xls IREF FD COLREF
#
# Get columns from a XLS spreadsheet.
# ----------------------------------------

sub get_columns_xls {
	my ($iref, $fd, $colref) = @_;

	unless ($iref->{workbook}) {
		# parse the spreadsheet once
		$iref->{workbook} = $iref->{object}->Parse($fd);
		unless ($iref->{workbook}) {
			die "$0: couldn't parse spreadsheet\n";
		}
		$iref->{worksheet} = $iref->{workbook}->{Worksheet}[0];
		$iref->{row} = 0;
	}

	if ($iref->{row} <= $iref->{worksheet}->{MaxRow}) {
		@$colref = map {$_->Value()}
			@{$iref->{worksheet}->{Cells}[$iref->{row}++]};
		return @$colref;
	}
}

sub get_columns {
	my ($self, $colref) = @_;

	return $self->{func}->($self, $colref);
}

1;
