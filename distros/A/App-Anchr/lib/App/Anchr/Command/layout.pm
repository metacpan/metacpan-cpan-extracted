package App::Anchr::Command::layout;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "layout anthor group";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename", ],
        [ 'border=i', 'length of borders in anchors', { default => 100 }, ],
        [ "max=i",    "max distance",                 { default => 5000 }, ],
        [ 'pa=s',     'prefix of anchors',            { default => "anchor" }, ],
        [ 'oa=s',     'overlaps between anchors', ],
        [ "png",      "write a png file via graphviz", ],
        { show_defaults => 1, },
    );
}

sub usage_desc {
    return "anchr layout [options] <.ovlp.tsv> <.relation.tsv> <strand.fasta>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 3 ) {
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

    if ( $opt->{oa} ) {
        if ( !Path::Tiny::path( $opt->{oa} )->is_file ) {
            $self->usage_error("The overlap file [$opt->{oa}] doesn't exist.\n");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".contig.fasta";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # load overlaps and build graph
    #----------------------------#
    my $graph = Graph->new( directed => 1 );
    my %is_anchor;
    my $links_of = {};    # long_id => { anchor_id => overlap_on_long, }
    {
        open my $in_fh, "<", $args->[0];

        my %seen_pair;
        while ( my $line = <$in_fh> ) {
            my $info = App::Anchr::Common::parse_ovlp_line($line);

            # ignore self overlapping
            next if $info->{f_id} eq $info->{g_id};

            # we've orient all sequences to the same strand
            next if $info->{g_strand} == 1;

            # skip duplicated overlaps
            my $pair = join( "-", sort ( $info->{f_id}, $info->{g_id} ) );
            next if $seen_pair{$pair};
            $seen_pair{$pair}++;

            $is_anchor{ $info->{f_id} }++ if ( index( $info->{f_id}, $opt->{pa} . "/" ) == 0 );
            $is_anchor{ $info->{g_id} }++ if ( index( $info->{g_id}, $opt->{pa} . "/" ) == 0 );

            if ( $info->{f_B} > 0 ) {

                if ( $info->{f_E} == $info->{f_len} ) {

                    #          f.B        f.E
                    # f ========+---------->
                    # g         -----------+=======>
                    #          g.B        g.E
                    $graph->add_weighted_edge( $info->{f_id}, $info->{g_id},
                        $info->{g_len} - $info->{g_E} );
                }
                else {
                    #          f.B        f.E
                    # f ========+----------+=======>
                    # g         ----------->
                    #          g.B        g.E
                    $graph->add_weighted_edge( $info->{g_id}, $info->{f_id},
                        $info->{f_len} - $info->{f_E} );
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
                else {
                    #          f.B        f.E
                    # f         ----------->
                    # g ========+----------+=======>
                    #          g.B        g.E
                    $graph->add_weighted_edge( $info->{f_id}, $info->{g_id},
                        $info->{g_len} - $info->{g_E} );
                }
            }

            if ( $is_anchor{ $info->{f_id} } and !$is_anchor{ $info->{g_id} } ) {
                my ( $beg, $end ) = App::Anchr::Common::beg_end( $info->{g_B}, $info->{g_E}, );
                $links_of->{ $info->{g_id} }{ $info->{f_id} }
                    = AlignDB::IntSpan->new->add_pair( $beg, $end );
            }
            elsif ( $is_anchor{ $info->{g_id} } and !$is_anchor{ $info->{f_id} } ) {
                my ( $beg, $end ) = App::Anchr::Common::beg_end( $info->{f_B}, $info->{f_E}, );
                $links_of->{ $info->{f_id} }{ $info->{g_id} }
                    = AlignDB::IntSpan->new->add_pair( $beg, $end );
            }

        }
        close $in_fh;
    }

    #----------------------------#
    # Graph of anchors
    #----------------------------#
    my $anchor_graph = Graph->new( directed => 1 );
    {
        my @nodes = $graph->vertices;
        my @linkers = grep { !$is_anchor{$_} } @nodes;

        for my $l (@linkers) {
            my @p = grep { $is_anchor{$_} } $graph->predecessors($l);
            my @s = grep { $is_anchor{$_} } $graph->successors($l);

            for my $p (@p) {
                for my $s (@s) {
                    $anchor_graph->add_edge( $p, $s );
                }
            }

            if ( @p > 1 ) {
                @p = map { $_->[0] }
                    sort { $b->[1] <=> $a->[1] }
                    map { [ $_, $graph->get_edge_weight( $_, $l ) ] } @p;
                for my $i ( 0 .. $#p - 1 ) {
                    $anchor_graph->add_edge( $p[$i], $p[ $i + 1 ] );
                }
            }

            if ( @s > 1 ) {
                @s = map { $_->[0] }
                    sort { $a->[1] <=> $b->[1] }
                    map { [ $_, $graph->get_edge_weight( $l, $_, ) ] } @s;
                for my $i ( 0 .. $#s - 1 ) {
                    $anchor_graph->add_edge( $s[$i], $s[ $i + 1 ] );
                }
            }
        }

        if ( $opt->{png} ) {
            App::Anchr::Common::g2gv( $anchor_graph, $args->[0] . ".png" );
        }
        App::Anchr::Common::transitive_reduction($anchor_graph);
        if ( $opt->{png} ) {
            App::Anchr::Common::g2gv( $anchor_graph, $args->[0] . ".reduced.png" );
        }
    }

    #----------------------------#
    # existing relations
    #----------------------------#
    my $relation_of = {};
    {
        for my $line ( Path::Tiny::path( $args->[1] )->lines( { chomp => 1 } ) ) {
            my @fields = split "\t", $line;

            my $anchor_0   = $fields[0];
            my $anchor_1   = $fields[1];
            my @distances  = split ",", $fields[2];
            my @long_reads = split ",", $fields[3];

            my $pair = join "-", sort ( $anchor_0, $anchor_1, );
            $relation_of->{$pair} = {
                distances  => \@distances,
                long_reads => \@long_reads,
            };
        }
    }

    #----------------------------#
    # loading sequences
    #----------------------------#
    my $seq_of = App::Fasops::Common::read_fasta( $args->[2] );

    #----------------------------#
    # link anchors and break branches
    #----------------------------#
    my @paths;
    if ( $anchor_graph->is_dag ) {
        if ( scalar $anchor_graph->exterior_vertices == 2 ) {
            print STDERR "    Linear\n";

            my @ts = $anchor_graph->topological_sort;
            push @paths, \@ts;
        }
        else {
            print STDERR "    Branched\n";

            my @ts = $anchor_graph->topological_sort;

            my @branchings;
            my %idx_of;
            for my $idx ( 0 .. $#ts ) {
                $idx_of{ $ts[$idx] } = $idx;

                if (   $anchor_graph->out_degree( $ts[$idx] ) > 1
                    or $anchor_graph->in_degree( $ts[$idx] ) > 1 )
                {
                    push @branchings, $ts[$idx];
                }
            }

            $anchor_graph->delete_vertex($_) for @branchings;

            for my $wcc ( $anchor_graph->weakly_connected_components ) {
                my @cc = map { $_->[0] }
                    sort { $a->[1] <=> $b->[1] }
                    map { [ $_, $idx_of{$_} ] } @{$wcc};

                push @paths, \@cc;
            }

            # standalone branching nodes
            push @paths, [$_] for @branchings;
        }
    }
    else {
        print STDERR "    Cyclic\n";
        while ( $anchor_graph->has_a_cycle ) {
            my @cycles = $anchor_graph->find_a_cycle;
            $anchor_graph->delete_vertex($_) for @cycles;
            push @paths, [$_] for @cycles;
        }

        if ( scalar $anchor_graph->vertices ) {
            my @ts = $anchor_graph->topological_sort;
            my %idx_of;
            for my $idx ( 0 .. $#ts ) {
                $idx_of{ $ts[$idx] } = $idx;
            }

            for my $wcc ( $anchor_graph->weakly_connected_components ) {
                my @cc = map { $_->[0] }
                    sort { $a->[1] <=> $b->[1] }
                    map { [ $_, $idx_of{$_} ] } @{$wcc};

                push @paths, \@cc;
            }
        }
    }
    Path::Tiny::path( $opt->{outfile} . ".paths.yml" )->spew( YAML::Syck::Dump( \@paths ) );

    #----------------------------#
    # existing overlaps
    #----------------------------#
    my $existing_ovlp_of = {};
    if ( $opt->{oa} ) {
        open my $in_fh, "<", $opt->{oa};

        while ( my $line = <$in_fh> ) {
            my $info = App::Anchr::Common::parse_ovlp_line($line);

            # ignore self overlapping
            next if $info->{f_id} eq $info->{g_id};

            # we've orient all sequences to the same strand
            next if $info->{g_strand} == 1;

            my $pair = join( "-", sort ( $info->{f_id}, $info->{g_id} ) );

            $existing_ovlp_of->{$pair} = $info;
        }
        close $in_fh;
    }

    my $basename = Path::Tiny::path( $opt->{outfile} )->basename();
    ($basename) = split /\./, $basename;
    my $contig;
    my $count = 1;
    for my $i ( 0 .. $#paths ) {
        $contig .= sprintf ">%s_%d\n", $basename, $count;

        my @nodes = @{ $paths[$i] };

        if ( @nodes == 1 ) {
            $contig .= $seq_of->{ $nodes[0] };
            $contig .= "\n";
            $count++;
            next;
        }

        my $flag_start = 1;
        for my $j ( 0 .. $#nodes - 1 ) {
            my $anchor_0 = $nodes[$j];
            my $anchor_1 = $nodes[ $j + 1 ];
            my $pair     = join "-", sort ( $anchor_0, $anchor_1, );

            if ($flag_start) {
                $contig .= $seq_of->{$anchor_0};
                $flag_start = 0;
            }

            if ( !exists $relation_of->{$pair} ) {
                print STDERR "    No reliable links between $pair\n";
                $count++;
                $contig .= "\n";
                $contig .= sprintf ">%s_%d\n", $basename, $count;
                if ( $j == $#nodes - 1 ) {
                    $contig .= $seq_of->{$anchor_1};
                }

                $flag_start = 1;
                next;
            }

            my $seq_anchor_1 = $seq_of->{$anchor_1};

            if ( $existing_ovlp_of->{$pair} ) {
                my $ovlp_len = $existing_ovlp_of->{$pair}{ovlp_len};
                $contig .= substr $seq_anchor_1, $ovlp_len;
            }
            else {
                my $avg_distance
                    = int App::Fasops::Common::mean( @{ $relation_of->{$pair}{distances} } );

                if ( $avg_distance < 0 ) {
                    if ( abs($avg_distance) < 5 ) {
                        $contig .= substr $seq_anchor_1, abs($avg_distance);
                    }
                    else {
                        my $ovlp_len_120      = int( abs($avg_distance) * 1.2 );
                        my $ovlp_seq_contig   = substr $contig, -$ovlp_len_120;
                        my $ovlp_seq_anchor_1 = substr $seq_anchor_1, 0, $ovlp_len_120;

                        my $ovlp_seq;
                        if ( abs($avg_distance) < 30 ) {

                            # abs($avg_distance) should be less than 30.
                            # Larger overlaps have been detected by daligner (--oa)
                            my ( $lcss, $offset_contig, $offset_anchor_1 )
                                = App::Anchr::Common::lcss( $ovlp_seq_contig, $ovlp_seq_anchor_1 );

                            if ($lcss) {

                                # build overlap sequences
                                substr $ovlp_seq_contig,   $offset_contig,   length($lcss), "";
                                substr $ovlp_seq_anchor_1, $offset_anchor_1, length($lcss), "";
                                $ovlp_seq = $ovlp_seq_contig . $lcss . $ovlp_seq_anchor_1;
                            }
                            else {
                                # call poa
                                $ovlp_seq = App::Anchr::Common::poa_consensus(
                                    [ $ovlp_seq_contig, $ovlp_seq_anchor_1 ] );
                            }
                        }
                        else {
                            # call poa
                            $ovlp_seq = App::Anchr::Common::poa_consensus(
                                [ $ovlp_seq_contig, $ovlp_seq_anchor_1 ] );
                        }

                        # remove length of ovlp_len_120 from contig and anchor_1
                        substr $contig, -$ovlp_len_120, $ovlp_len_120, "";
                        substr $seq_anchor_1, 0, $ovlp_len_120, "";

                        $contig .= $ovlp_seq . $seq_anchor_1;
                    }
                }
                else {
                    my @spaces;
                    for my $long_read ( @{ $relation_of->{$pair}{long_reads} } ) {

                        #@type AlignDB::IntSpan
                        my $intspan_0 = $links_of->{$long_read}{$anchor_0};
                        next unless defined $intspan_0;

                        #@type AlignDB::IntSpan
                        my $intspan_1 = $links_of->{$long_read}{$anchor_1};
                        next unless defined $intspan_1;

                        # reduce ends
                        $intspan_0 = $intspan_0->trim( $opt->{border} );
                        $intspan_1 = $intspan_1->trim( $opt->{border} );

                        my $intspan_space = $intspan_0->union($intspan_1)->holes;
                        next if $intspan_space->is_empty;

                        push @spaces, $intspan_space->substr_span( $seq_of->{$long_read} );
                    }

                    my $left_border = substr $contig, -$opt->{border};
                    my $right_border = substr $seq_anchor_1, 0, $opt->{border};
                    for my $s (@spaces) {
                        substr $s, 0, $opt->{border}, $left_border;
                        substr $s, -$opt->{border}, $opt->{border}, $right_border;
                    }

                    my $space_seq = App::Anchr::Common::poa_consensus( \@spaces );

                    # remove length of $opt->{border} from contig and anchor_1
                    substr $contig, -$opt->{border}, $opt->{border}, "";
                    substr $seq_anchor_1, 0, $opt->{border}, "";

                    $contig .= $space_seq;
                    $contig .= $seq_anchor_1;
                }
            }
        }

        $contig .= "\n";
        $count++;
    }

    Path::Tiny::path( $opt->{outfile} )->spew($contig);
}

1;
