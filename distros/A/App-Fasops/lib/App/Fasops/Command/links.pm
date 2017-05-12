package App::Fasops::Command::links;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

use constant abstract => 'scan blocked fasta files and output bi/multi-lateral range links';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "pair|p",      "pairwise links" ],
        [ "best|b",      "best-to-best pairwise links" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops links [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infiles> are paths to blocked fasta files, .fas.gz is supported.\n";
    $desc .= "\tinfile == stdin means reading from STDIN\n";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my @links;
    for my $infile ( @{$args} ) {
        my $in_fh;
        if ( lc $infile eq "stdin" ) {
            $in_fh = *STDIN{IO};
        }
        else {
            $in_fh = IO::Zlib->new( $infile, "rb" );
        }

        my $content = '';    # content of one block
        while (1) {
            last if $in_fh->eof and $content eq '';
            my $line = '';
            if ( !$in_fh->eof ) {
                $line = $in_fh->getline;
            }
            next if substr( $line, 0, 1 ) eq "#";

            if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
                my $info_of = App::Fasops::Common::parse_block( $content, 1 );
                $content = '';

                my @headers = keys %{$info_of};

                if ( $opt->{best} ) {
                    my @matrix = map { [ (undef) x ( scalar @headers ) ] } 0 .. $#headers;

                    # distance is 0 for same sequence
                    for my $i ( 0 .. $#headers ) {
                        $matrix[$i][$i] = 0;
                    }

                    # compute a triangle, fill full matrix
                    for ( my $i = 0; $i <= $#headers; $i++ ) {
                        for ( my $j = $i + 1; $j <= $#headers; $j++ ) {
                            my $D = App::Fasops::Common::pair_D(
                                [   $info_of->{ $headers[$i] }{seq},
                                    $info_of->{ $headers[$j] }{seq},
                                ]
                            );
                            $matrix[$i][$j] = $D;
                            $matrix[$j][$i] = $D;
                        }
                    }

                    # print YAML::Syck::Dump \@matrix;

                    # best_pairwise
                    my @pair_ary;
                    for my $i ( 0 .. $#headers ) {
                        my @row = @{ $matrix[$i] };
                        $row[$i] = 999;    # remove the score (zero) of this item
                        my $min = List::Util::min(@row);
                        my $min_idx = App::Fasops::Common::firstidx { $_ == $min } @row;

                        # to remove duplications of a:b and b:a
                        push @pair_ary, join ":", sort { $a <=> $b } ( $i, $min_idx );
                    }
                    @pair_ary = App::Fasops::Common::uniq(@pair_ary);

                    for (@pair_ary) {
                        my ( $i, $j ) = split ":";
                        push @links, [ $headers[$i], $headers[$j] ];
                    }
                }
                elsif ( $opt->{pair} ) {
                    for ( my $i = 0; $i <= $#headers; $i++ ) {
                        for ( my $j = $i + 1; $j <= $#headers; $j++ ) {
                            push @links, [ $headers[$i], $headers[$j] ];
                        }
                    }
                }
                else {
                    push @links, \@headers;
                }
            }
            else {
                $content .= $line;
            }
        }

        $in_fh->close;
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    for my $link (@links) {
        printf {$out_fh} join( "\t", @{$link} );
        printf {$out_fh} "\n";
    }
    close $out_fh;
}

1;
