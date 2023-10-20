package App::EANUtils;

use 5.010001;
use strict;
use warnings;

use Perinci::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-28'; # DATE
our $DIST = 'App-EANUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to EAN (International/European Article Number)',
};


our %argspecopt_quiet = (
    quiet => {
        summary => "If set to true, don't output message to STDOUT",
        schema => 'bool*',
        cmdline_aliases => {q=>{}},
    },
);

$SPEC{calc_ean8} = {
    v => 1.1,
    summary => "Calculate check digit of EAN-8 number(s)",
    args => {
        numbers => {
            summary => 'EAN-8 numbers without the check digit',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'number',
            schema => ['array*', of=>'ean8_without_check_digit*'],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    examples => [
        {
            summary => 'Calculate a single number',
            argv => ['9638-507'],
        },
        {
            summary => 'Calculate a couple of numbers, via pipe',
            src_plang => 'bash',
            src => 'echo -e "9638-507\\n1234567" | [[prog]]',
        },
    ],
};
sub calc_ean8 {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $res = [200, "OK", []];
    for my $num (@{ $args{numbers} }) {
        push @{$res->[2]}, Algorithm::CheckDigits::CheckDigits('ean')->complete($num);
    }
    $res;
}

$SPEC{calc_ean13} = {
    v => 1.1,
    summary => "Calculate check digit of EAN-13 number(s)",
    args => {
        numbers => {
            summary => 'EAN-13 numbers without the check digit',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'number',
            schema => ['array*', of=>'ean13_without_check_digit*'],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    examples => [
        {
            summary => 'Calculate a single number',
            argv => ['5-901234-12345'],
        },
        {
            summary => 'Calculate a couple of numbers, via pipe',
            src_plang => 'bash',
            src => 'echo -e "5-901234-12345\\n123456789012" | [[prog]]',
        },
    ],
};
sub calc_ean13 {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $res = [200, "OK", []];
    for my $num (@{ $args{numbers} }) {
        push @{$res->[2]}, Algorithm::CheckDigits::CheckDigits('ean')->complete($num);
    }
    $res;
}

$SPEC{check_ean8} = {
    v => 1.1,
    summary => "Check EAN-8 number(s)",
    description => <<'_',

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

_
    args => {
        ean8_numbers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'ean8_number',
            schema => ['array*', of=>'ean8_unvalidated*'],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        %argspecopt_quiet,
    },
    examples => [
        {
            summary => 'Check a single EAN-8 number (valid, exit code will be zero, message output to STDOUT)',
            argv => ['9638-5074'],
        },
        {
            summary => 'Check a single EAN-8 number (valid, exit code will be zero, no message)',
            argv => ['-q', '9638-5074'],
        },
        {
            summary => 'Check a single EAN-8 number (invalid, exit code is non-zero, message output to STDOUT)',
            argv => ['9638-5070'],
            status => 400,
        },
        {
            summary => 'Check a single EAN-8 number (invalid, exit code is non-zero, no message)',
            argv => ['-q', '9638-5070'],
            status => 400,
        },
        {
            summary => 'Check a couple of EAN-8 numbers, via pipe, JSON output',
            src_plang => 'bash',
            src => 'echo -e "9638-5074\\n12345678" | [[prog]] --json',
        },
    ],
};
sub check_ean8 {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $envres = envresmulti();
    for my $ean8 (@{ $args{ean8_numbers} }) {
        if (length $ean8 != 8) {
            $envres->add_result(400, "Number of digits is not 8", {item_id=>$ean8});
            print "$ean8 is INVALID (number of digits is not 8)\n" unless $args{quiet};
        } elsif (!Algorithm::CheckDigits::CheckDigits('ean')->is_valid($ean8)) {
            $envres->add_result(400, "Incorrect check digit", {item_id=>$ean8}) ;
            print "$ean8 is INVALID (incorrect check digit)\n" unless $args{quiet};
        } else {
            $envres->add_result(200, "OK", {item_id=>$ean8});
            print "$ean8 is valid\n" unless $args{quiet};
        }
    }
    $envres->as_struct;
}

$SPEC{check_ean13} = {
    v => 1.1,
    summary => "Check EAN-13 number(s)",
    description => <<'_',

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

_
    args => {
        ean13_numbers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'ean13_number',
            schema => ['array*', of=>'ean13_unvalidated*'],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        %argspecopt_quiet,
    },
    examples => [
        {
            summary => 'Check a single EAN-13 number (valid, exit code will be zero, message will be printed to STDOUT)',
            argv => ['5-901234-123457'],
        },
        {
            summary => 'Check a single EAN-13 number (valid, exit code will be zero, no message)',
            argv => ['-q', '5-901234-123457'],
        },
        {
            summary => 'Check a single EAN-13 number (invalid, exit code is non-zero, message output to STDOUT)',
            argv => ['5-901234-123450'],
            status => 400,
        },
        {
            summary => 'Check a single EAN-13 number (invalid, exit code is non-zero, no message)',
            argv => ['-q', '5-901234-123450'],
            status => 400,
        },
        {
            summary => 'Check a couple of EAN-13 numbers, via pipe, JSON output',
            src_plang => 'bash',
            src => 'echo -e "5-901234-123457\\n123-4567890-123" | [[prog]] -q --json',
        },
    ],
};
sub check_ean13 {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $envres = envresmulti();
    for my $ean13 (@{ $args{ean13_numbers} }) {
        if (length $ean13 != 13) {
            $envres->add_result(400, "Number of digits is not 13", {item_id=>$ean13});
            print "$ean13 is INVALID (number of digits is not 13)\n" unless $args{quiet};
        } elsif (!Algorithm::CheckDigits::CheckDigits('ean')->is_valid($ean13)) {
            $envres->add_result(400, "Invalid checksum digit", {item_id=>$ean13}) ;
            print "$ean13 is INVALID (incorrect check digit)\n" unless $args{quiet};
        } else {
            $envres->add_result(200, "OK", {item_id=>$ean13});
            print "$ean13 is valid\n" unless $args{quiet};
        }
    }
    $envres->as_struct;
}

1;
# ABSTRACT: Utilities related to EAN (International/European Article Number)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::EANUtils - Utilities related to EAN (International/European Article Number)

=head1 VERSION

This document describes version 0.003 of App::EANUtils (from Perl distribution App-EANUtils), released on 2023-01-28.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to EAN
(International/European Article Number):

=over

=item * L<calc-ean13>

=item * L<calc-ean8>

=item * L<check-ean13>

=item * L<check-ean8>

=back

=head1 FUNCTIONS


=head2 calc_ean13

Usage:

 calc_ean13(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate check digit of EAN-13 number(s).

Examples:

=over

=item * Calculate a single number:

 calc_ean13(numbers => ["5-901234-12345"]); # -> [200, "OK", [5901234123457], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<numbers>* => I<array[ean13_without_check_digit]>

EAN-13 numbers without the check digit.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 calc_ean8

Usage:

 calc_ean8(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate check digit of EAN-8 number(s).

Examples:

=over

=item * Calculate a single number:

 calc_ean8(numbers => ["9638-507"]); # -> [200, "OK", [96385074], {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<numbers>* => I<array[ean8_without_check_digit]>

EAN-8 numbers without the check digit.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_ean13

Usage:

 check_ean13(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check EAN-13 number(s).

Examples:

=over

=item * Check a single EAN-13 number (valid, exit code will be zero, message will be printed to STDOUT):

 check_ean13(ean13_numbers => ["5-901234-123457"]);

Result:

 [
   200,
   "All success",
   undef,
   {
     results => [{ item_id => 5901234123457, message => "OK", status => 200 }],
   },
 ]

=item * Check a single EAN-13 number (valid, exit code will be zero, no message):

 check_ean13(ean13_numbers => ["5-901234-123457"], quiet => 1);

Result:

 [
   200,
   "All success",
   undef,
   {
     results => [{ item_id => 5901234123457, message => "OK", status => 200 }],
   },
 ]

=item * Check a single EAN-13 number (invalid, exit code is non-zero, message output to STDOUT):

 check_ean13(ean13_numbers => ["5-901234-123450"]);

Result:

 [
   400,
   "Invalid checksum digit",
   undef,
   {
     results => [
       {
         item_id => 5901234123450,
         message => "Invalid checksum digit",
         status  => 400,
       },
     ],
   },
 ]

=item * Check a single EAN-13 number (invalid, exit code is non-zero, no message):

 check_ean13(ean13_numbers => ["5-901234-123450"], quiet => 1);

Result:

 [
   400,
   "Invalid checksum digit",
   undef,
   {
     results => [
       {
         item_id => 5901234123450,
         message => "Invalid checksum digit",
         status  => 400,
       },
     ],
   },
 ]

=back

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ean13_numbers>* => I<array[ean13_unvalidated]>

(No description)

=item * B<quiet> => I<bool>

If set to true, don't output message to STDOUT.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_ean8

Usage:

 check_ean8(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check EAN-8 number(s).

Examples:

=over

=item * Check a single EAN-8 number (valid, exit code will be zero, message output to STDOUT):

 check_ean8(ean8_numbers => ["9638-5074"]);

Result:

 [
   200,
   "All success",
   undef,
   {
     results => [{ item_id => 96385074, message => "OK", status => 200 }],
   },
 ]

=item * Check a single EAN-8 number (valid, exit code will be zero, no message):

 check_ean8(ean8_numbers => ["9638-5074"], quiet => 1);

Result:

 [
   200,
   "All success",
   undef,
   {
     results => [{ item_id => 96385074, message => "OK", status => 200 }],
   },
 ]

=item * Check a single EAN-8 number (invalid, exit code is non-zero, message output to STDOUT):

 check_ean8(ean8_numbers => ["9638-5070"]);

Result:

 [
   400,
   "Incorrect check digit",
   undef,
   {
     results => [
       { item_id => 96385070, message => "Incorrect check digit", status => 400 },
     ],
   },
 ]

=item * Check a single EAN-8 number (invalid, exit code is non-zero, no message):

 check_ean8(ean8_numbers => ["9638-5070"], quiet => 1);

Result:

 [
   400,
   "Incorrect check digit",
   undef,
   {
     results => [
       { item_id => 96385070, message => "Incorrect check digit", status => 400 },
     ],
   },
 ]

=back

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ean8_numbers>* => I<array[ean8_unvalidated]>

(No description)

=item * B<quiet> => I<bool>

If set to true, don't output message to STDOUT.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-EANUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-EANUtils>.

=head1 SEE ALSO

More general utilities related to check digits: L<App::CheckDigitsUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-EANUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
