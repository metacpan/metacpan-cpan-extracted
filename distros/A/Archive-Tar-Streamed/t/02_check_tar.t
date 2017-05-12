# -*- perl -*-

# t/02_check_tar.t - check that tar can read the output
# t/01_stream.t must be run first

use strict;
use Test::More;

my $tprog;

BEGIN { 
	open TPROG,'<','t/tarprog' or die "Failed to get tarprog";
	$tprog = <TPROG>;
	close TPROG;
	chomp $tprog;

	if ($tprog eq 'none') { 
		plan skip_all => "tar not available";
	}
	else {
		plan tests => 4;
	}

	#01
	use_ok( 'Archive::Tar::Streamed' );
}

my $tres = `$tprog tf test/stream.tar`;

#02
is($tres,<<END,"tar can list the files");
lib/Archive/Tar/Streamed.pm
t/01_stream.t
t/02_check_tar.t
t/03_read_tar.t
END

chdir 'test';

`$tprog xf stream.tar`;

#03
ok(-e 't',"t directory created");

#04
ok(-e 'lib','lib directory created');
