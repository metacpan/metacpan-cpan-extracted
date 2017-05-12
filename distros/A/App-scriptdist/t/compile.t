use Test::More tests => 1;

my $file = "blib/script/scriptdist";

print "bail out! Script file is missing!" unless -e $file;

my $output = `$^X -c $file 2>&1`;

print "bail out! Script file is missing!" unless
	like( $output, qr/syntax OK$/, 'script compiles' );
