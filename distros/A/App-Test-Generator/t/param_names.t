#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/param_names.t - a reference must never become a parameter name.
#
# A hashref written where a key/value list was intended stringifies to
# "HASH(0x...)" and used to end up in a generated schema as a parameter
# that the routine can never read.  The guard drops such keys and reports
# them, instead of emitting them silently.
# ======================================================================

use Test::Most;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;
use YAML::XS qw(LoadFile);

use App::Test::Generator::SchemaExtractor;

my $lib = abs_path(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
my $script = abs_path(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'extract-schemas'));

ok(-f $script, 'extract-schemas is where the test expects it') or BAIL_OUT('cannot find extract-schemas');

subtest 'the guard drops reference keys and reports them' => sub {
	my $extractor = bless {}, 'App::Test::Generator::SchemaExtractor';

	my %params = (
		'HASH(0xdeadbeef)' => { type => 'string' },
		'ARRAY(0x1234)'    => { type => 'string' },
		'count'            => { type => 'integer' },
		'first-name'       => { type => 'string' },	# legal Params::Get key
	);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $dropped = $extractor->_sanitize_parameter_names(\%params, 'unit test');

	is($dropped, 2, 'two reference keys were dropped');
	is_deeply([ sort keys %params ], [ 'count', 'first-name' ], 'real parameter names survive');
	like("@warnings", qr/HASH\(0xdeadbeef\)/, 'the hash reference key is reported');
	like("@warnings", qr/ARRAY\(0x1234\)/, 'the array reference key is reported');
	like("@warnings", qr/from unit test/, 'the report says where the key came from');
};

subtest 'extraction never emits a reference as a parameter' => sub {
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $module_dir = File::Spec->catdir($dir, 'lib', 'Param');
	make_path($module_dir);

	my $module = 'Param::Names';
	my $module_file = File::Spec->catfile($module_dir, 'Names.pm');
	open(my $fh, '>', $module_file) or die "cannot write $module_file: $!";
	print {$fh} <<'MODULE';
package Param::Names;
use strict;
use warnings;

=head2 tidy

=head4 input

	{
		count => { type => 'integer', optional => 0, min => 1 },
		name  => { type => 'string', optional => 0 },
	}

=head4 output

	{ type => 'string' }

=cut

sub tidy
{
	my ($count, $name) = @_;

	return "$name x $count";
}

1;
MODULE
	close($fh) or die "cannot close $module_file: $!";

	my $out = File::Spec->catdir($dir, 'schemas');
	make_path($out);

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join(':', $lib, File::Spec->catdir($dir, 'lib'), $ENV{PERL5LIB} // '');
	run3([$^X, "-I$lib", $script, '--output-dir', $out, $module_file], \undef, \$stdout, \$stderr);

	is($? >> 8, 0, 'extract-schemas succeeded') or diag("stdout:\n$stdout\nstderr:\n$stderr");

	my $schema = LoadFile(File::Spec->catfile($out, 'tidy.yml'));
	is_deeply([ sort keys %{$schema->{input}} ], [ 'count', 'name' ], 'only real parameters are in the schema');

	my @refs = grep { /\A(?:HASH|ARRAY|SCALAR|CODE|GLOB|REF)\(0x[0-9a-fA-F]+\)\z/ } keys %{$schema->{input}};
	is_deeply(\@refs, [], 'no reference shaped parameter names');

	unlike($stderr, qr/not a parameter name/, 'a clean module produces no parameter-name warnings');
};

done_testing();
