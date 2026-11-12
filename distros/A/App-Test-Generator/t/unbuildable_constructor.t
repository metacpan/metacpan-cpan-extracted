#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/unbuildable_constructor.t - a class whose constructor refuses to run
# gives the fuzz harness no $self, so extract-schemas must say so with
# new: ~ instead of new: {}.
#
# Without that, every generated harness for the class fails in setup and
# all-fuzz.t reports each routine as FAILED rather than skipping it.  The
# fixtures are written here, so changes to the extractor cannot silently
# stop emitting the signal.
# ======================================================================

use Test::Most;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;
use YAML::XS qw(LoadFile);

my $lib = abs_path(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
my $script = abs_path(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'extract-schemas'));

ok(-f $script, 'extract-schemas is where the test expects it') or BAIL_OUT('cannot find extract-schemas');

my $dir = File::Temp::tempdir(CLEANUP => 1);
my %module_file;

sub _write_module
{
	my ($name, $source) = @_;

	my @parts = split(/::/, $name);
	my $file = pop(@parts);
	my $path = File::Spec->catfile($dir, 'lib', @parts, "$file.pm");
	my $parent = File::Spec->catdir($dir, 'lib', @parts);
	make_path($parent);

	open(my $fh, '>', $path) or die "cannot write $path: $!";
	print {$fh} $source;
	close($fh) or die "cannot close $path: $!";

	$module_file{$name} = $path;
}

# An abstract base class: the constructor croaks when asked to build the
# package itself.
_write_module('Unbuildable::Abstract', <<'MODULE');
package Unbuildable::Abstract;
use strict;
use warnings;
use Carp qw(croak);

sub new
{
	my ($class, %args) = @_;

	croak("$class: abstract class") if($class eq __PACKAGE__);

	return bless { %args }, $class;
}

sub count
{
	my ($self) = @_;

	return scalar(keys %{$self});
}

1;
MODULE

# A constructor that croaks over an argument the extractor cannot supply.
_write_module('Unbuildable::NeedsKey', <<'MODULE');
package Unbuildable::NeedsKey;
use strict;
use warnings;
use Carp qw(croak);

sub new
{
	my ($class, %args) = @_;

	my $db = $args{'_db'}
		or croak('Unbuildable::NeedsKey: _db is required');

	return bless { _db => $db }, $class;
}

sub count
{
	my ($self) = @_;

	return 1;
}

1;
MODULE

# A control: an ordinary class, which must keep new: {} so its routines are
# still fuzzed.
_write_module('Unbuildable::Fine', <<'MODULE');
package Unbuildable::Fine;
use strict;
use warnings;

sub new
{
	my ($class) = @_;

	return bless {}, $class;
}

sub count
{
	my ($self) = @_;

	return 0;
}

1;
MODULE

sub _extract
{
	my ($module) = @_;

	my $out = File::Spec->catdir($dir, 'schemas', $module);
	make_path($out);

	my ($stdout, $stderr) = ('', '');
	run3(
		[$^X, "-I$lib", $script, '--output-dir', $out, $module_file{$module}],
		\undef, \$stdout, \$stderr
	);
	is($? >> 8, 0, "$module: extract-schemas succeeded")
		or diag("stdout:\n$stdout\nstderr:\n$stderr");

	my %schema;
	for my $yml (glob("$out/*.yml")) {
		my ($name) = $yml =~ m{/([^/]+)\.yml$};
		$schema{$name} = eval { (LoadFile($yml))[0] };
		die "cannot load $yml: $@" unless $schema{$name};
	}

	return \%schema;
}

subtest 'an abstract base class yields new: ~' => sub {
	my $schema = _extract('Unbuildable::Abstract');
	my $count = $schema->{count};

	ok(exists($count->{new}), 'the instance schema carries a new: key');
	ok(!defined($count->{new}), 'the instance schema says the object cannot be built');

	is($schema->{new}{output}{_STATUS}, 'DIES', 'new() itself is expected to die');
};

subtest 'a constructor needing an undeclared argument yields new: ~' => sub {
	my $schema = _extract('Unbuildable::NeedsKey');
	my $count = $schema->{count};

	ok(exists($count->{new}), 'the instance schema carries a new: key');
	ok(!defined($count->{new}), 'the instance schema says the object cannot be built');
	is($schema->{new}{output}{_STATUS}, 'DIES', 'new() itself is expected to die');
};

subtest 'a buildable class keeps new: {}' => sub {
	my $schema = _extract('Unbuildable::Fine');
	my $count = $schema->{count};

	ok(exists($count->{new}), 'the instance schema carries a new: key');
	ok(defined($count->{new}), 'the object is still built for the harness');
};

done_testing();
