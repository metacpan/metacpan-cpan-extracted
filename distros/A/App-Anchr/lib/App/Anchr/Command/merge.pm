package App::Anchr::Command::merge;
use strict;
use warnings;
use autodie;

use App::Anchr - command;
use App::Anchr::Common;

use constant abstract => "merge overlapped super-reads, k-unitigs, or anchors";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", ],
        [ "len|l=i",      "minimal length of overlaps",   { default => 1000 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default => 0.98 }, ],
        [ "parallel|p=i", "number of threads",            { default => 8 }, ],
        [ "verbose|v",    "verbose mode", ],
        [ "png",          "write a png file via graphviz", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr merge [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tAll operations are running in a tempdir and no intermediate files are kept.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 1 ) {
        my $message = "This command need one input file.\n\tIt found";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".merge.fasta";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # absolute pathes as we will chdir to tempdir later
    my $infile = Path::Tiny::path( $args->[0] )->absolute->stringify;

    if ( lc $opt->{outfile} ne "stdout" ) {
        $opt->{outfile} = Path::Tiny::path( $opt->{outfile} )->absolute->stringify;
    }

    # record cwd, we'll return there
    my $cwd     = Path::Tiny->cwd;
    my $tempdir = Path::Tiny->tempdir("anchr_merge_XXXXXXXX");
    chdir $tempdir;

    {    # overlaps
        my $cmd;
        $cmd .= "anchr overlap";
        $cmd .= " --len $opt->{len} --idt $opt->{idt} --parallel $opt->{parallel}";
        $cmd .= " $infile";
        $cmd .= " -o merge.ovlp.tsv";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("merge.ovlp.tsv")->is_file ) {
            Carp::croak "Failed: create merge.ovlp.tsv\n";
        }
    }

    my $graph = Graph->new( directed => 1 );
    {    # build graph
        my %seen_pair;
        for my $line ( $tempdir->child("merge.ovlp.tsv")->lines( { chomp => 1, } ) ) {
            my $info = App::Anchr::Common::parse_ovlp_line($line);

            # ignore self overlapping
            next if $info->{f_id} eq $info->{g_id};

            # ignore poor overlaps
            next if $info->{ovlp_idt} < $opt->{idt};
            next if $info->{ovlp_len} < $opt->{len};

            # we've orient overlapped sequences to the same strand
            next if $info->{g_strand} == 1;

            # skip duplicated overlaps
            my $pair = join( "-", sort ( $info->{f_id}, $info->{g_id} ) );
            next if $seen_pair{$pair};
            $seen_pair{$pair}++;

            # contained anchors have been removed
            if ( $info->{f_B} > 0 ) {
                if ( $info->{f_E} == $info->{f_len} ) {

                    #          f.B        f.E
                    # f ========+---------->
                    # g         -----------+=======>
                    #          g.B        g.E
                    $graph->add_weighted_edge( $info->{f_id}, $info->{g_id},
                        $info->{g_len} - $info->{g_E} );
                }
            }
            else {
                if ( $info->{g_E} == $info->{g_len} ) {

                    #          f.B        f.E
                    # f         -----------+=======>
                    # g ========+---------->
                    #          g.B        g.E
                    $graph->add_weighted_edge( $info->{g_id}, $info->{f_id},
                        $info->{f_len} - $info->{f_E} );
                }
            }
        }

        # Remove cyclic nodes
        while ( $graph->has_a_cycle ) {
            my @cycles = $graph->find_a_cycle;

            for my $v (@cycles) {
                for my $s ( $graph->successors($v) ) {
                    $graph->delete_edge( $v, $s ) if $graph->has_edge( $v, $s );
                }

                for my $p ( $graph->predecessors($v) ) {
                    $graph->delete_edge( $p, $v ) if $graph->has_edge( $p, $v );
                }
                $graph->delete_vertex($v);
            }
        }

        # Branching nodes will stay
        #
        # Remove branching nodes
        #        for my $v ( $graph->vertices ) {
        #            if ( $graph->out_degree($v) > 1 or $graph->in_degree($v) > 1 ) {
        #                $graph->delete_vertex($v);
        #            }
        #        }

        $tempdir->child("overlapped.txt")->spew( map {"$_\n"} $graph->vertices );

        if ( $opt->{png} ) {
            App::Anchr::Common::g2gv( $graph, $infile . ".png" );
        }
    }

    {    # Output non-overlapped
        my $cmd;
        $cmd .= "faops some -i -l 0 $infile overlapped.txt non-overlapped.fasta";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    #----------------------------#
    # loading sequences
    #----------------------------#
    my $seq_of = App::Fasops::Common::read_fasta($infile);

    #----------------------------#
    # merge
    #----------------------------#
    {
        my @topo_sorted = $graph->topological_sort;

        my %merge_of;
        my $count = 1;
        for my $wcc ( $graph->weakly_connected_components ) {
            my @pieces = @{$wcc};
            my $copy   = scalar @pieces;
            next if $copy == 1;

            my %idx_of;
            for my $p (@pieces) {
                $idx_of{$p} = App::Fasops::Common::firstidx { $_ eq $p } @topo_sorted;
            }

            @pieces = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map { [ $_, $idx_of{$_} ] } @pieces;

            my $flag_start = 1;
            for my $i ( 0 .. $#pieces - 1 ) {
                my $anchor_0 = $pieces[$i];
                my $anchor_1 = $pieces[ $i + 1 ];

                if ($flag_start) {
                    $merge_of{$count} = $seq_of->{$anchor_0};
                    $flag_start = 0;
                }

                if ( $graph->has_edge( $anchor_0, $anchor_1 ) ) {
                    my $weight = $graph->get_edge_weight( $anchor_0, $anchor_1 );
                    $merge_of{$count} .= substr $seq_of->{$anchor_1}, -$weight;
                }
                else {
                    $count++;
                    $merge_of{$count} = $seq_of->{$anchor_1};
                }
            }

            $count++;
        }

        my @contents = map { ( ">merge_$_", $merge_of{$_}, ) } sort { $a <=> $b } keys %merge_of;
        $tempdir->child("merged.fasta")->spew( map {"$_\n"} @contents );
    }

    {    # Outputs. stdout is handeld by faops
        my $cmd;
        $cmd .= "cat non-overlapped.fasta merged.fasta";
        $cmd .= " | faops filter -l 0 stdin";
        $cmd .= " $opt->{outfile}";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    chdir $cwd;
}

1;
