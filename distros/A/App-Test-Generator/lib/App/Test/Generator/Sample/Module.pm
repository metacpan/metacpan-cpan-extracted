package Test::App::Generator::Sample::Module;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

our $VERSION = '0.33';

# --------------------------------------------------
# Validation constants — centralised so that changes
# to limits only need to be made in one place
# --------------------------------------------------
Readonly my $MIN_EMAIL_LEN  => 5;
Readonly my $MAX_EMAIL_LEN  => 254;
Readonly my $MIN_BIRTH_YEAR => 1900;
Readonly my $MIN_NAME_LEN   => 1;
Readonly my $MAX_NAME_LEN   => 50;
Readonly my $MIN_SCORE      => 0.0;
Readonly my $MAX_SCORE      => 100.0;
Readonly my $PASS_THRESHOLD => 60.0;

=head1 NAME

Test::App::Generator::Sample::Module - Example module for schema extraction testing

=head1 VERSION

Version 0.33

=head1 SYNOPSIS

    use Test::App::Generator::Sample::Module;

    my $obj = Test::App::Generator::Sample::Module->new();
    my $result = $obj->validate_email('user@example.com');

=head1 DESCRIPTION

A sample module with a variety of well and poorly documented methods,
used to exercise L<App::Test::Generator::SchemaExtractor>. The methods
cover common parameter types, validation patterns, and confidence levels
so that the extractor's heuristics can be tested against known inputs.

=head2 new

Constructor. Returns a new instance.

    my $obj = Test::App::Generator::Sample::Module->new();

=head3 Returns

A blessed hashref.

=head3 API specification

=head4 input

    { class => { type => SCALAR } }

=head4 output

    { type => OBJECT, isa => 'Test::App::Generator::Sample::Module' }

=cut

sub new {
	my $class = $_[0];

	# Bless an empty hashref into the calling class
	return bless {}, $class;
}

=head2 validate_email

Validate an email address against basic structural rules.

    my $ok = $obj->validate_email('user@example.com');

=head3 Arguments

=over 4

=item * C<$email>

String (C<$MIN_EMAIL_LEN>-C<$MAX_EMAIL_LEN> chars). Required.

=back

=head3 Returns

1 if the address is valid. Croaks on any validation failure.

=head3 API specification

=head4 input

    {
        self  => { type => OBJECT, isa => 'Test::App::Generator::Sample::Module' },
        email => { type => SCALAR, min => 5, max => 254 },
    }

=head4 output

    { type => SCALAR, value => 1 }

=cut

sub validate_email {
	my ($self, $email) = @_;

	# Presence check before length checks to give a clear error
	croak 'Email is required' unless defined $email;
	croak 'Email too short'   unless length($email) >= $MIN_EMAIL_LEN;
	croak 'Email too long'    unless length($email) <= $MAX_EMAIL_LEN;

	# Basic structural check — one @ with non-empty local and domain parts
	croak 'Invalid email format'
		unless $email =~ /^[^@]+\@[^@]+\.[^@]+$/;

	return 1;
}

=head2 calculate_age

Calculate age in years from a birth year.

    my $age = $obj->calculate_age(1985);

=head3 Arguments

=over 4

=item * C<$birth_year>

Integer (C<$MIN_BIRTH_YEAR> to current year). Required.

=back

=head3 Returns

Age in years as an integer.

=head3 API specification

=head4 input

    {
        self       => { type => OBJECT, isa => 'Test::App::Generator::Sample::Module' },
        birth_year => { type => SCALAR, min => 1900 },
    }

=head4 output

    { type => SCALAR }

=cut

sub calculate_age {
	my ($self, $birth_year) = @_;

	# Get the current year from the system clock rather than using
	# a hardcoded value that would become stale each year
	my $current_year = (localtime)[5] + 1900;

	croak 'Birth year required'          unless defined $birth_year;
	croak 'Birth year must be a number'  unless $birth_year =~ /^\d+$/;

	# Upper bound is the current year — you cannot be born in the future
	croak 'Birth year out of range'
		unless $birth_year >= $MIN_BIRTH_YEAR && $birth_year <= $current_year;

	return $current_year - $birth_year;
}

=head2 process_names

Process a list of names and return the count of non-empty entries.

    my $count = $obj->process_names(['Alice', 'Bob', '']);

=head3 Arguments

=over 4

=item * C<$names>

Arrayref of name strings. Required.

=back

=head3 Returns

Count of non-empty name strings as an integer.

=head3 API specification

=head4 input

    {
        self  => { type => OBJECT,   isa => 'Test::App::Generator::Sample::Module' },
        names => { type => ARRAYREF },
    }

=head4 output

    { type => SCALAR, min => 0 }

=cut

sub process_names {
	my ($self, $names) = @_;

	croak 'Names required'                    unless defined $names;
	croak 'Names must be an array reference'  unless ref($names) eq 'ARRAY';

	# Count only non-empty name strings — undef and '' are skipped
	my $count = 0;
	for my $name (@{$names}) {
		# Increment only for defined, non-empty entries
		$count++ if defined($name) && length($name) > 0;
	}

	return $count;
}

=head2 set_config

Store a configuration hashref on the object.

    $obj->set_config({ timeout => 30, retries => 3 });

=head3 Arguments

=over 4

=item * C<$config>

Hashref of configuration options. Required.

=back

=head3 Returns

1 on success. Croaks if C<$config> is absent or not a hashref.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT,  isa => 'Test::App::Generator::Sample::Module' },
        config => { type => HASHREF },
    }

=head4 output

    { type => SCALAR, value => 1 }

=cut

sub set_config {
	my ($self, $config) = @_;

	croak 'Config required'                  unless defined $config;
	croak 'Config must be a hash reference'  unless ref($config) eq 'HASH';

	# Store the config hashref directly — callers own the data
	$self->{config} = $config;

	return 1;
}

=head2 greet

Generate a greeting message for a named person.

    my $msg = $obj->greet('Alice');
    my $msg = $obj->greet('Alice', 'Good morning');

=head3 Arguments

=over 4

=item * C<$name>

String (C<$MIN_NAME_LEN>-C<$MAX_NAME_LEN> chars). Required.

=item * C<$greeting>

String. Optional — defaults to C<"Hello">.

=back

=head3 Returns

Greeting string of the form C<"$greeting, $name!">.

=head3 API specification

=head4 input

    {
        self     => { type => OBJECT, isa => 'Test::App::Generator::Sample::Module' },
        name     => { type => SCALAR, min => 1, max => 50 },
        greeting => { type => SCALAR, optional => 1 },
    }

=head4 output

    { type => SCALAR }

=cut

sub greet {
	my ($self, $name, $greeting) = @_;

	croak 'Name is required' unless defined $name;
	croak 'Name too short'   unless length($name) >= $MIN_NAME_LEN;
	croak 'Name too long'    unless length($name) <= $MAX_NAME_LEN;

	# Apply default greeting when caller does not supply one
	$greeting ||= 'Hello';

	return "$greeting, $name!";
}

=head2 check_flag

Return a normalised boolean for a flag value.

    my $result = $obj->check_flag(1);   # returns 1
    my $result = $obj->check_flag(0);   # returns 0

=head3 Arguments

=over 4

=item * C<$enabled>

Boolean scalar. Required.

=back

=head3 Returns

1 if C<$enabled> is true, 0 otherwise.

=head3 API specification

=head4 input

    {
        self    => { type => OBJECT, isa => 'Test::App::Generator::Sample::Module' },
        enabled => { type => SCALAR },
    }

=head4 output

    { type => SCALAR }

=cut

sub check_flag {
	my ($self, $enabled) = @_;

	# Normalise any truthy/falsy value to a strict 1 or 0
	return $enabled ? 1 : 0;
}

=head2 validate_score

Validate a numeric test score and return a pass/fail string.

    my $status = $obj->validate_score(75.5);  # returns 'Pass'
    my $status = $obj->validate_score(45.0);  # returns 'Fail'

=head3 Arguments

=over 4

=item * C<$score>

Number (C<$MIN_SCORE>-C<$MAX_SCORE>). Required.

=back

=head3 Returns

The string C<'Pass'> if the score meets or exceeds C<$PASS_THRESHOLD>,
C<'Fail'> otherwise. Croaks on invalid input.

=head3 API specification

=head4 input

    {
        self  => { type => OBJECT, isa => 'Test::App::Generator::Sample::Module' },
        score => { type => SCALAR, min => 0.0, max => 100.0 },
    }

=head4 output

    { type => SCALAR }

=cut

sub validate_score {
	my ($self, $score) = @_;

	croak 'Score is required'    unless defined $score;

	# Accept integers, decimals, and values like '.5' but not '1.2.3'
	croak 'Score must be numeric'
		unless $score =~ /^(?:\d+\.?\d*|\.\d+)$/;

	croak 'Score out of range'
		unless $score >= $MIN_SCORE && $score <= $MAX_SCORE;

	# Compare against the pass threshold constant
	return $score >= $PASS_THRESHOLD ? 'Pass' : 'Fail';
}

=head2 mysterious_method

A deliberately under-documented method used to test that
L<App::Test::Generator::SchemaExtractor> correctly assigns low
confidence when validation is absent.

=cut

sub mysterious_method {
	my ($self, $thing) = @_;

	# Intentionally unvalidated — used to verify that SchemaExtractor
	# flags low-confidence schemas when no validation logic is present.
	# Callers passing non-numeric values will trigger a Perl warning;
	# this is expected behaviour for this test fixture.
	return $thing * 2;
}

=head1 AUTHOR

Example Author

=head1 LICENSE

This is free software.

=cut

1;
