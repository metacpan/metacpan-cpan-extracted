use strict;
use warnings;
use Test::Most;
use DB::Berkeley qw(DB_RDONLY);

my $file = 't/readonly.db';
unlink $file if -e $file;

# Create and populate DB
{
	my $db = DB::Berkeley->new($file, 0, 0600);
	$db->put('key1', 'value1');
	$db->put('key2', 'value2');
	$db->sync();
	undef $db;
}

# Open in read-only mode
my $ro = DB::Berkeley->new($file, DB_RDONLY, 0600);

# Sanity check: read access works
is($ro->get('key1'), 'value1', 'Can read key1 in read-only mode');
ok($ro->exists('key2'), 'Can check existence in read-only mode');

# Assert that write methods croak
my @write_methods = (
	[ put   => sub { $ro->put('key3', 'value3') } ],
	[ store => sub { $ro->store('key3', 'value3') } ],
	[ delete => sub { $ro->delete('key2') } ],
	[ sync  => sub { $ro->sync() } ],
);

foreach my $test (@write_methods) {
	my ($name, $code) = @$test;
	throws_ok(\&{$code}, qr/(permission|read-only|EINVAL|Invalid|EPERM)/i, "$name() in read-only mode croaks with permission error");
}

done_testing();

END {
	unlink $file if -e $file;
}
