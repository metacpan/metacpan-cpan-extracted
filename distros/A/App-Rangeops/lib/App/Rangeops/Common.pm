package App::Rangeops::Common;
use strict;
use warnings;
use autodie;

use 5.010001;

use Carp;
use Graph;
use IPC::Cmd;
use List::MoreUtils;
use Path::Tiny;
use YAML::Syck;

use AlignDB::IntSpan;
use App::RL::Common;
use App::Fasops::Common;

sub build_info {
    my $line_refs = shift;
    my $info_of   = shift;

    if ( !defined $info_of ) {
        $info_of = {};
    }

    for my $line ( @{$line_refs} ) {
        for my $part ( split /\t/, $line ) {
            my $info = App::RL::Common::decode_header($part);
            next unless App::RL::Common::info_is_valid($info);

            if ( !exists $info_of->{$part} ) {
                $info_of->{$part} = $info;
            }
        }
    }

    return $info_of;
}

sub build_info_intspan {
    my $line_refs = shift;
    my $info_of   = shift;

    if ( !defined $info_of ) {
        $info_of = {};
    }

    for my $line ( @{$line_refs} ) {
        for my $part ( split /\t/, $line ) {
            my $info = App::RL::Common::decode_header($part);
            next unless App::RL::Common::info_is_valid($info);

            $info->{intspan} = AlignDB::IntSpan->new;
            $info->{intspan}->add_pair( $info->{start}, $info->{end} );

            if ( !exists $info_of->{$part} ) {
                $info_of->{$part} = $info;
            }
        }
    }

    return $info_of;
}

sub sort_links {
    my $line_refs = shift;
    my $numeric   = shift;

    my @lines = @{$line_refs};

    #----------------------------#
    # Cache info
    #----------------------------#
    my $info_of = build_info( \@lines );

    #----------------------------#
    # Sort within links
    #----------------------------#
    for my $line (@lines) {
        my @parts = split /\t/, $line;
        my @invalids = grep { !exists $info_of->{$_} } @parts;
        my @ranges   = grep { exists $info_of->{$_} } @parts;

        # chromosome strand
        @ranges = map { $_->[0] }
            sort { $a->[1] cmp $b->[1] }
            map { [ $_, $info_of->{$_}{strand} ] } @ranges;

        # start point on chromosomes
        @ranges = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, $info_of->{$_}{start} ] } @ranges;

        # chromosome name
        if ($numeric) {
            @ranges = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map { [ $_, $info_of->{$_}{chr} ] } @ranges;
        }
        else {
            @ranges = map { $_->[0] }
                sort { $a->[1] cmp $b->[1] }
                map { [ $_, $info_of->{$_}{chr} ] } @ranges;
        }

        $line = join "\t", ( @ranges, @invalids );
    }

    #----------------------------#
    # Sort by first range's chromosome order among links
    #----------------------------#
    {
        # after swapping, remove dups again
        @lines = sort @lines;
        @lines = List::MoreUtils::PP::uniq(@lines);

        # strand
        @lines = map { $_->[0] }
            sort { $a->[1] cmp $b->[1] }
            map {
            my $first = ( split /\t/ )[0];
            [ $_, $info_of->{$first}{strand} ]
            } @lines;

        # start
        @lines = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map {
            my $first = ( split /\t/ )[0];
            [ $_, $info_of->{$first}{start} ]
            } @lines;

        # chromosome name
        if ($numeric) {
            @lines = map { $_->[0] }
                sort { $a->[1] <=> $b->[1] }
                map {
                my $first = ( split /\t/ )[0];
                [ $_, $info_of->{$first}{chr} ]
                } @lines;
        }
        else {
            @lines = map { $_->[0] }
                sort { $a->[1] cmp $b->[1] }
                map {
                my $first = ( split /\t/ )[0];
                [ $_, $info_of->{$first}{chr} ]
                } @lines;
        }
    }

    #----------------------------#
    # Sort by copy number among links (desc)
    #----------------------------#
    {
        @lines = map { $_->[0] }
            sort { $b->[1] <=> $a->[1] }
            map {
            [ $_, scalar( grep { exists $info_of->{$_} } split( /\t/, $_ ) ) ]
            } @lines;
    }

    return \@lines;
}

sub get_seq_faidx {
    my $filename = shift;
    my $location = shift;    # I:1-100

    # get executable
    my $bin;
    for my $e (qw{samtools}) {
        if ( IPC::Cmd::can_run($e) ) {
            $bin = $e;
            last;
        }
    }
    if ( !defined $bin ) {
        confess "Could not find the executable for [samtools]\n";
    }

    my $cmd = sprintf "%s faidx %s %s", $bin, $filename, $location;
    open my $pipe_fh, '-|', $cmd;

    my $seq;
    while ( my $line = <$pipe_fh> ) {
        chomp $line;
        if ( $line =~ /^[\w-]+/ ) {
            $seq .= $line;
        }
    }
    close $pipe_fh;

    return $seq;
}

1;
