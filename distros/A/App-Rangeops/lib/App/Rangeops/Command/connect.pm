package App::Rangeops::Command::connect;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract => 'connect bilaterial links into multilateral ones';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [   "ratio|r=f",
            "Break links if length identities less than this ratio, default is [0.9].",
            { default => 0.9 }
        ],
        [ "numeric|n", "Sort chromosome names numerically.", ],
        [ "verbose|v", "Verbose mode.", ],
    );
}

sub usage_desc {
    return "rangeops connect [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infiles> are bilaterial links files without hit strands\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        $self->usage_error("This command need one or more input files.");
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".cc.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $graph = Graph->new( directed => 0 );
    my $info_of = {};    # info of ranges
    for my $file ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($file) ) {
            $info_of = App::Rangeops::Common::build_info( [$line], $info_of );

            my @parts;
            for my $part ( split /\t/, $line ) {
                next unless exists $info_of->{$part};
                push @parts, $part;
            }

            # all ranges will be converted to positive strands
            next unless @parts == 2;

            my %new_0 = %{ $info_of->{ $parts[0] } };
            my %new_1 = %{ $info_of->{ $parts[1] } };

            my @strands;
            my $hit_strand = "+";
            {
                push @strands, $new_0{strand};
                push @strands, $new_1{strand};
                @strands = List::MoreUtils::PP::uniq(@strands);

                if ( @strands != 1 ) {
                    $hit_strand = "-";
                }

                $new_0{strand} = "+";
                $new_1{strand} = "+";
            }

            my $range_0 = App::RL::Common::encode_header( \%new_0, 1 );
            $info_of->{$range_0} = \%new_0;
            my $range_1 = App::RL::Common::encode_header( \%new_1, 1 );
            $info_of->{$range_1} = \%new_1;

            # add range
            for my $range ( $range_0, $range_1 ) {
                if ( !$graph->has_vertex($range) ) {
                    $graph->add_vertex($range);
                    print STDERR "Add range $range\n" if $opt->{verbose};
                }
            }

            # add edge
            if ( !$graph->has_edge( $range_0, $range_1 ) ) {
                $graph->add_edge( $range_0, $range_1 );
                $graph->set_edge_attribute( $range_0, $range_1, "strand",
                    $hit_strand );

                print STDERR join "\t", @parts, "\n" if $opt->{verbose};
                printf STDERR "Nodes %d \t Edges %d\n",
                    scalar $graph->vertices, scalar $graph->edges
                    if $opt->{verbose};
            }
            else {
                print STDERR " " x 4 . "Edge exists, next\n" if $opt->{verbose};
            }
        }

        print STDERR "==>" . "Finish processing [$file]\n" if $opt->{verbose};
    }

    #----------------------------#
    # Create cc and sort
    #----------------------------#
    my @lines;
    for my $cc ( $graph->connected_components ) {
        my @ranges = @{$cc};
        my $copy   = scalar @ranges;

        next if $copy == 1;

        my $line = join "\t", @ranges;
        push @lines, $line;
    }

    my @sorted_lines
        = @{ App::Rangeops::Common::sort_links( \@lines, $opt->{numeric} ) };

    #----------------------------#
    # Change strands of ranges based on first range in cc
    #----------------------------#
    my $new_graph = Graph->new( directed => 0 );
    for my $line (@sorted_lines) {
        my @ranges = split /\t/, $line;
        my $copy = scalar @ranges;
        print STDERR "Copy number of this cc is $copy\n" if $opt->{verbose};

        # transform range to info
        # set strand to undef
        # create intspan
        my @infos = map {
            my $info = App::RL::Common::decode_header($_);
            $info->{strand}  = undef;
            $info->{intspan} = AlignDB::IntSpan->new;
            $info->{intspan}->add_pair( $info->{start}, $info->{end} );
            $info;
        } @ranges;

        # set first node to positive strand
        $infos[0]->{strand} = "+";

        my $assigned  = AlignDB::IntSpan->new(0);
        my $unhandled = AlignDB::IntSpan->new;
        $unhandled->add_pair( 0, $copy - 1 );
        $unhandled->remove($assigned);

        my @edges;    # store edge pairs. not all nodes connected
        while ( $assigned->size < $copy ) {
            for my $i ( $assigned->elements ) {
                for my $j ( $unhandled->elements ) {
                    next if !$graph->has_edge( $ranges[$i], $ranges[$j] );
                    next
                        if !$graph->has_edge_attribute( $ranges[$i],
                        $ranges[$j], "strand" );
                    next if !defined $infos[$i]->{strand};

                    # assign strands
                    my $hit_strand
                        = $graph->get_edge_attribute( $ranges[$i], $ranges[$j],
                        "strand" );
                    if ( $hit_strand eq "-" ) {
                        printf " " x 4 . "change strand of %s\n", $ranges[$j]
                            if $opt->{verbose};
                        if ( $infos[$i]->{strand} eq "+" ) {
                            $infos[$j]->{strand} = "-";
                        }
                        else {
                            $infos[$j]->{strand} = "+";
                        }
                    }
                    else {
                        $infos[$j]->{strand} = $infos[$i]->{strand};
                    }
                    $unhandled->remove($j);
                    $assigned->add($j);

                    # break bad links
                    my $size_i = $infos[$i]->{intspan}->size;
                    my $size_j = $infos[$j]->{intspan}->size;
                    my ( $size_min, $size_max )
                        = List::MoreUtils::PP::minmax( $size_i, $size_j );
                    my $diff_ratio = sprintf "%.3f", $size_min / $size_max;

                    if ( $diff_ratio < $opt->{ratio} ) {
                        printf STDERR " " x 4 . "Break links between %s %s\n",
                            $ranges[$i], $ranges[$j]
                            if $opt->{verbose};
                        printf STDERR " " x 4
                            . "Ratio[%s]\tMin [%s]\tMax[%s]\n",
                            $diff_ratio, $size_min, $size_max
                            if $opt->{verbose};
                    }
                    else {
                        push @edges, [ $i, $j ];
                    }
                }
            }
        }

        # transform array_ref back to string
        my @nodes_new = map { App::RL::Common::encode_header( $_, 1 ) } @infos;

        for my $edge (@edges) {
            $new_graph->add_edge( $nodes_new[ $edge->[0] ],
                $nodes_new[ $edge->[1] ] );
        }
    }

    #----------------------------#
    # Recreate cc
    #----------------------------#
    my @new_lines;
    for my $cc ( $new_graph->connected_components ) {
        my @ranges = @{$cc};
        my $copy   = scalar @ranges;

        next if $copy == 1;

        my $line = join "\t", @ranges;
        push @new_lines, $line;
    }

    my @new_sorted_lines
        = @{ App::Rangeops::Common::sort_links( \@new_lines, $opt->{numeric} )
        };

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = \*STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} "$_\n" for @new_sorted_lines;

    close $out_fh;
}

1;
