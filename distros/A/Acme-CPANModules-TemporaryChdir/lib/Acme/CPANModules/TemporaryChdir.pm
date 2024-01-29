package Acme::CPANModules::TemporaryChdir;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-15'; # DATE
our $DIST = 'Acme-CPANModules-TemporaryChdir'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of modules to change directory temporarily',
    description => <<'MARKDOWN',

Changing directory can be tricky if you are doing it in a transaction or inside
a routine where you need to restore the previous working directory whether your
main action succeeds or not. Forgetting doing it and it will cause unexpected
behavior for the user calling your code.

Restoring previous directory can be as simple as:

    use Cwd qw(getcwd);

    my $prevcwd = getcwd();
    eval {
        # do some stuffs that might die ...
    };
    # check success status ...
    chdir $prevcwd or die "Can't chdir back to '$prevcwd': $!";

but it can get tedious. Some modules can help. These modules employ one of
several mechanisms provided by Perl:

1) Tied scalar, where reading from the scalar retrieves the current working
directory and writing to it changes the working directory. The user can set the
magic variable locally and have Perl restore the old value. Modules that use
this technique include: <pm:File::chdir>.

2) An object, where its constructor records the current working directory and
its DESTROY restores the previously recorded working directory. The user can
create a lexically scoped object that can change directory but restores the
previous working directory when the object goes out of scope. Modules that use
this technique include: <pm:File::pushd> and <pm:Dir::TempChdir>.

MARKDOWN
    entries => [
        {
            module => 'File::chdir',
        },
        {
            module => 'File::pushd',
        },
        {
            module => 'Dir::TempChdir',
        },
    ],
};

1;
# ABSTRACT: List of modules to change directory temporarily

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::TemporaryChdir - List of modules to change directory temporarily

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::TemporaryChdir (from Perl distribution Acme-CPANModules-TemporaryChdir), released on 2023-12-15.

=head1 DESCRIPTION

Changing directory can be tricky if you are doing it in a transaction or inside
a routine where you need to restore the previous working directory whether your
main action succeeds or not. Forgetting doing it and it will cause unexpected
behavior for the user calling your code.

Restoring previous directory can be as simple as:

 use Cwd qw(getcwd);
 
 my $prevcwd = getcwd();
 eval {
     # do some stuffs that might die ...
 };
 # check success status ...
 chdir $prevcwd or die "Can't chdir back to '$prevcwd': $!";

but it can get tedious. Some modules can help. These modules employ one of
several mechanisms provided by Perl:

1) Tied scalar, where reading from the scalar retrieves the current working
directory and writing to it changes the working directory. The user can set the
magic variable locally and have Perl restore the old value. Modules that use
this technique include: L<File::chdir>.

2) An object, where its constructor records the current working directory and
its DESTROY restores the previously recorded working directory. The user can
create a lexically scoped object that can change directory but restores the
previous working directory when the object goes out of scope. Modules that use
this technique include: L<File::pushd> and L<Dir::TempChdir>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<File::chdir>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

=item L<File::pushd>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

=item L<Dir::TempChdir>

Author: L<CGPAN|https://metacpan.org/author/CGPAN>

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

 % cpanm-cpanmodules -n TemporaryChdir

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries TemporaryChdir | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=TemporaryChdir -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::TemporaryChdir -E'say $_->{module} for @{ $Acme::CPANModules::TemporaryChdir::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-TemporaryChdir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-TemporaryChdir>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-TemporaryChdir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
