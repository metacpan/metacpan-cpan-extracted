package App::Egaz::Command::maskfasta;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

use constant abstract => 'soft/hard-masking sequences in a fasta file';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ 'hard',        'change masked regions to N', ],
        [ 'len|l=i',     'sequence line length',                 { default => 80 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz maskfasta [options] <infile> <runlist.yml>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";

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

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # load files
    #----------------------------#
    my $seq_of = App::Fasops::Common::read_fasta( $args->[0] );

    my $set_single
        = App::RL::Common::runlist2set( YAML::Syck::LoadFile( $args->[1] ) );

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    #----------------------------#
    # processing
    #----------------------------#
    for my $seq_name ( keys %{$seq_of} ) {
        my $seq = $seq_of->{$seq_name};

        if ( exists $set_single->{$seq_name} ) {
            my AlignDB::IntSpan $mask_set = $set_single->{$seq_name};

            # empty set have no @sets
            my @sets = $mask_set->sets;
            for my AlignDB::IntSpan $set (@sets) {
                my $offset = $set->min - 1;
                my $length = $set->size;

                my $str = substr $seq, $offset, $length;
                if ( $opt->{hard} ) {
                    my $str_len = length $str;
                    $str = 'N' x $str_len;
                }
                else {
                    $str = lc $str;
                }
                substr $seq, $offset, $length, $str;
            }
        }

        print {$out_fh} ">$seq_name\n";
        print {$out_fh} substr( $seq, 0, $opt->{len}, '' ) . "\n" while ($seq);
    }

    close $out_fh;
}

1;
