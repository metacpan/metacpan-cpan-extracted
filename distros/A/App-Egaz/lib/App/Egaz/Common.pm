package App::Egaz::Common;
use strict;
use warnings;
use autodie;

use 5.018001;

use Bio::Phylo qw();
use Bio::Phylo::IO qw();
use Carp qw();
use File::Find::Rule;
use File::ShareDir qw();
use IO::Zlib;
use IPC::Cmd qw();
use JSON qw();
use List::Util qw();
use List::MoreUtils qw();
use MCE;
use Number::Format qw();
use Path::Tiny qw();
use Set::Scalar;
use String::Similarity;
use Template;
use YAML::Syck qw();

use App::Fasops::Common;

sub resolve_file {
    my $original = shift;
    my @paths    = @_;

    my $file = $original;
    if ( !-e $file ) {
        $file = Path::Tiny::path($file)->basename();

        if ( !-e $file ) {
            for my $p (@paths) {
                $file = Path::Tiny::path($p)->child($file);
                last if -e $file;
            }
        }
    }

    if ( -e $file ) {
        return $file->stringify;
    }
    else {
        Carp::confess "Can't resole file for [$original]\n";
    }
}

sub round {
    my $float = shift;

    return int( $float + $float / abs( $float * 2 || 1 ) );
}

# Return a list of 1-based overlapping ranges
sub overlap_ranges {
    my $start   = shift;
    my $end     = shift;
    my $chunk   = shift;
    my $overlap = shift;

    my @ranges;
    for ( my $i = $start - 1; $i < $end; $i += $chunk ) {
        my $j = $i + $chunk + $overlap;
        $j = $end if ( $j > $end );
        push @ranges, [ ( $i + 1 ), $j ];
    }
    return \@ranges;
}

sub run_sparsemem {
    my Path::Tiny $result = shift;
    my $query             = shift;
    my $genome            = shift;
    my $length = shift || 20;

    # mummer
    # -b    compute forward and reverse complement matches
    # -F    force 4 column output format regardless of the number of reference sequence inputs
    # -n    match only the characters a, c, g, or t
    #
    # sparsemem only
    # -k    sampled suffix positions (one by default)
    my $template;
    my $exe;
    if ( IPC::Cmd::can_run('sparsemem') ) {
        $exe      = 'sparsemem';
        $template = "%s -maxmatch -F -l %d -b -n -k 4 -threads 4 %s %s > %s";
    }
    else {
        $exe      = 'mummer';
        $template = "%s -maxmatch -F -l %d -b -n %s %s > %s";
    }

    my $cmd = sprintf $template, $exe, $length, $genome, $query, $result->stringify;
    system $cmd;
}

sub get_size {
    my $file = shift;

    tie my %length_of, "Tie::IxHash";

    if ( IPC::Cmd::can_run('faops') ) {
        my $cmd = sprintf "faops size %s", $file;
        my @lines = grep {defined} split /\n/, `$cmd`;

        for (@lines) {
            my ( $key, $value ) = split /\t/;
            $length_of{$key} = $value;
        }
    }
    else {
        my $seq_of    = App::Fasops::Common::read_fasta($file);
        my @seq_names = keys %{$seq_of};

        for my $name (@seq_names) {
            $length_of{$name} = length $seq_of->{$name};
        }
    }

    return \%length_of;
}

#----------------------------#
# parsing tree
#----------------------------#
sub ladder {
    my $file        = shift;
    my $target_name = shift;

    my $tree = Bio::Phylo::IO::parse( -format => 'newick', -file => $file )->first;

    my $target = $tree->get_by_name($target_name);

    my @ladder = ( [$target_name], );
    my $set = Set::Scalar->new;
    $set->insert($target_name);

    my $start = $target;
    while (1) {
        my $parent = $start->get_parent;
        last unless $parent;
        my @nodes
            = grep { !$set->has( $_->get_name ) } @{ $parent->get_terminals };
        $set->insert( $_->get_name ) for @nodes;
        my $distance_of = {};
        for my $node (@nodes) {
            $distance_of->{ $node->get_name } = $node->calc_patristic_distance($target);
        }
        my @sorted = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, $distance_of->{$_} ] }
            keys %{$distance_of};
        push @ladder, [@sorted];

        $start = $parent;
    }

    return \@ladder;
}

sub exec_cmd {
    my $cmd = shift;
    my $opt = shift;

    if ( defined $opt and ref $opt eq "HASH" and $opt->{verbose} ) {
        print STDERR "CMD: ", $cmd, "\n";
    }

    system $cmd;
}

1;

