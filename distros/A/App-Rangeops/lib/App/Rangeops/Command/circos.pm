package App::Rangeops::Command::circos;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

use constant abstract => 'range links to circos links or highlight file';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "highlight|l", "Create highlights instead of links", ],
    );
}

sub usage_desc {
    return "rangeops circos [options] <infiles>";
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
            = Path::Tiny::path( $args->[0] )->absolute . ".links.txt";
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
            my @colors = reverse map {"paired-12-qual-$_"} ( 1 .. 12 );
            my $color_idx = 0;

            if ( defined $opt->{highlight} ) {

                for my $part (@parts) {
                    my $info = App::RL::Common::decode_header($part);
                    next unless App::RL::Common::info_is_valid($info);
                    my $str = join( " ",
                        $info->{chr}, $info->{start}, $info->{end},
                        "fill_color=" . $colors[$color_idx] );
                    push @lines, $str;
                }

                # rotate color
                $color_idx++;
                $color_idx = 0 if $color_idx > 11;
            }
            else {
                for ( my $i = 0; $i <= $#parts; $i++ ) {
                PAIR: for ( my $j = $i + 1; $j <= $#parts; $j++ ) {
                        my @fields;
                        for ( $i, $j ) {
                            my $info
                                = App::RL::Common::decode_header( $parts[$_] );
                            next PAIR
                                unless App::RL::Common::info_is_valid($info);

                            push @fields,
                                (
                                $info->{chr},
                                $info->{strand} eq "+"
                                ? ( $info->{start}, $info->{end} )
                                : ( $info->{end}, $info->{start} )
                                );
                        }
                        my $str = join( " ", @fields );
                        push @lines, $str;
                    }
                }
            }
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
