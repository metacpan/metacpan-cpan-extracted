package Acme::CPANModules::Foozilla;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Acme-CPANModules-Foozilla'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';

Do you want to name your project "<something>zilla", but searching MetaCPAN is
difficult because everything is about <pm:Dist::Zilla>? Here's a little help.
I've searched using `lcpan` (from <pm:App::lcpan>):

    lcpan mods --query-type name zilla | grep -iv Dist::

and the following is the summary.

**Mozilla**

Of course, Mozilla is the biggest name of things foozilla. There's a rather
decent `Mozilla::` namespace on CPAN with notable modules like <pm:Mozilla::DOM>
and <pm:Mozilla::Mechanize>. There are also <pm:Software::License::Mozilla_2_0>
(and its siblings), <pm:Graphics::ColorNames::Mozilla>, or <pm:Wx::Mozilla>.

**Bugzilla**

Also from the Mozilla project, hence the name. We have <WWW::Bugzilla> on CPAN,
but as you know Bugzilla itself is also written in Perl.

**Filezilla**

I can only find the following modules related to this popular file transfer
software: <pm:Software::Catalog::SW::filezilla>.

**That's it**

Vast world awaits for your new `*`zilla project.

_

our $LIST = {
    summary => "Ideas for module/script/project name using 'zilla'",
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Ideas for module/script/project name using 'zilla'

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Foozilla - Ideas for module/script/project name using 'zilla'

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Foozilla (from Perl distribution Acme-CPANModules-Foozilla), released on 2021-08-04.

=head1 DESCRIPTION

Do you want to name your project "<something>zilla", but searching MetaCPAN is
difficult because everything is about L<Dist::Zilla>? Here's a little help.
I've searched using C<lcpan> (from L<App::lcpan>):

 lcpan mods --query-type name zilla | grep -iv Dist::

and the following is the summary.

B<Mozilla>

Of course, Mozilla is the biggest name of things foozilla. There's a rather
decent C<Mozilla::> namespace on CPAN with notable modules like L<Mozilla::DOM>
and L<Mozilla::Mechanize>. There are also L<Software::License::Mozilla_2_0>
(and its siblings), L<Graphics::ColorNames::Mozilla>, or L<Wx::Mozilla>.

B<Bugzilla>

Also from the Mozilla project, hence the name. We have <WWW::Bugzilla> on CPAN,
but as you know Bugzilla itself is also written in Perl.

B<Filezilla>

I can only find the following modules related to this popular file transfer
software: L<Software::Catalog::SW::filezilla>.

B<That's it>

Vast world awaits for your new C<*>zilla project.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Dist::Zilla>

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item L<App::lcpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Mozilla::DOM>

Author: L<SLANNING|https://metacpan.org/author/SLANNING>

=item L<Mozilla::Mechanize>

Author: L<SLANNING|https://metacpan.org/author/SLANNING>

=item L<Software::License::Mozilla_2_0>

Author: L<LEONT|https://metacpan.org/author/LEONT>

=item L<Graphics::ColorNames::Mozilla>

Author: L<XAVIER|https://metacpan.org/author/XAVIER>

=item L<Wx::Mozilla>

Author: L<DSUGAL|https://metacpan.org/author/DSUGAL>

=item L<Software::Catalog::SW::filezilla>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n Foozilla

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Foozilla | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Foozilla -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Foozilla -E'say $_->{module} for @{ $Acme::CPANModules::Foozilla::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Foozilla>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Foozilla>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Foozilla>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
