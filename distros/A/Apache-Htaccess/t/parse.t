BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::Htaccess;

$loaded = 1;
print "ok\n";

if(  eval { require Text::Diff } and eval { require File::Copy } )
	{
	my @test_files = qw( t/test.ht t/htaccess );
	
	File::Copy::copy( @test_files );
	
	eval {
		my $obj = Apache::Htaccess->new( $test_files[-1] );
		print $obj ? '' : 'not ', "ok\n";
		};
	
	my $diff = Text::Diff::diff( @test_files );
	print $diff ? 'not ' : '', "ok\n";
	if( $diff ) { print STDERR "\n$diff" };

	unlink $test_files[-1];
	}
else
	{
	my( $module ) = $@ =~ /Can't locate (.*?) in \@INC/;
	
	print STDERR "\nThe parsing test relies on Text::Diff and File::Copy\n" .
		"but could not find one of those modules and so did not run.\n";
	print "ok # Skip Could not load $1 (optional). Skipped test.\n";
	print "ok # Skip Could not load $1 (optional). Skipped test.\n";
	}
