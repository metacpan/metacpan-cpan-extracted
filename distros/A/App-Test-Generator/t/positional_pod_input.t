#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/positional_pod_input.t - a POD =head4 input block with one entry may
# be describing the first positional argument rather than a hash key.
#
# Lingua::EN::NameCase::nc documents its one argument as "name" but reads
# $_[0].  Reading the block as a hash made the harness call
# nc(name => $value), which nc rejects as two arguments, so every case in
# its harness failed.  Two or more documented names, or code that reads an
# argument hash, must still mean named arguments.
#
# The fixtures are written here so a change to the extractor cannot
# silently start calling positional routines by name again.
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
	my $parent = File::Spec->catdir($dir, 'lib', @parts);
	make_path($parent);
	my $path = File::Spec->catfile($parent, "$file.pm");

	open(my $fh, '>', $path) or die "cannot write $path: $!";
	print {$fh} $source;
	close($fh) or die "cannot close $path: $!";

	$module_file{$name} = $path;
}

# One documented name, read from $_[0]: the name labels position 0.
_write_module('PodInput::OneName', <<'MODULE');
package PodInput::OneName;
use strict;
use warnings;

=head2 ncish

=head3 API SPECIFICATION

=head4 input

	{
		name => {
			type     => 'string',
			optional => 1,
		},
	}

=head4 output

	{ type => 'string' }

=cut

sub ncish
{
	my $name = @_ ? $_[0] : $_;

	return defined($name) ? uc($name) : '';
}

1;
MODULE

# Two documented names with a hash of arguments: still named.
_write_module('PodInput::TwoNames', <<'MODULE');
package PodInput::TwoNames;
use strict;
use warnings;

=head2 join_two

=head3 API SPECIFICATION

=head4 input

	{
		left => { type => 'string' },
		right => { type => 'string' },
	}

=head4 output

	{ type => 'string' }

=cut

sub join_two
{
	my %args = @_;

	return ($args{'left'} // '') . ($args{'right'} // '');
}

1;
MODULE

# One documented name but the body reads an argument hash: still named.
_write_module('PodInput::OneNameHash', <<'MODULE');
package PodInput::OneNameHash;
use strict;
use warnings;

=head2 hush

=head3 API SPECIFICATION

=head4 input

	{
		text => { type => 'string' },
	}

=head4 output

	{ type => 'string' }

=cut

sub hush
{
	my $args = shift;

	return lc($args->{'text'} // '');
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

subtest 'a lone documented name is position 0' => sub {
	my $schema = _extract('PodInput::OneName');
	my $input = $schema->{ncish}{input};

	is(scalar(keys %{$input}), 1, 'one input parameter');
	is($input->{name}{position}, 0, 'the documented name is the first position');
	is($input->{name}{type}, 'string', 'its type is kept');
};

subtest 'two documented names stay named' => sub {
	my $schema = _extract('PodInput::TwoNames');
	my $input = $schema->{join_two}{input};

	is(scalar(keys %{$input}), 2, 'two input parameters');
	ok(!exists($input->{$_}{position}), "$_ has no position") for sort keys %{$input};
};

subtest 'a lone documented name with an argument hash stays named' => sub {
	my $schema = _extract('PodInput::OneNameHash');
	my $input = $schema->{hush}{input};

	ok(exists($input->{text}), 'the documented parameter is kept');
	ok(!exists($input->{text}{position}), 'it is not given a position');
};

done_testing();
