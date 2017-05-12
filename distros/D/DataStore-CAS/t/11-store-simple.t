#! /usr/bin/env perl -T
use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Path::Class;
use Data::Dumper;
use File::stat;

sub slurp {
	my $f= shift;
	if (ref $f ne 'GLOB') {
		open(my $handle, '<:raw', $f) or do { diag "open($_[0]): $!"; return undef; };
		$f= $handle;
	}
	local $/= undef;
	my $x= <$f>;
	return $x;
}
sub dies(&$) {
	my ($code, $comment)= @_;
	try {
		&$code;
		fail "Failed to die during '$comment'";
	}
	catch {
		ok "died - $comment";
	};
}
sub dies_like(&$$) {
	my ($code, $pattern, $comment)= @_;
	try {
		&$code;
		fail "Failed to die during '$comment'";
	}
	catch {
		like($_, $pattern, $comment);
	};
}

use_ok('DataStore::CAS::Simple') || BAIL_OUT;

chdir('t') if -d 't';
-d 'cas_tmp' or BAIL_OUT('missing cas_tmp directory for testing file-based cas');

my $casdir= dir('cas_tmp','cas_store_simple');
my $casdir2= dir('cas_tmp','cas_store_simple2');
my $casdir3= dir('cas_tmp','cas_store_simple3');

subtest test_constructor => sub {
	$casdir->rmtree(0, 0);
	mkdir($casdir) or die "$!";

	my $cas= new_ok('DataStore::CAS::Simple', [ path => $casdir, create => 1, digest => 'SHA-1', fanout => [2] ]);

	my $nullfile= $casdir->file('da','39a3ee5e6b4b0d3255bfef95601890afd80709');
	is( slurp($nullfile), '', 'null hash exists and is empty' );
	like( slurp($casdir->file('conf','fanout')), qr/^2\r?\n$/, 'fanout file correctly written' );
	like( slurp($casdir->file('conf','digest')), qr/^SHA-1\r?\n$/, 'digest file correctly written' );

	unlink $nullfile or die "$!";
	dies_like { DataStore::CAS::Simple->new(path => $casdir) } qr/missing a required/, 'missing null file';

	IO::File->new($nullfile, "w")->print("\n");
	dies_like { DataStore::CAS::Simple->new(path => $casdir) } qr/missing a required/, 'invalid null file';

	unlink $nullfile;
	unlink $casdir->file('conf','VERSION') or die "$!";
	dies_like { DataStore::CAS::Simple->new(path => $casdir) } qr/valid CAS/, 'invalid CAS dir';
	dies_like { DataStore::CAS::Simple->new(path => $casdir, create => 1) } qr/not empty/, 'can\'t create if not empty';

	$casdir->rmtree(0, 0);
	mkdir($casdir) or die "$!";
	dies_like { DataStore::CAS::Simple->new(path => $casdir, create => 1, fanout => [6]) } qr/fanout/, 'fanout too wide';

	$casdir->rmtree(0, 0);
	mkdir($casdir) or die "$!";
	dies_like { DataStore::CAS::Simple->new(path => $casdir, create => 1, fanout => [1,1,1,1,1,1]) } qr/fanout/, 'fanout too wide';

	$cas= new_ok('DataStore::CAS::Simple', [ path => $casdir, create => 1, digest => 'SHA-1', fanout => [1,1,1,1,1] ], 'create with deep fanout');
	$cas= undef;
	$cas= new_ok('DataStore::CAS::Simple', [ path => $casdir ], 're-open');
	done_testing;
};

subtest test_get_put => sub {
	$casdir->rmtree(0, 0);
	mkdir($casdir) or die "$!";

	my $cas= new_ok('DataStore::CAS::Simple', [ path => $casdir, create => 1, digest => 'SHA-1' ]);

	isa_ok( (my $file= $cas->get( 'da39a3ee5e6b4b0d3255bfef95601890afd80709' )), 'DataStore::CAS::File', 'get null file' );
	is( $file->size, 0, 'size of null is 0' );

	is( $cas->get( '0000000000000000000' ), undef, 'non-existent hash' );

	is( $cas->put(''), 'da39a3ee5e6b4b0d3255bfef95601890afd80709', 'put empty file again' );

	my $str= 'String of Text';
	my $hash= '00de5a1e6cc9c22ce07401b63f7b422c999d66e6';
	is( $cas->put($str), $hash, 'put scalar' );
	is( $cas->get($hash)->size, length($str), 'file length matches' );
	is( slurp($cas->get($hash)->open), $str, 'scalar read back correctly' );
	
	my $handle;
	open($handle, "<", \$str) or die;
	is( $cas->put($handle), $hash, 'put handle' );
	
	my $tmpfile= file('cas_tmp','test_file_1');
	$handle= $tmpfile->open('w');
	print $handle $str
		or die;
	close $handle;
	is( $cas->put($tmpfile), $hash, 'put Class::Path::File' );
	
	is( $cas->put_file("$tmpfile"), $hash, 'put_file(filename)' );
	
	is( $cas->put($cas->get($hash)), $hash, 'put DataStore::CAS::File' );
	
	done_testing;
};

subtest test_hardlink_optimization => sub {
	$casdir->rmtree(0, 0);
	$casdir2->rmtree(0, 0);
	$casdir3->rmtree(0, 0);
	mkdir($casdir) or die "$!";
	mkdir($casdir2) or die "$!";
	mkdir($casdir3) or die "$!";

	my $cas1= new_ok('DataStore::CAS::Simple', [ path => $casdir,  create => 1, digest => 'SHA-1' ]);
	my $cas2= new_ok('DataStore::CAS::Simple', [ path => $casdir2, create => 1, digest => 'SHA-1' ]);
	my $cas3= new_ok('DataStore::CAS::Simple', [ path => $casdir3, create => 1, digest => 'SHA-256' ]);

	my $str= 'Testing Testing Testing';
	my $hash1= '36803d17c40ace10c936ab493d7a957c60bdce4a';
	my $hash256= 'e6ec36e4c3abf21935f8555c5f2c9ce755d67858291408ec02328140ae1ac8b0';

	is( $cas1->put($str, { reuse_hash => 1, hardlink => 1 }), $hash1, 'correct sha-1 hash' );
	my $file= $cas1->get($hash1) or die;
	is( $file->local_file, $cas1->_path_for_hash($hash1), 'path is what we expected' );

	is( $cas2->put($file, { reuse_hash => 1, hardlink => 1 }), $hash1, 'correct sha-1 when migrated' );
	my $file2= $cas2->get($hash1) or die;
	is( $file2->local_file, $cas2->_path_for_hash($hash1) );

	my $stat1= stat( $file->local_file ) or die "stat: $!";
	my $stat2= stat( $file2->local_file ) or die "stat: $!";
	is( $stat1->dev.','.$stat1->ino, $stat2->dev.','.$stat2->ino, 'inodes match - hardlink succeeded' );

	# make sure it doesn't get the same hash when copied to a cas with different digest
	is( $cas3->put($file, { reuse_hash => 1, hardlink => 1 }), $hash256, 'correct sha-256 hash from sha-1 file' );
	my $file3= $cas3->get($hash256);
	my $stat3= stat( $file3->local_file ) or die "stat: $!";
	is( $stat3->dev.','.$stat3->ino, $stat1->dev.','.$stat1->ino, 'inodes match - hardlink succeeded' );

	is( $cas1->put($file3, { reuse_hash => 1, hardlink => 1 }), $hash1, 'correct sha-1 hash from sha-2 file' );

	done_testing;
};

subtest test_iterator => sub {
	$casdir->rmtree(0, 0);
	mkdir($casdir) or die "$!";
	
	my $cas1= new_ok('DataStore::CAS::Simple', [ path => $casdir,  create => 1, digest => 'SHA-1' ]);
	isa_ok( my $i= $cas1->iterator, 'CODE' );
	is( $i->(), $cas1->hash_of_null, 'one element' );
	is( $i->(), undef, 'end of list' );

	my $hashes= {
		'String of Text' => '00de5a1e6cc9c22ce07401b63f7b422c999d66e6',
		'Testing'        => '0820b32b206b7352858e8903a838ed14319acdfd',
		'Something'      => 'b74dd130fe4e46c52aeb39878480cfe50324dab9',
		'Something1'     => 'ee6c06282ef9600df99eee106fb770b8c3dd1ff1',
		'Something2'     => 'ca2a1a4e26b79949243d23e526936bccca0493ce',
	};
	is( $cas1->put($_), $hashes->{$_} )
		for keys %$hashes;
	my @expected= sort (values %$hashes, $cas1->hash_of_null);
	$i= $cas1->iterator;
	my @actual;
	while (defined (my $x= $i->())) { push @actual, $x; }
	is_deeply( \@actual, \@expected, 'iterated correctly' );
	
	ok( $cas1->delete(delete $hashes->{'Testing'}), 'deleted item' );
	@expected= sort (values %$hashes, $cas1->hash_of_null);
	$i= $cas1->iterator;
	@actual= ();
	while (defined (my $x= $i->())) { push @actual, $x; }
	is_deeply( \@actual, \@expected, 'iterated correctly' );
	
	done_testing;
};

done_testing;
