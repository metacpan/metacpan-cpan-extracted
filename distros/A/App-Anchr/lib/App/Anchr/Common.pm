package App::Anchr::Common;
use strict;
use warnings;
use autodie;

use 5.010001;

use Carp qw();
use File::ShareDir qw();
use Graph;
use GraphViz;
use IO::Zlib;
use IPC::Cmd qw();
use JSON qw();
use List::Util;
use Path::Tiny qw();
use Statistics::Descriptive qw();
use Template;
use YAML::Syck qw();

use AlignDB::IntSpan;
use AlignDB::Stopwatch;
use App::RL::Common;
use App::Fasops::Common;

sub get_len_from_header {
    my $fa_fn = shift;

    my %len_of;

    my $fa_fh;
    if ( lc $fa_fn eq 'stdin' ) {
        $fa_fh = *STDIN{IO};
    }
    else {
        open $fa_fh, "<", $fa_fn;
    }

    while ( my $line = <$fa_fh> ) {
        if ( substr( $line, 0, 1 ) eq ">" ) {
            if ( $line =~ /\/(\d+)\/\d+_(\d+)/ ) {
                $len_of{$1} = $2;
            }
        }
    }

    close $fa_fh;

    return \%len_of;
}

sub get_replaces {
    my $fn = shift;

    my $replace_of = {};
    my @lines = Path::Tiny::path($fn)->lines( { chomp => 1 } );

    for my $line (@lines) {
        my @fields = split /\t/, $line;
        if ( @fields == 2 ) {
            if ( $fields[0] =~ /\/(\d+)\/\d+_\d+/ ) {
                $replace_of->{$1} = $fields[1];
            }
        }
    }

    return $replace_of;
}

sub get_replaces2 {
    my $fn  = shift;
    my $opt = shift;

    my $replace_of = {};
    my @lines = Path::Tiny::path($fn)->lines( { chomp => 1 } );

    for my $line (@lines) {
        my @fields = split /\t/, $line;
        if ( @fields == 2 ) {
            if ( defined $opt and ref $opt eq "HASH" and $opt->{reverse} ) {
                $replace_of->{ $fields[1] } = $fields[0];
            }
            else {
                $replace_of->{ $fields[0] } = $fields[1];
            }
        }
    }

    return $replace_of;
}

sub exec_cmd {
    my $cmd = shift;
    my $opt = shift;

    if ( defined $opt and ref $opt eq "HASH" and $opt->{verbose} ) {
        print STDERR "CMD: ", $cmd, "\n";
    }

    system $cmd;
}

sub parse_ovlp_line {
    my $line = shift;

    chomp $line;
    my @fields = split "\t", $line;

    my $info = {
        f_id      => $fields[0],
        g_id      => $fields[1],
        ovlp_len  => $fields[2],
        ovlp_idt  => $fields[3],
        f_strand  => $fields[4],
        f_B       => $fields[5],
        f_E       => $fields[6],
        f_len     => $fields[7],
        g_strand  => $fields[8],
        g_B       => $fields[9],
        g_E       => $fields[10],
        g_len     => $fields[11],
        contained => $fields[12],
    };

    return $info;
}

sub create_ovlp_line {
    my $info = shift;

    my $line = join "\t",
        $info->{f_id},     $info->{g_id}, $info->{ovlp_len}, $info->{ovlp_idt},
        $info->{f_strand}, $info->{f_B},  $info->{f_E},      $info->{f_len},
        $info->{g_strand}, $info->{g_B},  $info->{g_E},      $info->{g_len}, $info->{contained};

    return $line;
}

sub parse_paf_line {
    my $line = shift;

    chomp $line;
    my @fields = split "\t", $line;

    my $info = {
        f_id     => $fields[0],
        g_id     => $fields[5],
        ovlp_len => $fields[10],
        ovlp_idt => sprintf( "%.3f", $fields[9] / $fields[10] ),
        f_strand => 0,
        f_B      => $fields[2] + 1,
        f_E      => $fields[3] + 1,
        f_len    => $fields[1],
        $fields[4] eq "+"
        ? ( g_strand => 0,
            g_B      => $fields[7] + 1,
            g_E      => $fields[8] + 1,
            )
        : ( g_strand => 1,
            g_B      => $fields[8] + 1,
            g_E      => $fields[7] + 1,
        ),
        g_len     => $fields[6],
        contained => 'overlap',
    };

    for my $key (qw(f_B f_E g_B g_E)) {
        if ( $info->{$key} == 1 ) {
            $info->{$key} = 0;
        }
    }

    return $info;
}

sub beg_end {
    my $beg = shift;
    my $end = shift;

    if ( $beg > $end ) {
        ( $beg, $end ) = ( $end, $beg );
    }

    if ( $beg == 0 ) {
        $beg = 1;
    }

    return ( $beg, $end );
}

sub bump_coverage {
    my $tier_of  = shift;
    my $beg      = shift;
    my $end      = shift;
    my $coverage = shift || 2;

    return if $tier_of->{$coverage}->equals( $tier_of->{all} );

    ( $beg, $end ) = beg_end( $beg, $end );

    my $new_set = AlignDB::IntSpan->new->add_pair( $beg, $end );
    for my $i ( 1 .. $coverage ) {
        my $i_set = $tier_of->{$i}->intersect($new_set);
        $tier_of->{$i}->add($new_set);

        my $j = $i + 1;
        last if $j > $coverage;
        $new_set = $i_set->copy;
    }
}

sub serial2name {
    my $dazz_db = shift;

    my $serials = shift;

    my $cmd = sprintf "DBshow -n %s %s ", $dazz_db, join( " ", @{$serials} );
    my @lines = map { $_ =~ s/^>//; $_; } grep {defined} split /\n/, `$cmd`;

    my %name_of;
    for my $i ( 0 .. $#lines ) {
        $name_of{ $serials->[$i] } = $lines[$i];
    }

    return \%name_of;
}

sub judge_distance {
    my $d_ref = shift;
    my $max_dis = shift || 5000;

    return 0 unless defined $d_ref;

    my $sum = 0;
    my $min = $d_ref->[0];
    my $max = $min;
    for my $d ( @{$d_ref} ) {
        $sum += $d;
        if ( $d < $min ) { $min = $d; }
        if ( $d > $max ) { $max = $d; }
    }
    my $avg = $sum / scalar( @{$d_ref} );
    return 0 if $avg > $max_dis;

    # max k-mer is 127.
    # For k-unitigs, overlaps are less than k-mer
    my $v = $max - $min;
    if ( $v < 20 or abs( $v / $avg ) < 0.2 ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub g2gv {

    #@type Graph
    my $g  = shift;
    my $fn = shift;

    my $gv = GraphViz->new( directed => 1 );

    for my $v ( $g->vertices ) {
        $gv->add_node($v);
    }

    for my $e ( $g->edges ) {
        if ( $g->has_edge_weight( @{$e} ) ) {
            $gv->add_edge( @{$e}, label => $g->get_edge_weight( @{$e} ) );
        }
        else {
            $gv->add_edge( @{$e} );
        }
    }

    Path::Tiny::path($fn)->spew_raw( $gv->as_png );
}

sub g2gv0 {

    #@type Graph
    my $g  = shift;
    my $fn = shift;

    my $gv = GraphViz->new( directed => 0 );

    for my $v ( $g->vertices ) {
        $gv->add_node($v);
    }

    for my $e ( $g->edges ) {
        $gv->add_edge( @{$e} );
    }

    Path::Tiny::path($fn)->spew_raw( $gv->as_png );
}

sub transitive_reduction {

    #@type Graph
    my $g = shift;

    my $count = 0;
    my $prev_count;
    while (1) {
        last if defined $prev_count and $prev_count == $count;
        $prev_count = $count;

        for my $v ( $g->vertices ) {
            next if $g->out_degree($v) < 2;

            my @s = sort { $a cmp $b } $g->successors($v);
            for my $i ( 0 .. $#s ) {
                for my $j ( 0 .. $#s ) {
                    next if $i == $j;
                    if ( $g->is_reachable( $s[$i], $s[$j] ) ) {
                        $g->delete_edge( $v, $s[$j] );

                        $count++;
                    }
                }
            }
        }
    }

    return $count;
}

sub poa_consensus {
    my $seq_refs = shift;

    my $aln_prog = "poa";

    # temp in and out
    my $temp_in  = Path::Tiny->tempfile("seq_in_XXXXXXXX");
    my $temp_out = Path::Tiny->tempfile("seq_out_XXXXXXXX");

    # msa may change the order of sequences
    my @indexes = 0 .. scalar( @{$seq_refs} - 1 );
    {
        my $fh = $temp_in->openw();
        for my $i (@indexes) {
            printf {$fh} ">seq_%d\n", $i;
            printf {$fh} "%s\n",      $seq_refs->[$i];
        }
        close $fh;
    }

    my @args;
    {
        push @args, "-hb";
        push @args, "-read_fasta " . $temp_in->absolute->stringify;
        push @args, "-clustal " . $temp_out->absolute->stringify;
        push @args, File::ShareDir::dist_file( 'App-Anchr', 'poa-blosum80.mat' );
    }

    my $cmd_line = join " ", ( $aln_prog, @args );
    my $ok = IPC::Cmd::run( command => $cmd_line );

    if ( !$ok ) {
        Carp::confess("Calling [$aln_prog] failed\n");
    }

    my $consensus = join "", grep {/^CONSENS0/} $temp_out->lines( { chomp => 1, } );
    $consensus =~ s/CONSENS0//g;
    $consensus =~ s/\s//g;
    $consensus =~ s/-//g;

    return $consensus;
}

# https://metacpan.org/source/GSULLIVAN/String-LCSS-1.00/lib/String/LCSS.pm
# `undef` is returned if the susbstring length is one char or less.
# In scalar context, returns the substring.
# In array context, returns the index of the match root in the two args.
sub lcss {
    my $solns0 = ( _lcss( $_[0], $_[1] ) )[0];
    return unless $solns0;
    my @match = @{$solns0};
    return if length $match[0] == 1;
    return wantarray ? @match : $match[0];
}

sub _lcss {

    # Return array-of-arrays of longest substrings and indices
    my ( $r1, $r2 ) = @_;
    my ( $l1, $l2, ) = ( length $r1, length $r2, );
    ( $r1, $r2, $l1, $l2, ) = ( $r2, $r1, $l2, $l1, ) if $l1 > $l2;

    my ( $best, @solns ) = 0;
    for my $start ( 0 .. $l2 - 1 ) {
        for my $l ( reverse 1 .. $l1 - $start ) {
            my $substr = substr( $r1, $start, $l );
            my $o = index( $r2, $substr );
            next if $o < 0;
            if ( $l > $best ) {
                $best = length $substr;
                @solns = [ $substr, $start, $o ];
            }
            elsif ( $l == $best ) {
                push @solns, [ $substr, $start, $o ];
            }
        }
    }
    return @solns;
}

1;
