=head1 NAME

CLIPSeqTools::PlotApp::reads_long_gaps_size_distribution - Create plots for
script reads_long_gaps_size_distribution.

=head1 SYNOPSIS

clipseqtools-plot reads_long_gaps_size_distribution [options/parameters]

=head1 DESCRIPTION

Create plots for script reads_long_gaps_size_distribution.

=head1 OPTIONS

  Input.
    --file <Str>           file with long gaps distribution.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::reads_long_gaps_size_distribution;
$CLIPSeqTools::PlotApp::reads_long_gaps_size_distribution::VERSION = '0.1.8';

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

	my $figfile = $self->o_prefix . 'reads_long_gaps_size_distribution.pdf';
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
	$R->run(q{mybreaks = c(seq(0,500,100), seq(1000,5000,2000),
		seq(10000,50000,20000), Inf)});
	$R->run(q{idata$size_group = cut(idata$gap_size, breaks=mybreaks,
		dig.lab=4)});

	# Aggregate (sum) counts and percents for size groups
	$R->run(q{aggregate_counts = tapply(idata$count, idata$size_group , sum)});
	$R->run(q{aggregate_percents = tapply(idata$percent, idata$size_group , sum)});

	# Do plots
	$R->run(q{pdf(figfile, width=21)});
	$R->run(q{par(mfrow = c(1, 3), cex.lab=1.6, cex.axis=1.2, cex.main=1.6,
		lwd=1.5, oma=c(0, 0, 2, 0), mar=c(9.1, 5.1, 4.1, 2.1))});

	$R->run(q{plot(aggregate_counts, type="b", xaxt="n", pch=19, xlab = NA,
		ylab="Number of reads", main="Number of reads with given gap size")});
	$R->run(q{axis(1, at=1:length(aggregate_counts),
		labels=names(aggregate_counts), las=2)});
	$R->run(q{mtext(side = 1, "Gap size", line = 7)});

	$R->run(q{plot(aggregate_percents, type="b", xaxt="n", pch=19, xlab = NA,
		ylab="Percent of reads (%)", main="Percent of reads with given gap size")});
	$R->run(q{axis(1, at=1:length(aggregate_percents),
		labels=names(aggregate_percents), las=2)});
	$R->run(q{mtext(side = 1, "Gap size", line = 7)});

	$R->run(q{plot((aggregate_counts / sum(idata$count)) * 100, type="b",
		xaxt="n", pch=19, xlab = NA, ylab="Percent of gaps (%)", main="Percent
		of gaps with given size")});
	$R->run(q{axis(1, at=1:length(aggregate_counts),
		labels=names(aggregate_counts), las=2)});
	$R->run(q{mtext(side = 1, "Gap size", line = 7)});

	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}


1;
