package App::Test::Generator::Provenance;

use strict;
use warnings;

use Exporter qw(import);

our $VERSION = '0.52';

our @EXPORT_OK = qw(
	SOURCE_VALIDATOR SOURCE_INPUT_SPEC SOURCE_POD
	SOURCE_CODE SOURCE_SIGNATURE SOURCE_FIELD
	sources documented_sources type_checks_source
	source_is_valid source_is_documented source_checks_types
);

=head1 NAME

App::Test::Generator::Provenance - The allowed values of a schema parameter's C<_source> marker

=head1 VERSION

Version 0.52

=head1 SYNOPSIS

    use App::Test::Generator::Provenance qw(
        SOURCE_POD source_is_documented source_is_valid
    );

    # When the extractor records where a parameter came from
    $spec->{_source} = SOURCE_POD;

    # When the harness decides whether a constraint is documentation
    $is_hint = source_is_documented($spec->{_source});

=head1 DESCRIPTION

Every generated schema parameter carries a C<_source> marker saying where
its type and constraints came from.  The extractor writes the marker and
the generated harness reads it, so both must agree on the same set of
values.  Defining that set here, once, stops the two from drifting apart:
the extractor can only emit a value from L</sources>, and the harness only
treats a value from L</documented_sources> as documentation.

The markers are:

    value        meaning
    validator    the routine's own validator confirmed the type
    input_spec   an input specification in the POD declared the type
    pod          ordinary POD prose declared the type or a constraint
    code         the routine's code revealed the parameter
    signature    a subroutine signature declared the parameter
    field        a field declaration declared the parameter

A documented marker (C<input_spec> or C<pod>) describes valid input; it
is not a check the routine was seen to make.  C<validator> is the marker
that says the routine checks types itself.  The other markers say only
that the parameter exists.

=head1 CONSTANTS

=head2 SOURCE_VALIDATOR, SOURCE_INPUT_SPEC, SOURCE_POD, SOURCE_CODE, SOURCE_SIGNATURE, SOURCE_FIELD

The six allowed marker values, exported on request.

=head1 FUNCTIONS

=head2 sources

Returns the allowed marker values as a list.  Use it to validate a marker
read from a schema.

=head3 API SPECIFICATION

=head4 input

    {}

=head4 output

    {}

A list of strings, not a reference.  No type is declared because the schema
format has no type for a returned list.

=head2 documented_sources

Returns the markers that describe documentation rather than an enforced
check: C<pod> and C<input_spec>.

=head3 API SPECIFICATION

=head4 input

    {}

=head4 output

    {}

A list of strings, not a reference.  No type is declared because the schema
format has no type for a returned list.

=head2 type_checks_source

Returns the marker that says the routine checks types itself:
C<validator>.

=head3 API SPECIFICATION

=head4 input

    {}

=head4 output

    { type => SCALAR }

=head2 source_is_valid

    $ok = source_is_valid($source);

True when the marker is one of L</sources>.

=head3 API SPECIFICATION

=head4 input

    {
        source => { type => 'any', optional => 1 },
    }

An undefined value or a reference is never a marker and gives 0; nothing
is thrown.

=head4 output

    { type => SCALAR }

1 or 0.

=head2 source_is_documented

    $hint = source_is_documented($source);

True when the marker is one of L</documented_sources>.  An undefined or
unknown marker is not documentation.

=head3 API SPECIFICATION

=head4 input

    {
        source => { type => 'any', optional => 1 },
    }

An undefined value or a reference is never a marker and gives 0; nothing
is thrown.

=head4 output

    { type => SCALAR }

1 or 0.

=head2 source_checks_types

    $checked = source_checks_types($source);

True when the marker is L</type_checks_source>.

=head3 API SPECIFICATION

=head4 input

    {
        source => { type => 'any', optional => 1 },
    }

An undefined value or a reference is never a marker and gives 0; nothing
is thrown.

=head4 output

    { type => SCALAR }

1 or 0.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

use constant SOURCE_VALIDATOR  => 'validator';
use constant SOURCE_INPUT_SPEC => 'input_spec';
use constant SOURCE_POD        => 'pod';
use constant SOURCE_CODE       => 'code';
use constant SOURCE_SIGNATURE  => 'signature';
use constant SOURCE_FIELD      => 'field';

use constant _SOURCES => [
	SOURCE_VALIDATOR,
	SOURCE_INPUT_SPEC,
	SOURCE_POD,
	SOURCE_CODE,
	SOURCE_SIGNATURE,
	SOURCE_FIELD,
];

use constant _DOCUMENTED_SOURCES => [
	SOURCE_POD,
	SOURCE_INPUT_SPEC,
];

sub sources
{
	return @{_SOURCES()};
}

sub documented_sources
{
	return @{_DOCUMENTED_SOURCES()};
}

sub type_checks_source
{
	return SOURCE_VALIDATOR();
}

sub source_is_valid
{
	my ($source) = @_;

	return 0 unless defined($source) && !ref($source) && length($source);
	return scalar grep { $_ eq $source } sources();
}

sub source_is_documented
{
	my ($source) = @_;

	return 0 unless defined($source) && !ref($source);
	return scalar grep { $_ eq $source } documented_sources();
}

sub source_checks_types
{
	my ($source) = @_;

	return 0 unless defined($source) && !ref($source);
	return ($source eq SOURCE_VALIDATOR()) ? 1 : 0;
}

1;
