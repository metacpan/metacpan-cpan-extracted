package App::Rangeops::Command::clean;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract =>
    'replace ranges within links, incorporate hit strands and remove nested links';

sub opt_spec {
    return (
        [   "replace|r=s",
            "Two-column tsv file, normally produced by command merge."
        ],
        [   "bundle|b=i",
            "Bundle overlapped links. This value is the overlapping size, default is [0]. Suggested value is [500].",
            { default => 0 },
        ],
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "verbose|v",   "Verbose mode.", ],
    );
}

sub usage_desc {
    return "rangeops clean [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc
        .= "\t<infiles> are bilateral links files, with or without hit strands\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        my $message = "This command need one or more input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".clean.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Load replaces
    #----------------------------#
    my $info_of    = {};    # info of ranges
    my $replace_of = {};
    if ( $opt->{replace} ) {
        print STDERR "==> Load replaces\n" if $opt->{verbose};
        for my $line ( App::RL::Common::read_lines( $opt->{replace} ) ) {
            $info_of = App::Rangeops::Common::build_info( [$line], $info_of );

            my @parts = split /\t/, $line;
            if ( @parts == 2 ) {
                $replace_of->{ $parts[0] } = $parts[1];
            }
        }
    }

    #----------------------------#
    # Replacing and incorporating
    #----------------------------#
    print STDERR "==> Incorporating strands\n" if $opt->{verbose};
    my @lines;
    for my $file ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($file) ) {
            $info_of = App::Rangeops::Common::build_info( [$line], $info_of );

            my @new_parts;

            # replacing
            for my $part ( split /\t/, $line ) {

                if ( exists $replace_of->{$part} ) {
                    my $original = $part;
                    my $replaced = $replace_of->{$part};

                    # create new info, don't touch anything of $info_of
                    # use original strand
                    my %new = %{ $info_of->{$replaced} };
                    $new{strand} = $info_of->{$original}{strand};

                    my $new_part = App::RL::Common::encode_header( \%new, 1 );
                    push @new_parts, $new_part;
                }
                else {
                    push @new_parts, $part;
                }
            }
            my $new_line = join "\t", @new_parts;
            $info_of
                = App::Rangeops::Common::build_info( [$new_line], $info_of );

            # incorporating
            if ( @new_parts == 3 or @new_parts == 2 ) {
                my $info_0 = $info_of->{ $new_parts[0] };
                my $info_1 = $info_of->{ $new_parts[1] };

                if (    App::RL::Common::info_is_valid($info_0)
                    and App::RL::Common::info_is_valid($info_1) )
                {
                    my @strands;

                    if ( @new_parts == 3 ) {
                        if ( $new_parts[2] eq "+" or $new_parts[2] eq "-" ) {
                            push @strands,
                                pop(@new_parts);    # new @new_parts == 2
                        }
                    }

                    if ( @new_parts == 2 ) {

                        my %new_0 = %{$info_0};
                        my %new_1 = %{$info_1};

                        push @strands, $new_0{strand};
                        push @strands, $new_1{strand};

                        @strands = List::MoreUtils::PP::uniq(@strands);
                        if ( @strands == 1 ) {
                            $new_0{strand} = "+";
                            $new_1{strand} = "+";
                        }
                        else {
                            $new_0{strand} = "+";
                            $new_1{strand} = "-";
                        }

                        my $range_0
                            = App::RL::Common::encode_header( \%new_0, 1 );
                        $info_of->{$range_0} = \%new_0;
                        my $range_1
                            = App::RL::Common::encode_header( \%new_1, 1 );
                        $info_of->{$range_1} = \%new_1;

                        @new_parts = ( $range_0, $range_1 );
                        $new_line = join "\t", @new_parts;
                    }
                }
            }
            $info_of
                = App::Rangeops::Common::build_info( [$new_line], $info_of );

            # skip identical ranges
            if ( @new_parts == 2 ) {
                my $info_0 = $info_of->{ $new_parts[0] };
                my $info_1 = $info_of->{ $new_parts[1] };

                if (    App::RL::Common::info_is_valid($info_0)
                    and App::RL::Common::info_is_valid($info_1) )
                {
                    if (    $info_0->{chr} eq $info_1->{chr}
                        and $info_0->{start} == $info_1->{start}
                        and $info_0->{end} == $info_1->{end} )
                    {
                        $new_line = undef;
                    }
                }
            }

            push @lines, $new_line;
        }
    }

    @lines   = grep {defined} List::MoreUtils::PP::uniq(@lines);
    @lines   = @{ App::Rangeops::Common::sort_links( \@lines ) };
    $info_of = App::Rangeops::Common::build_info_intspan( \@lines );

    #----------------------------#
    # Remove nested links
    #----------------------------#
    # now all @lines (links) are without hit strands
    my $flag_nest = 1;
    while ($flag_nest) {
        print STDERR "==> Remove nested links\n" if $opt->{verbose};

        my %to_remove = ();
        my @chr_pairs = map {
            my ( $r0, $r1 ) = split /\t/;
            $info_of->{$r0}{chr} . ":" . $info_of->{$r1}{chr}
        } @lines;
        for my $i ( 0 .. $#lines - 1 ) {
            my @rest_idx
                = grep { $chr_pairs[$i] eq $chr_pairs[$_] }
                ( $i + 1 .. $#lines );

            for my $j (@rest_idx) {
                my $line_i = $lines[$i];
                my ( $range0_i, $range1_i ) = split /\t/, $line_i;

                my $line_j = $lines[$j];
                my ( $range0_j, $range1_j ) = split /\t/, $line_j;

                my $intspan0_i = $info_of->{$range0_i}{intspan};
                my $intspan1_i = $info_of->{$range1_i}{intspan};

                my $intspan0_j = $info_of->{$range0_j}{intspan};
                my $intspan1_j = $info_of->{$range1_j}{intspan};

                if (    $intspan0_i->superset($intspan0_j)
                    and $intspan1_i->superset($intspan1_j) )
                {
                    $to_remove{$line_j}++;
                }
                elsif ( $intspan0_j->superset($intspan0_i)
                    and $intspan1_j->superset($intspan1_i) )
                {
                    $to_remove{$line_i}++;
                }
            }
        }
        @lines = grep { !exists $to_remove{$_} } @lines;
        $flag_nest = scalar keys %to_remove; # when no lines to remove, end loop
    }
    @lines = @{ App::Rangeops::Common::sort_links( \@lines ) };

    #----------------------------#
    # Bundle links
    #----------------------------#
    if ( $opt->{bundle} ) {
        print STDERR "==> Bundle overlapped links\n" if $opt->{verbose};
        my @chr_strand_pairs = map {
            my ( $r0, $r1 ) = split /\t/;
            $info_of->{$r0}{chr} . ":"
                . $info_of->{$r0}{strand} . ":"
                . $info_of->{$r1}{chr} . ":"
                . $info_of->{$r1}{strand}
        } @lines;
        my $graph = Graph->new( directed => 0 );    # graph of lines

        for my $i ( 0 .. $#lines - 1 ) {
            my @rest_idx
                = grep { $chr_strand_pairs[$i] eq $chr_strand_pairs[$_] }
                ( $i + 1 .. $#lines );

            for my $j (@rest_idx) {
                my $line_i = $lines[$i];
                my ( $range0_i, $range1_i ) = split /\t/, $line_i;

                my $line_j = $lines[$j];
                my ( $range0_j, $range1_j ) = split /\t/, $line_j;

                if ( !$graph->has_vertex($line_i) ) {
                    $graph->add_vertex($line_i);
                }
                if ( !$graph->has_vertex($line_j) ) {
                    $graph->add_vertex($line_j);
                }

                my $intspan0_i = $info_of->{$range0_i}{intspan};
                my $intspan1_i = $info_of->{$range1_i}{intspan};

                my $intspan0_j = $info_of->{$range0_j}{intspan};
                my $intspan1_j = $info_of->{$range1_j}{intspan};

                if (    $intspan0_i->overlap($intspan0_j) >= $opt->{bundle}
                    and $intspan1_i->overlap($intspan1_j) >= $opt->{bundle} )
                {
                    $graph->add_edge( $line_i, $line_j );
                }
            }
        }

        # bundle connected lines
        my @cc = grep { scalar @{$_} > 1 } $graph->connected_components;
        for my $c (@cc) {
            printf STDERR "\n" . " " x 4 . "Merge %s lines\n", scalar @{$c}
                if $opt->{verbose};

            my @merged_range;

            for my $i ( 0, 1 ) {
                my ( $chr, $strand );
                my $merge_intspan = AlignDB::IntSpan->new;

                for my $line ( @{$c} ) {
                    @lines = grep { $_ ne $line } @lines;
                    my $range = ( split /\t/, $line )[$i];
                    $chr    = $info_of->{$range}{chr};
                    $strand = $info_of->{$range}{strand};
                    $merge_intspan->merge( $info_of->{$range}{intspan} );
                }

                $merged_range[$i] = App::RL::Common::encode_header(
                    {   chr    => $chr,
                        strand => $strand,
                        start  => $merge_intspan->min,
                        end    => $merge_intspan->max,
                    }
                );
            }

            my $line = join "\t", @merged_range;
            push @lines, $line;
            print STDERR " " x 8 . "$line\n" if $opt->{verbose};

            # new range introduced, update $info_of
            $info_of = App::Rangeops::Common::build_info_intspan( [$line],
                $info_of );
        }

        @lines = @{ App::Rangeops::Common::sort_links( \@lines ) };
    }

    #----------------------------#
    # Links of nearly identical ranges escaped from merging
    #----------------------------#
    if ( $opt->{replace} ) {
        print STDERR "==> Remove self links\n" if $opt->{verbose};

        my @same_pair_lines = map {
            my ( $r0, $r1 ) = split /\t/;
            $info_of->{$r0}{chr} eq $info_of->{$r1}{chr} ? ($_) : ()
        } @lines;

        for my $line (@same_pair_lines) {
            my ( $range0, $range1 ) = split /\t/, $line;

            my $intspan0 = $info_of->{$range0}{intspan};
            my $intspan1 = $info_of->{$range1}{intspan};

            my $intspan_i = $intspan0->intersect($intspan1);
            if ( $intspan_i->is_not_empty ) {
                if (    $intspan_i->size / $intspan0->size > 0.5
                    and $intspan_i->size / $intspan1->size > 0.5 )
                {
                    @lines = grep { $_ ne $line } @lines;
                }
            }
        }
    }

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

    print {$out_fh} "$_\n" for @lines;

    close $out_fh;
}

1;
