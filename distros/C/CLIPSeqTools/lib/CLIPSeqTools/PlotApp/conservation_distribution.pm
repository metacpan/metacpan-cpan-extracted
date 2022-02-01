=head1 NAME

CLIPSeqTools::PlotApp::conservation_distribution - Create plots for script
conservation_distribution.

=head1 SYNOPSIS

clipseqtools-plot conservation_distribution [options/parameters]

=head1 DESCRIPTION

Create plots for script conservation_distribution.

=head1 OPTIONS

  Input.
    --file <Str>                 file with conservation distribution.

  Output
    --o_prefix <Str>             output path prefix. Script will create and
                                 add extension to path. Default: ./

    -v --verbose                 print progress lines and extra information.
    -h -? --usage --help         print help message

=cut

package CLIPSeqTools::PlotApp::conservation_distribution;
$CLIPSeqTools::PlotApp::conservation_distribution::VERSION = '1.0.0';

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
	documentation => 'file with conservation distribution.',
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

	warn "Creating plots for conservation with R\n" if $self->verbose;
	$self->run_R;
}

sub run_R {
	my ($self) = @_;

	my $figfile = $self->o_prefix . 'conservation_distribution.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile', $self->file);
	$R->set('figfile', $figfile);

	# Disable scientific notation
	$R->run(q{options(scipen=999)});

	# Read table with data
	$R->run(q{idata = read.delim(ifile)});

	# Create groups of scores
	$R->run(q{mybreaks = c(-Inf, seq(0,1000,100))});
	$R->run(q{idata$score_group = cut(idata$conservation_score,
		breaks=mybreaks, dig.lab=4)});

	# Aggregate (sum) counts for score groups
	$R->run(q{aggregate_counts = tapply(idata$count, idata$score_group, sum)});
	$R->run(q{aggregate_counts_no_copy_number =
		tapply(idata$count_no_copy_number, idata$score_group , sum)});

	# Do plots
	$R->run(q{pdf(figfile, width=14)});
	$R->run(q{par(mfrow = c(1, 2), cex.lab=1.2, cex.axis=1.1, cex.main=1.2,
		lwd=1.2, oma=c(0, 0, 2, 0), mar=c(9.1, 5.1, 4.1, 2.1))});

	$R->run(q{plot(aggregate_counts, type="b", xaxt="n", pch=19, xlab = NA,
		log="y", ylab="Number of reads",
		main="Number of reads with given conservation score")});
	$R->run(q{axis(1, at=1:length(aggregate_counts),
		labels=names(aggregate_counts), las=2)});
	$R->run(q{mtext(side = 1, "Conservation score", line = 7, cex=1.2)});

	$R->run(q{plot((aggregate_counts / sum(aggregate_counts, na.rm=TRUE)) *
		100, type="b", xaxt="n", pch=19, xlab = NA,
		ylab="Percent of reads (%)",
		main="Percent of reads with given conservation score")});
	$R->run(q{axis(1, at=1:length(aggregate_counts),
		labels=names(aggregate_counts), las=2)});
	$R->run(q{mtext(side = 1, "Conservation score", line = 7, cex=1.2)});

	$R->run(q{plot(aggregate_counts_no_copy_number, type="b", xaxt="n",
		pch=19, xlab = NA, log="y", ylab="Number of unique reads",
		main="Number of unique reads with given conservation score")});
	$R->run(q{axis(1, at=1:length(aggregate_counts_no_copy_number),
		labels=names(aggregate_counts_no_copy_number), las=2)});
	$R->run(q{mtext(side = 1, "Conservation score", line = 7, cex=1.2)});

	$R->run(q{plot((aggregate_counts_no_copy_number /
		sum(aggregate_counts_no_copy_number, na.rm=TRUE)) * 100, type="b",
		xaxt="n", pch=19, xlab = NA, ylab="Percent of unique reads (%)",
		main="Percent of reads with given conservation score")});
	$R->run(q{axis(1, at=1:length(aggregate_counts_no_copy_number),
		labels=names(aggregate_counts_no_copy_number), las=2)});
	$R->run(q{mtext(side = 1, "Conservation score", line = 7, cex=1.2)});

	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}


1;
