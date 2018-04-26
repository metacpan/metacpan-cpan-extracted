package App::Fasops::Common;
use strict;
use warnings;
use autodie;

use 5.018001;

use Carp qw();
use File::ShareDir qw();
use IO::Zlib;
use IPC::Cmd qw();
use List::Util;
use Path::Tiny qw();
use Tie::IxHash;
use YAML::Syck qw();

use AlignDB::IntSpan;
use App::RL::Common;

sub mean (@) {
    @_ = grep { defined $_ } @_;
    return 0 unless @_;
    return $_[0] unless @_ > 1;
    return List::Util::sum(@_) / scalar(@_);
}

sub any (&@) {
    my $f = shift;
    for (@_) {
        return 1 if $f->();
    }
    return 0;
}

sub all (&@) {
    my $f = shift;
    for (@_) {
        return 0 unless $f->();
    }
    return 1;
}

sub uniq (@) {
    my %seen = ();
    my $k;
    my $seen_undef;
    return grep { defined $_ ? not $seen{ $k = $_ }++ : not $seen_undef++ } @_;
}

sub firstidx (&@) {
    my $f = shift;
    for my $i ( 0 .. $#_ ) {
        local *_ = \$_[$i];
        return $i if $f->();
    }
    return -1;
}

sub read_replaces {
    my $file = shift;

    tie my %replace, "Tie::IxHash";
    my @lines = Path::Tiny::path($file)->lines( { chomp => 1 } );
    for (@lines) {
        my @fields = split /\t/;
        if ( @fields >= 1 ) {
            my $ori = shift @fields;
            $replace{$ori} = [@fields];
        }
    }

    return \%replace;
}

sub parse_block {
    my $block     = shift;
    my $want_full = shift;

    my @lines = grep {/\S/} split /\n/, $block;
    Carp::croak "Numbers of headers not equal to seqs\n" if @lines % 2;

    tie my %info_of, "Tie::IxHash";
    while (@lines) {
        my $header = shift @lines;
        $header =~ s/^\>//;
        chomp $header;

        my $seq = shift @lines;
        chomp $seq;

        my $info_ref = App::RL::Common::decode_header($header);
        $info_ref->{seq} = $seq;
        if ( $want_full or !defined $info_ref->{name} ) {
            my $ess_header = App::RL::Common::encode_header( $info_ref, 1 );
            $info_of{$ess_header} = $info_ref;
        }
        else {
            $info_of{ $info_ref->{name} } = $info_ref;
        }
    }

    return \%info_of;
}

sub parse_block_header {
    my $block = shift;

    my @lines = grep {/\S/} split /\n/, $block;
    Carp::croak "Numbers of headers not equal to seqs\n" if @lines % 2;

    tie my %info_of, "Tie::IxHash";
    while (@lines) {
        my $header = shift @lines;
        $header =~ s/^\>//;
        chomp $header;

        my $seq = shift @lines;
        chomp $seq;

        my $info_ref = App::RL::Common::decode_header($header);
        my $ess_header = App::RL::Common::encode_header( $info_ref, 1 );
        $info_ref->{seq} = $seq;
        $info_of{$ess_header} = $info_ref;
    }

    return \%info_of;
}

sub parse_axt_block {
    my $block     = shift;
    my $length_of = shift;

    my @lines = grep {/\S/} split /\n/, $block;
    Carp::croak "A block of axt should contain three lines\n" if @lines != 3;

    my (undef,         $first_chr,  $first_start,  $first_end, $second_chr,
        $second_start, $second_end, $query_strand, undef,
    ) = split /\s+/, $lines[0];

    if ( $query_strand eq "-" ) {
        if ( defined $length_of and ref $length_of eq "HASH" ) {
            if ( exists $length_of->{$second_chr} ) {
                $second_start = $length_of->{$second_chr} - $second_start + 1;
                $second_end   = $length_of->{$second_chr} - $second_end + 1;
                ( $second_start, $second_end ) = ( $second_end, $second_start );
            }
        }
    }

    my $info_refs = [
        {   name   => "target",
            chr    => $first_chr,
            start  => $first_start,
            end    => $first_end,
            strand => "+",
            seq    => $lines[1],
        },
        {   name   => "query",
            chr    => $second_chr,
            start  => $second_start,
            end    => $second_end,
            strand => $query_strand,
            seq    => $lines[2],
        },
    ];

    return $info_refs;
}

sub parse_maf_block {
    my $block = shift;

    my @lines = grep {/\S/} split /\n/, $block;
    Carp::croak "A block of maf should contain s lines\n" unless @lines > 0;

    tie my %info_of, "Tie::IxHash";

    for my $sline (@lines) {
        my ( undef, $src, $start, $size, $strand, $srcSize, $text ) = split /\s+/, $sline;

        my ( $species, $chr_name ) = split /\./, $src;
        $chr_name = $species if !defined $chr_name;

        # adjust coordinates to be one-based inclusive
        $start = $start + 1;

        my $end = $start + $size - 1;

        if ( $strand eq "-" ) {
            $start = $srcSize - $start + 1;
            $end   = $srcSize - $end + 1;
            ( $start, $end ) = ( $end, $start );
        }

        $info_of{$species} = {
            name   => $species,
            chr    => $chr_name,
            start  => $start,
            end    => $end,
            strand => $strand,
            seq    => $text,
        };
    }

    return \%info_of;
}

sub revcom {
    my $seq = shift;

    $seq =~ tr/ACGTMRWSYKVHDBNacgtmrwsykvhdbn-/TGCAKYWSRMBDHVNtgcakyswrmbdhvn-/;
    my $seq_rc = reverse $seq;

    return $seq_rc;
}

sub seq_length {
    my $seq = shift;

    my $gaps = $seq =~ tr/-/-/;

    return length($seq) - $gaps;
}

#@returns AlignDB::IntSpan
sub indel_intspan {
    my $seq = shift;

    my $intspan = AlignDB::IntSpan->new();
    my $length  = length($seq);

    my $offset = 0;
    my $start  = 0;
    my $end    = 0;
    for my $pos ( 1 .. $length ) {
        my $base = substr( $seq, $pos - 1, 1 );
        if ( $base eq '-' ) {
            if ( $offset == 0 ) {
                $start = $pos;
            }
            $offset++;
        }
        else {
            if ( $offset != 0 ) {
                $end = $pos - 1;
                $intspan->add_pair( $start, $end );
            }
            $offset = 0;
        }
    }
    if ( $offset != 0 ) {
        $end = $length;
        $intspan->add_pair( $start, $end );
    }

    return $intspan;
}

#@returns AlignDB::IntSpan
sub seq_intspan {
    my $seq = shift;

    my $intspan = AlignDB::IntSpan->new();
    my $length  = length($seq);
    $intspan->add_pair( 1, $length );

    $intspan->subtract( indel_intspan($seq) );

    return $intspan;
}

sub align_seqs {
    my $seq_refs = shift;
    my $aln_bin  = shift // "mafft";

    # get executable
    my $bin;

    if ( $aln_bin =~ /clus/i ) {
        $aln_bin = 'clustalw';
        for my $e (qw{clustalw clustal-w clustalw2}) {
            if ( IPC::Cmd::can_run($e) ) {
                $bin = $e;
                last;
            }
        }
    }
    elsif ( $aln_bin =~ /musc/i ) {
        $aln_bin = 'muscle';
        for my $e (qw{muscle}) {
            if ( IPC::Cmd::can_run($e) ) {
                $bin = $e;
                last;
            }
        }
    }
    elsif ( $aln_bin =~ /maff/i ) {
        $aln_bin = 'mafft';
        for my $e (qw{mafft}) {
            if ( IPC::Cmd::can_run($e) ) {
                $bin = $e;
                last;
            }
        }
    }

    if ( !defined $bin ) {
        Carp::confess "Could not find the executable for $aln_bin\n";
    }

    # temp in and out
    #@type Path::Tiny
    my $temp_in = Path::Tiny->tempfile("seq_in_XXXXXXXX");

    #@type Path::Tiny
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
    if ( $aln_bin eq "clustalw" ) {
        push @args, "-align -type=dna -output=fasta -outorder=input -quiet";
        push @args, "-infile=" . $temp_in->absolute->stringify;
        push @args, "-outfile=" . $temp_out->absolute->stringify;
    }
    elsif ( $aln_bin eq "muscle" ) {
        push @args, "-quiet";
        push @args, "-in " . $temp_in->absolute->stringify;
        push @args, "-out " . $temp_out->absolute->stringify;
    }
    elsif ( $aln_bin eq "mafft" ) {
        push @args, "--quiet";
        push @args, "--auto";
        push @args, $temp_in->absolute->stringify;
        push @args, "> " . $temp_out->absolute->stringify;
    }

    my $cmd_line = join " ", ( $bin, @args );
    my $ok = IPC::Cmd::run( command => $cmd_line );

    if ( !$ok ) {
        Carp::confess("$aln_bin call failed\n");
    }

    my @aligned;
    my $seq_of = read_fasta( $temp_out->absolute->stringify );
    for my $i (@indexes) {
        push @aligned, $seq_of->{ "seq_" . $i };
    }

    # delete .dnd files created by clustalw
    #printf STDERR "%s\n", $temp_in->absolute->stringify;
    if ( $aln_bin eq "clustalw" ) {
        my $dnd = $temp_in->absolute->stringify . ".dnd";
        path($dnd)->remove;
    }

    undef $temp_in;
    undef $temp_out;

    return \@aligned;
}

sub align_seqs_quick {
    my $seq_refs   = shift;
    my $aln_prog   = shift;
    my $indel_pad  = shift;
    my $indel_fill = shift;

    if ( !defined $aln_prog ) {
        $aln_prog = "mafft";
    }
    if ( !defined $indel_pad ) {
        $indel_pad = 50;
    }
    if ( !defined $indel_fill ) {
        $indel_fill = 50;
    }

    my @aligned   = @{$seq_refs};
    my $seq_count = scalar @aligned;

    # all indel regions
    my $realign_region = AlignDB::IntSpan->new();
    for my $seq (@aligned) {
        my $indel_intspan = indel_intspan($seq);
        $indel_intspan = $indel_intspan->pad($indel_pad);
        $realign_region->merge($indel_intspan);
    }

    # join adjacent realign regions
    $realign_region = $realign_region->fill($indel_fill);

    # realign all segments in realign_region
    for my $span ( reverse $realign_region->spans ) {
        my $seg_start = $span->[0];
        my $seg_end   = $span->[1];

        my @segments;
        for my $i ( 0 .. $seq_count - 1 ) {
            my $seg = substr( $aligned[$i], $seg_start - 1, $seg_end - $seg_start + 1 );
            push @segments, $seg;
        }
        my $realigned_segments = align_seqs( \@segments );

        for my $i ( 0 .. $seq_count - 1 ) {
            my $seg = $realigned_segments->[$i];
            $seg = uc $seg;
            substr( $aligned[$i], $seg_start - 1, $seg_end - $seg_start + 1, $seg );
        }
    }

    return \@aligned;
}

#----------------------------#
# trim pure dash regions
#----------------------------#
sub trim_pure_dash {
    my $seq_refs = shift;

    my $seq_count  = @{$seq_refs};
    my $seq_length = length $seq_refs->[0];

    return unless $seq_length;

    my $trim_region = AlignDB::IntSpan->new();

    for my $pos ( 1 .. $seq_length ) {
        my @bases;
        for my $i ( 0 .. $seq_count - 1 ) {
            my $base = substr( $seq_refs->[$i], $pos - 1, 1 );
            push @bases, $base;
        }

        if ( all { $_ eq '-' } @bases ) {
            $trim_region->add($pos);
        }
    }

    for my $span ( reverse $trim_region->spans ) {
        my $seg_start = $span->[0];
        my $seg_end   = $span->[1];

        for my $i ( 0 .. $seq_count - 1 ) {
            substr( $seq_refs->[$i], $seg_start - 1, $seg_end - $seg_start + 1, "" );
        }
    }

    return;
}

#----------------------------#
# trim outgroup only sequence
#----------------------------#
# if intersect is superset of union
#   T G----C
#   Q G----C
#   O GAAAAC
sub trim_outgroup {
    my $seq_refs = shift;

    my $seq_count = scalar @{$seq_refs};

    Carp::confess "Need three or more sequences\n" if $seq_count < 3;

    # Don't expand indel set here. Last seq is outgroup
    my @indel_intspans;
    for my $i ( 0 .. $seq_count - 2 ) {
        my $indel_intspan = indel_intspan( $seq_refs->[$i] );
        push @indel_intspans, $indel_intspan;
    }

    # find trim_region
    my $union_set     = AlignDB::IntSpan::union(@indel_intspans);
    my $intersect_set = AlignDB::IntSpan::intersect(@indel_intspans);

    my $trim_region = AlignDB::IntSpan->new();
    for my $span ( $union_set->runlists ) {
        if ( $intersect_set->superset($span) ) {
            $trim_region->add($span);
        }
    }

    # trim all segments in trim_region
    for my $span ( reverse $trim_region->spans ) {
        my $seg_start = $span->[0];
        my $seg_end   = $span->[1];

        for my $i ( 0 .. $seq_count - 1 ) {
            substr( $seq_refs->[$i], $seg_start - 1, $seg_end - $seg_start + 1, "" );
        }
    }

    return;
}

#----------------------------#
# record complex indels and ingroup indels
#----------------------------#
# All ingroup intersect sets are parts of complex indels after trim_outgroup()
# intersect 4-6
#   T GGA--C
#   Q G----C
#   O GGAGAC
# result, complex_region 2-3
#   T GGAC
#   Q G--C
#   O GGAC
sub trim_complex_indel {
    my $seq_refs = shift;

    my $seq_count   = scalar @{$seq_refs};
    my @ingroup_idx = ( 0 .. $seq_count - 2 );

    Carp::confess "Need three or more sequences\n" if $seq_count < 3;

    # Don't expand indel set here. Last seq is outgroup
    my @indel_intspans;
    for my $i (@ingroup_idx) {
        my $indel_intspan = indel_intspan( $seq_refs->[$i] );
        push @indel_intspans, $indel_intspan;
    }
    my $outgroup_indel_intspan = indel_intspan( $seq_refs->[ $seq_count - 1 ] );

    # find trim_region
    my $union_set     = AlignDB::IntSpan::union(@indel_intspans);
    my $intersect_set = AlignDB::IntSpan::intersect(@indel_intspans);

    my $complex_region = AlignDB::IntSpan->new();
    for ( reverse $intersect_set->spans ) {
        my $seg_start = $_->[0];
        my $seg_end   = $_->[1];

        # trim sequence, including outgroup
        for my $i ( 0 .. $seq_count - 1 ) {
            substr( $seq_refs->[$i], $seg_start - 1, $seg_end - $seg_start + 1, "" );
        }

        # add to complex_region
        for my $span ( $union_set->runlists ) {
            my $sub_union_set = AlignDB::IntSpan->new($span);
            if ( $sub_union_set->superset("$seg_start-$seg_end") ) {
                $complex_region->merge($sub_union_set);
            }
        }

        # modify all related set
        $union_set = $union_set->banish_span( $seg_start, $seg_end );
        for (@ingroup_idx) {
            $indel_intspans[$_]
                = $indel_intspans[$_]->banish_span( $seg_start, $seg_end );
        }
        $outgroup_indel_intspan->banish_span( $seg_start, $seg_end );
        $complex_region = $complex_region->banish_span( $seg_start, $seg_end );
    }

    # add ingroup-outgroup complex indels to complex_region
    for my $i (@ingroup_idx) {
        my $outgroup_intersect_intspan = $outgroup_indel_intspan->intersect( $indel_intspans[$i] );
        for my $sub_out_set ( $outgroup_intersect_intspan->sets ) {
            for my $sub_union_set ( $union_set->sets ) {

                # union_set > intersect_set
                if ( $sub_union_set->larger_than($sub_out_set) ) {
                    $complex_region->merge($sub_union_set);
                }
            }
        }
    }

    return $complex_region->runlist;
}

# read normal fasta files
sub read_fasta {
    my $infile = shift;

    my ( @names, %seqs );

    my $in_fh = IO::Zlib->new( $infile, "rb" );

    my $cur_name;
    while ( my $line = $in_fh->getline ) {
        chomp $line;
        if ( $line eq '' or substr( $line, 0, 1 ) eq " " ) {
            next;
        }
        elsif ( substr( $line, 0, 1 ) eq "#" ) {
            next;
        }
        elsif ( substr( $line, 0, 1 ) eq ">" ) {
            ($cur_name) = split /\s+/, $line;
            $cur_name =~ s/^>//;
            push @names, $cur_name;
            $seqs{$cur_name} = '';
        }
        else {
            $seqs{$cur_name} .= $line;
        }
    }

    $in_fh->close;

    tie my %seq_of, "Tie::IxHash";
    for my $name (@names) {
        $seq_of{$name} = $seqs{$name};
    }
    return \%seq_of;
}

sub calc_gc_ratio {
    my $seq_refs = shift;

    my $seq_count = scalar @{$seq_refs};

    my @ratios;
    for my $i ( 0 .. $seq_count - 1 ) {

        # Count all four bases
        my $a_count = $seq_refs->[$i] =~ tr/Aa/Aa/;
        my $g_count = $seq_refs->[$i] =~ tr/Gg/Gg/;
        my $c_count = $seq_refs->[$i] =~ tr/Cc/Cc/;
        my $t_count = $seq_refs->[$i] =~ tr/Tt/Tt/;

        my $four_count = $a_count + $g_count + $c_count + $t_count;
        my $gc_count   = $g_count + $c_count;

        if ( $four_count == 0 ) {
            next;
        }
        else {
            my $gc_ratio = $gc_count / $four_count;
            push @ratios, $gc_ratio;
        }
    }

    return mean(@ratios);
}

sub pair_D {
    my $seq_refs = shift;

    my $seq_count = scalar @{$seq_refs};
    if ( $seq_count != 2 ) {
        Carp::confess "Need two sequences\n";
    }

    my $legnth = length $seq_refs->[0];

    my ( $comparable_bases, $differences ) = (0) x 2;

    for my $pos ( 1 .. $legnth ) {
        my $base0 = substr $seq_refs->[0], $pos - 1, 1;
        my $base1 = substr $seq_refs->[1], $pos - 1, 1;

        if (   $base0 =~ /[atcg]/i
            && $base1 =~ /[atcg]/i )
        {
            $comparable_bases++;
            if ( $base0 ne $base1 ) {
                $differences++;
            }
        }
    }

    if ( $comparable_bases == 0 ) {
        Carp::carp "comparable_bases == 0\n";
        return 0;
    }
    else {
        return $differences / $comparable_bases;
    }
}

# Split D value to D1 (substitutions in first_seq), D2( substitutions in second_seq) and Dcomplex
# (substitutions can't be referred)
sub ref_pair_D {
    my $seq_refs = shift;    # first, second, outgroup

    my $seq_count = scalar @{$seq_refs};
    if ( $seq_count != 3 ) {
        Carp::confess "Need three sequences\n";
    }

    my ( $d1, $d2, $dc ) = (0) x 3;
    my $length = length $seq_refs->[0];

    return ( $d1, $d2, $dc ) if $length == 0;

    for my $pos ( 1 .. $length ) {
        my $base0   = substr $seq_refs->[0], $pos - 1, 1;
        my $base1   = substr $seq_refs->[1], $pos - 1, 1;
        my $base_og = substr $seq_refs->[2], $pos - 1, 1;
        if ( $base0 ne $base1 ) {
            if (   $base0 =~ /[atcg]/i
                && $base1 =~ /[atcg]/i
                && $base_og =~ /[atcg]/i )
            {
                if ( $base1 eq $base_og ) {
                    $d1++;
                }
                elsif ( $base0 eq $base_og ) {
                    $d2++;
                }
                else {
                    $dc++;
                }
            }
            else {
                $dc++;
            }
        }
    }

    for ( $d1, $d2, $dc ) {
        $_ /= $length;
    }

    return ( $d1, $d2, $dc );
}

sub multi_seq_stat {
    my $seq_refs = shift;

    my $seq_count = scalar @{$seq_refs};
    if ( $seq_count < 2 ) {
        Carp::confess "Need two or more sequences\n";
    }

    my $legnth = length $seq_refs->[0];

    # For every positions, search for polymorphism_site
    my ( $comparable_bases, $identities, $differences, $gaps, $ns, $align_errors, ) = (0) x 6;
    for my $pos ( 1 .. $legnth ) {
        my @bases = ();
        for my $i ( 0 .. $seq_count - 1 ) {
            my $base = substr( $seq_refs->[$i], $pos - 1, 1 );
            push @bases, $base;
        }
        @bases = uniq(@bases);

        if ( all { $_ =~ /[agct]/i } @bases ) {
            $comparable_bases++;
            if ( all { $_ eq $bases[0] } @bases ) {
                $identities++;
            }
            else {
                $differences++;
            }
        }
        elsif ( any { $_ eq '-' } @bases ) {
            $gaps++;
        }
        else {
            $ns++;
        }
    }
    if ( $comparable_bases == 0 ) {
        print YAML::Syck::Dump { seqs => $seq_refs, };
        Carp::carp "number_of_comparable_bases == 0!!\n";
        return [ $legnth, $comparable_bases, $identities, $differences,
            $gaps, $ns, $legnth, undef, ];
    }

    my @all_Ds;
    for ( my $i = 0; $i < $seq_count; $i++ ) {
        for ( my $j = $i + 1; $j < $seq_count; $j++ ) {
            my $D = pair_D( [ $seq_refs->[$i], $seq_refs->[$j] ] );
            push @all_Ds, $D;
        }
    }

    my $D = mean(@all_Ds);

    return [ $legnth, $comparable_bases, $identities, $differences,
        $gaps, $ns, $align_errors, $D, ];
}

sub get_snps {
    my $seq_refs = shift;

    my $align_length = length $seq_refs->[0];
    my $seq_count    = scalar @{$seq_refs};

    # SNPs
    my $snp_bases_of = {};
    for my $pos ( 1 .. $align_length ) {
        my @bases;
        for my $i ( 0 .. $seq_count - 1 ) {
            my $base = substr( $seq_refs->[$i], $pos - 1, 1 );
            push @bases, $base;
        }

        if ( all { $_ =~ /[agct]/i } @bases ) {
            if ( any { $_ ne $bases[0] } @bases ) {
                $snp_bases_of->{$pos} = \@bases;
            }
        }
    }

    my @sites;
    for my $pos ( sort { $a <=> $b } keys %{$snp_bases_of} ) {

        my @bases = @{ $snp_bases_of->{$pos} };

        my $target_base = $bases[0];
        my $all_bases = join '', @bases;

        my $query_base;
        my $mutant_to;
        my $snp_freq = 0;
        my $snp_occured;
        my @class = uniq(@bases);
        if ( scalar @class < 2 ) {
            Carp::confess "no snp\n";
        }
        elsif ( scalar @class > 2 ) {
            $snp_freq    = -1;
            $snp_occured = 'unknown';
        }
        else {
            for (@bases) {
                if ( $target_base ne $_ ) {
                    $snp_freq++;
                    $snp_occured .= '0';
                }
                else {
                    $snp_occured .= '1';
                }
            }
            ($query_base) = grep { $_ ne $target_base } @bases;
            $mutant_to = $target_base . '<->' . $query_base;
        }

        # here freq is the minor allele freq
        $snp_freq = List::Util::min( $snp_freq, $seq_count - $snp_freq );

        push @sites,
            {
            snp_pos         => $pos,
            snp_target_base => $target_base,
            snp_query_base  => $query_base,
            snp_all_bases   => $all_bases,
            snp_mutant_to   => $mutant_to,
            snp_freq        => $snp_freq,
            snp_occured     => $snp_occured,
            };
    }

    return \@sites;
}

sub polarize_snp {
    my $sites        = shift;
    my $outgroup_seq = shift;

    for my $site ( @{$sites} ) {
        my $outgroup_base = substr $outgroup_seq, $site->{snp_pos} - 1, 1;

        my @nts = split '', $site->{snp_all_bases};
        my @class;
        for my $nt (@nts) {
            my $class_bool = 0;
            for (@class) {
                if ( $_ eq $nt ) { $class_bool = 1; }
            }
            unless ($class_bool) {
                push @class, $nt;
            }
        }

        my ( $mutant_to, $snp_freq, $snp_occured );

        if ( scalar @class < 2 ) {
            Carp::confess "Not a real SNP\n";
        }
        elsif ( scalar @class == 2 ) {
            for my $nt (@nts) {
                if ( $nt eq $outgroup_base ) {
                    $snp_occured .= '0';
                }
                else {
                    $snp_occured .= '1';
                    $snp_freq++;
                    $mutant_to = "$outgroup_base->$nt";
                }
            }
        }
        else {
            $snp_freq    = -1;
            $mutant_to   = 'Complex';
            $snp_occured = 'unknown';
        }

        # outgroup_base is not equal to any nts
        if ( $snp_occured eq ( '1' x ( length $snp_occured ) ) ) {
            $snp_freq    = -1;
            $mutant_to   = 'Complex';
            $snp_occured = 'unknown';
        }

        $site->{snp_outgroup_base} = $outgroup_base;
        $site->{snp_mutant_to}     = $mutant_to;
        $site->{snp_freq}          = $snp_freq;
        $site->{snp_occured}       = $snp_occured;
    }

    return $sites;
}

sub get_indels {
    my $seq_refs = shift;

    my $seq_count = scalar @{$seq_refs};

    my $indel_set = AlignDB::IntSpan->new();
    for my $i ( 0 .. $seq_count - 1 ) {
        my $seq_indel_set = indel_intspan( $seq_refs->[$i] );
        $indel_set->merge($seq_indel_set);
    }

    my @sites;

    # indels
    for my $cur_indel ( $indel_set->spans ) {
        my ( $indel_start, $indel_end ) = @{$cur_indel};
        my $indel_length = $indel_end - $indel_start + 1;

        my @indel_seqs;
        for my $seq ( @{$seq_refs} ) {
            push @indel_seqs, ( substr $seq, $indel_start - 1, $indel_length );
        }
        my $indel_all_seqs = join "|", @indel_seqs;

        my $indel_type;
        my @uniq_indel_seqs = uniq(@indel_seqs);

        # seqs with least '-' char wins
        my ($indel_seq) = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, tr/-/-/ ] } @uniq_indel_seqs;

        if ( scalar @uniq_indel_seqs < 2 ) {
            Carp::confess "no indel!\n";
            next;
        }
        elsif ( scalar @uniq_indel_seqs > 2 ) {
            $indel_type = 'C';
        }
        elsif ( $indel_seq =~ /-/ ) {
            $indel_type = 'C';
        }
        else {
            #   'D': means deletion relative to target/first seq
            #        target is ----
            #   'I': means insertion relative to target/first seq
            #        target is AAAA
            if ( $indel_seqs[0] eq $indel_seq ) {
                $indel_type = 'I';
            }
            else {
                $indel_type = 'D';
            }
        }

        my $indel_freq = 0;
        my $indel_occured;
        if ( $indel_type eq 'C' ) {
            $indel_freq    = -1;
            $indel_occured = 'unknown';
        }
        else {
            for (@indel_seqs) {

                # same as target '1', not '0'
                if ( $indel_seqs[0] eq $_ ) {
                    $indel_freq++;
                    $indel_occured .= '1';
                }
                else {
                    $indel_occured .= '0';
                }
            }
        }

        # here freq is the minor allele freq
        $indel_freq = List::Util::min( $indel_freq, $seq_count - $indel_freq );

        push @sites,
            {
            indel_start    => $indel_start,
            indel_end      => $indel_end,
            indel_length   => $indel_length,
            indel_seq      => $indel_seq,
            indel_all_seqs => $indel_all_seqs,
            indel_freq     => $indel_freq,
            indel_occured  => $indel_occured,
            indel_type     => $indel_type,
            };
    }

    return \@sites;
}

sub polarize_indel {
    my $sites        = shift;
    my $outgroup_seq = shift;

    my $outgroup_indel_set = indel_intspan($outgroup_seq);

    for my $site ( @{$sites} ) {
        my @indel_seqs = split /\|/, $site->{indel_all_seqs};

        my $indel_outgroup_seq = substr $outgroup_seq, $site->{indel_start} - 1,
            $site->{indel_length};

        my ( $indel_type, $indel_occured, $indel_freq );

        my $indel_set
            = AlignDB::IntSpan->new()->add_pair( $site->{indel_start}, $site->{indel_end} );

        # this line is different to previous subroutines
        my @uniq_indel_seqs = uniq( @indel_seqs, $indel_outgroup_seq );

        # seqs with least '-' char wins
        my ($indel_seq) = map { $_->[0] }
            sort { $a->[1] <=> $b->[1] }
            map { [ $_, tr/-/-/ ] } @uniq_indel_seqs;

        if ( scalar @uniq_indel_seqs < 2 ) {
            Carp::confess "no indel!\n";
        }
        elsif ( scalar @uniq_indel_seqs > 2 ) {
            $indel_type = 'C';
        }
        elsif ( $indel_seq =~ /-/ ) {
            $indel_type = 'C';
        }
        else {

            if (    ( $indel_outgroup_seq !~ /\-/ )
                and ( $indel_seq ne $indel_outgroup_seq ) )
            {

                # this section should already be judged in previes
                # uniq_indel_seqs section, but I keep it here for safe

                # reference indel content does not contain '-' and is not equal
                # to the one of alignment
                #     AAA
                #     A-A
                # ref ACA
                $indel_type = 'C';
            }
            elsif ( $outgroup_indel_set->intersect($indel_set)->is_not_empty ) {
                my $island = $outgroup_indel_set->find_islands($indel_set);
                if ( $island->equal($indel_set) ) {

                    #     NNNN
                    #     N--N
                    # ref N--N
                    $indel_type = 'I';
                }
                else {
                    # reference indel island is larger or smaller
                    #     NNNN
                    #     N-NN
                    # ref N--N
                    # or
                    #     NNNN
                    #     N--N
                    # ref N-NN
                    $indel_type = 'C';
                }
            }
            elsif ( $outgroup_indel_set->intersect($indel_set)->is_empty ) {

                #     NNNN
                #     N--N
                # ref NNNN
                $indel_type = 'D';
            }
            else {
                Carp::confess "Errors when polarizing indel!\n";
            }
        }

        if ( $indel_type eq 'C' ) {
            $indel_occured = 'unknown';
            $indel_freq    = -1;
        }
        else {
            for my $seq (@indel_seqs) {
                if ( $seq eq $indel_outgroup_seq ) {
                    $indel_occured .= '0';
                }
                else {
                    $indel_occured .= '1';
                    $indel_freq++;
                }
            }
        }

        $site->{indel_outgroup_seq} = $indel_outgroup_seq;
        $site->{indel_type}         = $indel_type;
        $site->{indel_occured}      = $indel_occured;
        $site->{indel_freq}         = $indel_freq;
    }

    return $sites;
}

sub chr_to_align {
    my AlignDB::IntSpan $intspan = shift;
    my $pos = shift;

    my $chr_start  = shift || 1;
    my $chr_strand = shift || "+";

    my $chr_end = $chr_start + $intspan->size - 1;

    if ( $pos < $chr_start || $pos > $chr_end ) {
        Carp::confess "[$pos] out of ranges [$chr_start,$chr_end]\n";
    }

    my $align_pos;
    if ( $chr_strand eq "+" ) {
        $align_pos = $pos - $chr_start + 1;
        $align_pos = $intspan->at($align_pos);
    }
    else {
        $align_pos = $pos - $chr_start + 1;
        $align_pos = $intspan->at( -$align_pos );
    }

    return $align_pos;
}

sub align_to_chr {
    my AlignDB::IntSpan $intspan = shift;
    my $pos = shift;

    my $chr_start  = shift || 1;
    my $chr_strand = shift || "+";

    my $chr_end = $chr_start + $intspan->size - 1;

    if ( $pos < 1 ) {
        Carp::confess "align pos out of ranges\n";
    }

    my $chr_pos;
    if ( $intspan->contains($pos) ) {
        $chr_pos = $intspan->index($pos);
    }
    elsif ( $pos < $intspan->min ) {
        $chr_pos = 1;
    }
    elsif ( $pos > $intspan->max ) {
        $chr_pos = $intspan->size;
    }
    else {
        # pin to left base
        my @spans = $intspan->spans;
        for my $i ( 0 .. $#spans ) {
            if ( $spans[$i]->[1] < $pos ) {
                next;
            }
            else {
                $pos = $spans[ $i - 1 ]->[1];
                last;
            }
        }
        $chr_pos = $intspan->index($pos);
    }

    if ( $chr_strand eq "+" ) {
        $chr_pos = $chr_pos + $chr_start - 1;
    }
    else {
        $chr_pos = $chr_end - $chr_pos + 1;
    }

    return $chr_pos;
}

sub calc_ld {
    my $strA = shift;
    my $strB = shift;

    my $size = length $strA;

    if ( $size != length $strB ) {
        Carp::confess "Lengths not equal for [$strA] and [$strA]\n";
        return;
    }

    for ( $strA, $strB ) {
        if (/[^10]/) {
            Carp::confess "[$_] contains illegal chars\n";
            return;
        }
    }

    my $A_count = $strA =~ tr/1/1/;
    my $fA      = $A_count / $size;
    my $fa      = 1 - $fA;

    my $B_count = $strB =~ tr/1/1/;
    my $fB      = $B_count / $size;
    my $fb      = 1 - $fB;

    if ( any { $_ == 0 } ( $fA, $fa, $fB, $fb ) ) {
        return ( undef, undef );
    }

    # '1' in strA and '1' in strB as fAB
    my ( $AB_count, $fAB ) = ( 0, 0 );
    for my $i ( 1 .. $size ) {
        my $ichar = substr $strA, $i - 1, 1;
        my $schar = substr $strB, $i - 1, 1;
        if ( $ichar eq '1' and $schar eq '1' ) {
            $AB_count++;
        }
    }
    $fAB = $AB_count / $size;

    my $DAB = $fAB - $fA * $fB;

    my ( $r, $dprime );
    $r = $DAB / sqrt( $fA * $fa * $fB * $fb );

    if ( $DAB < 0 ) {
        $dprime = $DAB / List::Util::min( $fA * $fB, $fa * $fb );
    }
    else {
        $dprime = $DAB / List::Util::min( $fA * $fb, $fa * $fB );
    }

    return ( $r, $dprime );
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
        push @args, File::ShareDir::dist_file( 'App-Fasops', 'poa-blosum80.mat' );
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Fasops::Common - collection of common subroutines

=head1 SYNOPSIS

    use App::Fasops::Common;

    my $length = App::Fasops::Common::seq_length("AGCTTT---CCA");

=head1 METHODS

=head2 chr_to_align

    my $chr_pos = App::Fasops::Common::align_to_chr( $intspan, $pos, $chr_start, $chr_strand, );
    my $chr_pos = App::Fasops::Common::align_to_chr( $intspan, $pos, $chr_start, );

Give a chr position, return an align position starting from '1'.

=head2 align_to_chr

    my $pos = App::Fasops::Common::align_to_chr( $intspan, $chr_pos, $chr_start, $chr_strand, );
    my $pos = App::Fasops::Common::align_to_chr( $intspan, $chr_pos, $chr_start, );

Give a chr position, return an align position starting from '1'.
If the position in target is located in a gap, then return the left base's position.
5' for positive strand and 3' for negative stran. (Just like GATK's indel left align.)

=head2 calc_ld

    my ( $r, $dprime ) = App::Fasops::Common::calc_ld("111000", "111000");

Returns the r and D' (Hill and Robertson, 1968) of two polymorphic sites.

L<https://cran.r-project.org/web/packages/genetics/genetics.pdf>

=cut
