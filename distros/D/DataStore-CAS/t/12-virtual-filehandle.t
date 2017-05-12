#! /usr/bin/env perl -T
use strict;
use warnings;
use Try::Tiny;

use Test::More skip_all => 'Apply these tests to the splitting CAS module\'s handle object once written';
use Data::Dumper;

use_ok('File::CAS::Store::Virtual') || BAIL_OUT;

$SIG{__WARN__}= sub { carp(join('',@_)) };

my $sto= new_ok('File::CAS::Store::Virtual', [], 'virtual store');

my @data= (
	'',
	do { my $x= '0123456789'; while (length $x < 80) { $x .= $x; } $x; },
	do { my $x= '0123456789'; while (length $x < 1000000) { $x .= $x; } $x; },
	"abcdef\nghijkl\n\n",
);

my @hashes= ( map { $sto->put($_) } @data );

my $f= $sto->get($hashes[1]);

ok( defined($f), 'found hash 1' );
is( $f->size, length($data[1]), 'correct length' );
is( $f->hash, $hashes[1] );
is( $f->store, $sto );

# create the filehandle
my $vfh;
isa_ok(($vfh= $f->newHandle), 'GLOB', 'file->newHandle' );

# basic read
my $buf;
is( sysread($vfh, $buf, 10), 10, 'read 10 bytes' );
is( length($buf), 10, 'got 10 bytes' );
is( tell($vfh), 10, 'at pos 10' );

# correct EOF conditions
my ($ttl, $x)= (0,1);
$buf= undef;
while ($x) { $x= sysread($vfh, $buf, 99999, length($buf)); $ttl+= $x if $x; }
is( $ttl, length($data[1])-10, 'read remaining bytes' );
is( length($buf), length($data[1])-10, 'got remaining bytes' );
is( tell($vfh), length($data[1]), 'at end' );
ok( eof($vfh), 'eof is true' );

# readline in "slurp" context
is( seek($vfh, 0, 0), '0 but true', 'rewind' );
{ local $/= undef; $buf= <$vfh>; }
is( $buf, $data[1], 'slurp' );

# readline in scalar context
$vfh= $sto->get($hashes[3])->newHandle;
is(<$vfh>, "abcdef\n", 'readline' );

# readline on a really long string with no newlines
$vfh= $sto->get($hashes[2])->newHandle;
is(<$vfh>, $data[2], 'readline (long)' );

#readline in list context
$vfh= $sto->get($hashes[3])->newHandle;
is_deeply( [ <$vfh> ], [ "abcdef\n", "ghijkl\n", "\n" ], 'readline (array ctx)' );

done_testing;