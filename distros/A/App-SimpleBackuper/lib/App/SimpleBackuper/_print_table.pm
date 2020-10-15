package App::SimpleBackuper;

use strict;
use warnings;

sub _print_table {
	my($table, $header_rows_cnt) = @_;
	
	my @column_lengths = (0) x @{ $table->[0] };
	foreach my $row ( @$table ) {
		$column_lengths[ $_ ] = length $row->[ $_ ] foreach grep { ! $column_lengths[ $_ ] or $column_lengths[ $_ ] < length $row->[ $_ ] } 0 .. $#$row;
	}
	
	for my $q ( 0 .. $#$table ) {
		if($header_rows_cnt and $header_rows_cnt == $q) {
			print '-' x ($column_lengths[ $_ ] + ($_ ? length(' | ') : 0)) foreach 0 .. $#{ $table->[$q] };
			print "\n";
		}
		for my $w ( 0 .. $#{ $table->[ $q ] } ) {
			printf "%-$column_lengths[ $w ]s", $table->[ $q ]->[ $w ];
			print $w == $#{ $table->[ $q ] } ? "\n" : ' | ';
		}
	}
}

1;
