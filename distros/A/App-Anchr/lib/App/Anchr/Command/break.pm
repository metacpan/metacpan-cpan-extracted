package App::Anchr::Command::break;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "break long reads by anthors";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", ],
        [ 'range|r=s',    'ranges of anchors',            { required => 1 }, ],
        [ 'border=i',     'length of borders in anchors', { default  => 100 }, ],
        [ 'power=f',      'multiplying power',            { default  => 3 }, ],
        [ "len|l=i",      "minimal length of overlaps",   { default  => 1000 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default  => 0.85 }, ],
        [ "parallel|p=i", "number of threads",            { default  => 4 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr break [options] <dazz DB> <ovlp file>";
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

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".breaks.fasta";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # absolute paths before we chdir to $out_dir
    my $fn_dazz = Path::Tiny::path( $args->[0] )->absolute->stringify;
    my $fn_ovlp = Path::Tiny::path( $args->[1] )->absolute->stringify;

    if ( lc $opt->{outfile} ne "stdout" ) {
        $opt->{outfile} = Path::Tiny::path( $opt->{outfile} )->absolute->stringify;
    }

    # record cwd, we'll return there
    my $cwd     = Path::Tiny->cwd;
    my $tempdir = Path::Tiny->tempdir("anchr_break_XXXXXXXX");
    chdir $tempdir;

    #@type AlignDB::IntSpan
    my $anchor_range = AlignDB::IntSpan->new->add_runlist( $opt->{range} );

    #----------------------------#
    # Load overlaps and build links
    #----------------------------#

    # drop multi-matched long reads
    my $multi_matched = AlignDB::IntSpan->new;    # long_id

    # drop contained long reads
    my $contained_long = AlignDB::IntSpan->new;    # long_id

    my $links_of    = {};                          # long_id => { anchor_id => overlap_on_long, }
    my $full_set_of = {};                          # long_id => IntSpan
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

                if ( $contained eq "contains" ) {
                    $contained_long->add($g_id);
                }

                if ( !exists $full_set_of->{$g_id} ) {
                    $full_set_of->{$g_id} = AlignDB::IntSpan->new->add_pair( 1, $g_len );
                }
            }
            elsif ( $anchor_range->contains($g_id) and !$anchor_range->contains($f_id) ) {
                my ( $beg, $end ) = App::Anchr::Common::beg_end( $f_B, $f_E, );
                $links_of->{$f_id}{$g_id} = AlignDB::IntSpan->new->add_pair( $beg, $end );

                if ( $contained eq "contained" ) {
                    $contained_long->add($f_id);
                }

                if ( !exists $full_set_of->{$f_id} ) {
                    $full_set_of->{$f_id} = AlignDB::IntSpan->new->add_pair( 1, $f_len );
                }
            }
        }
        close $in_fh;
    }

    for my $long_id ( $multi_matched->as_array ) {
        if ( exists $links_of->{$long_id} ) {
            delete $links_of->{$long_id};
        }
    }

    for my $long_id ( $contained_long->as_array ) {
        if ( exists $links_of->{$long_id} ) {
            delete $links_of->{$long_id};
        }
    }

    my $region_of = {};    # long_id => IntSpan
    for my $long_id ( keys %{$links_of} ) {

        # covered parts of long reads
        my $covered = AlignDB::IntSpan->new;
        for my $anchor_id ( keys %{ $links_of->{$long_id} } ) {

            #@type AlignDB::IntSpan
            my $set = $links_of->{$long_id}{$anchor_id};
            $set = $set->trim( $opt->{border} );
            $covered->add($set);    # avoid overlapped anchors
        }

        my $multiplied = int( $opt->{len} * $opt->{power} );
        my $rest_set
            = $full_set_of->{$long_id}->diff($covered)->pad($multiplied);
        $region_of->{$long_id} = $full_set_of->{$long_id}->intersect($rest_set);
    }

    {
        $tempdir->child("break.fasta")->remove;
        for my $serial ( sort { $a <=> $b } keys %{$region_of} ) {

            #@type AlignDB::IntSpan
            my $region = $region_of->{$serial};

            for my $set ( $region->sets ) {
                my $cmd;
                $cmd .= "DBshow -U $fn_dazz $serial";
                $cmd .= " | faops frag -l 0 stdin @{[$set->min]} @{[$set->max]} stdout";
                $cmd .= " >> break.fasta";
                App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }
        }

        if ( !$tempdir->child("break.fasta")->is_file ) {
            Carp::croak "Failed: create break.fasta\n";
        }

        YAML::Syck::DumpFile(
            "break.yml",
            {   "Contained"           => $contained_long->runlist,
                "Contained count"     => $contained_long->size,
                "Multi-matched"       => $multi_matched->runlist,
                "Multi-matched count" => $multi_matched->size,
                "region_of" => { map { $_ => $region_of->{$_}->runlist } keys %{$region_of} },
            }
        );
    }

    {
        # Outputs. stdout is handeld by faops
        my $cmd;
        $cmd .= "faops filter -l 0 break.fasta";
        $cmd .= " $opt->{outfile}";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        $tempdir->child("break.yml")->copy("$opt->{outfile}.break.yml");
    }

    chdir $cwd;
}

1;
