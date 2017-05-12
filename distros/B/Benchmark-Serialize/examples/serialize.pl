#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Benchmark::Serialize qw( cmpthese );

use Benchmark::Serialize::Library::ProtocolBuffers;
use Benchmark::Serialize::Library::ProtocolBuffers::XS;
use Benchmark::Serialize::Library::Data::Serializer;

my @benchmark          = ();      # package names of benchmarks to run
my $iterations         = -1;      # integer
my $structure          = {
    array  => [ 'a' .. 'j' ],
    hash   => { 'a' .. 'z' },
    string => 'x' x 200
};

my $protocolbuffers; # Can't process inline as we might need the structure

Getopt::Long::Configure( 'bundling' );
Getopt::Long::GetOptions(
    'b|benchmark=s@' => \@benchmark,
    'deflate!'       => \$Benchmark::Serialize::benchmark_deflate,
    'inflate!'       => \$Benchmark::Serialize::benchmark_inflate,
    'roundtrip!'     => \$Benchmark::Serialize::benchmark_roundtrip,
    'i|iterations=i' => \$iterations,
    'o|output=s'     => \$Benchmark::Serialize::output,
    'v|verbose!'     => \$Benchmark::Serialize::verbose,
    's|structure=s'  => sub {
        die "Structure option requires YAML.\n"
        unless YAML->require;

        $structure = YAML::LoadFile( $_[1] );
    },
    'ds|data-serializer=s'  => sub { Benchmark::Serialize::Library::Data::Serializer->register($_[1]) }, 
    'pbx=s'                 => sub { Benchmark::Serialize::Library::ProtocolBuffers::XS->register($_[1]) }, 
    'pb|protocol-buffers:s' => \$protocolbuffers,
    'e|eval=s'       => sub {
        $structure = eval $_[1];

        die unless defined $structure;
    }
) or exit 1;

if (defined $protocolbuffers) {
    Benchmark::Serialize::Library::ProtocolBuffers->register( ProtocolBuffers => ($protocolbuffers ? $protocolbuffers : $structure) );
}

@benchmark = ("all") unless @benchmark;

cmpthese($iterations, $structure, @benchmark);

