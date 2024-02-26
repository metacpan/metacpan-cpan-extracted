package Acme::CPANModules::MagicVariableTechnique;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-MagicVariableTechnique'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules which employ magic variable technique to do stuffs',
    description => <<'_',

This is a list of modules which provide some "magic" variable which you can
get/set to perform stuffs. I personally find this technique is mostly useful to
"temporarily set" stuffs, by combining it with Perl's `local()`.

_
    entries => [
        {
            module => 'File::chdir',
            description => <<'_',

Provides `$CWD` which you can use to change directory. By doing:

    local $CWD = ...;

in a subroutine or block, you can safely change directory temporarily without
messing current directory and breaking code in other parts. Very handy and
convenient.

This is the first module I found/use where I realized the technique. Since then
I've been looking for other modules using similar technique, and have even
created a few myself.

_
        },
        {
            module => 'File::umask',
            description => <<'_',

Provides `$UMASK` to get/set umask.

_
        },
        {
            module => 'Umask::Local',
            description => <<'_',

Like <pm:File::umask>, but instead of using a tied variable, uses an object with
its `DESTROY` method restoring original umask. I find the interface a bit more
awkward.

_
            alternate_modules => ['File::umask'],
        },
        {
            module => 'Locale::Tie',
            description => <<'_',

Provides `$LANG`, `$LC_ALL`, `$LC_TIME`, and few others to let you (temporarily)
set locale settings.

_
        },
        {
            module => 'Locale::Scope',
            description => <<'_',

Like <pm:Locale::Tie>, but instead of using a tied variable, uses an object with
its `DESTROY` method restoring original settings.

_
        },
    ],
};

1;
# ABSTRACT: List of modules which employ magic variable technique to do stuffs

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::MagicVariableTechnique - List of modules which employ magic variable technique to do stuffs

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::MagicVariableTechnique (from Perl distribution Acme-CPANModules-MagicVariableTechnique), released on 2023-10-29.

=head1 DESCRIPTION

This is a list of modules which provide some "magic" variable which you can
get/set to perform stuffs. I personally find this technique is mostly useful to
"temporarily set" stuffs, by combining it with Perl's C<local()>.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<File::chdir>

Author: L<DAGOLDEN|https://metacpan.org/author/DAGOLDEN>

Provides C<$CWD> which you can use to change directory. By doing:

 local $CWD = ...;

in a subroutine or block, you can safely change directory temporarily without
messing current directory and breaking code in other parts. Very handy and
convenient.

This is the first module I found/use where I realized the technique. Since then
I've been looking for other modules using similar technique, and have even
created a few myself.


=item L<File::umask>

Author: L<SHARYANTO|https://metacpan.org/author/SHARYANTO>

Provides C<$UMASK> to get/set umask.


=item L<Umask::Local>

Author: L<ROUZIER|https://metacpan.org/author/ROUZIER>

Like L<File::umask>, but instead of using a tied variable, uses an object with
its C<DESTROY> method restoring original umask. I find the interface a bit more
awkward.


Alternate modules: L<File::umask>

=item L<Locale::Tie>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Provides C<$LANG>, C<$LC_ALL>, C<$LC_TIME>, and few others to let you (temporarily)
set locale settings.


=item L<Locale::Scope>

Author: L<KARUPA|https://metacpan.org/author/KARUPA>

Like L<Locale::Tie>, but instead of using a tied variable, uses an object with
its C<DESTROY> method restoring original settings.


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

 % cpanm-cpanmodules -n MagicVariableTechnique

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries MagicVariableTechnique | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=MagicVariableTechnique -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::MagicVariableTechnique -E'say $_->{module} for @{ $Acme::CPANModules::MagicVariableTechnique::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-MagicVariableTechnique>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-MagicVariableTechnique>.

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

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-MagicVariableTechnique>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
