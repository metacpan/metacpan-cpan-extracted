package App::Anchr::Command::overlap;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "detect overlaps by daligner";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", ],
        [ "len|l=i", "minimal length of overlaps",   { default => 500 }, ],
        [ "idt|i=f", "minimal identity of overlaps", { default => 0.7 }, ],
        [ "serial", "serials instead of original names in the output file", ],
        [ "all",    "all overlaps instead of proper overlaps", ],
        [ "parallel|p=i", "number of threads", { default => 8 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr overlap [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tThis command is for small files.\n ";
    $desc .= "\tAll operations are running in a tempdir and no intermediate files are kept.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        my $message = "This command need one or more input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".ovlp.tsv";
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
    my $cwd     = Path::Tiny->cwd;
    my $tempdir = Path::Tiny->tempdir("anchr_ovlp_XXXXXXXX");
    chdir $tempdir;

    my $basename = $tempdir->basename();
    $basename =~ s/\W+/_/g;

    {    # Preprocess reads to format them for dazzler
        my $cmd = "cat";
        $cmd .= sprintf " %s", $_ for @infiles;
        $cmd .= " | anchr dazzname stdin -o stdout";
        $cmd .= " | faops filter -l 0 stdin renamed.fasta";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("stdout.replace.tsv")->is_file ) {
            Carp::croak "Failed: create stdout.replace.tsv\n";
        }
    }

    {    # Make the dazzler DB, each block is of size 50 MB
        my $cmd;
        $cmd .= "fasta2DB $basename renamed.fasta";
        $cmd .= " && DBdust $basename";
        $cmd .= " && DBsplit -s50 $basename";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("$basename.db")->is_file ) {
            Carp::croak "Failed: fasta2DB\n";
        }
    }

    {    # Run daligner
        my $block_number;
        for my $line ( $tempdir->child("$basename.db")->lines ) {
            if ( $line =~ /^blocks\s+=\s+(\d+)/ ) {
                $block_number = $1;
                last;
            }
        }

        my $cmd
            = "HPC.daligner $basename -M16 -T$opt->{parallel} -e$opt->{idt} -l$opt->{len} -s$opt->{len} -mdust | bash";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( defined $block_number and $block_number > 1 ) {
            $cmd = "LAcat $basename.#.las > $basename.las";
            App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        }

        if ( !$tempdir->child("$basename.las")->is_file ) {
            Carp::croak "Failed: daligner\n";
        }
    }

    {    # outputs
        my $cmd = "LAshow -o $basename.db $basename.las > show.txt";
        if ( $opt->{all} ) {
            $cmd = "LAshow $basename.db $basename.las > show.txt";
        }
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("show.txt")->is_file ) {
            Carp::croak "Failed: LAshow\n";
        }

        $cmd = "anchr show2ovlp renamed.fasta show.txt";
        if ( !$opt->{serial} ) {
            $cmd .= " -r stdout.replace.tsv";
        }
        $cmd .= " -o $opt->{outfile}";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    chdir $cwd;
}

1;
