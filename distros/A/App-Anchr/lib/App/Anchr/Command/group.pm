package App::Anchr::Command::group;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "group anthors by long reads";

sub opt_spec {
    return (
        [ "dir|d=s", "output directory", ],
        [ "range|r=s",    "ranges of anchors",            { required => 1 }, ],
        [ "coverage|c=i", "minimal coverage",             { default  => 2 }, ],
        [ "max=i",        "max distance",                 { default  => 5000 }, ],
        [ "len|l=i",      "minimal length of overlaps",   { default  => 1000 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default  => 0.85 }, ],
        [ "keep",         "don't remove multi-matched reads", ],
        [ 'oa=s',         'overlaps between anchors', ],
        [ "parallel|p=i", "number of threads",            { default  => 4 }, ],
        [ "verbose|v",    "verbose mode", ],
        [ "png",          "write a png file via graphviz", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr group [options] <dazz DB> <ovlp file>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tThis command relies on an existing dazz db.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
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

    if ( !AlignDB::IntSpan->valid( $opt->{range} ) ) {
        $self->usage_error("Invalid --range [$opt->{range}]\n");
    }

    if ( $opt->{oa} ) {
        if ( !Path::Tiny::path( $opt->{oa} )->is_file ) {
            $self->usage_error("The overlap file [$opt->{oa}] doesn't exist.\n");
        }
    }

    if ( !exists $opt->{dir} ) {
        $opt->{dir}
            = Path::Tiny::path( $args->[0] )->parent->child("group")->absolute->stringify;
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type Path::Tiny
    my $out_dir = Path::Tiny::path( $opt->{dir} );
    $out_dir->mkpath();

    # absolute paths before we chdir to $out_dir
    my $fn_dazz = Path::Tiny::path( $args->[0] )->absolute->stringify;
    my $fn_ovlp = Path::Tiny::path( $args->[1] )->absolute->stringify;

    #@type AlignDB::IntSpan
    my $anchor_range = AlignDB::IntSpan->new->add_runlist( $opt->{range} );

    #----------------------------#
    # Load overlaps and build links
    #----------------------------#

    # Anchors may match to multiple parts of a long read.
    # Multi-matched overlapps would create cyclic paths and ruin the graph.
    # Some of these matchs are real, but more are false positives.
    # If sequences from a ZMW are not splitted into subreads properly, then a multi-matched overlap
    # is identified.
    #       ===
    # ------------>
    #              )
    #   <----------
    #       ===
    my $multi_matched = AlignDB::IntSpan->new;    # long_id

    my $links_of   = {};                          # long_id => { anchor_id => overlap_on_long, }
    my $strands_of = {};                          # long_id => { anchor_id => strand_to_long }
    {
        open my $in_fh, "<", $fn_ovlp;

        my %multi_match_of;
        my %seen_pair;

        while ( my $line = <$in_fh> ) {
            chomp $line;
            my @fields = split "\t", $line;
            next unless @fields == 13;

            my ( $f_id,     $g_id, $ovlp_len, $ovlp_idt ) = @fields[ 0 .. 3 ];
            my ( $f_strand, $f_B,  $f_E,      $f_len )    = @fields[ 4 .. 7 ];
            my ( $g_strand, $g_B,  $g_E,      $g_len )    = @fields[ 8 .. 11 ];
            my $contained = $fields[12];

            # ignore self overlapping
            next if $f_id eq $g_id;

            # ignore poor overlaps
            next if $ovlp_idt < $opt->{idt};
            next if $ovlp_len < $opt->{len};

            # only want anchor-long overlaps
            if ( $anchor_range->contains($f_id) and $anchor_range->contains($g_id) ) {
                next;
            }
            if ( !$anchor_range->contains($f_id) and !$anchor_range->contains($g_id) ) {
                next;
            }

            # record multi-matched
            if ( $anchor_range->contains($f_id) and !$anchor_range->contains($g_id) ) {
                my $pair = join( "-", ( $f_id, $g_id ) );
                my $matched
                    = AlignDB::IntSpan->new->add_pair( App::Anchr::Common::beg_end( $g_B, $g_E, ) );
                if ( !exists $multi_match_of{$pair} ) {
                    $multi_match_of{$pair} = $matched;
                }
                else {
                    my $i_set = $matched->intersect( $multi_match_of{$pair} );
                    if ( $i_set->is_empty ) {
                        $multi_matched->add($g_id);
                    }
                    elsif ( $i_set->size
                        / List::Util::max( $matched->size, $multi_match_of{$pair}->size ) < 0.9 )
                    {
                        $multi_matched->add($g_id);
                    }
                }
            }

            {    # skip duplicated overlaps
                my $pair = join( "-", sort ( $f_id, $g_id ) );
                next if $seen_pair{$pair};
                $seen_pair{$pair}++;
            }

            if ( $anchor_range->contains($f_id) and !$anchor_range->contains($g_id) ) {
                my ( $beg, $end ) = App::Anchr::Common::beg_end( $g_B, $g_E, );
                $links_of->{$g_id}{$f_id} = AlignDB::IntSpan->new->add_pair( $beg, $end );

                # $f_strand is always 0
                $strands_of->{$g_id}{$f_id} = $g_strand;
            }
            elsif ( $anchor_range->contains($g_id) and !$anchor_range->contains($f_id) ) {
                my ( $beg, $end ) = App::Anchr::Common::beg_end( $f_B, $f_E, );
                $links_of->{$f_id}{$g_id} = AlignDB::IntSpan->new->add_pair( $beg, $end );

                $strands_of->{$f_id}{$g_id} = $g_strand;
            }
        }
        close $in_fh;
    }

    if ( !$opt->{keep} ) {
        for my $long_id ( $multi_matched->as_array ) {
            if ( exists $links_of->{$long_id} ) {
                delete $links_of->{$long_id};
            }
            if ( exists $strands_of->{$long_id} ) {
                delete $strands_of->{$long_id};
            }
        }
    }

    my $graph = Graph->new( directed => 0 );
    for my $serial ( $anchor_range->as_array ) {
        $graph->add_vertex($serial);
    }
    {    # Grouping
        for my $long_id ( sort { $a <=> $b } keys %{$links_of} ) {
            my @anchors = sort { $a <=> $b }
                keys %{ $links_of->{$long_id} };

            my $count = scalar @anchors;

            # long reads overlapped with 2 or more anchors will participate in distances judgment
            next unless $count >= 2;

            for my $i ( 0 .. $count - 1 ) {
                for my $j ( $i + 1 .. $count - 1 ) {

                    #@type AlignDB::IntSpan
                    my $set_i = $links_of->{$long_id}{ $anchors[$i] };
                    next unless ref $set_i eq "AlignDB::IntSpan";
                    next if $set_i->is_empty;

                    #@type AlignDB::IntSpan
                    my $set_j = $links_of->{$long_id}{ $anchors[$j] };
                    next unless ref $set_j eq "AlignDB::IntSpan";
                    next if $set_j->is_empty;

                    my $distance = $set_i->distance($set_j);
                    next unless defined $distance;

                    my $strand_i = $strands_of->{$long_id}{ $anchors[$i] };
                    my $strand_j = $strands_of->{$long_id}{ $anchors[$j] };

                    my $strand = $strand_i == $strand_j ? 0 : 1;

                    $graph->add_edge( $anchors[$i], $anchors[$j] );

                    # long_ids
                    if ( $graph->has_edge_attribute( $anchors[$i], $anchors[$j], "long_ids" ) ) {
                        my $long_ids_ref
                            = $graph->get_edge_attribute( $anchors[$i], $anchors[$j], "long_ids" );
                        push @{$long_ids_ref}, $long_id;
                    }
                    else {
                        $graph->set_edge_attribute( $anchors[$i], $anchors[$j], "long_ids",
                            [$long_id], );
                    }

                    # distances between anchors
                    if ( $graph->has_edge_attribute( $anchors[$i], $anchors[$j], "distances" ) ) {
                        my $distances_ref
                            = $graph->get_edge_attribute( $anchors[$i], $anchors[$j], "distances" );
                        push @{$distances_ref}, $distance;
                    }
                    else {
                        $graph->set_edge_attribute( $anchors[$i], $anchors[$j], "distances",
                            [$distance], );
                    }

                    # strands
                    if ( $graph->has_edge_attribute( $anchors[$i], $anchors[$j], "strands" ) ) {
                        my $strands_ref
                            = $graph->get_edge_attribute( $anchors[$i], $anchors[$j], "strands" );
                        push @{$strands_ref}, $strand;
                    }
                    else {
                        $graph->set_edge_attribute( $anchors[$i], $anchors[$j], "strands",
                            [$strand], );
                    }
                }
            }
        }

        # overlaps between anchors
        my $anchor_ovlp_of = {};
        if ( $opt->{oa} ) {
            open my $in_fh, "<", $opt->{oa};

            while ( my $line = <$in_fh> ) {
                my $info = App::Anchr::Common::parse_ovlp_line($line);

                # ignore self overlapping
                next if $info->{f_id} eq $info->{g_id};

                my $pair = join( "-", sort ( $info->{f_id}, $info->{g_id} ) );

                $anchor_ovlp_of->{$pair} = $info;
            }
            close $in_fh;
        }

        # Delete unreliable edges
        for my $edge ( $graph->edges ) {

            # if enough long reads support overlaps between anchors, ignore other long reads
            my $pair = join( "-", sort ( @{$edge} ) );
            if ( exists $anchor_ovlp_of->{$pair} ) {
                my $d_ref = $graph->get_edge_attribute( @{$edge}, "distances" );
                my @indexes = grep { $d_ref->[$_] < 0 } ( 0 .. scalar @{$d_ref} - 1 );

                if ( @indexes >= $opt->{coverage} and ( @indexes / @{$d_ref} ) >= 0.6 ) {
                    my $id_ref     = $graph->get_edge_attribute( @{$edge}, "long_ids" );
                    my $strand_ref = $graph->get_edge_attribute( @{$edge}, "strands" );

                    # distances are negative
                    my ( @new_d, @new_id, @new_strand );
                    for my $i (@indexes) {
                        push @new_d,      $d_ref->[$i];
                        push @new_id,     $id_ref->[$i];
                        push @new_strand, $strand_ref->[$i];
                    }

                    $graph->set_edge_attribute( @{$edge}, "distances", \@new_d );
                    $graph->set_edge_attribute( @{$edge}, "long_ids",  \@new_id );
                    $graph->set_edge_attribute( @{$edge}, "strands",   \@new_strand );
                }
            }

            # numbers of long reads less than $opt->{coverage}
            my $long_ids_ref = $graph->get_edge_attribute( @{$edge}, "long_ids" );
            if ( scalar @{$long_ids_ref} < $opt->{coverage} ) {
                $graph->delete_edge( @{$edge} );
                next;
            }

            # non-consistent distances
            my $distances_ref = $graph->get_edge_attribute( @{$edge}, "distances" );
            if ( !App::Anchr::Common::judge_distance( $distances_ref, $opt->{max}, ) ) {
                $graph->delete_edge( @{$edge} );
                next;
            }

            # non-consistent strands
            my $strands_ref = $graph->get_edge_attribute( @{$edge}, "strands" );
            my @strands = App::Fasops::Common::uniq( @{$strands_ref} );
            if ( @strands != 1 ) {
                $graph->delete_edge( @{$edge} );
                next;
            }
        }
    }

    #----------------------------#
    # Outputs
    #----------------------------#
    my @ccs         = $graph->connected_components();
    my $non_grouped = AlignDB::IntSpan->new;
    for my $cc ( grep { scalar @{$_} == 1 } @ccs ) {
        $non_grouped->add( $cc->[0] );
    }

    if ( !$non_grouped->is_empty ) {
        printf STDERR "Non-grouped: %s\n", $non_grouped;
        printf STDERR "Count: %d/%d\n", $non_grouped->size, $anchor_range->size;

        my $cmd;
        $cmd .= "DBshow -U $fn_dazz ";
        $cmd .= join " ", $non_grouped->as_array;
        $cmd .= " | faops filter -l 0 stdin stdout";
        $cmd .= " > " . $out_dir->child("non_grouped.fasta")->stringify;
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    }

    $out_dir->child("groups.txt")->remove;
    @ccs = map { $_->[0] }
        sort { $b->[1] <=> $a->[1] }
        map { [ $_, scalar( @{$_} ) ] }
        grep { scalar @{$_} > 1 } @ccs;

    my $cc_serial = 1;
    for my $cc (@ccs) {
        my @members  = sort { $a <=> $b } @{$cc};
        my $count    = scalar @members;
        my $basename = sprintf "%s_%s", $cc_serial, $count;

        $out_dir->child("groups.txt")->append("$basename\n");

        #----------------------------#
        # anchors
        #----------------------------#
        if ( $count > 0 ) {
            my $cmd;
            $cmd .= "DBshow -U $fn_dazz ";
            $cmd .= join " ", @members;
            $cmd .= " | faops filter -l 0 stdin stdout";
            $cmd .= " > " . $out_dir->child("$basename.anchor.fasta")->stringify;

            system $cmd;
        }

        #----------------------------#
        # distances and long reads
        #----------------------------#
        my $long_id_set = AlignDB::IntSpan->new;
        {

            # anchor_i => anchor_j => [[distances], [long_ids]]
            my $relation_of = {};
            my @anchor_long_pairs;

            for my $i ( 0 .. $count - 1 ) {
                for my $j ( $i + 1 .. $count - 1 ) {
                    if ( $graph->has_edge( $members[$i], $members[$j], ) ) {
                        my $distances_ref
                            = $graph->get_edge_attribute( $members[$i], $members[$j], "distances" );

                        my $long_ids_ref
                            = $graph->get_edge_attribute( $members[$i], $members[$j], "long_ids" );

                        $long_id_set->add( @{$long_ids_ref} );

                        $relation_of->{ $members[$i] }{ $members[$j] }
                            = [ $distances_ref, $long_ids_ref ];

                        for my $long_id ( @{$long_ids_ref} ) {
                            push @anchor_long_pairs, [ $members[$i], $long_id ];
                            push @anchor_long_pairs, [ $members[$j], $long_id ];
                        }
                    }
                }
            }

            # serials to names
            my $name_of
                = App::Anchr::Common::serial2name( $fn_dazz, [ @members, $long_id_set->as_array ] );

            my $fn_relation = $out_dir->child("$basename.relation.tsv");
            $fn_relation->remove;
            for my $key_i ( sort keys %{$relation_of} ) {
                for my $key_j ( sort keys %{ $relation_of->{$key_i} } ) {
                    my $str_dis = join( ",", @{ $relation_of->{$key_i}{$key_j}[0] } );
                    my $str_long = join( ",",
                        map { $name_of->{$_} } @{ $relation_of->{$key_i}{$key_j}[1] } );
                    my $line = sprintf "%s\t%s\t%s\t%s\n", $name_of->{$key_i},
                        $name_of->{$key_j}, $str_dis, $str_long;
                    $fn_relation->append($line);
                }
            }

            @anchor_long_pairs = sort
                map { sprintf( "%s\t%s\n", $name_of->{ $_->[0] }, $name_of->{ $_->[1] } ) }
                @anchor_long_pairs;
            @anchor_long_pairs = App::Fasops::Common::uniq(@anchor_long_pairs);
            $out_dir->child("$basename.restrict.tsv")->spew(@anchor_long_pairs);
        }

        #----------------------------#
        # long reads
        #----------------------------#
        if ( !$long_id_set->is_empty ) {
            my $cmd;
            $cmd .= "DBshow -U $fn_dazz ";
            $cmd .= join " ", $long_id_set->as_array;
            $cmd .= " | faops filter -l 0 stdin stdout";
            $cmd .= " > " . $out_dir->child("$basename.long.fasta")->stringify;

            system $cmd;
        }

        $cc_serial++;
    }
    printf STDERR "CC count %d\n", scalar(@ccs);

    if ( $opt->{png} ) {
        App::Anchr::Common::g2gv0( $graph, $fn_dazz . ".png" );
    }
}

1;
