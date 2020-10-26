package App::Dazz::Command::contained;
use strict;
use warnings;
use autodie;

use App::Dazz - command;
use App::Dazz::Common;

use constant abstract => "discard contained unitigs";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", ],
        [ "len|l=i",      "minimal length of overlaps",   { default => 500 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default => 0.98 }, ],
        [ "proportion=f", "nearly contained proportion",  { default => 0.98 }, ],
        [ "prefix=s",     "prefix of names",              { default => "infile" }, ],
        [ "tmp=s",        "user defined tempdir", ],
        [ "parallel|p=i", "number of threads",            { default => 8 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "dazz contained [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".contained.fasta";
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
            TEMPLATE => "dazz_contained_XXXXXXXX",
            DIR      => $opt->{tmp},
        );
    }
    else {
        $tempdir = Path::Tiny->tempdir("dazz_contained_XXXXXXXX");
    }
    chdir $tempdir;

    my $basename = $tempdir->basename();
    $basename =~ s/\W+/_/g;

    {    # filter short contigs then rename reads as there're duplicated names
        for my $i ( 0 .. $#infiles ) {
            my $cmd;
            $cmd .= "faops filter -a $opt->{len} -l 0 $infiles[$i] stdout";
            $cmd .= " | faops dazz -p $opt->{prefix}_$i stdin infile.$i.fasta";

            App::Dazz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, }, );
        }
    }

    {    # overlaps
        my $cmd;
        $cmd .= "dazz overlap";
        $cmd .= " --len $opt->{len} --idt $opt->{idt} --parallel $opt->{parallel}";
        $cmd .= sprintf " infile.%d.fasta", $_ for ( 0 .. $#infiles );
        $cmd .= " -o contained.ovlp.tsv";
        App::Dazz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("contained.ovlp.tsv")->is_file ) {
            Carp::croak "Failed: create contained.ovlp.tsv\n";
        }
    }

    {    # discard some SR
        my @discards;
        my %seen_pair;
        for my $line ( $tempdir->child("contained.ovlp.tsv")->lines( { chomp => 1, } ) ) {
            my $info = App::Dazz::Common::parse_ovlp_line($line);

            # ignore self overlapping
            next if $info->{f_id} eq $info->{g_id};

            # ignore poor overlaps
            next if $info->{ovlp_idt} < $opt->{idt};
            next if $info->{ovlp_len} < $opt->{len};

            # skip duplicated overlaps
            my $pair = join( "-", sort ( $info->{f_id}, $info->{g_id} ) );
            next if $seen_pair{$pair};
            $seen_pair{$pair}++;

            # discard contained SR
            if ( $info->{contained} eq q{contains} ) {
                push @discards, $info->{g_id};
                next;
            }
            if ( $info->{contained} eq q{contained} ) {
                push @discards, $info->{f_id};
                next;
            }

            # discard nearly contained SR
            my $f_r = $info->{ovlp_len} / $info->{f_len};
            my $g_r = $info->{ovlp_len} / $info->{g_len};

            if ( $f_r <= $opt->{proportion} and $g_r > $opt->{proportion} ) {
                push @discards, $info->{g_id};
                next;
            }

            if ( $g_r <= $opt->{proportion} and $f_r > $opt->{proportion} ) {
                push @discards, $info->{f_id};
                next;
            }

            if ( $f_r > $opt->{proportion} and $g_r > $opt->{proportion} ) {
                if ( $info->{f_len} >= $info->{g_len} ) {
                    push @discards, $info->{g_id};
                }
                else {
                    push @discards, $info->{f_id};
                }
                next;
            }
        }

        @discards = App::Fasops::Common::uniq( sort @discards );
        $tempdir->child("discard.txt")->spew( map {"$_\n"} @discards );
    }

    {    # Outputs. stdout is handeld by faops
        my $cmd = "cat";
        $cmd .= sprintf " infile.%d.fasta", $_ for ( 0 .. $#infiles );
        $cmd .= " | faops some -i -l 0 stdin discard.txt $opt->{outfile}";
        App::Dazz::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    chdir $cwd;
}

1;
