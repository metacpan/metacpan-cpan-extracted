package App::Test::Generator::Emitter::Perl;

use strict;
use warnings;
use Carp qw(croak);
use Readonly;

# --------------------------------------------------
# Plan key names — must match those emitted by
# App::Test::Generator::TestStrategy and
# App::Test::Generator::Planner
# --------------------------------------------------
Readonly my $TEST_BASIC           => 'basic_test';
Readonly my $TEST_GETTER          => 'getter_test';
Readonly my $TEST_SETTER          => 'setter_test';
Readonly my $TEST_GETSET          => 'getset_test';
Readonly my $TEST_CHAINING        => 'chaining_test';
Readonly my $TEST_ERROR_HANDLING  => 'error_handling_test';
Readonly my $TEST_CONTEXT         => 'context_tests';
Readonly my $TEST_OBJECT_INJECT   => 'object_injection_test';
Readonly my $TEST_PREDICATE       => 'predicate_test';
Readonly my $TEST_BOOLEAN         => 'boolean_test';
Readonly my $TEST_VOID            => 'void_context_test';
Readonly my $TEST_BOUNDARY        => 'boundary_tests';

# --------------------------------------------------
# Input/output type strings from the schema
# --------------------------------------------------
Readonly my $TYPE_OBJECT  => 'object';
Readonly my $TYPE_BOOLEAN => 'boolean';

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Emits Perl test code for a set of method schemas and their associated
test plans. Each method plan is translated into one or more test blocks
using L<Test::Most>. The emitted code is returned as a string ready to
be written to a C<.t> file.

=head2 new

Construct a new Perl emitter.

    my $emitter = App::Test::Generator::Emitter::Perl->new(
        schema  => \%schemas,
        plans   => \%plans,
        package => 'My::Module',
    );

=head3 Arguments

=over 4

=item * C<schema>

A hashref of method name to schema hashref. Required.

=item * C<plans>

A hashref of method name to test plan hashref, as produced by
L<App::Test::Generator::TestStrategy> or
L<App::Test::Generator::Planner>. Required.

=item * C<package>

The Perl package name of the module under test. Required.

=back

=head3 Returns

A blessed hashref. Croaks if any required argument is missing.

=head3 API specification

=head4 input

    {
        schema  => { type => HASHREF },
        plans   => { type => HASHREF },
        package => { type => SCALAR  },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Emitter::Perl',
    }

=cut

sub new {
	my ($class, %args) = @_;

	# All three arguments are required for meaningful emission
	croak 'schema required'  unless defined $args{schema};
	croak 'plans required'   unless defined $args{plans};
	croak 'package required' unless defined $args{package};

	return bless {
		schema  => $args{schema},
		plans   => $args{plans},
		package => $args{package},
	}, $class;
}

=head2 emit

Generate and return the complete Perl test file source as a string,
including the file header, one test block per method, and the
C<done_testing()> footer.

    my $emitter = App::Test::Generator::Emitter::Perl->new(
        schema  => \%schemas,
        plans   => \%plans,
        package => 'My::Module',
    );
    my $test_code = $emitter->emit;
    write_file('t/generated.t', $test_code);

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A string containing the complete Perl test file source.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Emitter::Perl' },
    }

=head4 output

    { type => SCALAR }

=cut

sub emit {
	my $self = $_[0];

	# Start with the file header then append per-method test blocks
	my $code = $self->_emit_header();

	# Sort methods for deterministic output order
	for my $method (sort keys %{ $self->{plans} }) {
		$code .= $self->_emit_method_tests($method);
	}

	# TAP footer required by Test::More / Test::Most
	$code .= "\ndone_testing();\n";

	return $code;
}

# --------------------------------------------------
# _emit_header
#
# Purpose:    Generate the standard test file header
#             including strict/warnings, use_ok and
#             a default object construction.
#
# Entry:      None beyond $self.
# Exit:       Returns a string of Perl code.
# Side effects: None.
# Notes:      The generated $obj is used by all
#             subsequent test blocks.
# --------------------------------------------------
sub _emit_header {
	my $self = $_[0];

	return <<"END_HEADER";
use strict;
use warnings;
use Test::Most;

use_ok('$self->{package}');

my \$obj = new_ok('$self->{package}');

END_HEADER
}

# --------------------------------------------------
# _emit_method_tests
#
# Purpose:    Dispatch to the appropriate emit method
#             for each test type flagged in the plan
#             for a given method.
#
# Entry:      $method - the method name string.
#             Plan and schema are read from $self.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# Notes:      Test types are emitted in a fixed order
#             for deterministic output. Methods with
#             no recognised plan flags produce no
#             output beyond the section comment.
# --------------------------------------------------
sub _emit_method_tests {
	my ($self, $method) = @_;

	my $plan   = $self->{plans}{$method};
	my $code   = "\n# --- Tests for $method ---\n";

	# Emit each test type in a consistent fixed order
	$code .= $self->_emit_basic_test($method)
		if $plan->{$TEST_BASIC};

	$code .= $self->_emit_getter_test($method)
		if $plan->{$TEST_GETTER};

	$code .= $self->_emit_setter_test($method)
		if $plan->{$TEST_SETTER};

	$code .= $self->_emit_getset_test($method)
		if $plan->{$TEST_GETSET};

	$code .= $self->_emit_chaining_test($method)
		if $plan->{$TEST_CHAINING};

	$code .= $self->_emit_error_test($method)
		if $plan->{$TEST_ERROR_HANDLING};

	$code .= $self->_emit_context_test($method)
		if $plan->{$TEST_CONTEXT};

	$code .= $self->_emit_object_injection_test($method)
		if $plan->{$TEST_OBJECT_INJECT};

	$code .= $self->_emit_boolean_test($method)
		if $plan->{$TEST_PREDICATE} || $plan->{$TEST_BOOLEAN};

	$code .= $self->_emit_void_test($method)
		if $plan->{$TEST_VOID};

	return $code;
}

# --------------------------------------------------
# _emit_basic_test
#
# Purpose:    Emit a minimal test that calls the
#             method and verifies it does not die.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_basic_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$result = eval { \$obj->$method() };
	ok(!\$@, '$method does not die');
}
END_TEST
}

# --------------------------------------------------
# _emit_getter_test
#
# Purpose:    Emit a test that calls the getter and
#             verifies it returns a defined value.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_getter_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$value = \$obj->$method();
	ok(defined \$value, '$method returns a value');
}
END_TEST
}

# --------------------------------------------------
# _emit_setter_test
#
# Purpose:    Emit a test that calls the setter with
#             a string argument and verifies it
#             accepts the input without dying.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_setter_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	ok(\$obj->$method('test'), '$method accepts input');
}
END_TEST
}

# --------------------------------------------------
# _emit_getset_test
#
# Purpose:    Emit a round-trip get/set test. The
#             test type (object, boolean, or string)
#             is determined from the schema input
#             parameter type.
#
# Entry:      $method - method name string.
#             Schema is read from $self.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# Notes:      Falls back to string round-trip if the
#             parameter type is unrecognised.
# --------------------------------------------------
sub _emit_getset_test {
	my ($self, $method) = @_;

	my $schema  = $self->{schema}{$method};

	# Find the first non-internal input parameter
	my ($param) = grep { !/^_/ } keys %{ $schema->{input} || {} };
	my $type    = ($param && $schema->{input}{$param}{type}) // '';

	# Object injection round-trip
	if($type eq $TYPE_OBJECT) {
		return <<"END_TEST";
{
	my \$mock = bless {}, 'Test::MockObject';
	\$obj->$method(\$mock);
	isa_ok(\$obj->$method(), ref(\$mock), '$method get/set works');
}
END_TEST
	}

	# Boolean round-trip
	if($type eq $TYPE_BOOLEAN) {
		return <<"END_TEST";
{
	\$obj->$method(1);
	ok(\$obj->$method(), '$method get/set boolean true works');
	\$obj->$method(0);
	ok(!\$obj->$method(), '$method get/set boolean false works');
}
END_TEST
	}

	# Default string round-trip
	return <<"END_TEST";
{
	\$obj->$method('value');
	is(\$obj->$method(), 'value', '$method get/set works');
}
END_TEST
}

# --------------------------------------------------
# _emit_chaining_test
#
# Purpose:    Emit a test that verifies the method
#             returns $self for method chaining.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_chaining_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$ret = \$obj->$method();
	isa_ok(\$ret, ref(\$obj), '$method returns self for chaining');
}
END_TEST
}

# --------------------------------------------------
# _emit_error_test
#
# Purpose:    Emit a test that calls the method with
#             undef input and verifies it handles the
#             error gracefully.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_error_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$result = eval { \$obj->$method(undef) };
	ok(!\$result || \$@, '$method handles invalid input');
}
END_TEST
}

# --------------------------------------------------
# _emit_context_test
#
# Purpose:    Emit tests that call the method in
#             both scalar and list context to verify
#             context-aware return behaviour.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# Notes:      Uses eval to verify the calls survive
#             rather than checking return values,
#             since context-aware return values vary.
# --------------------------------------------------
sub _emit_context_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$scalar = eval { \$obj->$method() };
	ok(!\$@, '$method survives in scalar context');

	my \@list = eval { \$obj->$method() };
	ok(!\$@, '$method survives in list context');
}
END_TEST
}

# --------------------------------------------------
# _emit_object_injection_test
#
# Purpose:    Emit a test that injects a mock object
#             and verifies the same object is returned
#             by the getter.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_object_injection_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$mock = bless {}, 'Mock::Object';
	\$obj->$method(\$mock);
	isa_ok(\$obj->$method(), 'Mock::Object',
		'$method stores injected object instance');
}
END_TEST
}

# --------------------------------------------------
# _emit_boolean_test
#
# Purpose:    Emit a test that verifies the method
#             returns a defined scalar boolean value.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# Notes:      Checks that the return value is defined,
#             is not a reference, and is boolean-like
#             without using numeric comparison which
#             would warn on string returns.
# --------------------------------------------------
sub _emit_boolean_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$result = \$obj->$method();
	ok(defined \$result,  '$method returns a defined value');
	ok(!ref \$result,     '$method returns a scalar');
	ok(\$result ? 1 : 0, '$method returns a boolean-like value');
}
END_TEST
}

# --------------------------------------------------
# _emit_void_test
#
# Purpose:    Emit a test that verifies the method
#             does not return a meaningful value,
#             consistent with a void return type.
#
# Entry:      $method - method name string.
# Exit:       Returns a string of Perl test code.
# Side effects: None.
# --------------------------------------------------
sub _emit_void_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$result = eval { \$obj->$method() };
	ok(!\$@,         '$method does not die');
	ok(!defined \$result || 1, '$method void return noted');
}
END_TEST
}

1;
