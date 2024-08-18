package Acme::CPANModules::MultipleDispatch;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-01'; # DATE
our $DIST = 'Acme-CPANModules-MultipleDispatch'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'MARKDOWN';
**About multiple dispatch**

Multiple dispatch is a technique where you can define /multiple/ functions (or
methods) of the same name but with different signatures (e.g. different type of
arguments, different number of arguments) and the runtime will choose
(/dispatch/) the correct function by matching the signature of the caller to
that of the defined functions.

This technique has several benefits, mostly simplifying user code particularly
when dealing with different types/arguments, because you are deferring the
checks to the runtime. For example, if you create a function to concat two
strings:

    function combine(Str a, Str b) {
        a + b;
    }

and later wants to support some other types, instead of peppering the original
function with `if` statements, you can just supply additional functions with the
same name but with different arguments you want to support:

    function combine(Num a, Num b) {
        a.as_str() + b.as_str();
    }

    function combine(File a, File b) {
        a.open().read() + b.open().read();
    }

Some languages, particularly strongly-typed ones, support multiple dispatch:
Julia, C#, Common Lisp, Groovy. Raku (Perl 6) also supports multiple dispatch.

Perl 5 does not. But some modules will allow you to fake it.


**Modules**

<pm:Multi::Dispatch>. By DCONWAY.

<pm:Dios>. Also by DCONWAY. An object system which supports multiple dispatch.

<pm:Class::Multimethods>. Older module by DCONWAY.


**Keywords**

multi dispatch, multisub, multimethod.

MARKDOWN

our $LIST = {
    summary => 'List of modules to do smart matching',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to do smart matching

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::MultipleDispatch - List of modules to do smart matching

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::MultipleDispatch (from Perl distribution Acme-CPANModules-MultipleDispatch), released on 2024-07-01.

=head1 DESCRIPTION

B<About multiple dispatch>

Multiple dispatch is a technique where you can define /multiple/ functions (or
methods) of the same name but with different signatures (e.g. different type of
arguments, different number of arguments) and the runtime will choose
(/dispatch/) the correct function by matching the signature of the caller to
that of the defined functions.

This technique has several benefits, mostly simplifying user code particularly
when dealing with different types/arguments, because you are deferring the
checks to the runtime. For example, if you create a function to concat two
strings:

 function combine(Str a, Str b) {
     a + b;
 }

and later wants to support some other types, instead of peppering the original
function with C<if> statements, you can just supply additional functions with the
same name but with different arguments you want to support:

 function combine(Num a, Num b) {
     a.as_str() + b.as_str();
 }
 
 function combine(File a, File b) {
     a.open().read() + b.open().read();
 }

Some languages, particularly strongly-typed ones, support multiple dispatch:
Julia, C#, Common Lisp, Groovy. Raku (Perl 6) also supports multiple dispatch.

Perl 5 does not. But some modules will allow you to fake it.

B<Modules>

L<Multi::Dispatch>. By DCONWAY.

L<Dios>. Also by DCONWAY. An object system which supports multiple dispatch.

L<Class::Multimethods>. Older module by DCONWAY.

B<Keywords>

multi dispatch, multisub, multimethod.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Multi::Dispatch>

Author: L<DCONWAY|https://metacpan.org/author/DCONWAY>

=item L<Dios>

Author: L<DCONWAY|https://metacpan.org/author/DCONWAY>

=item L<Class::Multimethods>

Author: L<DCONWAY|https://metacpan.org/author/DCONWAY>

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

 % cpanm-cpanmodules -n MultipleDispatch

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries MultipleDispatch | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=MultipleDispatch -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::MultipleDispatch -E'say $_->{module} for @{ $Acme::CPANModules::MultipleDispatch::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-MultipleDispatch>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-MultipleDispatch>.

=head1 SEE ALSO

L<Bencher::ScenarioBundle::SmartMatch>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-MultipleDispatch>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
