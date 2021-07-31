package Bencher::Scenario::Example::CmdLineTemplate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.058'; # VERSION

our $scenario = {
    participants => [
        {name => 'template_ary', cmdline_template => ['<prog>', "-e1"]},
        {name => 'template_str', cmdline_template => '<prog> -e1'},
    ],
    datasets => [
        { name=>"perl", args => {prog => $^X} },
    ],
};

1;
# ABSTRACT: Demonstrate cmdline_template

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Example::CmdLineTemplate - Demonstrate cmdline_template

=head1 VERSION

This document describes version 1.058 of Bencher::Scenario::Example::CmdLineTemplate (from Perl distribution Bencher-Backend), released on 2021-07-31.

=head1 SYNOPSIS

 % bencher -m Example::CmdLineTemplate [other options]...

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
