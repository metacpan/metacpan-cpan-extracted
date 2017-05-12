use Test::More tests => 2;

use strict;
use warnings;
use IPC::Open3;

BEGIN{  use_ok 'Alien::pdf2json' }

my $p = Alien::pdf2json->new;

my($wtr, $rdr, $err);
use Symbol 'gensym'; $err = gensym;
my $pid = open3($wtr, $rdr, $err,
	$p->pdf2json_path, "-help" );
# WARN: this could block --- I should use select() or IPC::Run3, but this may work for now
my $result = join "", <$err>;
waitpid( $pid, 0 );

like($result, qr/pdf2json version/, 'can run pdf2json');


done_testing;
