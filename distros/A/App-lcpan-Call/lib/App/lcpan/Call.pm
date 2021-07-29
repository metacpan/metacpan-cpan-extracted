package App::lcpan::Call;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-21'; # DATE
our $DIST = 'App-lcpan-Call'; # DIST
our $VERSION = '0.120'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(call_lcpan_script check_lcpan);

my %common_args = (
    max_age => {
        summary => 'Maximum index age (in seconds)',
        schema => 'duration',
        description => <<'_',

If unspecified, will look at `LCPAN_MAX_AGE` environment variable. If that is
also undefined, will default to 14 days.

_
    },
);

$SPEC{call_lcpan_script} = {
    v => 1.1,
    summary => '"Call" lcpan script',
    args => {
        %common_args,
        argv => {
            schema => ['array*', of=>'str*'],
            default => [],
        },
    },
};
sub call_lcpan_script {
    require Perinci::CmdLine::Call;

    my %args = @_;

    state $checked;
    unless ($checked) {
        my $check_res = check_lcpan(%args);
        die "$check_res->[1]\n" unless $check_res->[0] == 200;
    }

    Perinci::CmdLine::Call::call_cli_script(
        script => 'lcpan',
        argv   => $args{'argv'},
    );
}

$SPEC{check_lcpan} = {
    v => 1.1,
    summary => "Check that local CPAN mirror exists and is fairly recent",
    description => <<'_',

Will return status 200 if `lcpan` script is installed (available from PATH),
local CPAN mirror exists, and is fairly recent and queryable. This routine will
actually attempt to run "lcpan stats-last-index-time" and return the result if
the result is 200 *and* the index is updated quite recently. By default "quite
recently" is defined as not older than 2 weeks or whatever LCPAN_MAX_AGE says
(in seconds).

_
    args => {
        %common_args,
    },
};
sub check_lcpan {
    require File::Which;
    require Perinci::CmdLine::Call;

    my %args;

    File::Which::which("lcpan")
          or die "lcpan is not available, please install it first\n";
    my $res = Perinci::CmdLine::Call::call_cli_script(
        script => 'lcpan',
        argv   => ['stats-last-index-time'],
    );
    return [412, "Can't 'lcpan stats': $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    my $stats = $res->[2];
    my $max_age = $args{max_age} // $ENV{LCPAN_MAX_AGE} // 14*86400;
    my $max_age_in_days = sprintf("%g", $max_age / 86400);
    my $age = time - $stats->{raw_last_index_time};
    my $age_in_days = sprintf("%g", $age / 86400);
    if ($age > $max_age) {
        return [412, "lcpan index is over $max_age_in_days day(s) old ".
                    "($age_in_days), please refresh it first with ".
                    "'lcpan update'"];
    }
    $res;
}

1;
# ABSTRACT: Check that local CPAN mirror exists and is fairly recent

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Call - Check that local CPAN mirror exists and is fairly recent

=head1 VERSION

This document describes version 0.120 of App::lcpan::Call (from Perl distribution App-lcpan-Call), released on 2021-07-21.

=head1 FUNCTIONS


=head2 call_lcpan_script

Usage:

 call_lcpan_script(%args) -> [$status_code, $reason, $payload, \%result_meta]

"Call" lcpan script.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<argv> => I<array[str]> (default: [])

=item * B<max_age> => I<duration>

Maximum index age (in seconds).

If unspecified, will look at C<LCPAN_MAX_AGE> environment variable. If that is
also undefined, will default to 14 days.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_lcpan

Usage:

 check_lcpan(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check that local CPAN mirror exists and is fairly recent.

Will return status 200 if C<lcpan> script is installed (available from PATH),
local CPAN mirror exists, and is fairly recent and queryable. This routine will
actually attempt to run "lcpan stats-last-index-time" and return the result if
the result is 200 I<and> the index is updated quite recently. By default "quite
recently" is defined as not older than 2 weeks or whatever LCPAN_MAX_AGE says
(in seconds).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max_age> => I<duration>

Maximum index age (in seconds).

If unspecified, will look at C<LCPAN_MAX_AGE> environment variable. If that is
also undefined, will default to 14 days.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head2 LCPAN_MAX_AGE => int

Set the default of C<max_age>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-Call>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-Call>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-Call>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
