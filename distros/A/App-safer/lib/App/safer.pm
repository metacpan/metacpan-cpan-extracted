package App::safer;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-06-15'; # DATE
our $DIST = 'App-safer'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

sub _list_encodings {
    require Module::List::Tiny;

    my %args = @_;
    my $detail = $args{detail};

    my $modules = Module::List::Tiny::list_modules("Text::Safer::", {list_modules => 1, recurse=>1});
    my @res;
    my $resmeta = $detail ? {"table.fields" => [qw/encoding summary args/]} : {};
    for my $e (sort keys %$modules) {
        $e =~ s/^Text::Safer:://;
        if ($detail) {
            my $mod = "Text::Safer::$e";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
            my $meta = \%{"$mod\::META"};
            push @res, {
                encoding => $e,
                summary => $meta->{summary},
                args => join(", ", sort keys %{ $meta->{args} // {} }),
            };
        } else {
            push @res, $e;
        }
    }
    return [200, "OK", \@res, $resmeta];
}

my $num_l_specified = 0;

$SPEC{app} = {
    v => 1.1,
    summary => 'CLI for Text::Safer',
    args => {
        action => {
            schema => ['str*', in=>[qw/list-encodings encode/]],
            default => 'encode',
            cmdline_aliases => {
                a => {},
                l => {
                    is_flag => 1,
                    summary => 'Shortcut for --action=list-encodings, specify another -l for --detail listing',
                    code => sub {
                        $_[0]{action} = 'list-encodings';
                        if ($num_l_specified++) {
                            $_[0]{detail} = 1;
                        }
                    },
                },
            },
        },
        detail => {
            schema => 'bool*',
            summary => 'Show detail information in list',
        },
        encoding => {
            schema => 'str*',
            default => 'alphanum_kebab_nodashend_lc',
            cmdline_aliases => {e=>{}},
            completion => sub {
                require Complete::Util;

                my %args = @_;

                my $encres = _list_encodings(detail => 1);
                Complete::Util::complete_array_elem(
                    array     => [map { $_->{encoding} } @{ $encres->[2] }],
                    summaries => [map { $_->{summary}  } @{ $encres->[2] }],
                    word      => $args{word},
                );
            },
        },
        # TODO: encoding_args
        text => {
            schema => 'str*',
            pos => 0,
        },
    }, # args
    examples => [
        {
            summary => 'List available encodings',
            argv => ["-l"],
        },
        {
            summary => 'List available encodings (verbose mode)',
            argv => ["-ll"],
        },
        {
            summary => 'Convert a single text',
            src => "echo 'Foo Bar, Co., Ltd.' | [[prog]]",
            src_plang => "bash",
        },
        {
            summary => 'Convert each line then show result and add to clipboard (required clipadd from App::ClipboardUtils)',
            src => "clipadd -c [[prog]] --tee",
            src_plang => "bash",
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub app {
    $num_l_specified = 0;

    my %args = @_;

    my $action = $args{action} // 'encode';
    my $text = $args{text};
    my $encoding = $args{encoding} // 'alphanum_kebab_nodashend_lc';
    my $detail = $args{detail};

    if ($action eq 'list-encodings') {
        return _list_encodings(detail => $detail);
    }

    $text = do { local $/; scalar <> } unless defined $text;
    $text //= "";
    require Text::Safer;
    [200, "OK", Text::Safer::encode_safer($text, $encoding)];
}

1;
# ABSTRACT: CLI for Text::Safer

__END__

=pod

=encoding UTF-8

=head1 NAME

App::safer - CLI for Text::Safer

=head1 VERSION

This document describes version 0.003 of App::safer (from Perl distribution App-safer), released on 2025-06-15.

=head1 SYNOPSIS

See L<safer> script.

=head1 FUNCTIONS


=head2 app

Usage:

 app(%args) -> [$status_code, $reason, $payload, \%result_meta]

CLI for Text::Safer.

Examples:

=over

=item * List available encodings:

 app(action => "list-encodings");

Result:

 [
   200,
   "OK",
   [
     {
       encoding => "alphanum_kebab",
       summary => "Replace sequences of non-alphanumeric characters (underscores not included) with a single dash, e.g. Foo_Bar!!!Baz. -> Foo_Bar-Baz-",
       args => "lc",
     },
     {
       encoding => "alphanum_kebab_nodashend_lc",
       summary => "Like alphanum_kebab, but additionally lower case & remove dash at the beginning & end of text, e.g. \"Foo Bar, Co., Ltd.\" -> \"foo-bar-co-ltd\"",
       args => "",
     },
     {
       encoding => "alphanum_snake",
       summary => "Replace sequences of non-alphanumeric characters (including dashes) with a single underscore, e.g. Foo-Bar_Baz!!!Qux-. -> Foo_Bar_Baz_Qux_",
       args => "lc",
     },
     {
       encoding => "alphanum_snake_lc",
       summary => "Like alphanum_snake, but additionally lower case",
       args => "",
     },
   ],
   { "table.fields" => ["encoding", "summary", "args"] },
 ]

=item * List available encodings (verbose mode):

 app(action => "list-encodings", detail => 1);

Result:

 [
   200,
   "OK",
   [
     {
       encoding => "alphanum_kebab",
       summary => "Replace sequences of non-alphanumeric characters (underscores not included) with a single dash, e.g. Foo_Bar!!!Baz. -> Foo_Bar-Baz-",
       args => "lc",
     },
     {
       encoding => "alphanum_kebab_nodashend_lc",
       summary => "Like alphanum_kebab, but additionally lower case & remove dash at the beginning & end of text, e.g. \"Foo Bar, Co., Ltd.\" -> \"foo-bar-co-ltd\"",
       args => "",
     },
     {
       encoding => "alphanum_snake",
       summary => "Replace sequences of non-alphanumeric characters (including dashes) with a single underscore, e.g. Foo-Bar_Baz!!!Qux-. -> Foo_Bar_Baz_Qux_",
       args => "lc",
     },
     {
       encoding => "alphanum_snake_lc",
       summary => "Like alphanum_snake, but additionally lower case",
       args => "",
     },
   ],
   { "table.fields" => ["encoding", "summary", "args"] },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "encode")

(No description)

=item * B<detail> => I<bool>

Show detail information in list.

=item * B<encoding> => I<str> (default: "alphanum_kebab_nodashend_lc")

(No description)

=item * B<text> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-safer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-safer>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-safer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
