=head1 NAME

CLIPSeqTools::PlotApp::nucleotide_composition - Create plots for script
nucleotide_composition.

=head1 SYNOPSIS

clipseqtools-plot nucleotide_composition [options/parameters]

=head1 DESCRIPTION

Create plots for script nucleotide_composition.

=head1 OPTIONS

  Input.
    --file <Str>           input file.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::nucleotide_composition;
$CLIPSeqTools::PlotApp::nucleotide_composition::VERSION = '0.1.7';

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
	documentation => 'file with long gaps distribution.',
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

	my $figfile = $self->o_prefix . 'nucleotide_composition.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile', $self->file);
	$R->set('figfile', $figfile);

	# Disable scientific notation
	$R->run(q{options(scipen=999)});

	# Read table with data
	$R->run(q{idata = read.delim(ifile)});

	# Measure percentages
	$R->run(q{idata$A_percent = idata$A_count / idata$total_count * 100});
	$R->run(q{idata$C_percent = idata$C_count / idata$total_count * 100});
	$R->run(q{idata$G_percent = idata$G_count / idata$total_count * 100});
	$R->run(q{idata$T_percent = idata$T_count / idata$total_count * 100});
	$R->run(q{idata$N_percent = idata$N_count / idata$total_count * 100});

	# Do plots
	$R->run(q{pdf(figfile, width=7)});
	$R->run(q{par(mfrow = c(1, 1), cex.lab=1.2, cex.axis=1.2, cex.main=1.2,
		lwd=1.2, oma=c(0, 0, 0, 0), mar=c(5.1, 5.1, 4.1, 2.1))});
	$R->run(q{plot(idata$position, idata$A_percent, type="o",
		col="darkred", ylim=c(0,100), xlab="Position in read",
		ylab="Percent of nucleotides (%)", main="Nucleotide composition per
		read position", cex=0.5)});
	$R->run(q{lines(idata$position, idata$C_percent, type="o",
		col="orange", cex=0.5)});
	$R->run(q{lines(idata$position, idata$G_percent, type="o",
		col="lightblue", cex=0.5)});
	$R->run(q{lines(idata$position, idata$T_percent, type="o",
		col="darkblue", cex=0.5)});
	$R->run(q{lines(idata$position, idata$N_percent, type="o", col="black",
		cex=0.5)});
	$R->run(q{legend( "topright" , c("A", "C", "G", "T", "N"),
		fill=c("darkred", "orange", "lightblue", "darkblue", "black"))});
	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}


1;
