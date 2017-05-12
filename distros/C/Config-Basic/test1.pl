#!/usr/bin/perl

use strict;

use Config::Basic;
use Data::Dumper;
use Config::General;

print "#" x 30;
print "\n First example\n";
print "#" x 30;
print "\n";

my $data_file = "test1.cfg";

# Instantiate a new Config::Basic object
# the input file is "test1.cfg"
# we expect 3 sections tag
# and each trailling part of the section matching one of the regular "traillers" REGEX is skipped
# this allow to skip trailling blank line or comment at the end,
# but keep blank line and comment inside the section

my $a = Config::Basic->new(
    -file     => $data_file,
    -sections => [ 'global', 'server', 'defaults', 'special' ],
    -traillers => [ '^#' ],
    -headers => [  '^#' ],
);

print "\nPrint the 'sections' set\n";
print Dumper( $a->sections );

print "\nPrint the parsed data\n";
print "look at the value start_headers and end_traillers\n";
print "for the section 'special' and the first section 'server'\n";
my $res = $a->parse();
print Dumper( $res );

my $se = $a->get_section( $res->{ server }[1] );
print "ref=".(ref $se )."\n";

print "\nPrint Config::General result for the second 'server' section\n";
my @h = @{$se};


my %re = Config::General::ParseConfig( -String =>   (join "\n", @h)  );

print Dumper( \%re );
print "\nSet a new sections set and print it\n";
print Dumper( $a->sections( [ 'global', 'server', 'special', 'defaults' ] ) );


print "\nParse the data and print\n";
$res = $a->parse();
print Dumper( $res );


print "\nExtract the second firts 'server'\n";
$se = $a->get_section( $res->{ server }[0] );
print Dumper( $se );


print "\nPrint the 'traillers' set\n";
$se = $a->traillers( );
print Dumper( $se );

print "\nPrint the 'headers' set\n";
$se = $a->headers( );
print Dumper( $se );


print "\n";
print "#" x 30;
print "\n Second example\n";
print "#" x 30;
print "\n";

use IO::All;


my @data = io( $data_file )->chomp->slurp;
my $b    = Config::Basic->new(
    -file     => \@data,
    -sections => [ 'global', 'server', 'defaults' ],
    -traillers => [ '^\s+$' ,'^#' ],
);

my $res = $b->parse();

# Get the second 'server' section and use start , end and real data
my ( $start, $end, $sect ) = $b->get_section( $res->{ server }[1] );

# set the line counter to the start of the section
my $line_nbr = $start;
foreach my $line ( @{ $sect } )
{
# increment the line counter
    $line_nbr++;
    
# made some test onthe line data
    if ( $line =~ /type/ )
    {
        print "$line_nbr $line\n";
	
# directly modify the line in the real data
        $data[ $line_nbr -1 ] =~ s/udp/UDP/;
    }
}

# show the result (or save, or  ...)
print Dumper( \@data );
