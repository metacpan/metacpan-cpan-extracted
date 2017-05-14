package App::TOMLUtils;

our $VERSION = '0.001'; # VERSION
our $DATE = '2017-05-09'; # DATE

use 5.010001;

our %common_args = (
    toml => {
        summary => 'TOML file',
        schema  => ['str*'],
        req     => 1,
        pos     => 0,
        cmdline_src => 'stdin_or_file',
        tags    => ['common'],
    },

    #ignore_unknown_directive => {
    #    schema  => 'bool',
    #    default => 0,
    #    tags    => ['common', 'category:parser'],
    #},
);

sub _get_parser {
    require TOML::Parser;

    my $args = shift;
    TOML::Parser->new();
}

1;
# ABSTRACT: TOML utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TOMLUtils - TOML utilities

=head1 VERSION

This document describes version 0.001 of App::TOMLUtils (from Perl distribution App-TOMLUtils), released on 2017-05-09.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<parse-toml>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TOMLUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TOMLUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TOMLUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://github.com/toml-lang/toml>

L<TOML::Parser>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
