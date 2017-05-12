#!/usr/bin/perl -w
# Conflict regression test. Ensure that early conflicts that lose more
# lines after resolution than they spanned in the first place don't
# screw up the application of later hunks or (worse) start conflicting
# with them.

use Algorithm::Diff  qw{diff};
use Test::Simple tests => 1;
use Algorithm::Diff::Apply qw{apply_diffs};

$orig =             [qw{1 2 3 4 a b c d e f         }] ;
$dif1 = diff($orig, [qw{                  f z1 z2   }] );
$dif2 = diff($orig, [qw{                e f         }] );
$expc = join(':',  qw{d1>> d2>> e <<done f z1 z2 });
$resu = join(':', apply_diffs($orig, { resolver => \&resolver },
			      d1 => $dif1,
			      d2 => $dif2) );
ok($resu eq $expc)
	or print STDERR "\n   GOT: $resu\nWANTED: $expc\n\n";

sub resolver
{
	my %opt = @_;
	my %alt = %{$opt{alt_txts}};
	my @ret;
	foreach my $id (sort keys %alt)
	{
		push @ret, "${id}>>";
		push @ret, @{$alt{$id}};
	}
	push @ret, "<<done";
	return @ret;
	
}
