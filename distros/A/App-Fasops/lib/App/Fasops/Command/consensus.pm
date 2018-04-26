package App::Fasops::Command::consensus;
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
    return 'create consensus from blocked fasta file';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename. [stdout] for screen" ],
        [ "outgroup",    "has outgroup at the end of blocks", ],
        [ "cname",        "the name of consensus", { default => "consensus" }, ],
        [ "parallel|p=i", "run in parallel mode",  { default => 1 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops consensus [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> are paths to blocked fasta files, .fas.gz is supported
* infile == stdin means reading from STDIN
* `poa` is used for creating consensus sequences

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

    tie my %info_out, "Tie::IxHash";
    {
        my @keys = keys %{$info_of};

        my $outgroup;
        if ( $opt->{outgroup} ) {
            $outgroup = pop @keys;
        }

        # copy prev info
        $info_out{ $opt->{cname} } = $info_of->{ $keys[0] };
        if ( $opt->{outgroup} ) {
            $info_out{$outgroup} = $info_of->{$outgroup};
        }

        # create consensus
        my $seq_refs = [];
        for my $key (@keys) {
            push @{$seq_refs}, $info_of->{$key}{seq};
        }
        my $cseq = App::Fasops::Common::poa_consensus( $seq_refs, $opt->{msa} );

        # update info
        if ( defined $info_out{ $opt->{cname} }->{name} ) {
            $info_out{ $opt->{cname} }->{name} = $opt->{cname};
        }
        else {
            $info_out{ $opt->{cname} }->{chr} = $opt->{cname};
        }
        $info_out{ $opt->{cname} }->{seq} = $cseq;
    }

    my $out_string;

    for my $key ( keys %info_out ) {
        $out_string .= sprintf ">%s\n", App::RL::Common::encode_header( $info_out{$key} );
        $out_string .= sprintf "%s\n",  $info_out{$key}->{seq};
    }
    $out_string .= "\n";

    return $out_string;
}

1;
