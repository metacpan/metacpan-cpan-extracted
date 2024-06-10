#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
use v5.36;
use strict;
use warnings;

use Bio::SeqAlignment::Components::Sundry::DocumentSequenceModifications
  qw(store_modifications retrieve_modifications);
use Bio::SeqAlignment::Components::Sundry::IOHelpers
  qw(read_fastx_sequences write_fastx_sequences split_fastx_sequences);
use Bio::SeqAlignment::Components::Sundry::Tailing qw(add_polyA);
use Data::MessagePack;
use File::Basename;
use File::Spec;
use FindBin qw($Bin);
use Getopt::Long qw(:config no_ignore_case);
use JSON;
use YAML::Tiny;

###############################################################################
## system constants
use constant DEFAULT_READS      => 300;
use constant DEFAULT_READS_FILE => 'reads.txt';
use constant POLYESTER_SEED     => 45;

###############################################################################

# Define the variables for the options with default NULL values for optional arguments
my $bias;
my @distparams;
my $errormodel;
my $errorrate;
my $fastafile;
my $fcfile;
my $gcbias;
my $max_sequences_per_file = 0;         ## default is to not split the files
my $modformat              = 'YAML';    ## default format is 'YAML
my @numreps;
my $outdir;
my $paired;
my $readsfile;
my $readlen;
my $fraglen;
my $fragsd;
my $seed;
my $strandspec;
my $taildist;
my $writeinfo;

# Configure Getopt::Long
GetOptions(
    'bias|b:s'           => \$bias, # fragment selection bias (optional, string)
    'distparams|P=f{1,}' => \@distparams
    ,    # distribution parameters (mandatory, list of numeric values)
    'errormodel|e:s' => \$errormodel,   # error model (optional, string)
    'errorrate|E:f'  => \$errorrate,    # error probability (optional, float)
    'fastafile|f=s'  => \$fastafile,    # fasta file (path) (mandatory, strings)
    'fcfile|c:s'     => \$fcfile,       # fold change (path) (optional, string)
    'fraglen|F:i'    => \$fraglen,   # fragment length (avg) (optional, integer)
    'fragsd|S:i'     => \$fragsd,    # fragment length (sd) (optional, integer)
    'gcbias|g:i'     => \$gcbias,    # gc bias (optional, integer)
    'maxseqs|m:i'    => \$max_sequences_per_file,    # max sequences per file
    'modformat|M:s'  => \$modformat
    , # case insensitive format for storing modifications (one of JSON, YAML, or MessagePack)
    'numreps|n:i{,}' =>
      \@numreps,    # num of replicates in each group (optional, list)
    'outdir|o:s' => \$outdir,  # path to output directory (optional, string)
    'paired|p:s' => \$paired,  # paired reads (TRUE or FALSE) (optional, string)
    'readlen|R:i'   => \$readlen,    # read length (optional, integer)
    'readsfile|r:s' =>
      \$readsfile,    # reads_per_transcript (path) (optional, string)
    'seed|d:i'       => \$seed,    # random seed (optional, integer)
    'strandspec|s:s' =>
      \$strandspec,    # strand specificity (TRUE or FALSE) (optional, string)
    'taildist|t=s'  => \$taildist,    # tail distribution (mandatory, string)
    'writeinfo|w:i' =>
      \$writeinfo    # save simulation info? (optional, integer/boolean)
) or die "Error in command line arguments\n";

###############################################################################
# Boring list of things to do

# Check for mandatory arguments
die "Error: --fastafile is required.\n" unless $fastafile;

## Check that the fastafile exists
die "Error: $fastafile does not exist.\n" unless -e $fastafile;

$seed = POLYESTER_SEED unless defined $seed;

## create outdir if provided, but set it to dirname of fastafile if not
unless ( defined $outdir ) {
    $outdir = dirname($fastafile);
}
else {
    mkdir $outdir unless -d $outdir;
}

## set readsfile to constant expression if not provided
my $has_readfile = 1;
$has_readfile = 0 unless ( defined $readsfile );

###############################################################################
## Pipeline logic : add polyA tails to source files, then simulate reads with R
## Idea is to flesh out the pipeline logic in the script, then refactor through
## a pipeline module

## Pipeline Segment 1 : read sequences from the fasta file
my $bioseq_objects = read_fastx_sequences($fastafile);

## Pipeline Segment 2 : set up various defauls if not provided
default_read_counts( $outdir, DEFAULT_READS_FILE, $#$bioseq_objects + 1 )
  unless $has_readfile;

## Pipeline Segment 3 : adds polyA tails to the sequences & record what was done
my $modifications_HoH =
  add_polyA( $bioseq_objects, $taildist, $seed, @distparams );

## Pipeline Segment 4 : write the modified sequences to a new fasta file
$fastafile = basename($fastafile);
$fastafile =~ s/(.+)\.fasta$/$1_tail.fasta/;
$fastafile = File::Spec->catfile( $outdir, $fastafile );
write_fastx_sequences( $fastafile, $bioseq_objects );

## Pipeline Segment 5 : simulate reads with R
polyester_run(
    bias       => $bias,
    errormodel => $errormodel,
    errorrate  => $errorrate,
    fastafile  => $fastafile,
    fcfile     => $fcfile,
    gcbias     => $gcbias,
    numreps    => \@numreps,
    outdir     => $outdir,
    paired     => $paired,
    readsfile  => $readsfile,
    readlen    => $readlen,
    fraglen    => $fraglen,
    fragsd     => $fragsd,
    seed       => $seed,
    strandspec => $strandspec,
    writeinfo  => $writeinfo
);

## Pipeline Segment 6 : store the modifications into a file for future use
my $mod_fname = store_modifications(
    mods        => $modifications_HoH,
    bioseq_file => $fastafile,
    format      => $modformat
);

## Pipeline Segment 7 : split files into smaller files
if ($max_sequences_per_file) {
    my @simulated_read_files =
      glob( File::Spec->catfile( $outdir, 'sample_*.fasta' ) );
    split_fastx_sequences( \@simulated_read_files, $max_sequences_per_file );
    say "done splitting files";
}

## Pipeline Segment 8 : cleanup
unlink $readsfile unless $has_readfile;
unlink $fastafile;

###############################################################################
# Subroutines

sub default_read_counts {
    my ( $outdir, $reads_fname, $num_of_seqs, $seq_count ) = @_;
    $seq_count = $seq_count // DEFAULT_READS;
    $readsfile = File::Spec->catfile( $outdir, $reads_fname );
    open my $reads_fh, '>', $readsfile
      or die "Error: unable to open $readsfile for writing\n";
    for ( 1 .. $num_of_seqs ) {
        say {$reads_fh} $seq_count;
    }
    close $reads_fh;
}

sub polyester_run {    # simulate reads with R
    my (%polyester_params) = @_;
    my $bias               = $polyester_params{bias};
    my $errormodel         = $polyester_params{errormodel};
    my $errorrate          = $polyester_params{errorrate};
    my $fastafile          = $polyester_params{fastafile};
    my $fcfile             = $polyester_params{fcfile};
    my $gcbias             = $polyester_params{gcbias};
    my $numreps            = $polyester_params{numreps};
    my $outdir             = $polyester_params{outdir};
    my $paired             = $polyester_params{paired};
    my $readsfile          = $polyester_params{readsfile};
    my $readlen            = $polyester_params{readlen};
    my $fraglen            = $polyester_params{fraglen};
    my $fragsd             = $polyester_params{fragsd};
    my $seed               = $polyester_params{seed};
    my $strandspec         = $polyester_params{strandspec};
    my $writeinfo          = $polyester_params{writeinfo};

    my $r_command =
      "Rscript --vanilla --slave --default-packages=getopt,polyester,utils "
      . File::Spec->catfile( $Bin, "polyester.R" );

## Add the options to the R command
    $r_command .= " --bias \"$bias\""             if defined $bias;
    $r_command .= " --errormodel \"$errormodel\"" if defined $errormodel;
    $r_command .= " --errorrate $errorrate"       if defined $errorrate;
    $r_command .= " --fastafile \"$fastafile\"";
    $r_command .= " --fcfile \"$fcfile\""      if defined $fcfile;
    $r_command .= " --gcbias $gcbias"          if defined $gcbias;
    $r_command .= " --numreps \"@{$numreps}\"" if $numreps;
    $r_command .= " --outdir \"$outdir\""      if defined $outdir;
    $r_command .= " --paired $paired"          if defined $paired;
    $r_command .= " --readsfile \"$readsfile\"";
    $r_command .= " --readlen $readlen"       if defined $readlen;
    $r_command .= " --fraglen $fraglen"       if defined $fraglen;
    $r_command .= " --fragsd $fragsd"         if defined $fragsd;
    $r_command .= " --seed $seed"             if defined $seed;
    $r_command .= " --strandspec $strandspec" if defined $strandspec;
    $r_command .= " --writeinfo $writeinfo"   if defined $writeinfo;

## Execute the R command
    system($r_command);
}

__END__
