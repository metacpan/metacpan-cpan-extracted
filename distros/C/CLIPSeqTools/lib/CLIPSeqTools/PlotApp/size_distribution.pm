=head1 NAME

CLIPSeqTools::PlotApp::size_distribution - Create plots for script
size_distribution.

=head1 SYNOPSIS

clipseqtools-plot size_distribution [options/parameters]

=head1 DESCRIPTION

Create plots for script size_distribution.

=head1 OPTIONS

  Input.
    --file <Str>           input file.

  Output
    --o_prefix <Str>       output path prefix. Script will create and add
                           extension to path. [Default: ./]

    -v --verbose           print progress lines and extra information.
    -h -? --usage --help   print help message

=cut

package CLIPSeqTools::PlotApp::size_distribution;
$CLIPSeqTools::PlotApp::size_distribution::VERSION = '0.1.7';

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

	my $figfile = $self->o_prefix . 'size_distribution.pdf';

	# Start R
	my $R = Statistics::R->new();

	# Pass arguments to R
	$R->set('ifile', $self->file);
	$R->set('figfile', $figfile);

	# Disable scientific notation
	$R->run(q{options(scipen=999)});

	# Read table with data
	$R->run(q{idata = read.delim(ifile)});

	# Do plots
	$R->run(q{pdf(figfile, width=14)});
	$R->run(q{par(mfrow = c(1, 2), cex.lab=1.2, cex.axis=1.2, cex.main=1.2,
		lwd=1.2, oma=c(0, 0, 2, 0), mar=c(5.1, 5.1, 4.1, 2.1))});
	$R->run(q{plot(idata$size, idata$count, type="b", pch=19, xlab="Size",
		ylab="Number of reads", main="Number of reads with given size")});
	$R->run(q{plot(idata$size, (idata$count / sum(idata$count)) * 100,
		type="b", pch=19, xlab="Size", ylab="Percent of reads (%)",
		main="Percent of reads with given size")});
	$R->run(q{graphics.off()});

	# Close R
	$R->stop();
}


1;
