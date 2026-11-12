#!/usr/bin/env perl

use strict;
use warnings;

# Regression test for the object-state checks that App::Test::Generator writes
# into a harness for an accessor:
#
#   - a getter must not change the object it was handed
#     ("getter leaves its object unmodified"), and
#   - a getset must change no state but its own property
#     ("setter changes nothing but its property").
#
# When they work they are invisible: the snapshot is taken and compared on
# every call and passes silently, so a change to the generator can stop
# emitting them without breaking any other test.  This file asserts that the
# emitted code still carries them, that they still fire for a routine which
# misbehaves, and that they stay quiet for the memoising getter and lazy
# initialisation that real modules rely on.
#
# It is self-contained: the module under test and the schemas are written to a
# temporary directory, so it does not depend on any other module's quirks.

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use Readonly;
use Test::Most;

use App::Test::Generator;

Readonly my $GETTER_MESSAGE => 'getter leaves its object unmodified';
Readonly my $SETTER_MESSAGE => 'setter changes nothing but its property';

my $tmpdir     = tempdir(CLEANUP => 1);
my $lib_dir    = File::Spec->catdir($tmpdir, 'lib');
my $schema_dir = File::Spec->catdir($tmpdir, 'schema');
my $out_dir    = File::Spec->catdir($tmpdir, 'out');
make_path($lib_dir, $schema_dir, $out_dir, File::Spec->catdir($lib_dir, 'StateCheck'));

# ---------------------------------------------------------------
# The module under test.  Every routine here is deliberately tiny: the point
# is which of them must be reported, not what they compute.
# ---------------------------------------------------------------
my $module = <<'MODULE';
package StateCheck::Cfg;

use strict;
use warnings;

sub new
{
	my $class = shift;

	return bless {
		count => 0,
		value => 'initial',
		name  => 'kept',
		unset => undef,
	}, $class;
}

# A getter that only reads
sub pure
{
	my $self = shift;

	return $self->{count};
}

# A getter that caches what it computed in a key it did not have
sub memo
{
	my $self = shift;

	$self->{cached} //= 7;

	return $self->{cached};
}

# A getter that fills in a field it was handed as undef
sub fills_undef
{
	my $self = shift;

	$self->{unset} //= 7;

	return $self->{unset};
}

# A getter that overwrites state the caller still holds
sub clobber
{
	my $self = shift;

	$self->{count} = 99;

	return $self->{count};
}

# A getter that removes state the caller still holds
sub drop_state
{
	my $self = shift;

	delete $self->{name};

	return 1;
}

# A getset that touches nothing but its own property
sub clean
{
	my ($self, $value) = @_;

	$self->{value} = $value if @_ > 1;

	return $self->{value};
}

# A getset that also writes somewhere else
sub dirty
{
	my ($self, $value) = @_;

	$self->{value} = $value if @_ > 1;
	$self->{count} = 99 if @_ > 1;

	return $self->{value};
}

sub twice
{
	my $number = shift;

	return $number * 2;
}

1;
MODULE

my $module_file = File::Spec->catfile($lib_dir, 'StateCheck', 'Cfg.pm');
open my $module_fh, '>', $module_file or die "$module_file: $!";
print {$module_fh} $module;
close $module_fh or die "$module_file: $!";

# ---------------------------------------------------------------
# Schemas.  Hand written rather than extracted, so that a change in
# SchemaExtractor can never make this file silently stop testing anything.
# ---------------------------------------------------------------
sub _getter_schema
{
	my ($function, $property, $extra_config) = @_;
	$extra_config //= '';

	return <<"YAML";
---
module: StateCheck::Cfg
function: $function
new: StateCheck::Cfg

accessor:
  type: getter
  property: $property

config:
  test_undef: no
  test_empty: no
$extra_config

output:
  type: integer
YAML
}

sub _getset_schema
{
	my ($function, $extra_config) = @_;
	$extra_config //= '';

	return <<"YAML";
---
module: StateCheck::Cfg
function: $function
new: StateCheck::Cfg

config:
  test_undef: no
  test_empty: no
$extra_config

accessor:
  type: getset
  property: value

input:
  value:
    type: string
    position: 0

output:
  type: string
YAML
}

sub _function_schema
{
	return <<'YAML';
---
module: StateCheck::Cfg
function: twice

config:
  test_undef: no
  test_empty: no

input:
  number:
    type: number
    position: 0

output:
  type: number
YAML
}

# Generate a harness, then run it against the fixture module and return both
# the emitted code and what it printed, so that the assertions below can look
# at the source and at the result of running it.
sub _generate
{
	my ($name, $yaml) = @_;

	my $schema = File::Spec->catfile($schema_dir, "$name.yml");
	open my $schema_fh, '>', $schema or die "$schema: $!";
	print {$schema_fh} $yaml;
	close $schema_fh or die "$schema: $!";

	my $harness = File::Spec->catfile($out_dir, "$name.t");
	# Let the generator see the fixture module, so that it does not warn that
	# the module under test is missing when it inspects the schema
	local @INC = (@INC, $lib_dir);
	App::Test::Generator->generate($schema, $harness);
	die "harness $name.t was not written" unless -s $harness;

	open my $harness_fh, '<', $harness or die "$harness: $!";
	my $code = do { local $/; <$harness_fh> };
	close $harness_fh;

	my ($stdout, $stderr) = ('', '');
	run3 [ $^X, "-I$lib_dir", $harness ], undef, \$stdout, \$stderr;
	$stdout = '' unless defined $stdout;
	$stderr = '' unless defined $stderr;

	return {code => $code, out => $stdout . $stderr};
}

my %harness;
my %getter_property = (
	pure		=> 'count',
	memo		=> 'cached',
	fills_undef	=> 'unset',
	clobber		=> 'count',
	drop_state	=> 'name',
);
foreach my $function (sort keys %getter_property) {
	$harness{$function} = _generate($function, _getter_schema($function, $getter_property{$function}));
}
foreach my $function (qw(clean dirty)) {
	$harness{$function} = _generate($function, _getset_schema($function));
}
$harness{twice} = _generate('twice', _function_schema());

# The same two routines with the checks switched off
$harness{clobber_gated} = _generate('clobber_gated', _getter_schema('clobber', 'count', "  check_accessors: no\n"));
$harness{dirty_gated}   = _generate('dirty_gated', _getset_schema('dirty', "  check_accessors: no\n"));

# ---------------------------------------------------------------
# What the generator emits
# ---------------------------------------------------------------
subtest 'getter harness snapshots its object around every call' => sub {
	like($harness{pure}{code}, qr/require Storable; Storable::dclone\(\$obj\)/, 'object is deep copied before the call');
	like($harness{pure}{code}, qr/\Q$GETTER_MESSAGE\E/, 'a getter that changed its object is reported');
	like($harness{pure}{out},  qr/^1\.\.\d+/m, 'harness ran to completion');
};

subtest 'a getter that declares no input is called with no arguments' => sub {
	like($harness{pure}{code},   qr/\$obj->pure\(\);/, 'called with no arguments');
	unlike($harness{pure}{code}, qr/\$obj->pure\(\$input\)/, "the schema's own input hashref is not passed");
};

subtest 'getset harness compares everything except its property' => sub {
	like($harness{clean}{code},   qr/\Q$SETTER_MESSAGE\E/, 'a setter that changed other state is reported');
	like($harness{clean}{code},   qr/ne 'value'/, 'the property it sets is excluded');
	unlike($harness{clean}{code}, qr/\Q$GETTER_MESSAGE\E/, 'no getter check on a getset');
};

subtest 'a harness for a plain function is unchanged' => sub {
	unlike($harness{twice}{code}, qr/\Q$GETTER_MESSAGE\E/, 'no getter check');
	unlike($harness{twice}{code}, qr/\Q$SETTER_MESSAGE\E/, 'no setter check');
	unlike($harness{twice}{code}, qr/Storable/, 'no copy is taken');
	like($harness{twice}{out},    qr/^1\.\.\d+/m, 'harness ran to completion');
};

# ---------------------------------------------------------------
# What the harness reports when it runs
# ---------------------------------------------------------------
subtest 'getters that leave their object alone are not reported' => sub {
	foreach my $function (qw(pure memo fills_undef)) {
		like($harness{$function}{out},   qr/^1\.\.\d+/m, "$function harness ran to completion");
		unlike($harness{$function}{out}, qr/^not ok \d+ - \Q$GETTER_MESSAGE\E/m, "$function is not reported");
	}
};

subtest 'a getter that overwrites its object is reported' => sub {
	like($harness{clobber}{out}, qr/^not ok \d+ - \Q$GETTER_MESSAGE\E/m, 'overwritten state is reported');
	like($harness{clobber}{out}, qr/\$got->\{count\} = '99'/, 'the changed value is named');
};

subtest 'a getter that deletes its object state is reported' => sub {
	like($harness{drop_state}{out}, qr/^not ok \d+ - \Q$GETTER_MESSAGE\E/m, 'deleted state is reported');
};

subtest 'a getset that changes only its property is not reported' => sub {
	like($harness{clean}{out},   qr/^1\.\.\d+/m, 'harness ran to completion');
	unlike($harness{clean}{out}, qr/^not ok \d+ - \Q$SETTER_MESSAGE\E/m, 'not reported');
};

subtest 'a getset that changes other state is reported' => sub {
	like($harness{dirty}{out}, qr/^not ok \d+ - \Q$SETTER_MESSAGE\E/m, 'other state change is reported');
	like($harness{dirty}{out}, qr/\$got->\{count\} = '99'/, 'the changed value is named');
};

subtest 'the accessor state checks can be turned off' => sub {
	unlike($harness{clobber_gated}{code}, qr/Storable::dclone/, 'no object copy is taken');
	unlike($harness{clobber_gated}{out}, qr/^not ok \d+ - \Q$GETTER_MESSAGE\E/m, 'no getter state check is made');
	like($harness{clobber_gated}{out}, qr/^1\.\.\d+/m, 'getter harness ran to completion');

	unlike($harness{dirty_gated}{out}, qr/^not ok \d+ - \Q$SETTER_MESSAGE\E/m, 'no setter state check is made');
	like($harness{dirty_gated}{out}, qr/^1\.\.\d+/m, 'getset harness ran to completion');
};

done_testing();
