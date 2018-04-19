package App::Egaz::Command::blastmatch;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'matched positions by blastn in genome sequences';
}

sub opt_spec {
    return (
        [ "outfile|o=s",  "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ "perchr",       "one (fake) runlist per chromosome", ],
        [ "coverage|c=f", "coverage of identical matches",        { default => 0.9 }, ],
        [ "batch=i",      "batch size of blast records",          { default => 500000 }, ],
        [ "parallel|p=i", "number of threads",                    { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz blastmatch [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> is reports produced by `egaz blastn`
* <infile> can't be stdin
* --perchr produces fake runlists, there might be overlaps, e.g. I:17221-25234,21428-25459

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
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Parse reports
    #----------------------------#
    print STDERR "Parse reports\n";
    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;

        my $wid = MCE->wid;
        print STDERR "* Process task [$chunk_id] by worker #$wid\n" if $opt->{verbose};

        my @lines = @{$chunk_ref};
        my %heads;
        for my $line (@lines) {
            next if $line =~ /^#/;
            chomp $line;

            # qseqid sseqid qstart qend sstart send qlen slen nident
            my @fields = grep {defined} split /\s+/, $line;
            if ( @fields != 9 ) {
                print "Fields error: $line\n";
                next;
            }

            my $query_name = $fields[0];
            my $hit_name   = $fields[1];

            my $query_length    = $fields[6];
            my $identical_match = $fields[8];

            my ( $h_start, $h_end ) = ( $fields[4], $fields[5] );
            if ( $h_start > $h_end ) {
                ( $h_start, $h_end ) = ( $h_end, $h_start );
            }

            my $query_coverage = $identical_match / $query_length;

            if ( $query_coverage >= $opt->{coverage} ) {
                my $head = "$hit_name(+):$h_start-$h_end";
                $heads{$head}++;
            }
        }

        printf STDERR " " x 4 . "Gather %d pieces\n", scalar keys %heads if $opt->{verbose};
        printf STDERR " " x 4 . "Last query name is %s\n", ( split /\s+/, $lines[-1] )[0]
            if $opt->{verbose};
        MCE->gather(%heads);
    };

    MCE::Flow::init {
        chunk_size  => $opt->{batch},
        max_workers => $opt->{parallel},
    };
    my %ranges = mce_flow_f $worker, $args->[0];
    MCE::Flow::finish;

    #----------------------------#
    # Remove ranges fully contained by others
    #----------------------------#
    print STDERR "Convert nodes to sets\n";
    my $nodes_of_chr = {};
    my %set_of;
    for my $node ( keys %ranges ) {
        my ( $chr, $set, undef ) = string_to_set($node);
        if ( !exists $nodes_of_chr->{$chr} ) {
            $nodes_of_chr->{$chr} = [];
        }
        push @{ $nodes_of_chr->{$chr} }, $node;
        $set_of{$node} = $set;
    }

    print STDERR "Sort by positions at chromosomes\n";

    # end positions
    for my $chr ( sort keys %{$nodes_of_chr} ) {
        my @temps = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { /\:(?:\d+)\-(\d+)/; [ $_, $1 ] } @{ $nodes_of_chr->{$chr} };
        $nodes_of_chr->{$chr} = \@temps;
    }

    # start positions
    for my $chr ( sort keys %{$nodes_of_chr} ) {
        my @temps = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { /\:(\d+)/; [ $_, $1 ] } @{ $nodes_of_chr->{$chr} };
        $nodes_of_chr->{$chr} = \@temps;
    }

    print STDERR "Overlaps between ranges\n";
    my %to_remove;
    for my $chr ( sort keys %{$nodes_of_chr} ) {
        my @nodes = @{ $nodes_of_chr->{$chr} };

        my $vicinity = 10;
        for my $idx ( 0 .. $#nodes - $vicinity ) {

            for my $i ( 0 .. $vicinity - 1 ) {
                for my $j ( $i .. $vicinity - 1 ) {
                    my $node_i = $nodes[ $idx + $i ];
                    my $set_i  = $set_of{$node_i};

                    my $node_j = $nodes[ $idx + $j ];
                    my $set_j  = $set_of{$node_j};

                    if ( $set_i->larger_than($set_j) ) {
                        $to_remove{$node_j}++;
                    }
                    elsif ( $set_j->larger_than($set_i) ) {
                        $to_remove{$node_i}++;
                    }

                }
            }
        }
    }

    printf STDERR " " x 4 . "Remove [%d] nested nodes\n", scalar keys %to_remove;
    my @sorted;
    for my $chr ( sort keys %{$nodes_of_chr} ) {
        for my $node ( @{ $nodes_of_chr->{$chr} } ) {
            if ( !exists $to_remove{$node} ) {
                push @sorted, $node;
            }
        }
    }

    #----------------------------#
    # Write outputs
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    if ( $opt->{perchr} ) {
        my $runlist_of;
        for my $node (@sorted) {
            my ( $chr, $set, undef ) = string_to_set($node);
            if ( !exists $runlist_of->{$chr} ) {
                $runlist_of->{$chr} = [];
            }
            push @{ $runlist_of->{$chr} }, $set->runlist;
        }

        for my $chr ( sort keys %{$runlist_of} ) {
            my $range = "$chr:" . join( ",", @{ $runlist_of->{$chr} } );
            print {$out_fh} $range . "\n";
        }
    }
    else {
        for my $node (@sorted) {
            my ( $chr, $set, undef ) = string_to_set($node);
            my $range = "$chr:" . $set->runlist;
            print {$out_fh} $range . "\n";
        }
    }

    close $out_fh;
}

sub string_to_set {
    my $node = shift;

    my ( $chr_part, $runlist ) = split /:/, $node;

    my $head_qr = qr{
        (?:(?P<name>[\w_]+)\.)?
            (?P<chr_name>[\w-]+)
            (?:\((?P<chr_strand>.+)\))?
        }xi;
    $chr_part =~ $head_qr;

    my $chr    = $+{chr_name};
    my $strand = "+";
    if ( defined $+{chr_strand} ) {
        $strand = $+{chr_strand};
    }
    my $set = AlignDB::IntSpan->new($runlist);

    return ( $chr, $set, $strand );
}

1;
