package Acme::CPANModules::CryptingPassword;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-21'; # DATE
our $DIST = 'Acme-CPANModules-CryptingPassword'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules/tools to crypt/hash a password',
    description => <<'_',

Bascally, the Perl's builtin `crypt()` is all you need. It supports all the
hashing algorithms supported by your system's C library. You just need to supply
the salt in the right format to select the hashing algorithm. See the function's
documentation for more details.

There are some wrappers and other utilities available on CPAN for added
convenience.

_
    entries => [
        {
            module => 'Crypt::Password::Util',
            description => <<'_',

This module offers a one-argument `crypt()` which generates an appropriate
("reasonably secure") salt for you. There are also utility functions to check
whether a string looks like a crypted password and to find out the type of the
crypted password.

_
        },

        {
            module => 'App::bcrypt',
            script => 'bcrypt',
            description => <<'_',

The distribution provides a `bcrypt` CLI utility to crypt every input line with
bcrypt. It can also compare a password with its crypt.

_
        },
    ],
};

1;
# ABSTRACT: List of modules/tools to crypt/hash a password

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CryptingPassword - List of modules/tools to crypt/hash a password

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CryptingPassword (from Perl distribution Acme-CPANModules-CryptingPassword), released on 2023-07-21.

=head1 DESCRIPTION

Bascally, the Perl's builtin C<crypt()> is all you need. It supports all the
hashing algorithms supported by your system's C library. You just need to supply
the salt in the right format to select the hashing algorithm. See the function's
documentation for more details.

There are some wrappers and other utilities available on CPAN for added
convenience.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Crypt::Password::Util>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This module offers a one-argument C<crypt()> which generates an appropriate
("reasonably secure") salt for you. There are also utility functions to check
whether a string looks like a crypted password and to find out the type of the
crypted password.


=item L<App::bcrypt>

Author: L<BDFOY|https://metacpan.org/author/BDFOY>

The distribution provides a C<bcrypt> CLI utility to crypt every input line with
bcrypt. It can also compare a password with its crypt.


Script: L<bcrypt>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n CryptingPassword

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CryptingPassword | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CryptingPassword -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CryptingPassword -E'say $_->{module} for @{ $Acme::CPANModules::CryptingPassword::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CryptingPassword>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CryptingPassword>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CryptingPassword>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
