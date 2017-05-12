#!/usr/bin/perl -w
# Basic conflict case.

use Algorithm::Diff  qw{diff};
use Test::Simple tests => 1;
use Algorithm::Diff::Apply qw{apply_diffs};

$orig =             [qw{a b c d e f     g h i}] ;
$dif1 = diff($orig, [qw{a b c d e f x y g h i}] );
$dif2 = diff($orig, [qw{a b c d e m n o p q i}] );
$expc = join(':',    qw{a b c d e
		        d1>>      f x y g h
                        d2>>      m n o p q
                        <<done              i}  );
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
