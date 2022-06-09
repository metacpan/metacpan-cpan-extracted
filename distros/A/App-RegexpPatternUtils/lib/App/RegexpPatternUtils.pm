package App::RegexpPatternUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Regexp::Pattern;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-08'; # DATE
our $DIST = 'App-RegexpPatternUtils'; # DIST
our $VERSION = '0.008'; # VERSION

our %SPEC;

our %args_common_pattern = (
    pattern => {
        summary => "Name of pattern, with module prefix but without the 'Regexp::Pattern'",
        schema => 'regexppattern::name*',
        req => 1,
        pos => 0,
    },
    gen_args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'gen_arg',
        summary => 'Supply generator arguments',
        description => <<'_',

If pattern is a dynamic pattern (generated on-demand) and the generator requires
some arguments, you can supply them here.

_
        cmdline_aliases => {A=>{}},
        schema => ['hash*', of=>'str*'],
    },
);

our %args_common_get_pattern = (
    %args_common_pattern,
    anchor => {
        summary => 'Generate an anchored version of the pattern',
        schema => 'bool*',
    },
);

$SPEC{get_regexp_pattern_pattern} = {
    v => 1.1,
    summary => 'Get a Regexp::Pattern::* pattern',
    args => {
        %args_common_pattern,
    },
    examples => [
        {
            args => {pattern=>'YouTube/video_id'},
        },
        {
            summary=>"Generate variant A of Example::re3",
            argv => ['Example::re3', '--gen-arg', 'variant=A'],
        },
        {
            summary=>"Generate variant B of Example::re3",
            argv => ['Example::re3', '--gen-arg', 'variant=B'],
        },
    ],
    links => [
    ],
};
sub get_regexp_pattern_pattern {
    my %args = @_;

    my $name = $args{pattern};
    $name =~ s!(/|\.)!::!g;

    my $re = re($name, $args{gen_args} // {});

    if (-t STDOUT && $args{-cmdline} &&
            ($args{-cmdline_r}{format} // 'text') =~ /text/) { ## no critic: InputOutput::ProhibitInteractiveTest
        require Data::Dump::Color;
        return [200, "OK", Data::Dump::Color::dump($re) . "\n",
                {'cmdline.skip_format'=>1}];
    } else {
        return [200, "OK", "$re"];
    }
}

$SPEC{list_regexp_pattern_modules} = {
    v => 1.1,
    summary => 'List all installed Regexp::Pattern::* modules',
};
sub list_regexp_pattern_modules {
    require Module::List::Tiny;

    my $res = Module::List::Tiny::list_modules(
        'Regexp::Pattern::', {list_modules=>1, recurse=>1});
    my @rows;
    for (sort keys %$res) {
        s/\ARegexp::Pattern:://;
        push @rows, $_;
    }
    [200, "OK", \@rows];
}

$SPEC{match_with_regexp_pattern} = {
    v => 1.1,
    summary => 'Match a string against a Regexp::Pattern pattern',
    args => {
        %args_common_get_pattern,
        string => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        captures => {
            summary => 'Return array of captures instead of just a boolean status',
            schema => 'bool*',
        },
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
    examples => [
        {
            summary => 'A non-match',
            args => {pattern=>'YouTube/video_id', string=>'foo'},
        },
        {
            summary => 'A match',
            args => {pattern=>'YouTube/video_id', string=>'Yb4EGj4_uS0'},
        },
    ],
    links => [
        {url=>'prog:get-regexp-pattern-pattern'},
        {url=>'prog:rpgrep'},
    ],
};
sub match_with_regexp_pattern {
    my %args = @_;

    my $name = $args{pattern};
    $name =~ s!(/|\.)!::!g;

    my %gen_args = %{ $args{gen_args} // {} };
    $gen_args{-anchor} = 1 if $args{anchor};

    my $re = re($name, \%gen_args);

    my $matches;
    my @captures;
    if ($args{string} =~ $re) {
        $matches = 1;
        if ($args{captures}) {
            # for perls that do not have @{^CAPTURE}
            for (1..@- - 1) {
                push @captures, ${$_};
            }
        }
    }

    my $msg = "String ".($matches ? "matches" : "DOES NOT match")." regexp pattern $name";
    [
        200, "OK",
        $args{captures} ? \@captures : $args{quiet} ? undef : $msg,
        {"cmdline.exit_code"=>$matches ? 0:1},
    ];
}

1;
# ABSTRACT: CLI utilities related to Regexp::Pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

App::RegexpPatternUtils - CLI utilities related to Regexp::Pattern

=head1 VERSION

This document describes version 0.008 of App::RegexpPatternUtils (from Perl distribution App-RegexpPatternUtils), released on 2022-05-08.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to L<Regexp::Pattern>:

=over

=item * L<get-regexp-pattern-pattern>

=item * L<list-regexp-pattern-modules>

=item * L<list-regexp-pattern-patterns>

=item * L<match-with-regexp-pattern>

=item * L<show-regexp-pattern-module>

=back

=head1 FUNCTIONS


=head2 get_regexp_pattern_pattern

Usage:

 get_regexp_pattern_pattern(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get a Regexp::Pattern::* pattern.

Examples:

=over

=item * Example #1:

 get_regexp_pattern_pattern(pattern => "YouTube/video_id"); # -> [200, "OK", "(?^:[A-Za-z0-9_-]{11})", {}]

=item * Generate variant A of Example::re3:

 get_regexp_pattern_pattern(pattern => "Example::re3", gen_args => { variant => "A" });

Result:

 [200, "OK", "(?^:\\d{3}-\\d{3})", {}]

=item * Generate variant B of Example::re3:

 get_regexp_pattern_pattern(pattern => "Example::re3", gen_args => { variant => "B" });

Result:

 [200, "OK", "(?^:\\d{3}-\\d{2}-\\d{5})", {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<gen_args> => I<hash>

Supply generator arguments.

If pattern is a dynamic pattern (generated on-demand) and the generator requires
some arguments, you can supply them here.

=item * B<pattern>* => I<regexppattern::name>

Name of pattern, with module prefix but without the 'Regexp::Pattern'.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_regexp_pattern_modules

Usage:

 list_regexp_pattern_modules() -> [$status_code, $reason, $payload, \%result_meta]

List all installed Regexp::Pattern::* modules.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 match_with_regexp_pattern

Usage:

 match_with_regexp_pattern(%args) -> [$status_code, $reason, $payload, \%result_meta]

Match a string against a Regexp::Pattern pattern.

Examples:

=over

=item * A non-match:

 match_with_regexp_pattern(pattern => "YouTube/video_id", string => "foo");

Result:

 [
   200,
   "OK",
   "String DOES NOT match regexp pattern YouTube::video_id",
   { "cmdline.exit_code" => 1 },
 ]

=item * A match:

 match_with_regexp_pattern(pattern => "YouTube/video_id", string => "Yb4EGj4_uS0");

Result:

 [
   200,
   "OK",
   "String matches regexp pattern YouTube::video_id",
   { "cmdline.exit_code" => 0 },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<anchor> => I<bool>

Generate an anchored version of the pattern.

=item * B<captures> => I<bool>

Return array of captures instead of just a boolean status.

=item * B<gen_args> => I<hash>

Supply generator arguments.

If pattern is a dynamic pattern (generated on-demand) and the generator requires
some arguments, you can supply them here.

=item * B<pattern>* => I<regexppattern::name>

Name of pattern, with module prefix but without the 'Regexp::Pattern'.

=item * B<quiet> => I<bool>

=item * B<string>* => I<str>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-RegexpPatternUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-RegexpPatternUtils>.

=head1 SEE ALSO

Other CLI's included in other distributions:

=over

=item * L<test-regexp-pattern> (from L<Test::Regexp::Pattern>)

=back

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

This software is copyright (c) 2022, 2020, 2018, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-RegexpPatternUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
