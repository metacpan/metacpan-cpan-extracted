package App::Fasops::Command::axt2fas;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

use constant abstract => 'convert axt to blocked fasta';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename, [stdout] for screen" ],
        [ "length|l=i", "the threshold of alignment length", { default => 1 } ],
        [ "tname|t=s",  "target name",                       { default => "target" } ],
        [ "qname|q=s",  "query name",                        { default => "query" } ],
        [   "size|s=s",
            "query chr.sizes. Without this file, positions of negtive strand of query will be wrong",
        ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops axt2fas [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= "Convert UCSC axt pairwise alignment file to blocked fasta file.\n";
    $desc .= "\t<infiles> are paths to axt files, .axt.gz is supported\n";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".fas";
    }

    if ( $opt->{tname} ) {
        if ( $opt->{tname} !~ /^[\w]+$/ ) {
            $self->usage_error("[--tname] should be an alphanumeric value.");
        }
    }
    if ( $opt->{qname} ) {
        if ( $opt->{qname} !~ /^[\w]+$/ ) {
            $self->usage_error("[--qname] should be an alphanumeric value.");
        }
    }

    if ( $opt->{size} ) {
        if ( !Path::Tiny::path( $opt->{size} )->is_file ) {
            $self->usage_error("The size file [$opt->{size}] doesn't exist.");
        }
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $length_of;
    if ( $opt->{size} ) {
        $length_of = App::RL::Common::read_sizes( $opt->{size} );
    }

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

            if ( substr( $line, 0, 1 ) eq "#" ) {
                next;
            }
            elsif ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
                my $info_refs = App::Fasops::Common::parse_axt_block( $content, $length_of );
                $content = '';

                next
                    if App::Fasops::Common::seq_length( $info_refs->[0]{seq} ) < $opt->{length};
                next
                    if App::Fasops::Common::seq_length( $info_refs->[1]{seq} ) < $opt->{length};

                $info_refs->[0]{name} = $opt->{tname};
                $info_refs->[1]{name} = $opt->{qname};

                for my $i ( 0, 1 ) {
                    my $info = $info_refs->[$i];
                    printf {$out_fh} ">%s\n", App::RL::Common::encode_header($info);
                    printf {$out_fh} "%s\n",  $info->{seq};
                }
                print {$out_fh} "\n";
            }
            else {
                $content .= $line;
            }
        }

        $in_fh->close;
    }

    close $out_fh;
}

1;
