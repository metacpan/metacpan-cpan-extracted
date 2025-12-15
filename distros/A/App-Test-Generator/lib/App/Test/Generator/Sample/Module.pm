package Test::App::Generator::Sample::Module;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.21';

=head1 NAME

Test::App::Generator::Sample::Module - Example module for schema extraction testing

=head1 SYNOPSIS

    use Sample::Module;

    my $obj = Sample::Module->new();
    my $result = $obj->validate_email('user@example.com');

=head1 DESCRIPTION

This is a sample module with well-documented methods to test
the schema extractor.

=cut

=head2 new

Constructor.

Returns a new Sample::Module object.

=cut

sub new {
	my $class = $_[0];
	return bless {}, $class;
}

=head2 validate_email($email)

Validates an email address.

Parameters:
  $email - string (5-254 chars), email address to validate

Returns:
  1 if valid, dies otherwise

=cut

sub validate_email {
    my ($self, $email) = @_;

    croak 'Email is required' unless defined $email;
    croak "Email too short" unless length($email) >= 5;
    croak "Email too long" unless length($email) <= 254;
    croak "Invalid email format" unless $email =~ /^[^@]+@[^@]+\.[^@]+$/;

    return 1;
}

=head2 calculate_age($birth_year)

Calculate age from birth year.

Parameters:
  $birth_year - integer (1900-2024), year of birth

Returns:
  Age in years (integer)

=cut

sub calculate_age {
    my ($self, $birth_year) = @_;

    croak "Birth year required" unless defined $birth_year;
    croak "Birth year must be a number" unless $birth_year =~ /^\d+$/;
    croak "Birth year out of range" unless $birth_year >= 1900 && $birth_year <= 2024;

    my $current_year = 2024;
    return $current_year - $birth_year;
}

=head2 process_names($names)

Process a list of names.

Parameters:
  $names - arrayref, list of name strings

Returns:
  Count of names processed

=cut

sub process_names {
    my ($self, $names) = @_;

    croak "Names required" unless defined $names;
    croak "Names must be an array reference" unless ref($names) eq 'ARRAY';

    my $count = 0;
    foreach my $name (@$names) {
        # Process each name
        $count++ if defined $name && length($name) > 0;
    }

    return $count;
}

=head2 set_config($config)

Set configuration options.

Parameters:
  $config - hashref, configuration options

Returns:
  1 on success

=cut

sub set_config {
    my ($self, $config) = @_;

    croak "Config required" unless defined $config;
    croak "Config must be a hash reference" unless ref($config) eq 'HASH';

    $self->{config} = $config;
    return 1;
}

=head2 greet($name, $greeting)

Generate a greeting message.

Parameters:
  $name - string (1-50 chars), person's name
  $greeting - string (optional), custom greeting (default: "Hello")

Returns:
  Greeting string

=cut

sub greet {
    my ($self, $name, $greeting) = @_;

    croak "Name is required" unless defined $name;
    croak "Name too short" unless length($name) >= 1;
    croak "Name too long" unless length($name) <= 50;

    $greeting ||= "Hello";

    return "$greeting, $name!";
}

=head2 check_flag($enabled)

Check a boolean flag.

Parameters:
  $enabled - boolean, whether feature is enabled

Returns:
  1 if enabled, 0 otherwise

=cut

sub check_flag {
    my ($self, $enabled) = @_;

    return $enabled ? 1 : 0;
}

=head2 validate_score($score)

Validate a test score.

Parameters:
  $score - number (0.0-100.0), test score percentage

Returns:
  Pass/Fail status string

=cut

sub validate_score {
    my ($self, $score) = @_;

    croak "Score is required" unless defined $score;
    croak "Score must be numeric" unless $score =~ /^[\d.]+$/;
    croak "Score out of range" unless $score >= 0.0 && $score <= 100.0;

    return $score >= 60.0 ? "Pass" : "Fail";
}

=head2 mysterious_method($thing)

A method with poor documentation.

Does something with a thing.

=cut

sub mysterious_method {
    my ($self, $thing) = @_;

    # No validation - extractor should flag this as low confidence
    return $thing * 2;
}

1;

__END__

=head1 AUTHOR

Example Author

=head1 LICENSE

This is free software.

=cut
