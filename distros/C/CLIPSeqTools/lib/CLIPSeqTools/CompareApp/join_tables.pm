=head1 NAME

CLIPSeqTools::CompareApp::join_tables - Perform inner join on tab delimited
table files. Can be used to prepare DESeq input file from counts tables.

=head1 SYNOPSIS

clipseqtools-compare join_tables [options/parameters]

=head1 DESCRIPTION

Perform inner join on tab delimited table files.
Joins two or more tables together based on key columns. The output table will
have the key columns used (must have the same name in all input tables) plus
one value column (must also have the same name in all input tables) from each
of the input tables.  The value columns will be named based on the -name
option in the same order as the -table option.

eg. Given files with the following column structure

    FileA: key_1	key_2	valuecol_1	valuecol_2
    FileB: key_1	key_2	valuecol_1	valuecol_2
    FileC: key_1	key_2	valuecol_1	valuecol_2

if the following command is used

    clipseqtools-compare join_tables \
        --table FileA --table FileB --table FileC \
        --key key_1 --key key_2 \
        --value valuecol_1 \
        --name FileA_values --name FileB_values --name FileC_values

the following output file is produced

    key_1	key_2	FileA_values	FileB_values	FileC_values


=head1 OPTIONS

  Input.
    --table <Str>          tab delimited file. The first line must have the
                           column names. Use multiple times to specify
                           multiple input tables.
    --key <Str>            name of column that has unique identifiers for each
                           row. Use multiple times to create a composite key.
    --value <Str>          name of column with the values that will be joined
                           in the output table.
    --name <name>          name of the value column in the output. Must be
                           given as many times as the -table option.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

  Other options.
    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::CompareApp::join_tables;
$CLIPSeqTools::CompareApp::join_tables::VERSION = '1.0.0';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::CompareApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'table' => (
	is            => 'rw',
	isa           => 'ArrayRef',
	required      => 1,
	documentation => 'tsv file. Use multiple times to specify multiple tables.',
);

option 'key' => (
	is            => 'rw',
	isa           => 'ArrayRef',
	required      => 1,
	documentation => 'key column name (must be the same for all tables). If given multiple times a composite key is used.',
);

option 'value' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'column name (must be the same for all tables).',
);

option 'name' => (
	is            => 'rw',
	isa           => 'ArrayRef',
	required      => 1,
	documentation => 'name of the value column in the output. Must be given as many times as the -table option.',
);

######################################################################
#########################   Consume Roles   ##########################
######################################################################
with
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => { validate_args => '_validate_args_for_output_prefix' },
		-excludes => 'validate_args',
	};


######################################################################
#######################   Interface Methods   ########################
######################################################################
sub validate_args {
	my ($self) = @_;

	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Starting job: join_tables\n";

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Joining Tables\n" if $self->verbose;
	$self->join_tables(
		$self->table, $self->key, $self->value, $self->name,
		$self->o_prefix.'joined.tab');
}

sub join_tables {
	my ($self, $table, $key, $value, $name, $outfile) = @_;

	open (my $OUT, ">", $outfile);

	my @tables = map {_read_table($_, $key, $value)} @{$table};

	for (my $i = 0; $i < @tables; $i++) {
		if (keys %{$tables[$i]} != keys %{$tables[$i-1]}) {
			die "Error: table sizes differ. Check input tables.\n";
		}
	}
# 	say OUT join("\t", "key", @{$opt->name});
	foreach my $key (keys %{$tables[0]}) {
		my @values = map {$_->{$key}} @tables;
		say $OUT join("\t", $key, @values);
	}
}

#######################################################################
########################   Private Functions   ########################
#######################################################################

sub _read_table {
	my ($file, $key_names, $value_name) = @_;
	open(my $IN, "<", $file);
	my $header = $IN->getline;
	chomp $header;
	my @colnames = split(/\t/, $header);
	my @key_indices;
	foreach my $key_name (@$key_names) {
		my $idx = _column_name_to_idx(\@colnames, $key_name);
		die "Error: cannot find column $key_name\n" if not defined $idx;
		push @key_indices, $idx;
	}
	my $value_idx = _column_name_to_idx(\@colnames, $value_name);
	die "Error: cannot find column $value_name\n" if not defined $value_idx;

	my %data;
	while (my $line = $IN->getline) {
		chomp $line;
		my @splitline = split(/\t/, $line);
		my $key = join('|', @splitline[@key_indices]);
		if (exists $data{$key}) {
			die "Error: duplicate key $key found\n";
		}
		$data{$key} = $splitline[$value_idx];
	}
	$IN->close;

	return \%data;
}

sub _column_name_to_idx {
	my ($names, $name) = @_;

	for (my $i=0; $i<@$names; $i++) {
		return $i if $name eq $names->[$i];
	}
	return undef;
}

1;
