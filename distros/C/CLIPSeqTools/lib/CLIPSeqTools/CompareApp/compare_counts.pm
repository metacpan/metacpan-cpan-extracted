=head1 NAME

CLIPSeqTools::CompareApp::compare_counts - Compare tables with counts.

=head1 SYNOPSIS

clipseqtools compare_counts [options/parameters]

=head1 DESCRIPTION

Do Upper Quartile normalization on specified value column of one or more
tables.  For each table, all entries are sorted by descending value (specified
by val_col).  All values are divided by the value of the 25%th entry.  The
25%th entry is specified by the table with the fewer entries after the entries
with value lower than val_thres in all tables are excluded.

=head1 OPTIONS

  Input options.
    --table <Str>          input table file/files. Use option multiple
                           times to specify multiple table files.
    --t_name <Str>         table name. Use option multiple times to give names
                           to all the tables. The number of table names must
                           match the number of input table files. If not set,
                           numbers are used instead. These names will be used
                           in the output files.
    --key_col <Str>        name for the column/columns to use as a key. It
                           must be unique for each table row. Use option
                           multiple times to specify multiple columns.
    --val_col <Str>        name of column with values to be normalized.

  Output.
    --o_table <Str>        output table file/files. Use option multiple
                           times to give multiple files. Must be given as
                           many times as the table option.

  Other options.
    --val_thres <Num>      rows with value lower or equal than val_thres
                           are not used for normalization. Default: 0
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::CompareApp::compare_counts;
$CLIPSeqTools::CompareApp::compare_counts::VERSION = '1.0.0';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::CompareApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use File::Spec;
use File::Path qw(make_path);
use Data::Table;
use List::Util qw(min);


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'table' => (
	is            => 'rw',
	isa           => 'ArrayRef[Str]',
	required      => 1,
	documentation => 'input table files. Use option two or more times to '.
						'give multiple files.',
);

option 'key_col' => (
	is            => 'rw',
	isa           => 'ArrayRef[Str]',
	required      => 1,
	documentation => 'name for the column/columns to use as a key. It must '.
						'be unique for each table row. Use option multiple '.
						'times to specify multiple columns.',
);

option 'val_col' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'name of column with values to be normalized.',
);

option 'val_thres' => (
	is            => 'rw',
	isa           => 'Num',
	default       => 0,
	documentation => 'rows with value lower or equal than val_thres are not '.
						'used for normalization.',
);

option 't_name' => (
	is            => 'rw',
	isa           => 'ArrayRef[Str]',
	documentation => 'table name. Use option multiple times to give names '.
						'to all the tables. The number of table names must '.
						'match the number of input table files. If not set, '.
						'numbers are used instead. These names will be used '.
						'in the output files.',
);

#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::Plot" => {
		-alias    => { validate_args => '_validate_args_for_plot' },
		-excludes => 'validate_args',
	},
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => { validate_args => '_validate_args_for_output_prefix' },
		-excludes => 'validate_args',
	};

#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;

	$self->_validate_args_for_plot;
	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting analysis: compare_counts\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Reading input files\n" if $self->verbose;
	my @tables = map {Data::Table::fromFile($_)} @{$self->table};
	die "Error: Input table sizes differ. Aborting.\n" if not all_tables_of_equal_size(@tables);
	$self->t_name([(1..@tables)]) if !defined $self->t_name;

	warn "Searching for 25th percentile\n" if $self->verbose;
	my $uq_idx = _quantile_idx_from_table_with_fewer(
		$self->val_col, $self->val_thres, $self->key_col, @tables);

	warn "Normalizing the values\n" if $self->verbose;
	#Normalized column name is value column + "_uq" suffix
	_build_normalized_column_in_tables($self->val_col, $uq_idx, @tables);

	warn "Writing output files\n" if $self->verbose;
	my @output_files = map {
		$self->o_prefix . $_ . '.counts.uq.tab'} @{$self->t_name};
	for (my $i=0; $i<@output_files; $i++) {
		my (undef, $dir, undef) = File::Spec->splitpath($output_files[$i]);
		make_path($dir);
		open (my $OUT, '>', $output_files[$i]);
		print $OUT $tables[$i]->tsv;
		close $OUT;
	}

	if ($self->plot) {
		warn "Creating plots\n" if $self->verbose;
		for (my $i = 0; $i < @output_files; $i++) {
			for (my $j = $i+1; $j < @output_files; $j++) {
				CLIPSeqTools::PlotApp->initialize_command_class(
					'CLIPSeqTools::PlotApp::scatterplot',
					table1   => $output_files[$i],
					table2   => $output_files[$j],
					key_col  => $self->key_col,
					val_col  => $self->val_col . '_uq',
					name1    => $self->t_name->[$i],
					name2    => $self->t_name->[$j],
					verbose  => $self->verbose,
					o_prefix => $self->o_prefix .
								$self->t_name->[$i].'_vs_'.$self->t_name->[$j].
								'.counts.uq.',
				)->run();
			}
		}
	}
}


#######################################################################
############################   Functions   ############################
#######################################################################
sub _build_normalized_column_in_tables {
	my ($value_col, $uq_idx, @tables) = @_;

	# Sort the tables by descending value
	map{$_->sort($value_col, Data::Table::NUMBER, Data::Table::DESC)} @tables;
	foreach my $table (@tables) {
		my $uq = $table->elm($uq_idx, $value_col);
		my @normalized_values = map {$_ / $uq} $table->col($value_col);
		$table->addCol(\@normalized_values, $value_col."_uq");
	}
}

sub _quantile_idx_from_table_with_fewer {
	my ($value_col, $val_thres, $key_cols, @tables) = @_;

	# Sort tables according to keys
	my @rule = map{$_, Data::Table::STRING, Data::Table::ASC} @{$key_cols};
	map {$_->sort(@rule)} @tables;

	my @rec_counts;
	foreach my $table (@tables) {
		my $records_count = 0;
		my $row_count = $table->nofRow;
		for (my $i=0; $i<$row_count; $i++) {
			my $value = $table->elm($i, $value_col);
			if ($value > $val_thres) {
				$records_count++;
			}
		}
		push @rec_counts, $records_count;
	}

	my $min_count = min(@rec_counts);
	my $quantile_idx = int($min_count * 0.25);

	return $quantile_idx;
}

sub all_tables_of_equal_size {
	my @tables = @_;

	my $row_count = $tables[0]->nofRow;
	my $col_count = $tables[0]->nofCol;

	foreach my $table (@tables) {
		if ($table->nofRow != $row_count or $table->nofCol != $col_count) {
			return 0;
		}
	}

	return 1;
}


1;
