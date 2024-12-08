package App::Egaz::Command::blastn;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'blastn wrapper between two fasta files';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ "evalue=f",    "expectation value (E) threshold",      { default => 0.01 }, ],
        [ "wordsize=i",  "length of best perfect match",         { default => 40 }, ],
        [   "outfmt=s", "out format",
            { default => "7 qseqid sseqid qstart qend sstart send qlen slen nident" },
        ],
        [ "tmp=s", "user defined tempdir", ],
        [ "parallel|p=i", "number of threads", { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz blastn [options] <infile> <genome.fa>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> should be a blocked fasta file (*.fas)
* <genome.fa> is a multi-sequence fasta file contains genome sequences
* `makeblastdb` and `blastn` should be in $PATH

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
        my $message = "This command need two input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # absolute pathes as we will chdir to tempdir later
    my @infiles;
    for my $infile ( @{$args} ) {
        push @infiles, Path::Tiny::path($infile)->absolute->stringify;
    }

    if ( lc $opt->{outfile} ne "stdout" ) {
        $opt->{outfile} = Path::Tiny::path( $opt->{outfile} )->absolute->stringify;
    }

    # record cwd, we'll return there
    my $cwd = Path::Tiny->cwd;
    my $tempdir;
    if ( $opt->{tmp} ) {
        $tempdir = Path::Tiny->tempdir(
            TEMPLATE => "blastn_XXXXXXXX",
            DIR      => $opt->{tmp},
        );
    }
    else {
        $tempdir = Path::Tiny->tempdir("blastn_XXXXXXXX");
    }
    chdir $tempdir;

    my $basename = $tempdir->basename();
    $basename =~ s/\W+/_/g;

    {    # makeblastdb
        my $cmd = "makeblastdb -dbtype nucl -in $infiles[1] -out $basename -logfile $basename.log";
        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        if ( !$tempdir->child("$basename.nsq")->is_file ) {
            Carp::croak "Failed: makeblastdb\n";
        }
    }

    {    # blastn
        my $cmd
            = sprintf "blastn -task megablast"
            . " -max_target_seqs 20 -culling_limit 20"    # reduce size of reports
            . " -dust no -soft_masking false"             # disable dust and soft masking
            . " -evalue $opt->{evalue} -word_size $opt->{wordsize}"
            . " -outfmt '$opt->{outfmt}'"
            . " -num_threads $opt->{parallel} -db $basename -query $infiles[0]"
            . " -out $basename.blast";

        my $blastn_usage = `blastn -h`;
        if ( $blastn_usage =~ /\-max_hsps int/ ) {
            $cmd .= " -max_hsps 10";                      # Nucleotide-Nucleotide BLAST 2.6.0+
        }
        elsif ( $blastn_usage =~ /\-max_hsps_per_subject int/ ) {
            $cmd .= " -max_hsps_per_subject 10";          # Nucleotide-Nucleotide BLAST 2.2.28+
        }

        App::Egaz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        if ( !$tempdir->child("$basename.blast")->is_file ) {
            Carp::croak "Failed: blastn\n";
        }
    }

    {                                                     # outputs
        if ( lc $opt->{outfile} ne "stdout" ) {
            Path::Tiny::path("$basename.blast")->copy( $opt->{outfile} );
        }
        else {
            print Path::Tiny::path("$basename.blast")->slurp;
        }
    }

    chdir $cwd;
}

1;
