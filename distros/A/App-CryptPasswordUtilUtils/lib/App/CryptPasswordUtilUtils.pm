package App::CryptPasswordUtilUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-06'; # DATE
our $DIST = 'App-CryptPasswordUtilUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{parse_crypt} = {
    v => 1.1,
    summary => 'Parse a crypt string and show information about it',
    args => {
        string => {
            schema => ['str*'],
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    examples => [
        {args=>{string=>'$6$rounds=15000$3ZOH1YOo/ALBNcB5$niBM/qaJNJP.mRk//KqSIN1aXwEeF7ZarmLcvPUiE6mdObA2JUSzrPAhxX7yvTvaFEq7t.SUlW7/Y6lBTgJeC.'}},
    ],
};
sub parse_crypt {
    require Crypt::Password::Util;

    my %args = @_;

    my $string = $args{string};

    Crypt::Password::Util::crypt_type($string, 'detail');
}

1;
# ABSTRACT: Utilities related to Crypt::Password::Util

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CryptPasswordUtilUtils - Utilities related to Crypt::Password::Util

=head1 VERSION

This document describes version 0.001 of App::CryptPasswordUtilUtils (from Perl distribution App-CryptPasswordUtilUtils), released on 2024-01-06.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<parse-crypt>

=back

=head1 FUNCTIONS


=head2 parse_crypt

Usage:

 parse_crypt(%args) -> any

Parse a crypt string and show information about it.

Examples:

=over

=item * Example #1:

 parse_crypt(string => "\$6\$rounds=15000\$3ZOH1YOo/ALBNcB5\$niBM/qaJNJP.mRk//KqSIN1aXwEeF7ZarmLcvPUiE6mdObA2JUSzrPAhxX7yvTvaFEq7t.SUlW7/Y6lBTgJeC.");

Result:

 {
   hash   => "niBM/qaJNJP.mRk//KqSIN1aXwEeF7ZarmLcvPUiE6mdObA2JUSzrPAhxX7yvTvaFEq7t.SUlW7/Y6lBTgJeC.",
   header => "\$6\$",
   salt   => "rounds=15000\$3ZOH1YOo/ALBNcB5",
   type   => "SSHA512",
 }

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<string>* => I<str>

(No description)


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CryptPasswordUtilUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CryptPasswordUtilUtils>.

=head1 SEE ALSO

L<Crypt::Password::Util>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CryptPasswordUtilUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
