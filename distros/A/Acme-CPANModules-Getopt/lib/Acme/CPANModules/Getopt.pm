package Acme::CPANModules::Getopt;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-Getopt'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $LIST = {
    summary => 'List of modules that parse command-line options',
    entry_features => {
        uses_spec => {summary => 'Whether user need to specify some sort of "spec" (list of options and potentially more details)'},
        uses_getopt_long => {summary => 'Whether module uses Getopt::Long (or is Getopt::Long itself)'},
        auto_help => {summary => 'Whether the module can generate automatic help message (usually from spec) when user specifies something like --help'},
        auto_version => {summary => 'Whether the module can generate automatic version message when user specifies something like --version'},
        file => {summary => 'Whether the module supports getting options from a file'},
        subcommand => {summary => 'Whether the module supports subcommands'},
    },
    entries => [
        {
            module => 'Getopt::Std',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => {value=>0, summary=>'Only calls main::HELP_MESSAGE'},
                auto_version => {value=>0, summary=>'Only calls main::VERSION_MESSAGE'},
            },
        },
        {
            module => 'Getopt::Long',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Getopt::Tiny',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 0,
                auto_version => 0,
            },
        },
        {
            module => 'Getopt::Long::Descriptive',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 0,
            },
        },
        {
            module => 'Getopt::Long::More',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
                file => 0, # planned
                subcommand => 0, # planned
            },
        },
        {
            module => 'Getopt::Simple',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Getopt::Compact',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Opt::Imistic',
            features => {
                uses_spec => 0,
                uses_getopt_long => 0,
                auto_help => 0,
                auto_version => 0,
            },
        },
        {
            module => 'Getopt::Valid',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Getopt::Std::Strict',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 0,
                auto_version => 0,
            },
        },
        {
            module => 'Getopt::Declare',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Getopt::Euclid',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1, # from POD
                auto_version => 1, #from POD
            },
        },
        {
            module => 'Docopt',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1,
                auto_version => 1, #?
            },
        },
        {
            module => 'Getopt::Auto',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1, # from POD
                auto_version => 1, # from POD
            },
        },
        {
            module => 'Getopt::Lucid',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 0,
                auto_version => 0,
            },
        },
        {
            module => 'Getopt::ArgvFile',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
                file => 1,
            },
        },
        {
            module => 'App::Options',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1,
                auto_version => 1, #?
                file => 1,
            },
        },
        {
            module => 'MooseX::Getopt',
            features => {
                uses_spec => 1,
                uses_getopt_long => {value=>1, summary=>'Uses Getopt::Long::Descriptive'},
                auto_help => 1,
                auto_version => 1,
                file => {value=>0, summary=>'Needs separate module: MooseX::ConfigFromFile or MooseX::SimpleConfig'},
            },
        },
        {
            module => 'MooX::Options',
            features => {
                uses_spec => 1,
                uses_getopt_long => {value=>1, summary=>'Uses Getopt::Long::Descriptive'},
                auto_help => 1,
                auto_version => 0,
                file => 1,
            },
        },
        {
            module => 'Getopt::Attribute',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Getopt::Modular',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        # App::Cmd
        # App::Spec
        {
            module => 'Smart::Options',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1,
                auto_version => 0,
                subcommand => 1,
                file => 1,
            },
        },
        {
            module => 'Getopt::ArgParse',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 0, #?
                auto_version => 0, #?
                subcommand => 1,
            },
        },
        {
            module => 'Getopt::Kingpin',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 1, #?
                auto_version => 1, #?
                subcommand => 1,
            },
        },
        {
            module => 'Getopt::Complete',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 0, #?
                auto_version => 0, #?
            },
        },
        {
            module => 'Getopt::Long::Complete',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
            },
        },
        {
            module => 'Getopt::Long::Subcommand',
            features => {
                uses_spec => 1,
                uses_getopt_long => 1,
                auto_help => 1,
                auto_version => 1,
                subcommand => 1,
            },
        },
        {
            module => 'Getopt::Long::Less',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 0,
                auto_version => 0,
            },
        },
        {
            module => 'Getopt::Long::EvenLess',
            features => {
                uses_spec => 1,
                uses_getopt_long => 0,
                auto_help => 0,
                auto_version => 0,
            },
        },
        # Getopt::Panjang
        # Perinci::CmdLine
        # ScriptX
    ],

};

1;
# ABSTRACT: List of modules that parse command-line options

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Getopt - List of modules that parse command-line options

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::Getopt (from Perl distribution Acme-CPANModules-Getopt), released on 2023-10-29.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Getopt::Std>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<Getopt::Long>

Author: L<JV|https://metacpan.org/author/JV>

=item L<Getopt::Tiny>

Author: L<MUIR|https://metacpan.org/author/MUIR>

=item L<Getopt::Long::Descriptive>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<Getopt::Long::More>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Getopt::Simple>

Author: L<RSAVAGE|https://metacpan.org/author/RSAVAGE>

=item L<Getopt::Compact>

Author: L<ASW|https://metacpan.org/author/ASW>

=item L<Opt::Imistic>

Author: L<ALTREUS|https://metacpan.org/author/ALTREUS>

=item L<Getopt::Valid>

Author: L<UKAUTZ|https://metacpan.org/author/UKAUTZ>

=item L<Getopt::Std::Strict>

Author: L<LEOCHARRE|https://metacpan.org/author/LEOCHARRE>

=item L<Getopt::Declare>

Author: L<FANGLY|https://metacpan.org/author/FANGLY>

=item L<Getopt::Euclid>

Author: L<BIGPRESH|https://metacpan.org/author/BIGPRESH>

=item L<Docopt>

Author: L<TOKUHIROM|https://metacpan.org/author/TOKUHIROM>

=item L<Getopt::Auto>

Author: L<GLEACH|https://metacpan.org/author/GLEACH>

=item L<Getopt::Lucid>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

=item L<Getopt::ArgvFile>

Author: L<JSTENZEL|https://metacpan.org/author/JSTENZEL>

=item L<App::Options>

Author: L<SPADKINS|https://metacpan.org/author/SPADKINS>

=item L<MooseX::Getopt>

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item L<MooX::Options>

Author: L<REHSACK|https://metacpan.org/author/REHSACK>

=item L<Getopt::Attribute>

Author: L<MARCEL|https://metacpan.org/author/MARCEL>

=item L<Getopt::Modular>

Author: L<DMCBRIDE|https://metacpan.org/author/DMCBRIDE>

=item L<Smart::Options>

Author: L<MIKIHOSHI|https://metacpan.org/author/MIKIHOSHI>

=item L<Getopt::ArgParse>

Author: L<MYTRAM|https://metacpan.org/author/MYTRAM>

=item L<Getopt::Kingpin>

Author: L<TAKASAGO|https://metacpan.org/author/TAKASAGO>

=item L<Getopt::Complete>

Author: L<NNUTTER|https://metacpan.org/author/NNUTTER>

=item L<Getopt::Long::Complete>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Getopt::Long::Subcommand>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Getopt::Long::Less>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Getopt::Long::EvenLess>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=back

=head1 ACME::CPANMODULES FEATURE COMPARISON MATRIX

 +---------------------------+---------------+------------------+----------------------+---------------+----------+----------------+
 | module                    | auto_help *1) | auto_version *2) | uses_getopt_long *3) | uses_spec *4) | file *5) | subcommand *6) |
 +---------------------------+---------------+------------------+----------------------+---------------+----------+----------------+
 | Getopt::Std               | no *7)        | no *8)           | no                   | yes           | N/A      | N/A            |
 | Getopt::Long              | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Getopt::Tiny              | no            | no               | no                   | yes           | N/A      | N/A            |
 | Getopt::Long::Descriptive | yes           | no               | yes                  | yes           | N/A      | N/A            |
 | Getopt::Long::More        | yes           | yes              | yes                  | yes           | no       | no             |
 | Getopt::Simple            | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Getopt::Compact           | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Opt::Imistic              | no            | no               | no                   | no            | N/A      | N/A            |
 | Getopt::Valid             | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Getopt::Std::Strict       | no            | no               | no                   | yes           | N/A      | N/A            |
 | Getopt::Declare           | yes           | yes              | no                   | yes           | N/A      | N/A            |
 | Getopt::Euclid            | yes           | yes              | no                   | yes           | N/A      | N/A            |
 | Docopt                    | yes           | yes              | no                   | yes           | N/A      | N/A            |
 | Getopt::Auto              | yes           | yes              | no                   | yes           | N/A      | N/A            |
 | Getopt::Lucid             | no            | no               | no                   | yes           | N/A      | N/A            |
 | Getopt::ArgvFile          | yes           | yes              | yes                  | yes           | yes      | N/A            |
 | App::Options              | yes           | yes              | no                   | yes           | yes      | N/A            |
 | MooseX::Getopt            | yes           | yes              | yes *9)              | yes           | no *10)  | N/A            |
 | MooX::Options             | yes           | no               | yes *9)              | yes           | yes      | N/A            |
 | Getopt::Attribute         | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Getopt::Modular           | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Smart::Options            | yes           | no               | no                   | yes           | yes      | yes            |
 | Getopt::ArgParse          | no            | no               | yes                  | yes           | N/A      | yes            |
 | Getopt::Kingpin           | yes           | yes              | no                   | yes           | N/A      | yes            |
 | Getopt::Complete          | no            | no               | no                   | yes           | N/A      | N/A            |
 | Getopt::Long::Complete    | yes           | yes              | yes                  | yes           | N/A      | N/A            |
 | Getopt::Long::Subcommand  | yes           | yes              | yes                  | yes           | N/A      | yes            |
 | Getopt::Long::Less        | no            | no               | no                   | yes           | N/A      | N/A            |
 | Getopt::Long::EvenLess    | no            | no               | no                   | yes           | N/A      | N/A            |
 +---------------------------+---------------+------------------+----------------------+---------------+----------+----------------+


Notes:

=over

=item 1. auto_help: Whether the module can generate automatic help message (usually from spec) when user specifies something like --help

=item 2. auto_version: Whether the module can generate automatic version message when user specifies something like --version

=item 3. uses_getopt_long: Whether module uses Getopt::Long (or is Getopt::Long itself)

=item 4. uses_spec: Whether user need to specify some sort of "spec" (list of options and potentially more details)

=item 5. file: Whether the module supports getting options from a file

=item 6. subcommand: Whether the module supports subcommands

=item 7. Only calls main::HELP_MESSAGE

=item 8. Only calls main::VERSION_MESSAGE

=item 9. Uses Getopt::Long::Descriptive

=item 10. Needs separate module: MooseX::ConfigFromFile or MooseX::SimpleConfig

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

 % cpanm-cpanmodules -n Getopt

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Getopt | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Getopt -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Getopt -E'say $_->{module} for @{ $Acme::CPANModules::Getopt::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Getopt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Getopt>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Getopt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
