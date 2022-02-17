package BorderStyle::Test::CustomChar;

use strict;
use warnings;

use Role::Tiny::With;
with 'BorderStyleRole::Spec::Basic';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.2'; # VERSION

our %BORDER = (
    v => 3,
    summary => 'A border style that uses a single custom character',
    args => {
        character => {
            schema => 'str*',
            req => 1,
        },
    },
    examples => [
        {
            summary => "Use x as the border character",
            args => {character=>"x"},
        },
    ],
);

sub get_border_char {
    my ($self, %args) = @_;
    my $repeat = $args{repeat} // 1;

    $self->{args}{character} x $repeat;
}

1;
# ABSTRACT: A border style that uses a single custom character

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyle::Test::CustomChar - A border style that uses a single custom character

=head1 VERSION

This document describes version 3.0.2 of BorderStyle::Test::CustomChar (from Perl distribution BorderStyle), released on 2022-02-14.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

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

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
