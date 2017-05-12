#!/usr/bin/perl -w
use strict;
use BerkeleyDB;
use Data::Dumper;
use Getopt::Long;

# Based on http:/flybase.org/static_pages/docs/software/index_cov_files.pl
# This script will process the output of bam_coverage_windows.pl
# to the data structure needed by the topoview glyph
# Sheldon McKay (sheldon.mckay@gmail.com)

my ($log,$outdir,$help);
GetOptions (
    "log"           => \$log,
    "output-dir=s"  => \$outdir,
    "help"          => \$help
);

my $usage  = q(
Usage: perl coverage_to_topoview.pl [-o output_dir] [-h] [-l] file1.wig.gz file2.wig.gz ...
    -o output directory (default 'topoview')
    -l use log2 for read counts (recommended)
    -h this help message
);

die $usage if !@ARGV || $help;

$outdir ||= 'topoview';

my (%bdb_hash,$max_signal,@SubsetNames);

system "mkdir -p $outdir";

my $outfile = "$outdir/data.cat";
unlink $outfile if -e $outfile;

open( COV, '>' . $outfile ) || die "Cannot open $outfile!";
my $hashfile = "$outdir/index.bdbhash";
unlink $hashfile if -e $hashfile;

%bdb_hash = ();
tie(%bdb_hash, "BerkeleyDB::Hash",
    -Filename => $hashfile,
    -Flags    => DB_CREATE);

$max_signal  = 0;
@SubsetNames = ();

for my $file ( sort @ARGV ) {
    next unless is_bed4($file);
    indexCoverageFile($file);
}

$bdb_hash{'subsets'} = join( "\t", @SubsetNames );
$bdb_hash{'max_signal'} = $max_signal;

my @all_keys = keys %bdb_hash;

for my $kkey ( sort @all_keys ) {
    print "\t$kkey => " . $bdb_hash{$kkey} . "\n";
}

if ( $max_signal > 10000 ) {
    warn "WARNING: max_signal=$max_signal - TOO HIGH.  Consider log2?\n";
}

untie %bdb_hash;
chmod( 0666, $hashfile );     # ! sometimes very important

close COV;


sub is_bed4 {
    my $file = shift;
    my $cat  = $file =~ /gz$/ ? 'zcat' 
             : $file =~ /bz2/ ? 'bzcat'
             : 'cat';
    open WIG, "$cat $file |" or die "could not open $file: $!";
    
    my $idx;
    while (<WIG>) {
	next if /^track/;
	last if ++$idx > 9;

	my ($ref,$start,$end,$score,@other) = split "\t";
	if (@other > 0) {
	    die "Extra fields, I was expecting BED4";
	}
	unless ($ref && $start && $end && $score) {
	    die "Not enough fields, I was expecting BED4";
	}
	unless (is_numeric($start) && is_numeric($end)) {
	    die "start ($start) and end ($end) are supposed to be numbers";
	}
	unless (is_numeric($score)) {
	    die "score ($score) is not numeric"
	}
    }
    
    return 1;
}

sub is_numeric {
    no warnings;
    return defined eval { $_[ 0] == 0 };
}

sub indexCoverageFile {
    my $file = shift;
    my $zcat = get_zcat($file);

    open( INF, "$zcat $file |" ) || die "Can't open $file";
    
    chomp(my $SubsetName = `basename $file .wig.gz`);

    print STDERR "Subset=$SubsetName\n";

    push( @SubsetNames, $SubsetName );

    my $old_ref = "";
    my @offsets    = ();

    my $step      = 1000; 
    my $coordstep = 5000;
    my $counter   = 0;
    my $offset    = tell(COV);

    $bdb_hash{$SubsetName} = $offset;    # record offset where new subset data starts

    my $old_signal  = 0;
    my $old_coord   = -200000;
    my $start       = 0;
    my $lastRecordedCoord = -200000;

    my @signals;
    while (<INF>) {
        $offset = tell(COV);

	next if /^$/ || /^\#/;
	my ($ref,$start,$end,$signal) = split;

	$signal = log($signal)/log(2) if $log;

	$start += 1; # zero-based, half-open coords in BED
	
	$signal = 0 if $signal < 0;

	# New chromosome
	if ( $ref ne $old_ref ) {
	    print STDERR "chromosome  = $ref\n";
	    dumpOffsets( $start, $SubsetName . ':' . $old_ref, @offsets )
		unless $old_ref eq "";    # previous subset:arm
	    $old_ref = $ref;
	    print COV "# subset=$SubsetName chromosome=$old_ref\n";
	    $offset = tell(COV);
	    $bdb_hash{ $SubsetName . ':' . $old_ref } =
		$offset;    # record offset where new subset:arm data starts
	    @offsets = ("-200000\t$offset");
	    print COV "-200000\t0\n";    # insert one fictive zero read
	    $offset = tell(COV);
	    print COV "0\t0\n";    # insert one more fictive zero read
	    push( @offsets, "0\t$offset" );
	    $counter           = 0;
	    $old_signal        = 0;
	    $old_coord         = 0;
	    $lastRecordedCoord = 0;
	}

    
	# fill in holes in coverage with 0
	if ($start > $old_coord+1 && $old_signal > 0) {
	    print COV join("\t",++$old_coord,0), "\n";
	    $old_coord++;
	    $counter++;
	    $offset = tell(COV);
	    $old_signal = 0;
	} 
	
        if ( $signal == $old_signal) {
	    $old_coord = $end;
	    next;
	}
	
	$max_signal = $signal if $max_signal < $signal;
	if (   $counter++ > $step
	       || $start - $lastRecordedCoord > $coordstep )
	{
	    push( @offsets, "$start\t$offset" );
	    $counter           = 0;
	    $lastRecordedCoord = $start;
	}

	$old_coord  = $end;
	$old_signal = $signal;
    
	print COV join("\t",$start,$signal), "\n";
    }

    # don't forget to dump offsets data on file end..
    dumpOffsets( $start,$SubsetName . ':' . $old_ref, @offsets )
      unless $old_ref eq "";    # previous subset:arm
    close(INF);
    return;
}

sub dumpOffsets {
    my ( $start, $key, @offsetlines ) = @_;
    print COV "# offsets for $key\n";
    my $offset     = tell(COV);
    my $prevoffset = $offset;
    $bdb_hash{ $key . ':offsets' } = $offset
      ; # record offset where offsets VALUES for subset:arm data start (skip header)
    my $oldbigstep = 0;
    foreach my $str (@offsetlines) {
        print COV $str . "\n";
        my ( $start, $floffset ) = split( /[ \t]+/, $str );

        # following wasn't working properly..
        my $newbigstep = int( $start / 1000000.0 );
        if ( $newbigstep > $oldbigstep ) {
            $bdb_hash{ $key . ':offsets:' . $newbigstep } =
              $prevoffset;    # one before is the right start
            $oldbigstep = $newbigstep;
        }
        $prevoffset = $offset;
        $offset     = tell(COV);
    }
    return;
}

#***********************************************************
#
#***********************************************************

sub get_zcat {
    my $fullfile = shift;
    if ( $fullfile =~ /\.gz$/i ) {
        my $zcat = `which zcat`;
        if ( $? != 0 ) { $zcat = `which gzcat`; }
        chomp($zcat);
        return ($zcat);
    }
    elsif ( $fullfile =~ /\.bz2$/i ) { return ('bzcat'); }
    return ('/bin/cat');
}

#*******
