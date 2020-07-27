package Acme::CPANModules::SExpression;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-10'; # DATE
our $DIST = 'Acme-CPANModules-SExpression'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';
**Parsing**

<pm::Data::SExpression>

<pm::SExpression::Decode::Marpa>

<pm::SExpression::Decode::Regexp>


**Dumping**

<pm:Data::Dumper::LispLike>

<pm:Data::Dump::SExpression>


_

our $LIST = {
    summary => 'Working with S-expression in Perl',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Working with S-expression in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::SExpression - Working with S-expression in Perl

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::SExpression (from Perl distribution Acme-CPANModules-SExpression), released on 2020-04-10.

=head1 DESCRIPTION

Working with S-expression in Perl.

B<Parsing>

<pm::Data::SExpression>

<pm::SExpression::Decode::Marpa>

<pm::SExpression::Decode::Regexp>

B<Dumping>

L<Data::Dumper::LispLike>

L<Data::Dump::SExpression>

=head1 INCLUDED MODULES

=over

=item * L<Data::Dumper::LispLike>

=item * L<Data::Dump::SExpression>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries SExpression | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=SExpression -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-SExpression>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-SExpression>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-SExpression>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
