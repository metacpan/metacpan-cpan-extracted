#! perl
use strict;
use warnings;
use diagnostics;

use Test::More tests => 20;
use File::Temp qw(tempfile :seekable);
use Algorithm::RabinKarp::Util qw( filter_regexp stream_fh );

use constant STR => 'Unbroken';

my ($fh, $test) =  tempfile();
print $fh STR;

{
	seek( $fh, 0, 0 );
	#open my $fh, '<', 'util.t' or die "Can't open my own test file.";
	my $gen = stream_fh($fh);
	is ref( $gen ), 'CODE', "We got back a generator";

	my $c = 0;
	while (my ($v, $p) = $gen->()) {
		is $p, $c, "Right position";	
		is chr($v), substr(STR, $c, 1), 'Right character';
		$c++
	}
}

{
	#open my $fh, '<', 'util.t' or die "Oh well: $!";
	seek( $fh, 0, 0 );
	ok my $gen = filter_regexp( qr{[Un]}, stream_fh($fh) ), "Created filter";

	my ($s, @pos);
	while (my ($v, $p) = $gen->()) {
		$s .= chr($v);
		push @pos, $p;
	}
	is $s, 'broke', "String has the characters U and n filtered.";
	is_deeply \@pos, [ 2, 3, 4, 5 , 6 ], 'All character positions are correct';
	close $fh;
}
