package App::Fasops::Command::refine;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow Sereal => 1;
use MCE::Candy;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

sub abstract {
    return 'realign blocked fasta file with external programs';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "outgroup",    "Has outgroup at the end of blocks", ],
        [ "parallel|p=i", "run in parallel mode", { default => 1 }, ],
        [ "msa=s",        "Aligning program",     { default => "mafft" }, ],
        [   "quick",
            "Quick mode, only aligning indel adjacent regions. Suitable for multiz outputs",
        ],
        [ "pad=i",  "In quick mode, enlarge indel regions", { default => 50 }, ],
        [ "fill=i", "In quick mode, join indel regions",    { default => 50 }, ],
        [ "chop=i", "Chop head and tail indels",            { default => 0 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops refine [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* List of msa:
    * mafft
    * muscle
    * clustalw
    * none: means skip realigning
* <infile> are paths to blocked fasta files, .fas.gz is supported
* infile == stdin means reading from STDIN

MARKDOWN

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
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".fas";
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

    my @infos;    # collect blocks for parallelly refining
    my $content = '';    # content of one block
    while (1) {
        last if $in_fh->eof and $content eq '';
        my $line = '';
        if ( !$in_fh->eof ) {
            $line = $in_fh->getline;
        }
        if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
            my $info_ary = App::Fasops::Common::parse_block_array( $content );
            $content = '';

            if ( $opt->{parallel} >= 2 ) {
                push @infos, $info_ary;
            }
            else {
                my $out_string = proc_block( $info_ary, $opt );
                print {$out_fh} $out_string;
            }
        }
        else {
            $content .= $line;
        }
    }
    $in_fh->close;

    if ( $opt->{parallel} >= 2 ) {
        my $worker = sub {
            my ( $self, $chunk_ref, $chunk_id ) = @_;

            my $info_ary = $chunk_ref->[0];
            my $out_string = proc_block( $info_ary, $opt );

            # preserving output order
            MCE->gather( $chunk_id, $out_string );
        };

        MCE::Flow::init {
            chunk_size  => 1,
            max_workers => $opt->{parallel},
            gather      => MCE::Candy::out_iter_fh($out_fh),
        };
        mce_flow $worker, \@infos;
        MCE::Flow::finish;
    }

    close $out_fh;
}

sub proc_block {
    my $info_ary = shift;
    my $opt      = shift;

    #----------------------------#
    # processing seqs, leave headers untouched
    #----------------------------#
    {
        my $seq_refs = [];
        for my $info ( @{$info_ary} ) {
            push @{$seq_refs}, $info->{seq};
        }

        #----------------------------#
        # realigning
        #----------------------------#
        if ( $opt->{msa} ne "none" ) {
            if ( $opt->{quick} ) {
                $seq_refs
                    = App::Fasops::Common::align_seqs_quick( $seq_refs,
                    $opt->{msa}, $opt->{pad}, $opt->{fill} );
            }
            else {
                $seq_refs = App::Fasops::Common::align_seqs( $seq_refs, $opt->{msa} );
            }
        }

        #----------------------------#
        # trimming
        #----------------------------#
        App::Fasops::Common::trim_pure_dash($seq_refs);
        if ( $opt->{outgroup} ) {
            App::Fasops::Common::trim_outgroup($seq_refs);
            App::Fasops::Common::trim_complex_indel($seq_refs);
        }

        for my $i ( 0 .. scalar @{$seq_refs} - 1 ) {
            $info_ary->[$i]{seq} = uc $seq_refs->[$i];
        }
    }

    #----------------------------#
    # change headers
    #----------------------------#
    if ( $opt->{chop} ) {
        trim_head_tail( $info_ary, $opt->{chop} );
    }

    my $out_string;
    for my $info ( @{$info_ary} ) {
        $out_string .= sprintf ">%s\n", App::RL::Common::encode_header($info);
        $out_string .= sprintf "%s\n",  $info->{seq};
    }
    $out_string .= "\n";

    return $out_string;
}

#----------------------------#
# trim head and tail indels
#----------------------------#
#  If head length set to 1, the first indel will be trimmed
#  Length set to 5 and the second indel will also be trimmed
#   GAAA--C...
#   --AAAGC...
#   GAAAAGC...
sub trim_head_tail {
    my $info_ary    = shift;
    my $chop_length = shift;    # indels in this region will also be trimmed

    # default value means only trimming indels starting at the first base
    $chop_length = defined $chop_length ? $chop_length : 1;

    my $align_length = length $info_ary->[0]{seq};

    # chop region covers all
    return if $chop_length * 2 >= $align_length;

    my $indel_set = AlignDB::IntSpan->new;
    for my $info ( @{$info_ary} ) {
        my $seq_indel_set = App::Fasops::Common::indel_intspan( $info->{seq} );
        $indel_set->merge($seq_indel_set);
    }

    # There're no indels at all
    # Leave $info_ary untouched
    return if $indel_set->is_empty;

    {    # head indel(s) to be trimmed
        my $head_set = AlignDB::IntSpan->new;
        $head_set->add_pair( 1, $chop_length );
        my $head_indel_set = $indel_set->find_islands($head_set);

        # head indels
        if ( $head_indel_set->is_not_empty ) {
            for ( 1 .. $head_indel_set->max ) {
                for my $info ( @{$info_ary} ) {
                    my $base = substr( $info->{seq}, 0, 1, '' );
                    if ( $base ne '-' ) {
                        if ( $info->{strand} eq "+" ) {
                            $info->{start}++;
                        }
                        else {
                            $info->{end}--;
                        }
                    }
                }
            }
        }
    }

    {    # tail indel(s) to be trimmed
        my $tail_set = AlignDB::IntSpan->new;
        $tail_set->add_range( $align_length - $chop_length + 1, $align_length );
        my $tail_indel_set = $indel_set->find_islands($tail_set);

        # tail indels
        if ( $tail_indel_set->is_not_empty ) {
            for ( $tail_indel_set->min .. $align_length ) {
                for my $info ( @{$info_ary} ) {
                    my $base = substr( $info->{seq}, -1, 1, '' );
                    if ( $base ne '-' ) {
                        if ( $info->{strand} eq "+" ) {
                            $info->{end}--;
                        }
                        else {
                            $info->{start}++;
                        }
                    }
                }
            }
        }
    }

}

1;
