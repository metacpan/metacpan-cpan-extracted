## no critic: InputOutput::RequireBriefOpen

package App::pdfgrep;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-13'; # DATE
our $DIST = 'App-PDFUtils'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use IPC::System::Options qw(system);
use Perinci::Sub::Util qw(gen_modified_sub);

our %SPEC;

gen_modified_sub(
    output_name => 'pdfgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines matching text in PDF files',
    description => <<'_',

This is a wrapper for pdftotext + grep-like utility that is based on
<pm:AppBase::Grep>. The unique features include multiple patterns and
`--dash-prefix-inverts`.

_
    add_args    => {
        files => {
            description => <<'_',

If not specified, will search for all PDF files recursively from the current
directory.

_
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            pos => 1,
            slurpy => 1,
        },
        # XXX recursive (-r)
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{examples} = [
        ];
        $meta->{links} = [
        ];
        $meta->{deps} = {
            prog => 'pdftotext',
        };
    },
    output_code => sub {
        my %args = @_;
        my ($tempdir, $fh, $file);

        my @files = @{ $args{files} // [] };
        if ($args{regexps} && @{ $args{regexps} }) {
            unshift @files, delete $args{pattern};
        }
        unless (@files) {
            require File::Find::Rule;
            @files = File::Find::Rule->new->file->name("*.pdf", "*.PDF")->in(".");
            unless (@files) { return [200, "No PDF files to search against"] }
        }

        my $show_label = @files > 1 ? 1:0;

        $args{_source} = sub {
          READ_LINE:
            {
                if (!defined $fh) {
                    return unless @files;

                    unless (defined $tempdir) {
                        require File::Temp;
                        $tempdir = File::Temp::tempdir(CLEANUP=>$ENV{DEBUG} ? 0:1);
                    }

                    $file = shift @files;
                    require File::Basename;
                    my $tempfile = File::Basename::basename($file) . ".txt";
                    my $i = 0;
                    while (1) {
                        my $tempfile2 = $tempfile . ($i ? ".$i" : "");
                        do { $tempfile = $tempfile2; last } unless -e "$tempdir/$tempfile2";
                        $i++;
                    }

                    log_trace "Running pdftotext $file $tempdir/$tempfile ...";
                    system "pdftotext", $file, "$tempdir/$tempfile"; # XXX check error

                    open $fh, "<", "$tempdir/$tempfile" or do {
                        warn "pdfgrep: Can't open '$tempdir/$tempfile': $!, skipped\n";
                        undef $fh;
                    };
                    redo READ_LINE;
                }

                my $line = <$fh>;
                if (defined $line) {
                    return ($line, $show_label ? $file : undef);
                } else {
                    undef $fh;
                    redo READ_LINE;
                }
            }
        };

        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines matching text in PDF files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pdfgrep - Print lines matching text in PDF files

=head1 VERSION

This document describes version 0.009 of App::pdfgrep (from Perl distribution App-PDFUtils), released on 2021-10-13.

=head1 FUNCTIONS


=head2 pdfgrep

Usage:

 pdfgrep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines matching text in PDF files.

This is a wrapper for pdftotext + grep-like utility that is based on
L<AppBase::Grep>. The unique features include multiple patterns and
C<--dash-prefix-inverts>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Require all patterns to match, instead of just one.

=item * B<color> => I<str> (default: "auto")

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<dash_prefix_inverts> => I<bool>

When given pattern that starts with dash "-FOO", make it to mean "^(?!.*FOO)".

This is a convenient way to search for lines that do not match a pattern.
Instead of using C<-v> to invert the meaning of all patterns, this option allows
you to invert individual pattern using the dash prefix, which is also used by
Google search and a few other search engines.

=item * B<files> => I<array[filename]>

If not specified, will search for all PDF files recursively from the current
directory.

=item * B<ignore_case> => I<bool>

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

=item * B<pattern> => I<str>

=item * B<quiet> => I<true>

=item * B<regexps> => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-PDFUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDFUtils>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDFUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
