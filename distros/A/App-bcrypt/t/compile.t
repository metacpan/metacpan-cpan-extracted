use Test::More;

use IPC::Open3;
use Symbol;

my $pid = open3(
	Symbol::gensym(),
	my $output_fh,
	my $error_fh,
	$^X, '-c', 'blib/script/bcrypt'
	);

my $output = do { local $/; <$output_fh> };
like $output, qr/syntax ok/i;

waitpid( $pid, 0 );

done_testing();
