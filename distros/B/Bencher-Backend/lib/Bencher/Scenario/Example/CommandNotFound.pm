package Bencher::Scenario::Example::CommandNotFound;

our $DATE = '2019-02-24'; # DATE
our $VERSION = '1.044'; # VERSION

our $scenario = {
    participants => [
        {name=>'found-array'    , cmdline=>['true']},
        {name=>'found-string'   , cmdline=>'true'},
        {name=>'notfound-array' , cmdline=>['foo1']},
        {name=>'notfound-string', cmdline=>'foo2'},
    ],
    #on_failure => 'skip',
};

1;
# ABSTRACT: An example scenario: command not found

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Example::CommandNotFound - An example scenario: command not found

=head1 VERSION

This document describes version 1.044 of Bencher::Scenario::Example::CommandNotFound (from Perl distribution Bencher-Backend), released on 2019-02-24.

=head1 SYNOPSIS

 % bencher -m Example::CommandNotFound [other options]...

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

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
