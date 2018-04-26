package App::Fasops::Command::slice;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

sub abstract {
    return 'extract alignment slices from a blocked fasta';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "name|n=s",    "According to this species. Default is the first one." ],
        [ "length|l=i", "the threshold of alignment length", { default => 1 } ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops slice [options] <infile> <runlist.yml>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infiles> are paths to axt files, .axt.gz is supported
* infile == stdin means reading from STDIN
* <runlist.yml> is a App::RL dump

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
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".slice.fas";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $in_fh;
    if ( lc $args->[0] eq "stdin" ) {
        $in_fh = *STDIN{IO};
    }
    else {
        $in_fh = IO::Zlib->new( $args->[0], "rb" );
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $set_single
        = App::RL::Common::runlist2set( YAML::Syck::LoadFile( $args->[1] ) );

    {
        my $content = '';    # content of one block
        while (1) {
            last if $in_fh->eof and $content eq '';
            my $line = '';
            if ( !$in_fh->eof ) {
                $line = $in_fh->getline;
            }
            if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
                my $info_of = App::Fasops::Common::parse_block($content);
                $content = '';

                # set $opt->{name} to the first one of the first block
                if ( !defined $opt->{name} ) {
                    ( $opt->{name} ) = keys %{$info_of};
                }

                # target name
                my $name = $opt->{name};

                # basic target information
                my $chr_name   = $info_of->{$name}{chr};
                my $chr_strand = $info_of->{$name}{strand};
                my $chr_start  = $info_of->{$name}{start};
                my $chr_end    = $info_of->{$name}{end};

                # chr present
                next unless exists $set_single->{$chr_name};
                next if $set_single->{$chr_name}->is_empty;

                # has intersect
                my $i_chr_intspan;
                {
                    my AlignDB::IntSpan $slice_set = $set_single->{$chr_name};
                    my $align_chr_set = AlignDB::IntSpan->new;
                    $align_chr_set->add_pair( $chr_start, $chr_end );
                    $i_chr_intspan = $slice_set->intersect($align_chr_set);
                }
                next if $i_chr_intspan->is_empty;

                # print YAML::Syck::Dump {
                #     name          => $name,
                #     chr_name      => $chr_name,
                #     chr_strand    => $chr_strand,
                #     chr_start     => $chr_start,
                #     chr_end       => $chr_end,
                #     i_chr_intspan => $i_chr_intspan->runlist,
                # };

                # target sequence intspan
                my $target_seq_intspan = App::Fasops::Common::seq_intspan( $info_of->{$name}{seq} );

                # every sequence intspans
                my %seq_intspan_of;
                for my $key ( keys %{$info_of} ) {
                    $seq_intspan_of{$key}
                        = App::Fasops::Common::seq_intspan( $info_of->{$key}{seq} );
                }

                # all indel regions
                my $indel_intspan = AlignDB::IntSpan->new;
                for my $key ( keys %{$info_of} ) {
                    $indel_intspan->add(
                        App::Fasops::Common::indel_intspan( $info_of->{$key}{seq} ) );
                }

                # there may be more than one subslice intersect this alignment
                my @sub_slices;
                for my AlignDB::IntSpan $ss_chr_intspan ( $i_chr_intspan->sets ) {

                    # chr positions to align positions
                    my $ss_start
                        = App::Fasops::Common::chr_to_align( $target_seq_intspan,
                        $ss_chr_intspan->min, $chr_start, $chr_strand );
                    my $ss_end
                        = App::Fasops::Common::chr_to_align( $target_seq_intspan,
                        $ss_chr_intspan->max, $chr_start, $chr_strand );
                    next if $ss_start >= $ss_end;

                    my $ss_intspan = AlignDB::IntSpan->new;
                    $ss_intspan->add_pair( $ss_start, $ss_end );

                    # borders of subslice inside a indel
                    if ( $indel_intspan->contains($ss_start) ) {
                        my $indel_island = $indel_intspan->find_islands($ss_start);
                        $ss_intspan->remove($indel_island);
                    }
                    if ( $indel_intspan->contains($ss_end) ) {
                        my $indel_island = $indel_intspan->find_islands($ss_end);
                        $ss_intspan->remove($indel_island);
                    }
                    next if $ss_intspan->size <= $opt->{length};
                    push @sub_slices, $ss_intspan;
                }

                # write heasers and sequences
                for my AlignDB::IntSpan $sub_slice (@sub_slices) {
                    my $ss_start = $sub_slice->min;
                    my $ss_end   = $sub_slice->max;

                    for my $key ( keys %{$info_of} ) {
                        my $key_start = App::Fasops::Common::align_to_chr(
                            $seq_intspan_of{$key}, $ss_start,
                            $info_of->{$key}{start},
                            $info_of->{$key}{strand}
                        );
                        my $key_end = App::Fasops::Common::align_to_chr(
                            $seq_intspan_of{$key}, $ss_end,
                            $info_of->{$key}{start},
                            $info_of->{$key}{strand}
                        );
                        my $ss_info = {
                            name   => $info_of->{$key}{name},
                            chr    => $info_of->{$key}{chr},
                            strand => $info_of->{$key}{strand},
                            start  => $key_start,
                            end    => $key_end,
                        };
                        printf {$out_fh} ">%s\n", App::RL::Common::encode_header($ss_info);
                        printf {$out_fh} "%s\n",
                            substr( $info_of->{$key}{seq}, $ss_start - 1, $ss_end - $ss_start + 1 );
                    }
                    print {$out_fh} "\n";
                }

            }
            else {
                $content .= $line;
            }
        }
    }
    close $out_fh;
    $in_fh->close;
}

1;
