=head1 NAME

CLIPSeqTools::PlotApp::scatterplot - Create scatterplot for two tables.

=head1 SYNOPSIS

clipseqtools-plot scatterplot [options/parameters]

=head1 DESCRIPTION

Create scatterplot for the given column for two tables.

=head1 OPTIONS

  Input.
    --table1 <Str>         first input table file.
    --table2 <Str>         second input table file.

    --key_col <Str>        name for the column/columns to use as a key. It
                           must be unique for each table row. Use option
                           multiple times to specify multiple columns.
    --val_col <Str>        name of column with values to be plotted.
                           The logarithm of the values is used.

  Output
    --name1 <Str>          name to be used in plot for first table
    --name2 <Str>          name to be used in plot for second table
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. Default: ./

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::scatterplot;
$CLIPSeqTools::PlotApp::scatterplot::VERSION = '0.1.7';

# Make it an app command
use MooseX::App::Command;
extends 'CLIPSeqTools::PlotApp';


#######################################################################
#######################   Load External modules   #####################
#######################################################################
use Modern::Perl;
use autodie;
use namespace::autoclean;
use Statistics::R;


#######################################################################
#######################   Command line options   ######################
#######################################################################
option 'table1' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'first input table file.'
);

option 'table2' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'second input table file.'
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

option 'name1' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'table1',
	documentation => 'name to be used in plot for first table.'
);

option 'name2' => (
	is            => 'rw',
	isa           => 'Str',
	default       => 'table2',
	documentation => 'name to be used in plot for second table.'
);


#######################################################################
##########################   Consume Roles   ##########################
#######################################################################
with
	"CLIPSeqTools::Role::Option::OutputPrefix" => {
		-alias    => { validate_args => '_validate_args_for_output_prefix' },
		-excludes => 'validate_args',
	};


#######################################################################
########################   Interface Methods   ########################
#######################################################################
sub validate_args {
	my ($self) = @_;

	$self->_validate_args_for_output_prefix;
}

sub run {
	my ($self) = @_;

	warn "Validating arguments\n" if $self->verbose;
	$self->validate_args();

	warn "Creating output path\n" if $self->verbose;
	$self->make_path_for_output_prefix();

	warn "Creating plots with R\n" if $self->verbose;
	$self->run_R;
}

sub run_R {
	my ($self) = @_;

	my $figfile = $self->o_prefix . 'scatterplot.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile1', $self->table1);
	$R->set('ifile2', $self->table2);
	$R->set('figfile', $figfile);

	# Read table with data
	$R->run(q{idata1 = read.delim(ifile1)});
	$R->run(q{idata2 = read.delim(ifile2)});

	# Merge tables
	$R->run(q{mdata = merge(idata1, idata2, by=c("} .
		join('","', @{$self->key_col}) . q{"))});

	# Change symbol size depending on the number of records
	$R->run(qq{cex_value = 1});
	$R->run(qq{if (dim(mdata)[1] > 50) {cex_value=.8}});
	$R->run(qq{if (dim(mdata)[1] > 500) {cex_value=.6}});
	$R->run(qq{if (dim(mdata)[1] > 2000) {cex_value=.2}});
	$R->run(qq{if (dim(mdata)[1] > 10000) {cex_value=.15}});

	# Do plots
	$R->run(q{pdf(figfile, width=7)});
	$R->run(q{par(mfrow = c(1, 1), cex.lab=1.2, cex.axis=1.2, cex.main=1.2,
		lwd=1.2)});

	my $val_col_x = $self->val_col . '.x';
	my $val_col_y = $self->val_col . '.y';
	my $name1 = $self->name1;
	my $name2 = $self->name2;
	$R->run(qq{plot(mdata\$$val_col_x, mdata\$$val_col_y, log="xy", pch=19,
		cex=cex_value, xlab = "$name1", ylab="$name2")});
	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}

1;

