package Acme::CPANModules::JSONVariants;

use strict;
use warnings;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-21'; # DATE
our $DIST = 'Acme-CPANModules-JSONVariants'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'MARKDOWN';
JSON is hugely popular, yet very simple. This has led to various extensions or
variants of JSON.

An overwhelmingly popular extension is comments, because JSON is used a lot in
configuration. Another popular extension is dangling (trailing) comma.

This list catalogs the various JSON variants which have a Perl implementation on
CPAN.


**JSON5**. <https://json5.org/>, "JSON for Humans". Allowing more whitespaces,
single-line comment (C++-style), multiline comment (C-style), single quote for
strings, hexadecimal number literal (e.g. 0x123abc), leading decimal point,
trailing decimal point, positive sign in number, trailing commas.

Perl modules: <pm:JSON5>, <pm:File::Serialize::Serializer::JSON5>.


1) **HJSON**. <https://hjson.org>, Human JSON. A JSON variant that aims to be
more user-friendly by allowing comments, unquoted keys, and optional commas.
It's designed to be easier to read and write by humans.

Perl modules: (none so far).


2) **JSONC**. JSON with Comments.

Perl modules: (none so far).


3) **CSON**. CofeeScript Object Notation. JSON-like data serialization format
inspired by CoffeeScript syntax. It allows for a more concise representation of
data by leveraging CoffeeScript's features such as significant whitespace and
optional commas.

Perl modules: (none so far).


4) **RJSON**. Relaxed JSON. Trailing commas, comments (C-style and C++-style),
single-quoted strings as well as bare/unquoted, hash key without value (value
will default to `undef`).

Perl modules: <pm:JSON::Relaxed>.


5) **<pm:JSON::Diffable>**. Basically just allowing for trailing commas.


6) **JSONLines**. <https://jsonlines.org>. A more restrictive JSON format, all
JSON records must fit in one line as newline is the record delimiter. Encoding
must be UTF-8. Convention for line-oriented processing which support JSON. E.g.
for CSV replacement.

Perl moduless: <pm:JSON::Lines>.


7) **YAML**. YAML is a superset of JSON. It allows for indentation-based syntax
and various features like references, heredocs, etc.

Perl modules: <pm:YAML>, <pm:YAML::PP>, among others.


MARKDOWN

our $LIST = {
    summary => 'List of JSON variants/extensions',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of JSON variants/extensions

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::JSONVariants - List of JSON variants/extensions

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::JSONVariants (from Perl distribution Acme-CPANModules-JSONVariants), released on 2024-03-21.

=head1 DESCRIPTION

JSON is hugely popular, yet very simple. This has led to various extensions or
variants of JSON.

An overwhelmingly popular extension is comments, because JSON is used a lot in
configuration. Another popular extension is dangling (trailing) comma.

This list catalogs the various JSON variants which have a Perl implementation on
CPAN.

B<JSON5>. L<https://json5.org/>, "JSON for Humans". Allowing more whitespaces,
single-line comment (C++-style), multiline comment (C-style), single quote for
strings, hexadecimal number literal (e.g. 0x123abc), leading decimal point,
trailing decimal point, positive sign in number, trailing commas.

Perl modules: L<JSON5>, L<File::Serialize::Serializer::JSON5>.

1) B<HJSON>. L<https://hjson.org>, Human JSON. A JSON variant that aims to be
more user-friendly by allowing comments, unquoted keys, and optional commas.
It's designed to be easier to read and write by humans.

Perl modules: (none so far).

2) B<JSONC>. JSON with Comments.

Perl modules: (none so far).

3) B<CSON>. CofeeScript Object Notation. JSON-like data serialization format
inspired by CoffeeScript syntax. It allows for a more concise representation of
data by leveraging CoffeeScript's features such as significant whitespace and
optional commas.

Perl modules: (none so far).

4) B<RJSON>. Relaxed JSON. Trailing commas, comments (C-style and C++-style),
single-quoted strings as well as bare/unquoted, hash key without value (value
will default to C<undef>).

Perl modules: L<JSON::Relaxed>.

5) B<< L<JSON::Diffable> >>. Basically just allowing for trailing commas.

6) B<JSONLines>. L<https://jsonlines.org>. A more restrictive JSON format, all
JSON records must fit in one line as newline is the record delimiter. Encoding
must be UTF-8. Convention for line-oriented processing which support JSON. E.g.
for CSV replacement.

Perl moduless: L<JSON::Lines>.

7) B<YAML>. YAML is a superset of JSON. It allows for indentation-based syntax
and various features like references, heredocs, etc.

Perl modules: L<YAML>, L<YAML::PP>, among others.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<JSON5>

Author: L<KARUPA|https://metacpan.org/author/KARUPA>

=item L<File::Serialize::Serializer::JSON5>

Author: L<YANICK|https://metacpan.org/author/YANICK>

=item L<JSON::Relaxed>

Author: L<MIKO|https://metacpan.org/author/MIKO>

=item L<JSON::Diffable>

Author: L<PHAYLON|https://metacpan.org/author/PHAYLON>

=item L<JSON::Lines>

Author: L<LNATION|https://metacpan.org/author/LNATION>

=item L<YAML>

Author: L<INGY|https://metacpan.org/author/INGY>

=item L<YAML::PP>

Author: L<TINITA|https://metacpan.org/author/TINITA>

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

 % cpanm-cpanmodules -n JSONVariants

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries JSONVariants | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=JSONVariants -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::JSONVariants -E'say $_->{module} for @{ $Acme::CPANModules::JSONVariants::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-JSONVariants>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-JSONVariants>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-JSONVariants>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
