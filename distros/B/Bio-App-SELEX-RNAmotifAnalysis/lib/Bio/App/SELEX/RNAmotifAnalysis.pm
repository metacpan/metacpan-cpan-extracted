#!/usr/bin/env perl
package Bio::App::SELEX::RNAmotifAnalysis;
# ABSTRACT: Cluster SELEX sequences and calculate their structures
use 5.008;
use strict;
use warnings;
use Text::LevenshteinXS qw( distance );
use Config::Tiny;
use autodie;
use Hash::Util qw( lock_keys );
use List::Util qw( min );
use Getopt::Long;
use Carp qw( croak confess);

my $DEFAULT_CONFIG = 'cluster.cfg';

# CONSTANTS
my $TRUE         = 1;
my $FALSE        = 0;
my $SPACE        = q{ };
my $EMPTY_STRING = q{};
my $VERBOSE      = 1;

my $FASTQ_TYPE  = 'fastq';
my $SIMPLE_TYPE = 'simple';

# Act like a script if called as one
unless ( caller() ) { main(); }

sub main {

    my $max_clusters    = 10;
    my $num_cpus        = 5;
    my $max_distance    = 5;
    my $max_top_seqs    = 300;
    my $config_filename = $DEFAULT_CONFIG;
    my $options         = GetOptions(

        # Required (one of these)
        "$FASTQ_TYPE=s"        => \my $fastq,
        "$SIMPLE_TYPE=s"       => \my $simple,

        # Optional
        'max_distance=i' => \$max_distance,
        'max_clusters=i' => \$max_clusters,
        'max_top_seqs=i' => \$max_top_seqs,
        'seed=s'         => \my $seed_filename,
        'cpus=i'         => \$num_cpus,
        'config=s'       => \$config_filename,
        'run'            => \my $run_scripts,
    );

    my $file_type;
    my $infile;
    if(defined $fastq){
        if(defined $simple){
            warn "--$FASTQ_TYPE and --$SIMPLE_TYPE flags are mutually exclusive!\n";
            help();
        }
        $infile    = $fastq;
        $file_type = $FASTQ_TYPE;
    }elsif(defined $simple){
        $infile    = $simple;
        $file_type = $SIMPLE_TYPE;
    }else{
        warn "either --$FASTQ_TYPE or --$SIMPLE_TYPE must be used!\n";
        help();
    }

    # Eliminate case sensitivity for 'type'
    $file_type = lc $file_type;

    my $config = get_config($config_filename);

    open( my $fh_in, '<', $infile );

    my $seed_fh;
    if ( defined $seed_filename && -e $seed_filename ) {
        open( $seed_fh, '<', $seed_filename );
    }

    my ($cluster_href, $distance_href) = cluster(
        fh           => $fh_in,
        max_distance => $max_distance,
        max_clusters => $max_clusters,
        seed_fh      => $seed_fh,
        file_type    => $file_type,
    );

    open( my $fh_all_clusters, '>', 'clusters.txt' );
    write_out_clusters(
        cluster_href    => $cluster_href,
        distance_href   => $distance_href,
        fh_all_clusters => $fh_all_clusters,
        max_top_seqs    => $max_top_seqs,
    );
    create_batch_files( $config, $num_cpus, $run_scripts );
    return;
}


sub get_config {
    my $config_filename = shift;

    my $config;
    if ( ! -e $config_filename ) {
        my $home_dir = $ENV{'HOME'};
        $config = Config::Tiny->new();
        $config->{executables} = {
            mafft           => 'mafft',
            RNAalifold      => 'RNAalifold',
            cmalign         => 'cmalign',
            cmbuild         => 'cmbuild',
            cmcalibrate     => 'cmcalibrate',
            cmsearch        => 'cmsearch',
            CreateStockholm => 'selex_clustal2stockholm.pl',
            stock2fasta     => 'selex_stock2fasta.pl',
        };
        $config->{Flags_for} = {
            RNAalifold => '-r -cv 0.6 -nc 10 -p -d2 -noLP -color -aln',
            mafft      => '--preservecase --clustalout',
        };
        $config->write($config_filename);
        warn "\nNo configuration file found. Creating new configuration file '$config_filename'\n";
        warn external_dependecnies();
        warn <<"MSG";

        If you have problems, you may need to ensure that each executable
        listed in '$config_filename' is located in a directory that is found
        in your PATH environment variable.\n";
MSG
    }
    $config = Config::Tiny->read($config_filename);
    return $config;
}

sub create_batch_files {
    my $config      = shift;
    my $num_cpus    = shift;
    my $run_scripts = shift;

    # Get all the file names to be processed
    my @fasta_filenames = glob '*_top.fasta';

    # Reduce number of cpus if there are fewer files
    $num_cpus = min(scalar @fasta_filenames, $num_cpus);

    # Create a batch of commands for each CPU to work on
    my @workload = map { $EMPTY_STRING } 1 .. $num_cpus;
    my $add_work = __add_work(
        {
            workload_aref => \@workload,
            num_cpus      => $num_cpus,
            config        => $config,
        }
    );
    $add_work->($_) for @fasta_filenames;

    # Execute the commands for each CPU
    for my $batch_num ( 1 .. $num_cpus ){

        # name script file for each batch
        my $batch_filename = "batch_$batch_num";

        # Create a directory for each batch
        system("mkdir $batch_filename.dir");

        # Move into batch directory
        chdir "$batch_filename.dir";

        # Write batch instruction to script file
        open( my $fh, '>', $batch_filename);
        print {$fh} $workload[ $batch_num - 1];
        close $fh;

        # Make script file executable
        system("chmod u+x $batch_filename");

        # Run the script, if desired
        if($run_scripts){
            system("./$batch_filename &");
        }

        # Return to directory about batch directory
        chdir '..';
    }
    return;
}

sub __add_work {
    my %opt = %{ shift() };
    my $workload_aref       = $opt{workload_aref} || croak "'workload_aref' required";
    my $num_cpus            = $opt{num_cpus}      || croak "'num_cpus' required";
    my $config              = $opt{config}        || croak "'config' required";
    my $work_index          = 0;
    my @filenames_to_rename = _filenames_to_rename();

    my $MAFFT_cmd      = "$config->{executables}{mafft} $config->{Flags_for}{mafft}";
    my $RNAalifold_cmd = "$config->{executables}{RNAalifold} $config->{Flags_for}{RNAalifold}";
    return sub {
        my $fasta_filename = shift;
        my %file           = file_name_hash($fasta_filename);

        # Don't allow accidentally creating new keys
        lock_keys %file;

        # Cycle through the sets number of work orders
        if ( $work_index >= $num_cpus ) {
            $work_index = 0;
        }

        $workload_aref->[$work_index] .= join(
            "\n",

            # Pull fasta file into current directory
            "mv ../$file{fasta} .",

            # Do alignment of sequences against each other
            "$MAFFT_cmd $file{fasta} > $file{aligned}",

            # Calculate the secondary structure
            "$RNAalifold_cmd < $file{aligned} > $file{sec_struct}",

            # Rename resulting files
            ( map { "mv $_ $file{$_}" } @filenames_to_rename ),

            # Convert secondary structure file to Stockholm format
            "$config->{executables}{CreateStockholm} $file{aligned} $file{sec_struct} > $file{stock}",

            # Determine covariance model
            "$config->{executables}{cmbuild} $file{covar_model} $file{stock}",

        ) . "\n";

        # Increment work index
        $work_index++;

        return;
    };
}

sub _pairs_from_filenames_to_rename {
    my $base_filename = shift;
    my @pairs = _pairs_from_array( $base_filename . '_', _filenames_to_rename());
    return @pairs;
}

sub _pairs_from_array {
    my ($added_string, @array) = @_;
    return map { $_ => $added_string . $_ } @array;
}

sub _filenames_to_rename {
    return qw( alirna.ps alidot.ps aln.ps alifold.out);
}

sub file_name_hash {
    my $fasta_filename = shift;
    my $base_filename  = base_filename($fasta_filename);
    my %file           = (
        fasta         => $fasta_filename,
        aligned       => $base_filename . '.aln',
        sec_struct    => $base_filename . '.gc',
        _pairs_from_filenames_to_rename($base_filename),
        stock         => $base_filename . '.sto',           #stockholm format
        covar_model   => $base_filename . '.cm',
    );
    return %file;
}

sub base_filename {
    my $filename = shift;
    $filename =~ s/(\.\w+)\z//;
    return $filename;
}

#: PUBLIC_SUBS
sub cluster {
    my %opt = @_;

    # Required parameters
    my $max_distance        = $opt{max_distance} || croak 'max_distance required';
    my $fh                  = $opt{fh}           || croak 'fh required';
    my $max_clusters        = $opt{max_clusters} || croak 'max_clusters required';
    my $file_type           = $opt{file_type}    || confess 'file_type required';

    # Optional parameters
    my $seed_fh             = $opt{seed_fh};

    my @seed_pairs;

    my @seq_count_pairs = get_sequences_from($fh, $file_type);

    # Add any seed sequences to the beginning of the sequence list
    # Oops, this also sorts and counts the sequences in the seed list.
    #   Is that a problem?
    if( defined $seed_fh){
        @seed_pairs = get_sequences_from($seed_fh, $file_type);
        unshift @seq_count_pairs, @seed_pairs;
    }

    my %cluster_for;
    my %distance_for; # Hash that keeps track of edit distances (parallel to %cluster_for)
    my $next_id         = 1;

    # Create the first cluster with the first sequence count pair.
    my $first_pair = shift @seq_count_pairs;
    $cluster_for{$next_id} = [ $first_pair];

    # No distance from itself!
    $distance_for{$next_id}{$first_pair->[0]} = 0;

    # Increment next cluster id, since it has already been used.
    $next_id++;

    # Add sequences to existing cluster, or create new ones up to the maximum
    while ( my $seq_count_pair = shift @seq_count_pairs ) {
        my ($cluster_id, $distance) = matching_cluster_and_distance( $max_distance, \%cluster_for, $seq_count_pair );

        # Create new cluster, if one wasn't found 
        if( ! defined $cluster_id){
            $cluster_id = $next_id;
            $distance   = 0;

            # Increment counter
            $next_id++;
        }

        # Add sequence info to the cluster, if the cluster is within the maximum requested
        if( $cluster_id <= $max_clusters){
            push @{ $cluster_for{$cluster_id} }, $seq_count_pair ;
            $distance_for{$cluster_id}{$seq_count_pair->[0]} = $distance;
        }
    }

    return (\%cluster_for, \%distance_for);
}

sub total_plus_cluster {
    my $opt             = shift;
    my $cluster         = $opt->{cluster};
    my @seqs_with_count = @{$cluster};
    my $total_count     = 0;

    for my $seq_with_count (@seqs_with_count) {
        $total_count += $seq_with_count->[1];
    }

    return {
            total       => $total_count,
            cluster     => \@seqs_with_count,
            original_id => $opt->{original_id},
        };
}

sub write_out_clusters {
    my %opt             = @_;

    # Required input
    my $cluster_href    = $opt{cluster_href}    || croak 'cluster_href required';
    my $distance_href   = $opt{distance_href}   || croak 'distance_href required';
    my $fh_all_clusters = $opt{fh_all_clusters} || croak 'fh_all_clusters required';
    my $max_top_seqs    = $opt{max_top_seqs}    || croak 'max_top_seqs required';

    # Optional input
    my $fh_href         = $opt{fh_href}         || {};

    # Sort clusters by number of sequences they contain (including redundant
    #   ones).
    my @total_plus_clusters =
      map { total_plus_cluster( {original_id => $_, cluster => $cluster_href->{$_}} ) }
      keys %{$cluster_href};

    my $new_id = 1;
                               # Sort clusters by number of sequences they contain (including redundant ones).
    for my $total_plus_cluster ( reverse sort { $a->{total} <=> $b->{total} } @total_plus_clusters ) { 

        my $number_of_sequences_in_cluster = scalar @{ $total_plus_cluster->{cluster} };

        my $grouping;

        # Call it a 'single' if only one unique sequence
        if($number_of_sequences_in_cluster == 1){
            $grouping = 'single';
        }else{
            $grouping = 'cluster';
        };

        # Print header for each cluster/single
        print {$fh_all_clusters} "######## $grouping $new_id ########\n";

        # Use prescribed filehandle for each sequence, or create one
        my $fh;
        if ( defined $fh_href->{$new_id} ) {
            $fh = $fh_href->{$new_id};
        }
        else {
            my $filename = $grouping . '_' . $new_id . '_top.fasta';
            open( $fh, '>', $filename );
            print "created output file '$filename'\n" if $VERBOSE;
        }

        # Write cluster info to the "all" and individual cluster files
        write_cluster(
                {
                    fh_all_clusters => $fh_all_clusters,
                    fh              =>              $fh,
                    cluster_aref    => $total_plus_cluster->{cluster},
                    cluster_number  =>              $new_id,
                    original_cluster_id  => $total_plus_cluster->{original_id},
                    max_top_seqs    =>    $max_top_seqs,
                    distance_href   =>   $distance_href,
                }
        );

        # Increment cluster id
        $new_id++;
    }
    return;
}

sub write_cluster {
    my $opt            = shift;

    my $fh_all_clusters  = $opt->{fh_all_clusters};
    my $fh               = $opt->{fh};
    my $cluster_aref     = $opt->{cluster_aref};
    my $distance_href    = $opt->{distance_href};
    my $cluster_number   = $opt->{cluster_number};
    my $max_top_seqs     = $opt->{max_top_seqs};
    my $original_id      = $opt->{original_cluster_id};

    my @seq_w_counts   = @{$cluster_aref};

    # Remove total count, leaving just pairs with counts
    my $internal_seq_id = 1;

    my $is_single;
    $is_single = $TRUE if @seq_w_counts == 1;

    my $num_seqs = scalar @seq_w_counts;

    # If there are more than max_top_seqs, then split them into two arrays:
    #   One that will be processed and the other that will simply be output
    my @overage_seqs;
    if ( $num_seqs > $max_top_seqs ) {
        @overage_seqs = @seq_w_counts[ $max_top_seqs .. ( $num_seqs     - 1 ) ];
        @seq_w_counts = @seq_w_counts[ 0             .. ( $max_top_seqs - 1 ) ];
    }

    # SEQ_W_COUNT_LOOP
    for my $seq_w_count (@seq_w_counts) {
        my ( $seq, $count ) = @{$seq_w_count};

        my $distance = $distance_href->{$original_id}{$seq};

        my $unique_id = join( '.', $cluster_number, $internal_seq_id, $count, $distance );

        # Print to individual cluster file and all clusters file
        print {$fh_all_clusters} "$unique_id\t$seq\n";

        print {$fh} ">$unique_id\n$seq\n";

        # Print second copy if this is a singleton (to make
        #   multi-sequence alignment behave well)
        if ($is_single) {
            $unique_id .= 'b';
            print {$fh} ">$unique_id\n$seq\n";
        }
        $internal_seq_id++;
    }

    # OVERAGE LOOP
    if (@overage_seqs) {
        my $filename = "cluster_${cluster_number}_overage.fasta";

        open( my $overage_fh, '>', $filename );
        for my $seq_w_count (@overage_seqs) {
            my ( $seq, $count ) = @{$seq_w_count};

            my $distance = $distance_href->{$original_id}{$seq};
            my $unique_id = join( '.', $cluster_number, $internal_seq_id, $count, $distance );
            print {$overage_fh} ">$unique_id\n$seq\n";
            print {$fh_all_clusters} "$unique_id\t$seq\n";
            $internal_seq_id++;
        }
    }

    return;
}

sub matching_cluster_and_distance {
    my $max_distance = shift;
    my $cluster_href = shift;
    my $seq_aref     = shift;

  ID_LOOP:
    for my $id ( keys %{$cluster_href} ) {
        my $cluster_seq = $cluster_href->{$id}->[0];

        my $distance = distance( $seq_aref->[0], $cluster_seq->[0] );

        # Short circuit ID_LOOP when one is found (supposedly only one will match)
        if ( $distance < $max_distance ) {
            return ($id, $distance);
        }
    }
    return;
}

sub get_sequences_from {
    my $fh   = shift || croak 'fh required';
    my $type = shift || confess 'file type required';
    my %count_of;
    my $next_seq = _next_sequence_for($fh, $type);
    while (1) {
        my $seq = $next_seq->();
        last if ! defined $seq;
        next if $seq eq $EMPTY_STRING;

        # If sequence has not been seen before, start counting it. Otherwise, add to the count.
        if( ! exists $count_of{$seq} ){
            $count_of{$seq} = 1;
        }else {
            $count_of{$seq} = $count_of{$seq} + 1;
        }
    }

    # Convert hash into an array containing paired values.
    #                       First value in the pair is the sequence.
    #                       |   The second value in the pair is the number of times (the
    #                       |   |  count) that that sequence is seen in the file.
    #                       v   v
    my @sequences = map { [ $_, $count_of{$_} ] } keys %count_of;

    # Sort the sequences so that the most abundant occur first in the array.
    @sequences    = sort { $b->[1] <=> $a->[1] } @sequences;

    return @sequences;
}

sub _next_sequence_for {
    my $fh   = shift || croak 'fh (first positional parameter) required';
    my $type = shift || confess 'file_type (second positional parameter) required';

    # Simply use next_line if we want each and every line
    return sub { next_line($fh) }
      if $type eq $SIMPLE_TYPE;

    # Only other supported file type is 'fastq'
    confess "Unrecognized type '$type'. Only '$SIMPLE_TYPE' and '$FASTQ_TYPE' are currently recognized."
        if $type ne $FASTQ_TYPE;

    # Skip first header line
    readline $fh;

    return sub {
        my $line = readline $fh;
        return if !defined $line;

        # remove newline and carriage return
        chomp $line;
        $line =~ s/\r//g;

        # Skip quality header, quality score, and next sequence header
        readline $fh;
        readline $fh;
        readline $fh;

        return $line;
    };
}

sub next_line {
    my $fh = shift;

    # Get next line from file
    my $line = readline $fh;

    # return undef if nothing left to read.
    return if ! defined $line;

    #remove newline
    chomp $line;

    #remove carriage return
    $line =~ s/\r//g;
    return $line;
}

sub help {
    print << "END";
    $0 --$FASTQ_TYPE=FILENAME [OPTIONS]
    $0 --$SIMPLE_TYPE=FILENAME [OPTIONS]

    OPTIONS (showing defaults)
        --max_distance  5
        --cpus          5
        --max_clusters  10
        --max_top_seqs  300
        --config        cluster.cfg
END
    exit();
}

sub external_dependecnies {
    return <<END;
External dependencies:
    mafft (see http://mafft.cbrc.jp/alignment/software/)
    Infernal (see http://infernal.janelia.org/), specifically:
       cmalign
       cmbuild
       cmcalibrate
       cmsearch
    RNA Vienna Package (see http://www.tbi.univie.ac.at/~ivo/RNA/), specifically:
        RNAalifold
These must be installed and in a directory that is your PATH environment variable.
END

};

1;

=pod

=head1 NAME

    Bio::App::SELEX::RNAmotifAnalysis - Cluster SELEX sequences and calculate their structures

=head1 SYNOPSIS

    RNAmotifAnalysis --fastq seqs.fq --cpus 4 --run

=head1 DESCRIPTION

    This module pipelines steps in the analysis of SELEX (Systematic Evolution
    of Ligands through EXponential enrichment) data.

    This main module creates scripts to do the following:

    (1) Cluster similar sequences based on edit distance.

    (2) Align sequences within each cluster (using mafft).

    (3) Calculate the secondary structure of the aligned sequences (using
        RNAalifold, from the Vienna RNA package)

    (4) Build covariance models using cmbuild from Infernal.

    Another useful utility installed with this distribution is
    "selex_covarianceSearch" for doing iterative refinements of
    covariance models.

    If you want to use files that simply list sequences, then use
    the "--simple" flag instead of the "--fastq" flag.

    This script assumes that you've already done all of the quality
    control of your sequences beforehand. If the FASTQ format is
    used, quality scores are ignored.

=head1 EXAMPLE USE

    RNAmotifAnalysis --infile seqs.fq --cpus 4 --run

    This will cluster the sequences found in 'seqs.fq' and create a FASTA file
    for each one. The FASTA files will be grouped into batches (i.e. one per
    cpu requested) that will be placed in a separate directory for each batch,
    and processed within that directory. At the end of processing, for each
    cluster there will be a covariance model and postscript illustration
    files. The batch script used to process each batch will be located in the
    respective batch directory.  To produce the scripts without running them,
    simply exclude the --run flag from the command line.

    The output file contains names that contain four period delimited values
      For example, 2.3.1.5 means
          that this is the second cluster
          this is the third sequence in the cluster
          there is one copy of this sequences
          it is an edit distance of 5 from the reference sequence

=head1 CONFIGURATION AND ENVIRONMENT

    As written, this code makes heavy use of UNIX utilities and is
    therefore only supported on UNIX-like environemnts (e.g. Linux, UNIX, Mac
    OS X).

    Install Infernal, MAFFT, and the RNA Vienna package ahead of time and add
    the directories containing their executables to your PATH, so that the
    first time you run RNAmotifAnalysis.pm the configuration file (cluster.cfg)
    that is generated will have all of the correct parameters. Otherwise,
    you'll need to update the configuration file manually.

    To update the PATH environment variable with the directory '/usr/local/myapps/bin/',
    update your .bashrc file, thus:

        echo 'export PATH=/usr/local/myapps/bin:$PATH' >> ~/.bashrc.

    Now, every time you open a new terminal window, the PATH environment
    variable will contain '/usr/local/myapps/bin/'. To make your new .bashrc
    file effective immediately (i.e. without having to open a new terminal
    window), use the following command:

        source ~/.bashrc

=head1 INSTALLATION

    These installation instructions assume being able to open and use a
    terminal window on Linux.

    (0) Some systems need several dependencies installed ahead of time.

        You may be able to skip this step. However, if subsequent steps don't
        work, then be sure that some basic libraries are installed, as shown
        below (or ask a system administrator to take care of it). For the
        applicable distribution, open a terminal and then type the commands as
        indicated:

        For RedHat or CentOS 5.x systems (tested on CentOS 5.5)

                sudo yum install gcc

        For RedHat or CentOS 6.x systems (tested on "Minimal Desktop" CentOS 6.0)

                sudo yum install gcc
                sudo yum install perl-devel

        For Ubuntu systems (tested on Ubuntu 12-04 LTS)

                sudo apt-get install curl

        For Debian 5.x systems:

                sudo apt-get install gcc
                sudo apt-get install make

    (1) Install the non-Perl dependencies:
        (Versions shown are those that we've tested. Please contact us if
        newer versions do not work.)

        Infernal            1.0.2    (http://infernal.janelia.org/)
        MAFFT               6.849b   (http://mafft.cbrc.jp/alignment/software/)
        RNA Vienna package  1.8.4    (http://www.tbi.univie.ac.at/~ivo/RNA/)

        After installing these, make sure all of the foloowing executables are
        in directories within your PATH:

            cmbuild
            cmcalibrate
            cmsearch
            cmalign
            mafft
            RNAalifold

    (2) Use a CPAN client to install Bio::App::SELEX::RNAmotifAnalysis.

        Here we demonstrate the use of cpanminus to install it to a local Perl module directory. These instructions assume absolutely no experience with cpanminus.

              1. Download cpanminus

                    curl -LOk http://xrl.us/cpanm


              2. Make it executable

                    chmod u+x cpanm


              3. Make a local lib/perl5 directory (if it doesn't already exist)

                    mkdir -p ~/lib/perl5


              4. Add relevant directories to your PERL5LIB and PATH environment
                 variables by adding the following text to your ~/.bashrc
                 file:


                    # Set PERL5LIB if it doesn't already exist
                    : ${PERL5LIB:=~/lib/perl5}

                    # Prepend to PERL5LIB if directory not already found in PERL5LIB
                    if ! echo $PERL5LIB | egrep -q "(^|:)~/perl5/lib/perl5($|:)"; then
                        export PERL5LIB=~/lib/perl5:$PERL5LIB;
                    fi

                    # Prepend to PATH if directory not already found in PATH
                    if ! echo $PATH | egrep -q "(^|:)~/perl5/bin($|:)"; then
                        export PATH=~/bin:$PATH;
                    fi


              5. Update environment variables immediately

                    source ~/.bashrc


              6. Install Module::Build

                    ./cpanm Module::Build


              7. Install Text::LevenshteinXS (even if you already have it installed elsewhere)

                    ./cpanm Text::LevenshteinXS


              8. Install Bio::App::SELEX::RNAmotifAnalysis

                    ./cpanm Bio::App::SELEX::RNAmotifAnalysis


    Please contact the author if, after consulting this documentation and
    searching Google with error messages, you still encounter difficulties
    during the installation process.

=head1 INCOMPATIBILITIES

    Windows:     lacks necessary *nix utilities
    SGI:         problems with compiled dependency Text::LevenshteinXS
    Sun/Solaris: problems with compiled dependency Text::LevenshteinXS
    BSD:         problems with compiled dependency Text::LevenshteinXS

=head1 BUGS AND LIMITATIONS

     There are no known bugs in this module.
     Please report problems to molecules <at> cpan <dot> org
     Patches are welcome.

=head1 RELATED PUBLICATIONS

    Ditzler MA, Lange MJ, Bose D, Bottoms CA, Virkler KF, et al. (2013) High-
    throughput sequence analysis reveals structural diversity and improved
    potency among RNA inhibitors of HIV reverse transcriptase. Nucleic Acids
    Res 41(3):1873-1884. doi: 10.1093/nar/gks1190

=cut
