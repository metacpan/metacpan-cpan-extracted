=head1 NAME

CLIPSeqTools::PlotApp::distribution_on_genic_elements - Create plots for
script distribution_on_genic_elements.

=head1 SYNOPSIS

clipseqtools-plot distribution_on_genic_elements [options/parameters]

=head1 DESCRIPTION

Create plots for script distribution_on_genic_elements.

=head1 OPTIONS

  Input.
    --file <Str>           input file.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::distribution_on_genic_elements;
$CLIPSeqTools::PlotApp::distribution_on_genic_elements::VERSION = '1.0.0';

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

	my $figfile = $self->o_prefix . 'distribution_on_genic_elements.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile', $self->file);
	$R->set('figfile', $figfile);

	# Read table with data
	$R->run(q{idata = read.delim(ifile)});

	# Remove first column with ids
	$R->run(q{idata = idata[, -grep("transcript_id", colnames(idata))]});

	# Calculate colSums and stdv
	$R->run(q{idata.utr5.colSums = colSums(idata[, grep("utr5",
		colnames(idata))], na.rm=TRUE)});
	$R->run(q{idata.cds.colSums = colSums(idata[, grep("cds",
		colnames(idata))], na.rm=TRUE)});
	$R->run(q{idata.utr3.colSums = colSums(idata[, grep("utr3",
		colnames(idata))], na.rm=TRUE)});

	# Calculate normalization factor
	$R->run(q{norm_factor = sum(idata, na.rm=TRUE)});

	# Normalize
	$R->run(q{idata.utr5.colSums.norm = idata.utr5.colSums / norm_factor});
	$R->run(q{idata.cds.colSums.norm = idata.cds.colSums / norm_factor});
	$R->run(q{idata.utr3.colSums.norm = idata.utr3.colSums / norm_factor});

	# Calculate min/max for y axis
	$R->run(q{max_y = max(idata.utr5.colSums.norm, idata.cds.colSums.norm,
		idata.utr3.colSums.norm)});

	# Do plots
	$R->run(q{pdf(figfile, width=21)});
	$R->run(q{par(mfrow = c(1, 3), cex.lab=1.8, cex.axis=1.8, cex.main=1.8,
		lwd=1.8, oma=c(1, 1, 2, 0), mar=c(5.1,5.1,4.1,2.1))});
	$R->run(q{plot(idata.utr5.colSums.norm, pch=19, type="b", col="darkred",
		main="5'UTR", xlab="Binned exonic length", ylab="Read density",
		ylim=c(0, max_y))});
	$R->run(q{plot(idata.cds.colSums.norm, pch=19, type="b", col="orange",
		main="CDS", xlab="Binned exonic length", ylab="Read density",
		ylim=c(0, max_y))});
	$R->run(q{plot(idata.utr3.colSums.norm, pch=19, type="b", col="darkblue",
		main="3'UTR", xlab="Binned exonic length", ylab="Read density",
		ylim=c(0, max_y))});
	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}


1;
