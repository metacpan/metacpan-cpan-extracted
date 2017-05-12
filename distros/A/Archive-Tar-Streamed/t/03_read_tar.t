# -*- perl -*-

# t/03_read_tar.t - read a tar archive

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
		plan tests => 9;
	}

	#01
	use_ok( 'Archive::Tar::Streamed' );
}

my $fh;
open $fh,'<','test/arch1.tar' or die "Couldn't open archive";
binmode $fh;

my $tar = Archive::Tar::Streamed->new($fh);

#02
isa_ok($tar,'Archive::Tar::Streamed','Return from new');

my $fil = $tar->next;

#03
isa_ok($fil,'Archive::Tar::File','Return from next');

#04
is($fil->name,'t/01_stream.t','Second file name OK');

$fil = $tar->next;

#05
isa_ok($fil,'Archive::Tar::File','Return from next');

#06
is($fil->name,'t/02_check_tar.t','Second file name OK');

$fil = $tar->next;

#07
isa_ok($fil,'Archive::Tar::File','Return from next');

#08
is($fil->name,'t/03_read_tar.t','Second file name OK');

#09
ok(!$tar->next, 'EOF detected');
