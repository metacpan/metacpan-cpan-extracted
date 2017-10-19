package App::Anchr::Command::overlap2;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "detect overlaps between two (large) files by daligner";

sub opt_spec {
    return (
        [ "dir|d=s",      "working directory",            { default => "." }, ],
        [ "p1=s",         "prefix of first file",         { default => "anchor" }, ],
        [ "p2=s",         "prefix of second file",        { default => "long" }, ],
        [ "pd=s",         "prefix of result files", ],
        [ "block|b=i",    "block size in Mbp",            { default => 20 }, ],
        [ "len|l=i",      "minimal length of overlaps",   { default => 1000 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default => 0.8 }, ],
        [ "all",          "all overlaps instead of proper overlaps", ],
        [ "parallel|p=i", "number of threads",            { default => 8 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr overlap2 [options] <infile1> <infile2>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tAll intermediate files (.fasta, .replace.tsv, .db, .las, .show.txt, .ovlp.tsv)";
    $desc .= " are keept in the working directory.\n";
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

    $opt->{dir} = Path::Tiny::path( $opt->{dir} )->absolute()->stringify;

    if ( $opt->{p1} eq $opt->{p2} ) {
        $self->usage_error("Two prefixes shouldn't be same.");
    }

    if ( !exists $opt->{pd} ) {
        $opt->{pd} = $opt->{p1} . ucfirst( $opt->{p2} );
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type Path::Tiny
    my $out_dir = Path::Tiny::path( $opt->{dir} );
    $out_dir->mkpath();

    # absolute paths before we chdir to $out_dir
    my $file1 = Path::Tiny::path( $args->[0] )->absolute->stringify;
    my $file2 = Path::Tiny::path( $args->[1] )->absolute->stringify;

    # enter out dir
    chdir $out_dir;

    {    # Preprocess first file for dazzler
        my $cmd;
        $cmd .= "faops filter -l 0 $file1 stdout";
        $cmd .= " | anchr dazzname --prefix $opt->{p1} stdin -o stdout";
        $cmd .= " > $opt->{p1}.fasta";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$out_dir->child("stdout.replace.tsv")->is_file ) {
            Carp::croak "Failed: create $opt->{p1}.replace.tsv\n";
        }
        else {
            $out_dir->child("stdout.replace.tsv")->move("$opt->{p1}.replace.tsv");
        }
    }

    chomp( my $first_sum   = `faops n50 -H -N 0 -S $opt->{p1}.fasta` );
    chomp( my $first_count = `faops n50 -H -N 0 -C $opt->{p1}.fasta` );

    {    # Preprocess second file for dazzler
        my $second_start = $first_count + 1;
        my $cmd;
        $cmd .= "faops filter -l 0 -u -a $opt->{len} $file2 stdout";
        $cmd .= " | anchr dazzname --prefix $opt->{p2} --start $second_start stdin -o stdout";
        $cmd .= " > $opt->{p2}.fasta";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$out_dir->child("stdout.replace.tsv")->is_file ) {
            Carp::croak "Failed: create $opt->{p2}.replace.tsv\n";
        }
        else {
            $out_dir->child("stdout.replace.tsv")->move("$opt->{p2}.replace.tsv");
        }
    }

    {    # Make the dazzler DB
        if (   $out_dir->child( $opt->{pd} . ".db" )->is_file
            or $out_dir->child( "." . $opt->{pd} . ".bps" )->is_file )
        {
            App::Anchr::Common::exec_cmd( "DBrm $opt->{pd}", { verbose => $opt->{verbose}, } );
        }

        my $cmd;
        $cmd .= "fasta2DB $opt->{pd} $opt->{p1}.fasta";
        $cmd .= " && fasta2DB $opt->{pd} $opt->{p2}.fasta";
        $cmd .= " && DBdust $opt->{pd}";
        $cmd .= " && DBsplit -s$opt->{block} $opt->{pd}";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$out_dir->child("$opt->{pd}.db")->is_file ) {
            Carp::croak "Failed: fasta2DB\n";
        }
    }

    {    # Run daligner
        my $block_number;
        for my $line ( $out_dir->child("$opt->{pd}.db")->lines ) {
            if ( $line =~ /^blocks\s+=\s+(\d+)/ ) {
                $block_number = $1;
                last;
            }
        }

        my $first_idx = int( $first_sum / 1_000_000 / $opt->{block} + 1 );

        print STDERR YAML::Syck::Dump {
            first_sum    => $first_sum,
            first_count  => $first_count,
            first_idx    => $first_idx,
            block_number => $block_number,
            block_size   => $opt->{block},
            }
            if $opt->{verbose};

        if (   $out_dir->child( $opt->{pd} . ".las" )->is_file
            or $out_dir->child( $opt->{pd} . ".1.las" )->is_file )
        {
            App::Anchr::Common::exec_cmd( "rm $opt->{pd}*.las", { verbose => $opt->{verbose}, } );
        }

        # Don't use HPC.daligner as we want to avoid all-vs-all comparisions.
        # HPC.daligner tries to give every sequences the same change to match with others.
        for my $i ( 1 .. $first_idx ) {

            # Start from $i instead of $first_idx for conveniences of LAmerge
            for my $j ( $i .. $block_number ) {
                my $cmd;
                $cmd .= "daligner -M16 -T$opt->{parallel}";
                $cmd .= " -e$opt->{idt} -l$opt->{len} -s$opt->{len} -mdust";
                $cmd .= " $opt->{pd}.$i $opt->{pd}.$j";
                $cmd .= " && LAcheck -vS $opt->{pd} $opt->{pd}.$i.$opt->{pd}.$j";
                $cmd .= " && LAcheck -vS $opt->{pd} $opt->{pd}.$j.$opt->{pd}.$i";

                App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }
        }

        for my $i ( 1 .. $first_idx ) {
            my $cmd;
            $cmd .= "LAmerge $opt->{pd}.$i";

            for my $j ( 1 .. $block_number ) {
                $cmd .= " $opt->{pd}.$i.$opt->{pd}.$j";
            }

            $cmd .= " && LAcheck -vS $opt->{pd} $opt->{pd}.$i";

            App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
        }

        App::Anchr::Common::exec_cmd( "rm $opt->{pd}.*.$opt->{pd}.*.las",
            { verbose => $opt->{verbose}, } );

        {
            my $cmd;
            $cmd .= "LAcat $opt->{pd}.#.las > $opt->{pd}.las";
            App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

            App::Anchr::Common::exec_cmd( "rm $opt->{pd}.*.las", { verbose => $opt->{verbose}, } );
        }

        if ( !$out_dir->child("$opt->{pd}.las")->is_file ) {
            Carp::croak "Failed: daligner\n";
        }
    }

    {    # outputs
        my $cmd = "LAshow -o $opt->{pd}.db $opt->{pd}.las > $opt->{pd}.show.txt";
        if ( $opt->{all} ) {
            $cmd = "LAshow $opt->{pd}.db $opt->{pd}.las > $opt->{pd}.show.txt";
        }
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$out_dir->child("$opt->{pd}.show.txt")->is_file ) {
            Carp::croak "Failed: LAshow\n";
        }

        $cmd = "cat $opt->{p1}.fasta $opt->{p2}.fasta ";
        $cmd .= " | anchr show2ovlp stdin $opt->{pd}.show.txt";
        $cmd .= " -o $opt->{pd}.ovlp.tsv";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

}

1;
