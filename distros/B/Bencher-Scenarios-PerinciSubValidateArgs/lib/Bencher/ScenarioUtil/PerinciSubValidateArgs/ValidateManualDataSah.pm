package Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah;

our $DATE = '2016-05-25'; # DATE
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Data::Sah;

use Exporter qw(import);
our @EXPORT_OK = qw(foo);

our %SPEC;

my $v_a1 = Data::Sah::gen_validator('int*', {return_type=>'str'});
my $v_a2 = Data::Sah::gen_validator([array => of=>'int*'], {return_type=>'str'});

$SPEC{foo} = {
    v => 1.1,
    args => {
        a1 => {
            schema => 'int*',
            req => 1,
        },
        a2 => {
            schema => [array => of=>'int*'],
            default => [1],
        },
    },
};
sub foo {
    my %args = @_;
    my $err;
    exists($args{a1}) or return [400, "Missing required argument 'a1'"];
    for (keys %args) {
        ($_ eq 'a1' || $_ eq 'a2') or return [400, "Unknown argument '$_'"];
    }
    if (exists $args{a1}) {
        $err = $v_a1->($args{a1});
        if ($err) { return [400, "Validation failed for argument 'a1': $err"] }
    }
    if (!defined($args{a2})) { $args{a2} = [1] }
    if (exists $args{a2}) {
        $err = $v_a2->($args{a2});
        if ($err) { return [400, "Validation failed for argument 'a2': $err"] }
    }
    [200, "OK"];
}

1;
# ABSTRACT: An example module that uses hand-written validation code, but the type validators are generated using Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah - An example module that uses hand-written validation code, but the type validators are generated using Data::Sah

=head1 VERSION

This document describes version 0.004 of Bencher::ScenarioUtil::PerinciSubValidateArgs::ValidateManualDataSah (from Perl distribution Bencher-Scenarios-PerinciSubValidateArgs), released on 2016-05-25.

=head1 FUNCTIONS


=head2 foo(%args) -> [status, msg, result, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<a1>* => I<int>

=item * B<a2> => I<array[int]> (default: [1])

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-PerinciSubValidateArgs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-PerinciSubValidateArgs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
