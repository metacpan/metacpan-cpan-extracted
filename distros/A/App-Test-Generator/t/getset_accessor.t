use strict;
use warnings;

# use Test::DescribeMe qw(extended);	# New features
use File::Temp qw(tempfile);
use Test::Most;
use YAML::XS qw(LoadFile);

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# -------------------------------
# Test input: getter/setter method
# -------------------------------
my $code = <<'PERL';
package GetSet::Test;

=head2 ua

Accessor method to get and set UserAgent object used internally.

=cut

sub ua {
	my $self = shift;

	if (@_) {
		my $params = Params::Validate::Strict::validate_strict({
			args => Params::Get::get_params('ua', @_),
			schema => {
				ua => {
					type => 'object',
					can  => 'get'
				}
			}
		});
		$self->{ua} = $params->{ua};
	}

	return $self->{ua};
}

sub getter_only {
	my $self = shift;
	return $self->{foo};
}

sub setter_only {
	my $self = shift;
	my $foo = shift;
	$self->{foo} = $foo;
	return $self;
}

# Mirrors CGI::Info::set_logger: the argument is stored as given when it is
# already a reference, otherwise it is handed to another class's constructor,
# so the setter accepts whatever that constructor accepts.
sub set_wrapped {
	my $self = shift;
	my $thing = shift;

	if(ref($thing)) {
		$self->{thing} = $thing;
	} else {
		$self->{thing} = Wrapper->new($thing);
	}

	return $self;
}

sub mutator {
	my $self = shift;
	$self->{bar} = shift;
	return $self->{bar};
}

=head2 agent

Returns UserAgent object

=cut

sub agent {
	my $self = shift;
	return $self->{ua};
}

sub ua2 {
	my $self = shift;
	if (@_) {
		my $p = Params::Validate::Strict::validate_strict({
			args => Params::Get::get_params('ua', @_),
			schema => {
				ua => { type => 'object' }
			}
		});
		$self->{ua2} = $p->{ua};
	}
	return $self->{ua2};
}

=head2 is_tablet

Returns a boolean if the website is being viewed on a tablet such as an iPad.

=cut

sub is_tablet {
	my $self = shift;

	if(defined($self->{is_tablet})) {
		return $self->{is_tablet};
	}

	if($ENV{'HTTP_USER_AGENT'} && ($ENV{'HTTP_USER_AGENT'} =~ /.+(iPad|TabletPC).+/)) {
		# TODO: add others when I see some nice user_agents
		$self->{is_tablet} = 1;
	} else {
		$self->{is_tablet} = 0;
	}

	return $self->{is_tablet};
}

# Mirrors CGI::Info::protocol: the value is computed from %ENV and cached, so
# the method takes no argument at all. Its conditions test $ENV and $self, and
# neither is evidence that an argument was supplied.
sub protocol {
	my $self = shift;

	return $self->{protocol} if ref($self) && exists $self->{protocol};

	my $result;
	if($ENV{'SCRIPT_URI'} && ($ENV{'SCRIPT_URI'} =~ /^([a-zA-Z][a-zA-Z0-9+\-.]*):\/\//)) {
		$result = $1;
	} elsif($ENV{'SERVER_PORT'} && ($ENV{'SERVER_PORT'} == 443)) {
		$result = 'https';
	}

	$self->{protocol} = $result if ref($self);
	return $result;
}

=head2 status($status)

Sets or returns the status of the object,
200 for OK,
otherwise an HTTP error code

=over 4

=item $status

Optional integer value to be set or retrieved.
If omitted, the value is retrieved.

=back

=cut

sub status
{
	my $self = shift;
	my $status = shift;

	# Set status if provided
	return $self->{status} = $status if(defined($status));

	# Determine status based on request method if status is not set
	unless (defined $self->{status}) {
		my $method = $ENV{'REQUEST_METHOD'};

		return 405 if $method && ($method eq 'OPTIONS' || $method eq 'DELETE');
		return 411 if $method && ($method eq 'POST' && !defined $ENV{'CONTENT_LENGTH'});

		return 200;
	}

	# Return current status or 200 by default
	return $self->{status} || 200;
}

1;
PERL

# -------------------------------
# Write code to a temp file
# -------------------------------
my ($fh, $filename) = tempfile( SUFFIX => '.pm', UNLINK => 1 );
print {$fh} $code;
close $fh;

# -------------------------------
# Run schema extractor
# -------------------------------
my $extractor = App::Test::Generator::SchemaExtractor->new(
	input_file => $filename,
);

my $schemas;
# Use no_write => 1 since we only want the schema data,
# not files written to disk — output_dir is not needed
lives_ok {
	$schemas = $extractor->extract_all(no_write => 1);
} 'Schema extraction did not die';

ok($schemas, 'Schemas extracted');

ok(
	exists $schemas->{ua},
	'ua method schema generated'
);

my $schema = $schemas->{ua};

# -------------------------------
# Assertions: accessor detection
# -------------------------------
is(
	$schema->{accessor}{type},
	'getset',
	'Detected getter/setter accessor'
);

is(
	$schema->{accessor}{property},
	'ua',
	'Correct accessor property detected'
);

# -------------------------------
# Assertions: instantiation
# -------------------------------
is(
	$schema->{new},
	'GetSet::Test',
	'Getter/setter requires object instantiation'
);

# -------------------------------
# Assertions: output typing
# -------------------------------
ok(
	exists $schema->{output},
	'Output schema exists'
);

is(
	$schema->{output}{type},
	'object',
	'Getter/setter output treated as object (not numeric/string)'
);

# -------------------------------
# Assertions: input typing
# -------------------------------
is(
	$schema->{input}{ua}{type},
	'object',
	'Setter input correctly typed as object'
);

is(
	$schemas->{getter_only}{accessor}{type},
	'getter',
	'Detected getter-only accessor'
);

# Getter-only should NOT have input at all
ok((!defined($schemas->{getter_only}{input})), 'Getter takes no input');
ok(defined($schemas->{getter_only}{output}{type}), 'Getter-only returns something');

is(
	$schemas->{setter_only}{accessor}{type},
	'setter',
	'Detected setter-only accessor'
);

is(
	$schemas->{setter_only}{input}{foo}{type},
	'string',
	'Setter-only input defaulted sanely'
);

is(
	$schemas->{set_wrapped}{input}{thing}{type},
	'any',
	'Setter that wraps its argument is not typed as a string'
);

is(
	$schemas->{agent}{output}{isa},
	'LWP::UserAgent',
	'POD-derived object isa propagated'
);

is(
	$schemas->{ua2}{accessor}{type},
	'getset',
	'PVS-based getter/setter detected'
);

is(
	$schemas->{ua2}{output}{type},
	'object',
	'Object type propagated from validator'
);

# Getter-only should not have phantom parameters
ok(
	!exists $schemas->{getter_only}{parameters},
	'Pure getter does not generate parameter list'
);

# Getter-only should have low output confidence
is($schemas->{getter_only}{_confidence}{output}{level}, 'low', 'Pure getter marked low confidence');

# Setter-only should instantiate object
is($schemas->{setter_only}{new}, 'GetSet::Test', 'Setter requires object instantiation');

# ua (getset) should not contain phantom parameters
ok(
	!exists $schemas->{ua}{parameters},
	'Get/set accessor does not expose synthetic positional parameters'
);

# ua property name must match method name
is(
	$schemas->{ua}{accessor}{property},
	'ua',
	'Get/set property name matches method'
);

# agent should be detected as getter
is(
	$schemas->{agent}{accessor}{type},
	'getter',
	'Agent method detected as getter'
);

# agent should not have input
ok(
	!exists $schemas->{agent}{input},
	'Agent getter has no input'
);

# agent should preserve POD-derived isa
is(
	$schemas->{agent}{output}{isa},
	'LWP::UserAgent',
	'Agent retains POD-derived isa'
);

# ua2 should not regress to unknown typing
isnt(
	$schemas->{ua2}{output}{type},
	'unknown',
	'Validator-backed accessor does not downgrade to unknown type'
);

# ua2 setter input must be object
is(
	$schemas->{ua2}{input}{ua}{type},
	'object',
	'ua2 setter input preserved as object'
);

# Ensure mutator isn't flagged as a getter
ok(exists $schemas->{mutator});
ok(!exists $schemas->{mutator}{accessor});

# is_tablet should be detected as getter
is($schemas->{is_tablet}{accessor}{type}, 'getter', 'is_tablet method detected as getter');

# CGI::Info::status stores its argument only when one is given, and returns
# the stored value otherwise. This is a get/set accessor, not a plain function.
# CGI::Info::protocol's condition on %ENV must not be read as an argument
# guard: doing so typed it as a getset accessor and the harness set a value
# that protocol() never looks at.
isnt($schemas->{protocol}{accessor}{type}, 'getset', 'Environment-driven getter is not a getset accessor');
is(scalar(keys %{ $schemas->{protocol}{input} // {} }), 0, 'Environment-driven getter takes no parameters');

is($schemas->{status}{accessor}{type}, 'getset', 'Conditional setter/return detected as getset');
is($schemas->{status}{accessor}{property}, 'status', 'Conditional accessor property detected');
is($schemas->{status}{input}{status}{type}, 'integer', 'POD-declared integer input preserved');
is($schemas->{status}{input}{status}{position}, 0, 'Conditional accessor argument keeps position 0');

done_testing();
