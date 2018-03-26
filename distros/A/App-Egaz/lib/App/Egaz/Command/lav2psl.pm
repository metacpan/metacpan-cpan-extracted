package App::Egaz::Command::lav2psl;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

use constant abstract => 'convert .lav files to .psl files';

sub opt_spec {
    return ( [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        { show_defaults => 1, } );
}

sub usage_desc {
    return "egaz lav2psl [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<MARKDOWN;

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

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # load lav
    #----------------------------#
    my $lav_content = Path::Tiny::path( $args->[0] )->slurp;
    my @lavs        = grep {/^[ds] /} split /\#\:lav\n/, $lav_content;
    my $d_stanza    = shift @lavs;                                      # Not needed by this program

    #    print YAML::Syck::Dump \@lavs;

    #----------------------------#
    # write outputs
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    for my $lav (@lavs) {

        #----------------------------#
        # s-stanza
        #----------------------------#
        # "<filename>[-]" <start> <stop> [<rev_comp_flag> <sequence_number>]
        $lav =~ /s \{\s+(.+?)\s+\}/s;
        my $s_stanza = $1;
        my @s_lines  = $s_stanza =~ /(.+ \s+ \d+ \s+ \d+ \s+ \d+ \s+ \d+)/gx;
        if ( scalar @s_lines != 2 ) {
            Carp::croak "s-stanza error.\n";
        }

        $s_lines[0] =~ /\s*\"?(.+?)\-?\"? \s+ (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+)/x;
        my ( $t_file, $t_seq_start, $t_seq_stop, $t_strand, $t_contig ) = ( $1, $2, $3, $4, $5 );
        if ( !-e $t_file ) {
            $t_file = App::Egaz::Common::resolve_file( $t_file,
                Path::Tiny::path( $args->[0] )->parent(), "." );
        }
        if ( $t_seq_start != 1 ) {
            Carp::croak "Target sequence doesn't start at 1\n";
        }

        $s_lines[1] =~ /\s*\"?(.+?)\-?\"? \s+ (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+)/x;
        my ( $q_file, $q_seq_start, $q_seq_stop, $q_strand, $q_contig ) = ( $1, $2, $3, $4, $5 );
        if ( !-e $q_file ) {
            $q_file = App::Egaz::Common::resolve_file( $q_file,
                Path::Tiny::path( $args->[0] )->parent(), "." );
        }
        if ( $q_seq_start != 1 ) {
            Carp::croak "Query sequence doesn't start at 1\n";
        }

        #----------------------------#
        # h-stanza
        #----------------------------#
        $lav =~ /h \{\s+(.+?)\s+\}/s;
        my $h_stanza = $1;
        my @h_lines  = $h_stanza =~ /(.+)/g;
        if ( scalar @h_lines != 2 ) {
            Carp::croak "h-stanza error.\n";
        }

        $h_lines[0] =~ m{">?\s*(\w+)};
        my $t_name = $1;

        $h_lines[1] =~ m{">?\s*(\w+)};
        my $q_name = $1;

        if ( $h_lines[1] =~ m{ \(reverse complement\)} ) {
            if ( $q_strand == 0 ) {
                Carp::croak "q_strand from h-stanza doesn't match with s-stanza.\n";
            }
        }

        #----------------------------#
        # generate psl lines
        #----------------------------#
        my @a_stanzas = $lav =~ /a \{\s+(.+?)\s+\}/sg;
        for my $a_stanza (@a_stanzas) {
            my ( $match, $mismatch ) = ( 0, 0, );
            my ( $q_num_ins, $q_base_ins, $t_num_ins, $t_base_ins, ) = ( 0, 0, 0, 0, );
            my ( @sizes, @q_begins, @t_begins );

            my @align_pieces = $a_stanza =~ /\s*l (\d+ \d+ \d+ \d+ \d+)/g;
            my $t_former_end;
            my $q_former_end;
            for my $align_piece (@align_pieces) {

                unless ( $align_piece =~ /(\d+) (\d+) (\d+) (\d+) (\d+)/g ) {
                    Carp::croak "l-line error\n";
                }
                my ( $t_begin, $q_begin, $t_end, $q_end, $percent_id ) = ( $1, $2, $3, $4, $5 );
                $t_begin--;
                $q_begin--;
                $percent_id = 0.01 * $percent_id;

                my $bases       = $q_end - $q_begin;
                my $match_piece = App::Egaz::Common::round( $percent_id * $bases );
                $match += $match_piece;
                $mismatch += $bases - $match_piece;

                if ( $t_former_end and $t_begin != $t_former_end ) {
                    $t_num_ins++;
                    $t_base_ins += $t_begin - $t_former_end;
                }
                if ( $q_former_end and $q_begin != $q_former_end ) {
                    $q_num_ins++;
                    $q_base_ins += $q_begin - $q_former_end;
                }
                $t_former_end = $t_end;
                $q_former_end = $q_end;

                push @sizes,    $t_end - $t_begin;
                push @q_begins, $q_begin;
                push @t_begins, $t_begin;
            }

            # b-line, begins
            unless ( $a_stanza =~ /\s*b (\d+) (\d+)/ ) {
                Carp::croak "No b-line.\n";
            }
            my $t_from = $1;
            my $q_from = $2;
            $t_from--;
            $q_from--;

            # e-line, ends
            unless ( $a_stanza =~ /\s*e (\d+) (\d+)/ ) {
                Carp::croak "No e-line.\n";
            }
            my $t_to = $1;
            my $q_to = $2;

            # s-line, scores
            unless ( $a_stanza =~ /\s*s (\d+)/ ) {
                Carp::croak "No s-line.\n";
            }
            my $score = $1;

            # prepare psl line
            my $psl_line;
            $psl_line .= sprintf "%d\t%d\t0\t0\t", $match, $mismatch;
            $psl_line .= sprintf "%d\t%d\t%d\t%d\t", $q_num_ins, $q_base_ins, $t_num_ins,
                $t_base_ins,;
            $psl_line .= sprintf "%s\t", $q_strand ? '-' : '+';

            # if query is - strand, convert begin/end to genomic coordinates
            if ($q_strand) {
                $psl_line .= sprintf "%s\t%d\t%d\t%d\t", $q_name, $q_seq_stop, $q_seq_stop - $q_to,
                    $q_seq_stop - $q_from;
            }
            else {
                $psl_line .= sprintf "%s\t%d\t%d\t%d\t", $q_name, $q_seq_stop, $q_from, $q_to;
            }

            $psl_line .= sprintf "%s\t%d\t%d\t%d\t", $t_name, $t_seq_stop, $t_from, $t_to;
            $psl_line .= sprintf "%d\t", scalar @align_pieces;

            $psl_line .= sprintf "%d,", $_ for (@sizes);
            $psl_line .= "\t";

            $psl_line .= sprintf "%d,", $_ for (@q_begins);
            $psl_line .= "\t";

            $psl_line .= sprintf "%d,", $_ for (@t_begins);
            $psl_line .= "\n";

            print {$out_fh} $psl_line;
        }
    }

    close $out_fh;

    return;
}

1;
