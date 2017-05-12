#!/usr/bin/env perl

use Test::Simple tests => 45;

use Compress::SelfExtracting 'compress';
require Compress::SelfExtracting::Filter;

ok(1);

use strict;
$|=1;

my @tests = (
[<<'TEST'  => "Hello, compressed world\n"],
#!/usr/bin/perl
use strict;

print "Hello, compressed world\n";
TEST

[(<<'PAD' x 50).<<'CONTENT' => "Hello, compressed world\n"]
# This is a comment intended to take up space.  It turns out that
# larger scripts may be handled differently!  blah blah blah blah blah
# blah blah blah blah blah blah blah blah blah blah blah blah blah
# blah blah blah blah blah blah blah blah blah blah blah blah blah
# blah blah blah blah blah blah blah blah blah blah blah blah blah
# blah blah
PAD

#!/usr/bin/perl
use strict;

print "Hello, compressed world\n";
CONTENT

);

for (@tests) {
    my ($script, $out) = @$_;
    for my $type (qw/LZW LZSS LZ77 Huffman BWT/) {
	for my $uu (0, 1) {
   	    for my $sa (0, 1) {
		if ($type eq 'LZW') {
  		    for my $bits (12, 16) {
			test_it($script, $out,
				type => $type, uu => $uu, bits => $bits,
				standalone => $sa);
 		    }
		} elsif ($type eq 'BWT' && length $script > 4096) {
# 		    print STDERR "BWT too slow for ", length($script),
# 			" bytes\n";
		} else {
		    test_it($script, $out,
			    type => $type, uu => $uu, standalone => $sa);
		}
 	    }
	}
    }
}

sub test_it
{
    my ($test, $test_output, %args) = @_;
    my $tmpperl = "tmp.$$.pl";
    my $e = compress $test, %args;
    open O, ">$tmpperl" or die $!;
    print O $e;
    close O;
    my $res = `perl -Mblib "$tmpperl" 2> /dev/null`;
    ok($res eq $test_output);
    unlink $tmpperl;
}
