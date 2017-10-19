package App::Anchr::Command::localcor;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow Sereal => 1;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => "anchor long reads to anchors";

sub opt_spec {
    return (
        [ "dir|d=s", "output directory", ],
        [ "range|r=s",    "ranges of anchors",            { required => 1 }, ],
        [ "len|l=i",      "minimal length of overlaps",   { default  => 1000 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default  => 0.85 }, ],
        [ "parallel|p=i", "number of threads",            { default  => 4 }, ],
        [ "miniasm",      "estimate assembly sizes by miniasm", ],
        [ "trim",         "also run canu -trim", ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr localcor [options] <dazz DB> <ovlp file>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tThis command relies on an existing dazz db.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
        my $message = "This command need one or more input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !AlignDB::IntSpan->valid( $opt->{range} ) ) {
        $self->usage_error("Invalid --range [$opt->{range}]\n");
    }

    if ( !exists $opt->{dir} ) {
        $opt->{dir}
            = Path::Tiny::path( $args->[0] )->parent->child("group")->absolute->stringify;
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type Path::Tiny
    my $out_dir = Path::Tiny::path( $opt->{dir} );
    $out_dir->mkpath();

    # absolute paths before we chdir to $out_dir
    my $fn_dazz = Path::Tiny::path( $args->[0] )->absolute->stringify;
    my $fn_ovlp = Path::Tiny::path( $args->[1] )->absolute->stringify;

    chdir $out_dir;

    #@type AlignDB::IntSpan
    my $anchor_range = AlignDB::IntSpan->new->add_runlist( $opt->{range} );

    #----------------------------#
    # Load overlaps
    #----------------------------#
    print STDERR "==> Loading overlaps\n"
        if $opt->{verbose};
    my $longs_of       = {};    # anchor_id => { long_id => 1 }
    my $length_of      = {};    # anchor_id => length
    my $long_length_of = {};    # long_id => length
    {
        open my $in_fh, "<", $fn_ovlp;

        my %seen_pair;
        while ( my $line = <$in_fh> ) {
            chomp $line;
            my @fields = split "\t", $line;
            next unless @fields == 13;

            my ( $f_id,     $g_id, $ovlp_len, $ovlp_idt ) = @fields[ 0 .. 3 ];
            my ( $f_strand, $f_B,  $f_E,      $f_len )    = @fields[ 4 .. 7 ];
            my ( $g_strand, $g_B,  $g_E,      $g_len )    = @fields[ 8 .. 11 ];
            my $contained = $fields[12];

            # ignore self overlapping
            next if $f_id eq $g_id;

            # ignore poor overlaps
            next if $ovlp_idt < $opt->{idt};
            next if $ovlp_len < $opt->{len};

            # only want anchor-long overlaps
            if ( $anchor_range->contains($f_id) and $anchor_range->contains($g_id) ) {
                next;
            }
            if ( !$anchor_range->contains($f_id) and !$anchor_range->contains($g_id) ) {
                next;
            }

            {    # skip duplicated overlaps
                my $pair = join( "-", sort ( $f_id, $g_id ) );
                next if $seen_pair{$pair};
                $seen_pair{$pair}++;
            }

            if ( $anchor_range->contains($f_id) and !$anchor_range->contains($g_id) ) {
                if ( !exists $length_of->{$f_id} ) {
                    $length_of->{$f_id} = $f_len;
                }
                if ( !exists $long_length_of->{$g_id} ) {
                    $long_length_of->{$g_id} = $g_len;
                }

                if ( !exists $longs_of->{$f_id} ) {
                    $longs_of->{$f_id} = {};
                }
                $longs_of->{$f_id}{$g_id}++;
            }
            elsif ( $anchor_range->contains($g_id) and !$anchor_range->contains($f_id) ) {
                if ( !exists $length_of->{$g_id} ) {
                    $length_of->{$g_id} = $g_len;
                }
                if ( !exists $long_length_of->{$f_id} ) {
                    $long_length_of->{$f_id} = $f_len;
                }

                if ( !exists $longs_of->{$g_id} ) {
                    $longs_of->{$g_id} = {};
                }
                $longs_of->{$g_id}{$f_id}++;
            }
        }
        close $in_fh;
    }
    my $mean_long_length = App::Fasops::Common::mean( values %{$long_length_of} );
    printf STDERR "==> Mean length of long reads: %d\n", $mean_long_length
        if $opt->{verbose};

    #----------------------------#
    # bring long reads to local
    #----------------------------#
    for my $anchor_id ( sort { $a <=> $b } keys %{$longs_of} ) {
        my @long_ids = sort { $a <=> $b } keys %{ $longs_of->{$anchor_id} };
        printf STDERR "  * anchor [%d]: [%d] long reads\n", $anchor_id, scalar @long_ids
            if $opt->{verbose};

        # write sequences
        my $prefix = "anchor-${anchor_id}-longs";
        if ( !Path::Tiny::path("$prefix.fasta")->is_file ) {
            my $cmd;
            $cmd .= "DBshow -U $fn_dazz ";
            $cmd .= join( " ", $anchor_id, @long_ids );
            $cmd .= " | faops filter -l 0 stdin stdout";
            $cmd .= " > $prefix.fasta";
            App::Anchr::Common::exec_cmd($cmd);
        }
    }

    #----------------------------#
    # canu correct[-trim]
    #----------------------------#
    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;

        my $anchor_id = $chunk_ref->[0];
        my $prefix    = "anchor-${anchor_id}-longs";

        # estimate assembly sizes, as canu need them
        my $est_size = 0;
        if ( $opt->{miniasm} ) {
            if ( !Path::Tiny::path("$prefix.fasta.gfa")->is_file ) {
                my $cmd;
                $cmd .= "minimap -Sw5 -L100 -m0 -t4 ";
                $cmd .= " $prefix.fasta $prefix.fasta";
                $cmd .= " | miniasm - ";
                $cmd .= " > $prefix.gfa";
                App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }

            my $fh_gfa = Path::Tiny::path("$prefix.gfa")->openr;
            while (<$fh_gfa>) {
                /^S/         or next;
                /LN:i:(\d+)/ or next;
                $est_size += $1;
            }
            close $fh_gfa;
        }

        if ( $est_size < $length_of->{$anchor_id} ) {
            $est_size = $length_of->{$anchor_id} + 2 * $mean_long_length;
        }

        # canu correct
        if ( !Path::Tiny::path("$prefix")->is_dir ) {
            my $cmd;
            $cmd .= "canu -correct";
            $cmd .= " -p $prefix -d $prefix";
            $cmd .= " genomeSize=$est_size";
            $cmd .= " gnuplotTested=true";
            $cmd .= " maxThreads=4";
            $cmd .= " -pacbio-raw $prefix.fasta";
            App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

            if ( $opt->{trim} ) {
                $cmd = "";
                $cmd .= "canu -trim";
                $cmd .= " -p $prefix -d $prefix";
                $cmd .= " genomeSize=$est_size";
                $cmd .= " gnuplotTested=true";
                $cmd .= " maxThreads=4";
                $cmd .= " -pacbio-corrected $prefix/$prefix.correctedReads.fasta.gz";
                App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
            }
        }

        MCE->gather( $anchor_id, $est_size );
    };

    my $max_worker = int( $opt->{parallel} / 4 );
    MCE::Flow::init {
        chunk_size  => 1,
        max_workers => $max_worker ? $max_worker : 1,
    };
    my %est_size_of = mce_flow $worker, [ sort { $a <=> $b } keys %{$longs_of} ];

    #----------------------------#
    # Outputs
    #----------------------------#
    Path::Tiny::path("anchor.sizes.tsv")->spew(
        map { sprintf "%s\t%d\t%d\n", $_, $length_of->{$_}, $est_size_of{$_} }
        sort { $a <=> $b } keys %{$longs_of}
    );

    {
        Path::Tiny::path("anchor.sizes.tsv")->remove;
        my @long_ids = sort { $a <=> $b } keys %{$long_length_of};
        while ( scalar @long_ids ) {
            my @batching = splice @long_ids, 0, 100;
            my $cmd;
            $cmd .= "DBshow -n $fn_dazz ";
            $cmd .= join( " ", @batching );
            $cmd .= " | sed 's/^>//'";
            $cmd .= " >> overlapped.long.txt";
            App::Anchr::Common::exec_cmd($cmd);
        }
    }
}

1;
