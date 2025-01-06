package Acme::CPANModules::CLI::PasswordManager;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-06'; # DATE
our $DIST = 'Acme-CPANModules-CLI-PasswordManager'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of various password manager CLIs on CPAN",
    description => <<'MARKDOWN',

Password manager CLIs are command-line tools which you can use to store and
retrieve password entries.

If you know of others, please drop me a message.

MARKDOWN
    entries => [
        {
            module => 'App::PasswordManager',
            script => 'password_manager',
            description => <<'MARKDOWN',

A simple script that lets you add, edit, list, and delete passwords from the
CLI. Passwords are stored in `~/.password_manager.json` in a simple JSON object
(hash) structure. Currently a very early release that still needs to be updated.

Pros:

- simplicity.

Cons:

- At the time of this writing (version 1.0.0) only the password hash is stored
  and returned, making this application unusable at the moment.
- Password must be entered as command-line argument, making it visible from
  process list and shell history, unless you explicitly disable those.
- Cannot add other fields to a record, e.g. comment/note, date, etc.
- Usernames are not encrypted.

MARKDOWN
        },

        {
            module => 'App::orgadb',
            script => 'orgadb-sel',
            description => <<'MARKDOWN',

A CLI to read entries from an addressbook file in a specific layout in Org
format. This tool can be used to read from a PGP-encrypted addressbook file, and
thus can also be used as a password retriever.

Pros:

- Standard tool and format for the data storage (PGP-encrypted Org file, which
  can be edited with Emacs).

Cons:

- Does not come with the functionality of adding/editing/removing entries. Use
  your editor like Emacs to do so.

MARKDOWN
        },
    ],
};

1;
# ABSTRACT: List of various password manager CLIs on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CLI::PasswordManager - List of various password manager CLIs on CPAN

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CLI::PasswordManager (from Perl distribution Acme-CPANModules-CLI-PasswordManager), released on 2025-01-06.

=head1 DESCRIPTION

Password manager CLIs are command-line tools which you can use to store and
retrieve password entries.

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::PasswordManager>

A simple script that lets you add, edit, list, and delete passwords from the
CLI. Passwords are stored in C<~/.password_manager.json> in a simple JSON object
(hash) structure. Currently a very early release that still needs to be updated.

Pros:

=over

=item * simplicity.

=back

Cons:

=over

=item * At the time of this writing (version 1.0.0) only the password hash is stored
and returned, making this application unusable at the moment.

=item * Password must be entered as command-line argument, making it visible from
process list and shell history, unless you explicitly disable those.

=item * Cannot add other fields to a record, e.g. comment/note, date, etc.

=item * Usernames are not encrypted.

=back


Script: L<password_manager>

=item L<App::orgadb>

A CLI to read entries from an addressbook file in a specific layout in Org
format. This tool can be used to read from a PGP-encrypted addressbook file, and
thus can also be used as a password retriever.

Pros:

=over

=item * Standard tool and format for the data storage (PGP-encrypted Org file, which
can be edited with Emacs).

=back

Cons:

=over

=item * Does not come with the functionality of adding/editing/removing entries. Use
your editor like Emacs to do so.

=back


Script: L<orgadb-sel>

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

 % cpanm-cpanmodules -n CLI::PasswordManager

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CLI::PasswordManager | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CLI::PasswordManager -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CLI::PasswordManager -E'say $_->{module} for @{ $Acme::CPANModules::CLI::PasswordManager::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CLI-PasswordManager>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CLI-PasswordManager>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CLI-PasswordManager>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
