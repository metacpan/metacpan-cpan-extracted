=head1 NAME

CLIPSeqTools::PlotApp::libraries_relative_read_density - Create plots for
script libraries_relative_read_density.

=head1 SYNOPSIS

clipseqtools-plot libraries_relative_read_density [options/parameters]

=head1 DESCRIPTION

Create plots for script libraries_relative_read_density.

=head1 OPTIONS

  Input.
    --file <Str>           input file.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::libraries_relative_read_density;
$CLIPSeqTools::PlotApp::libraries_relative_read_density::VERSION = '0.1.8';

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
option 'file' => (
	is            => 'rw',
	isa           => 'Str',
	required      => 1,
	documentation => 'input file.',
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

	my $figfile = $self->o_prefix . 'libraries_relative_read_density.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile', $self->file);
	$R->set('figfile', $figfile);

	# Read table with data
	$R->run(q{idata = read.delim(ifile)});

	# Convert counts to density
	$R->run(q{idata$norm_counts_with_copy_number_sense =
		idata$counts_with_copy_number_sense /
		(sum(as.numeric(idata$counts_with_copy_number_sense)) + 1)});
	$R->run(q{idata$norm_counts_no_copy_number_sense =
		idata$counts_no_copy_number_sense /
		(sum(as.numeric(idata$counts_no_copy_number_sense)) + 1)});
	$R->run(q{idata$norm_counts_with_copy_number_antisense =
		idata$counts_with_copy_number_antisense /
		(sum(as.numeric(idata$counts_with_copy_number_antisense)) + 1)});
	$R->run(q{idata$norm_counts_no_copy_number_antisense =
		idata$counts_no_copy_number_antisense /
		(sum(as.numeric(idata$counts_no_copy_number_antisense)) + 1)});

	# Find plot y_lim
	$R->run(q{ylimit = max(idata$norm_counts_with_copy_number_sense,
		idata$norm_counts_no_copy_number_sense,
		idata$norm_counts_with_copy_number_antisense,
		idata$norm_counts_no_copy_number_antisense)});

	# Do plots
	$R->run(q{pdf(figfile, width=28)});
	$R->run(q{par(mfrow = c(1, 4), cex.lab=1.8, cex.axis=1.7, cex.main=2,
		lwd=1.5, oma=c(0, 0, 2, 0))});
	$R->run(q{plot(idata$relative_position,
		idata$norm_counts_with_copy_number_sense, type="o", main="Sense
		records (with copy number)", xlab="Relative position", ylab="Density",
		col="darkred", ylim=c(0,ylimit))});
	$R->run(q{abline(v=0, lty=2, col="grey", lwd=1.5)});
	$R->run(q{plot(idata$relative_position,
		idata$norm_counts_no_copy_number_sense, type="o", main="Sense records
		(no copy number)", xlab="Relative position", ylab="Density",
		col="orange", ylim=c(0,ylimit))});
	$R->run(q{abline(v=0, lty=2, col="grey", lwd=1.5)});
	$R->run(q{plot(idata$relative_position,
		idata$norm_counts_with_copy_number_antisense, type="o",
		main="Anti-sense records (with copy number)", xlab="Relative
		position", ylab="Density", col="lightblue", ylim=c(0,ylimit))});
	$R->run(q{abline(v=0, lty=2, col="grey", lwd=1.5)});
	$R->run(q{plot(idata$relative_position,
		idata$norm_counts_no_copy_number_antisense, type="o", main="Anti-sense
		records (no copy number)", xlab="Relative position", ylab="Density",
		col="darkblue", ylim=c(0,ylimit))});
	$R->run(q{abline(v=0, lty=2, col="grey", lwd=1.5)});
	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}

1;
