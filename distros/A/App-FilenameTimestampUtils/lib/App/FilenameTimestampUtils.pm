package App::FilenameTimestampUtils;

use strict;
use warnings;

use Filename::Timestamp ();
use Perinci::Object qw(envresmulti);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'App-FilenameTimestampUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{extract_timestamp_from_filename} = {
    v => 1.1,
    summary => 'Extract timestamp from filenames',
    args => {
        filenames => {
            schema => ['array*', of=>'filename*', min_len=>1],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub extract_timestamp_from_filename {
    my %args = @_;

    my $envres = envresmulti();

    for my $filename (@{ $args{filenames} }) {
        my $fres = Filename::Timestamp::extract_timestamp_from_filename(
            filename => $filename,
        );
        $fres ||= {};
        $fres->{filename} = $filename if @{ $args{filenames} } > 1;
        $fres = $fres->{epoch} unless $args{detail};
        $envres->add_result(
            200,
            "OK",
            {item_id => $filename, payload => $fres},
        );
    }

    $envres->as_struct;
}

1;
# ABSTRACT: CLIs for Filename::Timestamp

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FilenameTimestampUtils - CLIs for Filename::Timestamp

=head1 VERSION

This document describes version 0.001 of App::FilenameTimestampUtils (from Perl distribution App-FilenameTimestampUtils), released on 2024-12-21.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Filename::Timestamp:

=over

=item * L<extract-timestamp-from-filename>

=back

=head1 FUNCTIONS


=head2 extract_timestamp_from_filename

Usage:

 extract_timestamp_from_filename(%args) -> [$status_code, $reason, $payload, \%result_meta]

Extract timestamp from filenames.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<filenames>* => I<array[filename]>

(No description)

=item * B<quiet> => I<bool>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FilenameTimestampUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FilenameTimestampUtils>.

=head1 SEE ALSO

L<Filename::Timestamp>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FilenameTimestampUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
