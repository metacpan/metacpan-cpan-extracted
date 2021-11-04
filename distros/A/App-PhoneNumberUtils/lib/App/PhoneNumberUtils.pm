package App::PhoneNumberUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-03'; # DATE
our $DIST = 'App-PhoneNumberUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %SPEC;

our %arg0_phnum = (
    phnum => {
        schema => ['str*', match => qr/[0-9]/],
        req => 1,
        pos => 0,
    },
);

$SPEC{phone_number_info} = {
    v => 1.1,
    summary => 'Show information about a phone number',
    description => <<'_',

This utility uses <pm:Number::Phone> to get information for a phone number. For
certain countries, the information provided can be pretty detailed including
coordinate, whether the number is an adult line, and the operator name. For
other countries, the information provided is more basic including whether a
number is a mobile number.

_
    args => {
        %arg0_phnum,
    },
    examples => [
        {args=>{phnum=>'+442087712924'}},
        {args=>{phnum=>'+6281812345678'}},
    ],
};
sub phone_number_info {
    require Number::Phone;

    my %args = @_;

    my $np = Number::Phone->new($args{phnum})
        or return [400, "Invalid phone number"];
    [200, "OK", {
        is_valid => $np->is_valid,
        is_allocated => $np->is_allocated,
        is_in_use => $np->is_in_use,
        is_geographic => $np->is_geographic,
        is_fixed_line => $np->is_fixed_line,
        is_mobile => $np->is_mobile,
        is_pager => $np->is_pager,
        is_ipphone => $np->is_ipphone,
        is_isdn => $np->is_isdn,
        is_adult => $np->is_adult,
        is_personal => $np->is_personal,
        is_corporate => $np->is_corporate,
        is_government => $np->is_government,
        is_international => $np->is_international,
        is_network_service => $np->is_network_service,
        is_drama => $np->is_drama,

        country_code => $np->country_code,
        regulator => $np->regulator,
        areacode => $np->areacode,
        areaname => $np->areaname,
        location => $np->location,
        subscriber => $np->subscriber,
        operator => $np->operator,
        operator_ported => $np->operator_ported,
        #type => $np->type,
        format => $np->format,
        format_for_country => $np->format_for_country,
    }];
}

$SPEC{normalize_phone_number} = {
    v => 1.1,
    summary => 'Normalize phone number',
    description => <<'_',

This utility uses <pm:Number::Phone> to format the phone number, which supports
country-specific formatting rules.

_
    args => {
        %arg0_phnum,
    },
    examples => [
        {args=>{phnum=>'+442087712924'}},
        {args=>{phnum=>'+6281812345678'}},
    ],
};
sub normalize_phone_number {
    require Number::Phone;

    my %args = @_;

    my $np = Number::Phone->new($args{phnum})
        or return [400, "Invalid phone number"];
    [200, "OK", $np->format];
}

$SPEC{phone_number_is_valid} = {
    v => 1.1,
    summary => 'Check whether phone number is valid',
    description => <<'_',

This utility uses <pm:Number::Phone> to determine whether a phone number is
valid.

_
    args => {
        %arg0_phnum,
        quiet => {
            schema => 'true*',
            cmdline_aliases => {q=>{}},
        },
    },
    examples => [
        {args=>{phnum=>'+442087712924'}},
        {args=>{phnum=>'+4420877129240'}},
        {args=>{phnum=>'+6281812345678'}},
        {args=>{phnum=>'+6281812345'}},
    ],
};
sub phone_number_is_valid {
    require Number::Phone;

    my %args = @_;

    my $valid = 0;
    {
        my $np = Number::Phone->new($args{phnum}) or last;
        $valid = 1;
    }

    return [200, "OK", $valid, {
        $args{quiet} ? ('cmdline.result' => '') : (),
        'cmdline.exit_code' => $valid ? 0:1,
    }];
}

1;
# ABSTRACT: Utilities related to phone numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PhoneNumberUtils - Utilities related to phone numbers

=head1 VERSION

This document describes version 0.002 of App::PhoneNumberUtils (from Perl distribution App-PhoneNumberUtils), released on 2021-06-03.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<normalize-phone-number>

=item * L<phone-number-info>

=item * L<phone-number-is-valid>

=back

=head1 FUNCTIONS


=head2 normalize_phone_number

Usage:

 normalize_phone_number(%args) -> [$status_code, $reason, $payload, \%result_meta]

Normalize phone number.

Examples:

=over

=item * Example #1:

 normalize_phone_number(phnum => "+442087712924"); # -> [200, "OK", "+44 20 8771 2924", {}]

=item * Example #2:

 normalize_phone_number(phnum => "+6281812345678"); # -> [200, "OK", "+62 818 1234 5678", {}]

=back

This utility uses L<Number::Phone> to format the phone number, which supports
country-specific formatting rules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<phnum>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 phone_number_info

Usage:

 phone_number_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show information about a phone number.

Examples:

=over

=item * Example #1:

 phone_number_info(phnum => "+442087712924");

Result:

 [
   200,
   "OK",
   {
     areacode           => 20,
     areaname           => "London",
     country_code       => 44,
     format             => "+44 20 8771 2924",
     format_for_country => "+44 20 8771 2924",
     is_adult           => 0,
     is_allocated       => 1,
     is_corporate       => 0,
     is_drama           => 0,
     is_fixed_line      => undef,
     is_geographic      => 1,
     is_government      => undef,
     is_in_use          => undef,
     is_international   => undef,
     is_ipphone         => 0,
     is_isdn            => undef,
     is_mobile          => 0,
     is_network_service => 0,
     is_pager           => 0,
     is_personal        => 0,
     is_valid           => 1,
     location           => [51.38309, -0.336079],
     operator           => "BT",
     operator_ported    => undef,
     regulator          => "OFCOM, http://www.ofcom.org.uk/",
     subscriber         => 87712924,
   },
   {},
 ]

=item * Example #2:

 phone_number_info(phnum => "+6281812345678");

Result:

 [
   200,
   "OK",
   {
     areacode           => undef,
     areaname           => undef,
     country_code       => 62,
     format             => "+62 818 1234 5678",
     format_for_country => "+62 818-1234-5678",
     is_adult           => undef,
     is_allocated       => undef,
     is_corporate       => undef,
     is_drama           => undef,
     is_fixed_line      => 0,
     is_geographic      => 0,
     is_government      => undef,
     is_in_use          => undef,
     is_international   => undef,
     is_ipphone         => undef,
     is_isdn            => undef,
     is_mobile          => 1,
     is_network_service => undef,
     is_pager           => undef,
     is_personal        => undef,
     is_valid           => 1,
     location           => undef,
     operator           => undef,
     operator_ported    => undef,
     regulator          => undef,
     subscriber         => undef,
   },
   {},
 ]

=back

This utility uses L<Number::Phone> to get information for a phone number. For
certain countries, the information provided can be pretty detailed including
coordinate, whether the number is an adult line, and the operator name. For
other countries, the information provided is more basic including whether a
number is a mobile number.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<phnum>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 phone_number_is_valid

Usage:

 phone_number_is_valid(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether phone number is valid.

Examples:

=over

=item * Example #1:

 phone_number_is_valid(phnum => "+442087712924"); # -> [200, "OK", 1, { "cmdline.exit_code" => 0 }]

=item * Example #2:

 phone_number_is_valid(phnum => "+4420877129240"); # -> [200, "OK", 0, { "cmdline.exit_code" => 1 }]

=item * Example #3:

 phone_number_is_valid(phnum => "+6281812345678"); # -> [200, "OK", 1, { "cmdline.exit_code" => 0 }]

=item * Example #4:

 phone_number_is_valid(phnum => "+6281812345"); # -> [200, "OK", 0, { "cmdline.exit_code" => 1 }]

=back

This utility uses L<Number::Phone> to determine whether a phone number is
valid.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<phnum>* => I<str>

=item * B<quiet> => I<true>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PhoneNumberUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PhoneNumberUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PhoneNumberUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Number::Phone>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
