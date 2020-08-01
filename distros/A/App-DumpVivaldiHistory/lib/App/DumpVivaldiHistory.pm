package App::DumpVivaldiHistory;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-19'; # DATE
our $DIST = 'App-DumpVivaldiHistory'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{dump_vivaldi_history} = {
    v => 1.1,
    summary => 'Dump Vivaldi history',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        profiles => {
            summary => 'Select profile(s) to dump',
            schema => ['array*', of=>'vivaldi::profile_name*', 'x.perl.coerce_rules'=>['From_str::comma_sep']],
            description => <<'_',

You can choose to dump history for only some profiles. By default, if this
option is not specified, history from all profiles will be dumped.

_
        },
        copy_size_limit => {
            schema => 'posint*',
            default => 100*1024*1024,
            description => <<'_',

Vivaldi often locks the History database for a long time. If the size of the
database is not too large (determine by checking against this limit), then the
script will copy the file to a temporary file and extract the data from the
copied database.

_
        },
    },
};
sub dump_vivaldi_history {
    require App::DumpChromeHistory;

    App::DumpChromeHistory::dump_chrome_history(
        _app => 'vivaldi',
        _chrome_dir => "$ENV{HOME}/.config/vivaldi",
    );
}

1;
# ABSTRACT: Dump Vivaldi history

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DumpVivaldiHistory - Dump Vivaldi history

=head1 VERSION

This document describes version 0.001 of App::DumpVivaldiHistory (from Perl distribution App-DumpVivaldiHistory), released on 2020-04-19.

=head1 SYNOPSIS

See the included script L<dump-vivaldi-history>.

=head1 FUNCTIONS


=head2 dump_vivaldi_history

Usage:

 dump_vivaldi_history(%args) -> [status, msg, payload, meta]

Dump Vivaldi history.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<copy_size_limit> => I<posint> (default: 104857600)

Vivaldi often locks the History database for a long time. If the size of the
database is not too large (determine by checking against this limit), then the
script will copy the file to a temporary file and extract the data from the
copied database.

=item * B<detail> => I<bool>

=item * B<profiles> => I<array[vivaldi::profile_name]>

Select profile(s) to dump.

You can choose to dump history for only some profiles. By default, if this
option is not specified, history from all profiles will be dumped.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DumpVivaldiHistory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DumpVivaldiHistory>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DumpVivaldiHistory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DumpChromeHistory>

L<App::DumpFirefoxHistory>

L<App::DumpOperaHistory>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
