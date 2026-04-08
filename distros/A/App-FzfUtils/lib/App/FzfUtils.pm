package App::FzfUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-04-08'; # DATE
our $DIST = 'App-FzfUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to fzf',
};

$SPEC{fzf2clip} = {
    v => 1.1,
    summary => "Select using fzf, then add selection to clipboard",
    description => <<'MARKDOWN',

This is basically a shortcut for:

    % fzf < input.txt | clipadd

where <prog:clipadd> is a utility from <pm:App::ClipboardUtils>.

MARKDOWN
    args => {
        input => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            pos => 0,
        },
        tee => {
            summary => 'In addition to adding to clipboard, also print to STDOUT',
            schema => 'bool*',
            cmdline_aliases => {t=>{}},
        },
    },
    deps => {
        all => [
            {prog => 'fzf'},
            #{prog => 'clipadd'},
        ],
    },
};
sub fzf2clip {
    require IPC::Open2;
    require Clipboard::Any;

    my %args = @_;

    my $input = $args{input};

    my $pid = IPC::Open2::open2(my $out, my $in, "fzf");
    for my $line (split /^/m, $input) {
        print $in $line;
    }
    close $in;
    my $result;
    {
        local $/;
        $result = <$out>;
        chomp($result) if defined $result;
    }
    close $out;
    waitpid($pid, 0);

  ADD_CLIPBOARD: {
        my $res = Clipboard::Any::add_clipboard_content(content => $result);
        return [500, "Can't add to clipboard: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
    }

    [200, "OK", $args{tee} ? $result : ""];
}

$SPEC{fzf2clip_loop} = {
    v => 1.1,
    summary => "Like fzf2clip, but loop/repeat",
    description => <<'MARKDOWN',

This is basically a shortcut for:

    % fzf --bind 'enter:execute(clipadd {})' < input.txt

where <prog:clipadd> is a utility from <pm:App::ClipboardUtils>.

MARKDOWN
    args => {
        input => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            pos => 0,
        },
    },
    deps => {
        all => [
            {prog => 'fzf'},
            {prog => 'clipadd'},
        ],
    },
};
sub fzf2clip_loop {
    require IPC::Open2;
    require Clipboard::Any;

    my %args = @_;

    my $input = $args{input};

    my $pid = IPC::Open2::open2(my $out, my $in, q[fzf --bind 'enter:execute-silent(clipadd {})']);
    for my $line (split /^/m, $input) {
        print $in $line;
    }
    close $in;
    close $out;
    waitpid($pid, 0);

    [200, "OK"];
}

$SPEC{cs_select} = {
    v => 1.1,
    summary => "Select entries from template to clipboard",
    description => <<'MARKDOWN',

This is basically similar to:

    % fzf --bind 'enter:execute(clipadd {})' < template.txt

except that it does some pre-processing to let each template entry be a
multiple-line text, and later do post-processing so the original entry is added
to the clipboard.

**Template format**

Template is an Org file with a particular format, where each entry is put under
a level-2 heading. The level-1 heading can be used for grouping/categorizing.
For example:

    * Product > P1
    ** Does P1 need to be replaced every 5 years?  :replacement:clipadd_1:
    Yes, ideally every 3-5 years.
    ** How to maintain P1 so it is in a good condition and can last longer?
    Wash after every use, then dry.
    Keep it clean.
    And of course replace after 3-5 years.
    * Product > P2
    ** Entry 1  :clipadd_2:
    ...
    ** Entry 2
    ...
    * General > Support
    ** Entry 3
    ...
    ** Entry 4
    ...

Before feeding to `fzf`, this utility will convert each entry into a single
line:

    [id=1][title=Does P1 need to be replaced every 5 years?]Yes, ideally every 3-5 years.[category=Product > P1][tag=replacement][tag=clipadd_1]
    [id=2][title=How to maintain P1 so it is in a good condition and can last longer?]Wash after every use, then dry. Keep it clean. And of course replace after 3-5 years.[category=Product > P1]
    [id=3][title=Entry 1]...[tag=clipadd_2][category=Product > P2]
    [id=4][title=Entry 2]...[category=Product > P2]
    [id=5][title=Entry 3]...[category=General > Support]
    [id=6][title=Entry 4]...[category=General > Support]

after selection, another script (<prog:cs-select-helper>) will turn back the
single-line entry into the original.

MARKDOWN
    args => {
        template => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            pos => 0,
        },
        wrap => {
            schema => 'posint*',
            cmdline_aliases => {w=>{}},
        },
    },
    deps => {
        all => [
            {prog => 'fzf'},
            {prog => 'clipadd'},
        ],
    },
};
sub cs_select {
    require Clipboard::Any;
    require File::Temp;
    require IPC::Open2;
    require JSON::PP;
    require Org::Parser::Tiny;
    require Text::ANSI::Util;

    my %args = @_;

    my $template = $args{template};
    my $doc = Org::Parser::Tiny->new->parse($template);

    my @lines;
    my $jsonfile;
  PREPROCESS_TEMPLATE: {
        my $dict = {};
        my $id = 0;
        for my $h1 (grep { $_->isa("Org::Parser::Tiny::Node::Headline") && $_->level == 1 } @{ $doc->children }) {
            my $category = $h1->title;
            my @tags = @{ $h1->tags };
            for my $h2 (grep { $_->isa("Org::Parser::Tiny::Node::Headline") && $_->level == 2 } @{ $h1->children }) {
                $id++;
                my $title = $h2->title;
                my $content = $h2->as_string;
                $content =~ s/\A.+\R//; # dump the raw heading

                my $clip_content;
                if ($args{wrap}) {
                    $clip_content = $title . ":\n" . Text::ANSI::Util::ta_wrap($content, $args{wrap});
                } else {
                    $clip_content = $title . ":\n" . $content;
                }

                (my $line_content = $content) =~ s/\R+/ /g;
                my $line = join(
                    "",
                    "[id=$id][title=", $h2->title, "]",
                    $line_content,
                    "[category=$category]",
                );
                push @lines, "$line\n";
                $dict->{$id} = $clip_content;
            }
        }

        (my $tempfh, $jsonfile) = File::Temp::tempfile('XXXXXXXX', TMPDIR=>1, SUFFIX=>'.json');
        log_trace "JSON file is at %s", $jsonfile;
        print $tempfh JSON::PP::encode_json($dict);
        close $tempfh;
    } # PREPROCESS_TEMPLATE

    my $pid = IPC::Open2::open2(my $out, my $in, qq[fzf --bind 'enter:execute-silent(cs-select-helper $jsonfile {})']);
    for my $line (@lines) {
        print $in $line;
    }
    close $in;
    close $out;
    waitpid($pid, 0);

    [200, "OK"];
}

1;
# ABSTRACT: Utilities related to fzf

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FzfUtils - Utilities related to fzf

=head1 VERSION

This document describes version 0.002 of App::FzfUtils (from Perl distribution App-FzfUtils), released on 2026-04-08.

=head1 DESCRIPTION

This distribution includes the following CLI utilities related to fzf:

=over

=item * L<cs-select>

=item * L<cs-select-helper>

=item * L<fzf2clip>

=item * L<fzf2clip-loop>

=back

=head1 FUNCTIONS


=head2 cs_select

Usage:

 cs_select(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select entries from template to clipboard.

This is basically similar to:

 % fzf --bind 'enter:execute(clipadd {})' < template.txt

except that it does some pre-processing to let each template entry be a
multiple-line text, and later do post-processing so the original entry is added
to the clipboard.

B<Template format>

Template is an Org file with a particular format, where each entry is put under
a level-2 heading. The level-1 heading can be used for grouping/categorizing.
For example:

 * Product > P1
 ** Does P1 need to be replaced every 5 years?  :replacement:clipadd_1:
 Yes, ideally every 3-5 years.
 ** How to maintain P1 so it is in a good condition and can last longer?
 Wash after every use, then dry.
 Keep it clean.
 And of course replace after 3-5 years.
 * Product > P2
 ** Entry 1  :clipadd_2:
 ...
 ** Entry 2
 ...
 * General > Support
 ** Entry 3
 ...
 ** Entry 4
 ...

Before feeding to C<fzf>, this utility will convert each entry into a single
line:

 [id=1][title=Does P1 need to be replaced every 5 years?]Yes, ideally every 3-5 years.[category=Product > P1][tag=replacement][tag=clipadd_1]
 [id=2][title=How to maintain P1 so it is in a good condition and can last longer?]Wash after every use, then dry. Keep it clean. And of course replace after 3-5 years.[category=Product > P1]
 [id=3][title=Entry 1]...[tag=clipadd_2][category=Product > P2]
 [id=4][title=Entry 2]...[category=Product > P2]
 [id=5][title=Entry 3]...[category=General > Support]
 [id=6][title=Entry 4]...[category=General > Support]

after selection, another script (L<cs-select-helper>) will turn back the
single-line entry into the original.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<template> => I<str>

(No description)

=item * B<wrap> => I<posint>

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



=head2 fzf2clip

Usage:

 fzf2clip(%args) -> [$status_code, $reason, $payload, \%result_meta]

Select using fzf, then add selection to clipboard.

This is basically a shortcut for:

 % fzf < input.txt | clipadd

where L<clipadd> is a utility from L<App::ClipboardUtils>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>

(No description)

=item * B<tee> => I<bool>

In addition to adding to clipboard, also print to STDOUT.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 fzf2clip_loop

Usage:

 fzf2clip_loop(%args) -> [$status_code, $reason, $payload, \%result_meta]

Like fzf2clip, but loopE<sol>repeat.

This is basically a shortcut for:

 % fzf --bind 'enter:execute(clipadd {})' < input.txt

where L<clipadd> is a utility from L<App::ClipboardUtils>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FzfUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FzfUtils>.

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FzfUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
