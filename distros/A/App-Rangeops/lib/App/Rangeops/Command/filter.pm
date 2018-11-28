package App::Rangeops::Command::filter;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

sub abstract {
    return 'filter links by numbers of ranges or length difference';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "number|n=s",  "Numbers of ranges, a valid IntSpan runlist.", ],
        [   "ratio|r=f",
            "Ratio of lengths differences. The suggested value is [0.8]",
        ],
    );
}

sub usage_desc {
    return "rangeops filter [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tIt's assumed that all ranges in input files are valid.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        $self->usage_error("This command need one or more input files.");
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".filter.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my @lines;
    for my $file ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($file) ) {
            my @parts = split /\t/, $line;
            if ( defined $opt->{number} ) {
                my $intspan = AlignDB::IntSpan->new;
                $intspan->merge( $opt->{number} );

                next unless $intspan->contains( scalar @parts );
            }

            if ( defined $opt->{ratio} ) {
                my @lengths;
                for my $part (@parts) {
                    my $info = App::RL::Common::decode_header($part);
                    next unless App::RL::Common::info_is_valid($info);
                    push @lengths, ( $info->{end} - $info->{start} + 1 );
                }
                my ( $l_min, $l_max ) = List::MoreUtils::PP::minmax(@lengths);
                my $diff_ratio = sprintf "%.3f", $l_min / $l_max;

                next if ( $diff_ratio < $opt->{ratio} );
            }

            push @lines, $line;    # May produce duplicated lines
        }
    }
    @lines = List::MoreUtils::PP::uniq(@lines);

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = \*STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} "$_\n" for @lines;

    close $out_fh;
}

1;
