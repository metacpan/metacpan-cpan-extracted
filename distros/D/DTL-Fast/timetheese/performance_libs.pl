#!/usr/bin/perl -I../lib/

use Benchmark qw(:all);
use DTL::Fast qw(get_template);
use Storable qw(freeze thaw);
use Compress::Zlib;

my @libs = qw(
    Data::Dumper
    DBI
    DTL::Fast
    Dotiac::DTL
    Cache::Memcached
    Cache::Memcached::Fast
    warnings
    strict
    Storable
    Digest::MD5
    Compress::Zlib
    Encode
    Carp
    URI::Escape
    URI::Escape::XS
    JSON::XS
);

my $cmd = {
    map{
        $_.(' 'x(25-length($_))) => sub { my $x=shift; sub{ system("perl -I../lib -e \"use $x;1;\"");} }->($_)
    } @libs
};


my $alluse = join '', map{ "use $_;" } @libs;
$cmd->{'All libs                 '} = sub { system("perl -I../lib -e \"$alluse;1;\"");};

timethese( 300, $cmd );
