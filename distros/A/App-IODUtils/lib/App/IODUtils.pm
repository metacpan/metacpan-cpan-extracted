package App::IODUtils;

our $VERSION = '0.15'; # VERSION
our $DATE = '2017-08-05'; # DATE

use 5.010001;

our %common_args = (
    iod => {
        summary => 'IOD file',
        schema  => ['str*'],
        req     => 1,
        pos     => 0,
        cmdline_src => 'stdin_or_file',
        tags    => ['common'],
    },

    default_section => {
        schema  => 'str*',
        default => 'GLOBAL',
        tags    => ['common', 'category:parser'],
    },
    enable_encoding => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
    enable_quoting => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
    enable_bracket => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
    enable_brace => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
    allow_encodings => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'allow_encoding',
        schema  => ['array*', of=>'str*'],
        tags    => ['common', 'category:parser'],
    },
    disallow_encodings => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'disallow_encoding',
        schema  => ['array*', of=>'str*'],
        tags    => ['common', 'category:parser'],
    },
    allow_directives => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'allow_directive',
        schema  => ['array*', of=>'str*'],
        tags    => ['common', 'category:parser'],
    },
    disallow_directives => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'disallow_directive',
        schema  => ['array*', of=>'str*'],
        tags    => ['common', 'category:parser'],
    },
    allow_bang_only => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
    enable_expr => {
        schema  => 'bool',
        default => 0,
        cmdline_aliases => {e=>{}},
        tags    => ['common', 'category:parser'],
    },
    allow_duplicate_key => {
        schema  => 'bool',
        default => 1,
        tags    => ['common', 'category:parser'],
    },
    ignore_unknown_directive => {
        schema  => 'bool',
        default => 0,
        tags    => ['common', 'category:parser'],
    },
    expr_vars => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'expr_var',
        schema => ['hash*', of=>'str'],
        tags    => ['common', 'category:parser'],
    },
);

our %inplace_arg = (
    inplace => {
        summary => 'Modify file in-place',
        schema => ['bool', is=>1],
        description => <<'_',

Note that this can only be done if you specify an actual file and not STDIN.
Otherwise, an error will be thrown.

_
    },
);

sub _check_inplace {
    my $args = shift;
    if ($args->{inplace}) {
        die [412, "To use in-place editing, please supply an actual file"]
            if @{ $args->{-cmdline_srcfilenames_iod} // []} == 0;
        die [412, "To use in-place editing, please supply only one file"]
            if @{ $args->{-cmdline_srcfilenames_iod} // []} > 1;
    }
}

sub _return_mod_result {
    my ($args, $doc) = @_;

    if ($args->{inplace}) {
        require File::Slurper;
        File::Slurper::write_text(
            $args->{-cmdline_srcfilenames_iod}[0], $doc->as_string);
        [200, "OK"];
    } else {
        [200, "OK", $doc->as_string, {'cmdline.skip_format'=>1}];
    }
}

sub _get_parser_options {
    my $args = shift;
    return (
        default_section          => $args->{default_section},
        enable_encoding          => $args->{enable_encoding},
        enable_quoting           => $args->{enable_quoting},
        enable_bracket           => $args->{enable_bracket},
        enable_brace             => $args->{enable_brace},
        (allow_encodings         => $args->{allow_encodings})     x !!@{ $args->{allow_encodings}     // [] },
        (disallow_encodings      => $args->{disallow_encodings})  x !!@{ $args->{disallow_encodings}  // [] },
        (allow_directives        => $args->{allow_directives})    x !!@{ $args->{allow_directives}    // [] },
        (disallow_directives     => $args->{disallow_directives}) x !!@{ $args->{disallow_directives} // [] },
        enable_expr              => $args->{enable_expr},
        (expr_vars                => $args->{expr_vars})          x !!(defined $args->{expr_vars}),
        allow_duplicate_key      => $args->{allow_duplicate_key},
        ignore_unknown_directive => $args->{ignore_unknown_directive},
    );
}

sub _get_parser {
    require Config::IOD;

    my $args = shift;
    Config::IOD->new(
        _get_parser_options($args),
    );
}

sub _get_reader {
    require Config::IOD::Reader;

    my $args = shift;
    Config::IOD::Reader->new(
        _get_parser_options($args),
    );
}

1;
# ABSTRACT: IOD utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::IODUtils - IOD utilities

=head1 VERSION

This document describes version 0.15 of App::IODUtils (from Perl distribution App-IODUtils), released on 2017-08-05.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<delete-iod-key>

=item * L<delete-iod-section>

=item * L<dump-iod>

=item * L<get-iod-key>

=item * L<get-iod-section>

=item * L<insert-iod-key>

=item * L<insert-iod-section>

=item * L<list-iod-sections>

=item * L<parse-iod>

=back

The main feature of these utilities is tab completion.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-IODUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-IODUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-IODUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
