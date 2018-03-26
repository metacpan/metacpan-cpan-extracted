package App::Egaz::Command::lav2axt;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

use constant abstract => 'convert .lav files to .axt files';

sub opt_spec {
    return ( [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        { show_defaults => 1, } );
}

sub usage_desc {
    return "egaz lav2axt [options] <infile>";
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

    my $serial = 0;
    my %cache;    # cache fasta files

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

        #----------------------------#
        # generate two sequences
        #----------------------------#
        if ( !exists $cache{$t_file} ) {
            my $seq_of = App::Fasops::Common::read_fasta($t_file);
            $cache{$t_file} = {
                seq_of    => $seq_of,
                seq_names => [ keys %{$seq_of} ],
            };
        }
        my $t_name = $cache{$t_file}->{seq_names}[ $t_contig - 1 ];
        my $t_seq  = $cache{$t_file}->{seq_of}{$t_name};

        if ( !exists $cache{$q_file} ) {
            my $seq_of = App::Fasops::Common::read_fasta($q_file);
            $cache{$q_file} = {
                seq_of    => $seq_of,
                seq_names => [ keys %{$seq_of} ],
            };
        }
        my $q_name = $cache{$q_file}->{seq_names}[ $q_contig - 1 ];
        my $q_seq  = $cache{$q_file}->{seq_of}{$q_name};
        if ($q_strand) {
            $q_seq = App::Fasops::Common::revcom($q_seq);
        }

        #----------------------------#
        # generate axt alignments
        #----------------------------#
        my @a_stanzas = $lav =~ /a \{\s+(.+?)\s+\}/sg;
        for my $a_stanza (@a_stanzas) {
            my $alignment_target  = '';
            my $alignment_query   = '';
            my @align_pieces      = $a_stanza =~ /\s*l (\d+ \d+ \d+ \d+) \d+/g;
            my $former_end_target = '';
            my $former_end_query  = '';
            for my $align_piece (@align_pieces) {
                unless ( $align_piece =~ /(\d+) (\d+) (\d+) (\d+)/g ) {
                    Carp::croak "l-line error\n";
                }
                my ( $t_begin, $q_begin, $t_end, $q_end ) = ( $1, $2, $3, $4 );
                my $t_del = '';
                my $q_del = '';
                if ( $alignment_target
                    && ( $t_begin - $former_end_target > 1 ) )
                {
                    $q_del = '-' x ( $t_begin - $former_end_target - 1 );
                    $alignment_query .= $q_del;
                }
                if ( $alignment_query
                    && ( $q_begin - $former_end_query > 1 ) )
                {
                    $t_del = '-' x ( $q_begin - $former_end_query - 1 );
                    $alignment_target .= $t_del;
                }
                my $length_target = $t_end - $t_begin + 1 + ( length $q_del );
                my $length_query  = $q_end - $q_begin + 1 + ( length $t_del );
                $alignment_target
                    .= substr( $t_seq, ( $t_begin - 1 - ( length $q_del ) ), $length_target );
                $alignment_query
                    .= substr( $q_seq, ( $q_begin - 1 - ( length $t_del ) ), $length_query );
                if ( ( length $alignment_query ) ne ( length $alignment_target ) ) {
                    Carp::croak "Target length doesn't match query's in the alignment.\n";
                }
                $former_end_target = $t_end;
                $former_end_query  = $q_end;
            }

            # b-line, begins
            unless ( $a_stanza =~ /\s*b (\d+) (\d+)/ ) {
                Carp::croak "No b-line.\n";
            }
            my $t_from = $1;
            my $q_from = $2;

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

            # only keep the first part in fasta header
            ($t_name) = split /\W+/, $t_name;
            ($q_name) = split /\W+/, $q_name;

            # prepare axt header
            my $axt_head = $serial;
            $axt_head .= " $t_name $t_from $t_to";
            $axt_head .= " $q_name $q_from $q_to ";
            $axt_head .= $q_strand ? '-' : '+';
            $axt_head .= " $score\n";

            # write axt file
            print {$out_fh} $axt_head;
            print {$out_fh} "$alignment_target\n";
            print {$out_fh} "$alignment_query\n\n";
            $serial++;
        }
    }

    close $out_fh;

    return;
}

1;
