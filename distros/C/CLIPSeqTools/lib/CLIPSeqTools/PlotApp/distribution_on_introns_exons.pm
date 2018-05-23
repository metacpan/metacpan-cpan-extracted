=head1 NAME

CLIPSeqTools::PlotApp::distribution_on_introns_exons - Create plots for script
distribution_on_introns_exons.

=head1 SYNOPSIS

clipseqtools-plot distribution_on_introns_exons [options/parameters]

=head1 DESCRIPTION

Create plots for script distribution_on_introns_exons.

=head1 OPTIONS

  Input.
    --file <Str>           input file.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::distribution_on_introns_exons;
$CLIPSeqTools::PlotApp::distribution_on_introns_exons::VERSION = '0.1.8';

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

	my $figfile = $self->o_prefix . 'distribution_on_introns_exons.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile', $self->file);
	$R->set('figfile', $figfile);

	# Read table with data
	$R->run(q{idata = read.delim(ifile)});

	# Create 2 new tables for exons and introns
	$R->run(q{exon_dat = subset(idata, idata$element == 'exon',
		select=-c(element, location))});
	$R->run(q{intron_dat = subset(idata, idata$element == 'intron',
		select=-c(element, location))});

	# Calculate normalization factor
	$R->run(q{norm_factor = sum(exon_dat, na.rm=TRUE) + sum(intron_dat,
		na.rm=TRUE)});

	# Calculate colSums and stdv
	$R->run(q{exon_dat.colSums = colSums(exon_dat, na.rm=TRUE)});
	$R->run(q{intron_dat.colSums = colSums(intron_dat, na.rm=TRUE)});

	# Normalize
	$R->run(q{exon_dat.colSums.norm = exon_dat.colSums / norm_factor});
	$R->run(q{intron_dat.colSums.norm = intron_dat.colSums / norm_factor});

	# Calculate min/max for y axis
	$R->run(q{max_y = max(exon_dat.colSums.norm, intron_dat.colSums.norm)});

	# Do plots
	$R->run(q{pdf(figfile, width=14)});
	$R->run(q{par(mfrow = c(1, 2), cex.lab=1.4, cex.axis=1.4, cex.main=1.4,
		lwd=1.4, oma=c(0, 1, 2, 0), mar=c(5.1,4.1,4.1,2.1))});
	$R->run(q{plot(intron_dat.colSums.norm, pch=19, type="b", col="darkred",
		main="Intron", xlab="Binned length", ylab="Read density", ylim=c(0,
		max_y))});
	$R->run(q{plot(exon_dat.colSums.norm, pch=19, type="b", col="orange",
		main="Exon", xlab="Binned length", ylab="Read density", ylim=c(0,
		max_y))});
	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}

1;
