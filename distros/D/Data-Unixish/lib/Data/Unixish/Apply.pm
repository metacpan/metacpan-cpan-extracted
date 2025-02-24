package Data::Unixish::Apply;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Data::Unixish::Util qw(%common_args filter_args);
use Module::Load;
use Package::Util::Lite qw(package_exists);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION

our %SPEC;

$SPEC{apply} = {
    v => 1.1,
    summary => 'Apply one or more dux functions',
    args => {
        in => {
            schema => ['any'], # XXX stream
            req => 1,
        },
        functions => {
            summary => 'Function(s) to apply',
            schema => ['any*', of => [
                'str*',
                ['array*', of => ['any' => of => [['str*'], ['array*']]]],
            ]],
            req => 1,
            description => <<'MARKDOWN',

A list of functions to apply. Each element is either a string (function name),
or a 2-element array (function names + arguments hashref). If you do not want to
specify arguments to a function, you can use a string.

Example:

    [
        'sort', # no arguments (all default)
        'date', # no arguments (all default)
        ['head', {items=>5}], # specify arguments
    ]

MARKDOWN
        },

    },
};
sub apply {
    my %args = @_;
    my $in0 = $args{in}        or return [400, "Please specify in"];
    my $ff0 = $args{functions} or return [400, "Please specify functions"];
    $ff0 = [$ff0] unless ref($ff0) eq 'ARRAY';

    # special case
    unless (@$ff0) {
        return [200, "No processing done", $in0];
    }

    my @ff;
    my ($in, $out);
    for my $i (0..@$ff0-1) {
        my $f = $ff0->[$i];
        #$log->tracef("Applying dux function %s ...", $f);
        my ($fn0, $fargs);
        if (ref($f) eq 'ARRAY') {
            $fn0 = $f->[0];
            $fargs = filter_args($f->[1]) // {};
        } else {
            $fn0 = $f;
            $fargs = {};
        }

        if ($i == 0) {
            $in = $in0;
        } else {
            $in = $out;
        }
        $out = [];

        # XXX load all functions before applying, like in Unix pipes
        my $pkg = "Data::Unixish::$fn0";
        unless (package_exists($pkg)) {
            eval { load $pkg; 1 } or
                return [500,
                        "Can't load package for dux function $fn0: $@"];
        }

        my $fnl = $fn0; $fnl =~ s/.+:://;
        my $fn = "Data::Unixish::$fn0\::$fnl";
        return [500, "Subroutine &$fn not defined"] unless defined &$fn;

        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
        my $res = $fn->(%$fargs, in=>$in, out=>$out);
        unless ($res->[0] == 200) {
            return [500, "Function $fn0 did not return success: ".
                        "$res->[0] - $res->[1]"];
        }
    }

    [200, "OK", $out];
}

1;
# ABSTRACT: Apply one or more dux functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::Apply - Apply one or more dux functions

=head1 VERSION

This document describes version 1.574 of Data::Unixish::Apply (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

 use Data::Unixish::Apply;
 Data::Unixish::Apply::apply(
     in => [1, 4, 2, 6, 7, 10],
     functions => ['sort', ['printf', {fmt=>'%04d'}]],
 ); # will result in [qw/0001 0002 0004 0006 0007 0010/],

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 apply

Usage:

 apply(%args) -> [$status_code, $reason, $payload, \%result_meta]

Apply one or more dux functions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<functions>* => I<str|array[str|array]>

Function(s) to apply.

A list of functions to apply. Each element is either a string (function name),
or a 2-element array (function names + arguments hashref). If you do not want to
specify arguments to a function, you can use a string.

Example:

 [
     'sort', # no arguments (all default)
     'date', # no arguments (all default)
     ['head', {items=>5}], # specify arguments
 ]

=item * B<in>* => I<any>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
