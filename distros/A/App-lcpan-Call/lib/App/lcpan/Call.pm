package App::lcpan::Call;

our $DATE = '2016-10-09'; # DATE
our $VERSION = '0.11'; # VERSION

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
# ABSTRACT: "Call" lcpan script

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Call - "Call" lcpan script

=head1 VERSION

This document describes version 0.11 of App::lcpan::Call (from Perl distribution App-lcpan-Call), released on 2016-10-09.

=head1 FUNCTIONS


=head2 call_lcpan_script(%args) -> [status, msg, result, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 check_lcpan(%args) -> [status, msg, result, meta]

Check that local CPAN mirror exists and is fairly recent.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<max_age> => I<duration>

Maximum index age (in seconds).

If unspecified, will look at C<LCPAN_MAX_AGE> environment variable. If that is
also undefined, will default to 14 days.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

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

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
