package Acme::CPANModules::RandomData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-26'; # DATE
our $DIST = 'Acme-CPANModules-RandomData'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';
**Generating**

<pm:Data::Random> generates random number, random generated word, random
dictionary word (default wordlist provided), date (in YYYY-MM-DD format), time
(in HH::MM:SS format), datetime, image (just a blank PNG with random size and
background color).

For more specific types of random data (person, password, etc), see other lists
mentioned below.

Keywords: random data.

_

our $LIST = {
    summary => 'Generating random person (name, title, age, etc)',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Generating random person (name, title, age, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::RandomData - Generating random person (name, title, age, etc)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::RandomData (from Perl distribution Acme-CPANModules-RandomData), released on 2021-05-26.

=head1 DESCRIPTION

B<Generating>

L<Data::Random> generates random number, random generated word, random
dictionary word (default wordlist provided), date (in YYYY-MM-DD format), time
(in HH::MM:SS format), datetime, image (just a blank PNG with random size and
background color).

For more specific types of random data (person, password, etc), see other lists
mentioned below.

Keywords: random data.

=head1 ACME::MODULES ENTRIES

=over

=item * L<Data::Random>

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

 % cpanm-cpanmodules -n RandomData

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries RandomData | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=RandomData -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::RandomData -E'say $_->{module} for @{ $Acme::CPANModules::RandomData::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-RandomData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-RandomData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-RandomData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::RandomPerson>

L<Acme::CPANModules::RandomPassword>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
