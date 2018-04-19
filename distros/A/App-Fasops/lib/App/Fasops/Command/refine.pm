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
            my $info_of = App::Fasops::Common::parse_block( $content, 1 );
            $content = '';

            if ( $opt->{parallel} >= 2 ) {
                push @infos, $info_of;
            }
            else {
                my $out_string = proc_block( $info_of, $opt );
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

            my $info_of = $chunk_ref->[0];
            my $out_string = proc_block( $info_of, $opt );

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
    my $info_of = shift;
    my $opt     = shift;

    #----------------------------#
    # processing seqs, leave headers untouched
    #----------------------------#
    {
        my @keys     = keys %{$info_of};
        my $seq_refs = [];
        for my $key (@keys) {
            push @{$seq_refs}, $info_of->{$key}{seq};
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

        for my $i ( 0 .. $#keys ) {
            $info_of->{ $keys[$i] }{seq} = uc $seq_refs->[$i];
        }
    }

    #----------------------------#
    # change headers
    #----------------------------#
    if ( $opt->{chop} ) {
        trim_head_tail( $info_of, $opt->{chop} );
    }

    my $out_string;

    for my $key ( keys %{$info_of} ) {
        $out_string .= sprintf ">%s\n", App::RL::Common::encode_header( $info_of->{$key} );
        $out_string .= sprintf "%s\n",  $info_of->{$key}{seq};
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
    my $info_of     = shift;
    my $chop_length = shift;    # indels in this region will also be trimmed

    # default value means only trimming indels starting at the first base
    $chop_length = defined $chop_length ? $chop_length : 1;

    my @keys         = keys %{$info_of};
    my $align_length = length $info_of->{ $keys[0] }{seq};

    # chop region covers all
    return if $chop_length * 2 >= $align_length;

    my $indel_set = AlignDB::IntSpan->new;
    for my $key (@keys) {
        my $seq_indel_set
            = App::Fasops::Common::indel_intspan( $info_of->{$key}{seq} );
        $indel_set->merge($seq_indel_set);
    }

    # There're no indels at all
    # Leave $info_of untouched
    return if $indel_set->is_empty;

    {    # head indel(s) to be trimmed
        my $head_set = AlignDB::IntSpan->new;
        $head_set->add_pair( 1, $chop_length );
        my $head_indel_set = $indel_set->find_islands($head_set);

        # head indels
        if ( $head_indel_set->is_not_empty ) {
            for my $i ( 1 .. $head_indel_set->max ) {
                for my $key (@keys) {
                    my $base = substr( $info_of->{$key}{seq}, 0, 1, '' );
                    if ( $base ne '-' ) {
                        if ( $info_of->{$key}{strand} eq "+" ) {
                            $info_of->{$key}{start}++;
                        }
                        else {
                            $info_of->{$key}{end}--;
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
            for my $i ( $tail_indel_set->min .. $align_length ) {
                for my $key (@keys) {
                    my $base = substr( $info_of->{$key}{seq}, -1, 1, '' );
                    if ( $base ne '-' ) {
                        if ( $info_of->{$key}{strand} eq "+" ) {
                            $info_of->{$key}{end}--;
                        }
                        else {
                            $info_of->{$key}{start}++;
                        }
                    }
                }
            }
        }
    }

    # create new $info_of
    my $new_info_of = {};
    for my $key (@keys) {
        my $info    = $info_of->{$key};
        my $new_key = App::RL::Common::encode_header($info);
        $new_info_of->{$new_key} = $info;
    }

    $info_of = $new_info_of;
}

1;
