package App::Egaz::Command::blastlink;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'link sequences by blastn';
}

sub opt_spec {
    return (
        [ "outfile|o=s",  "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ "coverage|c=f", "coverage of identical matches",        { default => 0.9 }, ],
        [ "batch=i",      "batch size of blast records",          { default => 500000 }, ],
        [ "parallel|p=i", "number of threads",                    { default => 2 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz blastlink [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> is reports produced by `egaz blastn`
* <infile> can't be stdin

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
        my @links;
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
            next if $query_name eq $hit_name;

            my $query_length = $fields[6];
            my $hit_length   = $fields[7];
            my $max_length   = List::Util::max( $query_length, $hit_length );
            next if $query_length / $max_length < $opt->{coverage};
            next if $hit_length / $max_length < $opt->{coverage};

            my $identical_match = $fields[8];
            next if $identical_match / $max_length < $opt->{coverage};

            my ( $h_start, $h_end ) = ( $fields[4], $fields[5] );
            my $strand = "+";
            if ( $h_start > $h_end ) {
                ( $h_start, $h_end ) = ( $h_end, $h_start );
                $strand = "-";
            }

            my $link = join "\t", $query_name, $hit_name, $strand;
            push @links, $link;
        }

        printf STDERR "Gather %d links\n", scalar @links if $opt->{verbose};
        MCE->gather(@links);
    };

    MCE::Flow::init {
        chunk_size  => $opt->{batch},
        max_workers => $opt->{parallel},
    };
    my @all_links = mce_flow_f $worker, $args->[0];
    MCE::Flow::finish;

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

    print STDERR "Remove duplicated links\n";
    @all_links = List::MoreUtils::PP::uniq(@all_links);

    for my $l (@all_links) {
        print {$out_fh} $l . "\n";
    }

    close $out_fh;
}

1;
