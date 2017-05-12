#!/usr/bin/env perl

use strict;
use warnings;

use Bio::HTS::Tabix;
use Data::Dumper;
use feature qw(say);
use Try::Tiny;
use Benchmark qw/cmpthese timethese/;

use Sapientia::Util::Bed;

die "File " . $ARGV[0] . " doesn't exist" unless -e $ARGV[0];

my @chroms = (1..22, 'X', 'Y', 'M');
my $num_lookups = 20;


my $t = Bio::HTS::Tabix->new( filename => $ARGV[0] );
sub tabix_perl {
#    for my $i ( 0 .. $num_lookups ) {
        #number between 100000 and 4000000
        my $start = int(rand(4000000)) + 100000;
        my $end = $start + 5;
        my $chrom = $chroms[int(rand(scalar @chroms))];
        
        #say "Fetching region $chrom:$start-$end... ";
        #my $iter = $t->query("$chrom:$start-$end");
        get_region($chrom, $start, $end);
        #say "Found " . scalar( get_region($chrom, $start, $end) ) . " entries";
        #say "\t$_" for get_region($chrom, $start, $end);
#    }
}

sub get_region {
    my ( $chrom, $start, $end ) = @_;

    my $iter = $t->query("$chrom:$start-$end");

    my @rows;
    try {
        while ( my $line = $iter->next ) {
            push @rows, _next($line);
        }
    }
    catch {
        say "No reads for region, probably";  
    };

    return @rows;
}

my $b = Sapientia::Util::Bed->new( bed_file => $ARGV[0], silent => 1 );
sub tabix_cmd {

#    for my $i ( 0 .. $num_lookups ) {
        #number between 100000 and 4000000
        my $start = int(rand(4000000)) + 100000;
        my $end = $start + 5;
        my $chrom = $chroms[int(rand(scalar @chroms))];
        
        #print "Fetching region $chrom:$start-$end... ";
        #say "Found " . scalar($b->get_region("$chrom:$start-$end"));
        $b->get_region("$chrom:$start-$end");
#    }
}

#rip from Util::Bed for fair comparison
sub _next {
    my ( $line ) = @_;

    my $parse_header = 0;

    #if we don't get a line just take the next one from the file
    if ( ! defined $line ) {
        die "where";
        return unless defined $line; #EOF
    }
    else {
        #strip off \n automatically
        chomp $line;
    }

    #see if we need to parse the header
    if ( $parse_header ) {
        die "haha";
    }

    #skip all comment lines
    if ( $line =~ /^#/ ) {
        die "no";
        #we reached EOF before finding another non comment line
        return unless $line;
    }

    #set the limit to -1 so it will include an empty start/end field
    my @row = split /\t/, $line, -1;
    #die "Found " . scalar( @row ) . " entries on bed line, need at least " . $self->num_header_fields
    #    if @row < $self->num_header_fields;

    #if there are more data fields than header fields, extract the excess
    #my @remaining = splice @row, scalar $self->num_header_fields;

    my %data;
    #map all fields in the header array to our data
    @data{ qw(whatever shit was there) } = @row;

    #now store the excess in a single field
    $data{extra_fields} = [];

    #its not really a bed file but a tsv dump of vcf, let's add a key field
    if ( exists $data{REF} and exists $data{ALT} ) {
        $data{key} = join ":", @data{qw(chr start REF ALT)};
    }

    return \%data;
}

cmpthese(100, { perl => \&tabix_perl, cmd => \&tabix_cmd });
