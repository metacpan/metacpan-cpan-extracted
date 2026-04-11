package App::Test::Generator::Emitter::Perl;

use strict;
use warnings;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

=cut

sub new {
	my ($class, %args) = @_;
	use Data::Dumper;
	warn Dumper($args{plans});
	return bless {
		schema => $args{schema},
		plans => $args{plans},
		package => $args{package},
	}, $class;
}

sub emit {
	my $self = $_[0];

	my $code = $self->_emit_header();

	foreach my $method (sort keys %{ $self->{plans} }) {
		$code .= $self->_emit_method_tests($method);
	}

	$code .= "\ndone_testing();\n";

	return $code;
}

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

sub _emit_method_tests {
	my ($self, $method) = @_;

    my $plan = $self->{plans}{$method};
    my $schema = $self->{schema}{$method};

    my $code = "\n# --- Tests for $method ---\n";

    if ($plan->{basic_test}) {
        $code .= $self->_emit_basic_test($method);
    }

    if ($plan->{getter_test}) {
        $code .= $self->_emit_getter_test($method);
    }

    if ($plan->{setter_test}) {
        $code .= $self->_emit_setter_test($method);
    }

    if ($plan->{getset_test}) {
        $code .= $self->_emit_getset_test($method);
    }

    if ($plan->{chaining_test}) {
        $code .= $self->_emit_chaining_test($method);
    }

    if ($plan->{error_handling_test}) {
        $code .= $self->_emit_error_test($method);
    }

    if ($plan->{context_tests}) {
        $code .= $self->_emit_context_test($method);
    }

	if ($plan->{object_injection_test}) {
		$code .= $self->_emit_object_injection_test($method);
	}

	if(($plan->{predicate_test}) || ($plan->{boolean_test})) {
		$code .= $self->_emit_boolean_test($method);
	}

    return $code;
}

sub _emit_basic_test {
    my ($self, $method) = @_;

    return <<"END_TEST";
{
    my \$result = eval { \$obj->$method() };
    ok(!\$@, '$method does not die');
}
END_TEST
}

sub _emit_getter_test {
    my ($self, $method) = @_;

    return <<"END_TEST";
{
    my \$value = \$obj->$method();
    ok(defined \$value, '$method returns a value');
}
END_TEST
}

sub _emit_setter_test {
    my ($self, $method) = @_;

    return <<"END_TEST";
{
    ok(\$obj->$method('test'), '$method accepts input');
}
END_TEST
}

sub _emit_getset_test {
	my ($self, $method) = @_;

	my $schema = $self->{schema}{$method};

	my ($param) = grep { $_ !~ /^_/ } keys %{ $schema->{input} || {} };

	my $type = $schema->{input}{$param}{type} // 'string';

	# -------------------------------
	# OBJECT INPUT
	# -------------------------------
	if ($type eq 'object') {
		return <<"END_TEST";
{
    my \$mock = bless {}, 'Test::MockObject';
    \$obj->$method(\$mock);
    isa_ok(\$obj->$method(), ref(\$mock), '$method get/set works');
}
END_TEST
	}

	# -------------------------------
	# DEFAULT STRING INPUT
	# -------------------------------
	return <<"END_TEST";
{
    \$obj->$method('value');
    is(\$obj->$method(), 'value', '$method get/set works');
}
END_TEST
}

sub _emit_chaining_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
    my \$ret = \$obj->$method();
    isa_ok(\$ret, ref(\$obj), '$method returns self for chaining');
}
END_TEST
}

sub _emit_error_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
    my \$result = eval { \$obj->$method(undef) };
    ok(!\$result || \$@, '$method handles invalid input');
}
END_TEST
}

sub _emit_context_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
    my \$scalar = \$obj->$method();
    my \@list   = \$obj->$method();

    ok(defined \$scalar, '$method works in scalar context');
    ok(defined \@list,   '$method works in list context');
}
END_TEST
}

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

sub _emit_boolean_test {
	my ($self, $method) = @_;

	return <<"END_TEST";
{
	my \$result = \$obj->$method();
	ok(defined \$result, '$method returns a value');
	ok(!ref \$result, '$method returns a scalar');
	ok(((\$result == 1) || (\$result == 0)), '$method returns a boolean');
}
END_TEST
}

1;
