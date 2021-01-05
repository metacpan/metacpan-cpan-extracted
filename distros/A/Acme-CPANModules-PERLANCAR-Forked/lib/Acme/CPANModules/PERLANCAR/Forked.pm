package Acme::CPANModules::PERLANCAR::Forked;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-22'; # DATE
our $DIST = 'Acme-CPANModules-PERLANCAR-Forked'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of my modules which are forked from others',
    description => <<'_',

This list serves as a reminder to check upstream for updates from time to time.

_
    entries => [
        {
            module => "PERLANCAR::Module::List",
            upstream_module => "Module::List",
            description => <<'_',

Also: <pm:Module::List::Tiny>, <pm:Module::List::Wildcard>.

_
        },
        {
            module => "Sys::RunAlone::Flexible",
            upstream_module => "Sys::RunAlone",
            description => <<'_',

Also: <pm:Sys::RunAlone::Flexible2>.

But since I have co-maint on <pm:Sys::RunAlone>, I plan to merge all these.

_
        },
        {
            module => "File::Slurper::Dash",
            upstream_module => "File::Slurper",
        },
        {
            module => "anywhere",
            upstream_module => "everywhere",
        },
        {
            module => "App::HTTPSThis",
            upstream_module => "App::HTTPThis",
        },
        {
            module => "Date::Extract::PERLANCAR",
            upstream_module => "Date::Extract",
        },
    ],
};

1;
# ABSTRACT: List of my modules which are forked from others

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Forked - List of my modules which are forked from others

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::Forked (from Perl distribution Acme-CPANModules-PERLANCAR-Forked), released on 2020-11-22.

=head1 DESCRIPTION

This list serves as a reminder to check upstream for updates from time to time.

=head1 MODULES INCLUDED IN THIS ACME::CPANMODULES MODULE

=over

=item * L<PERLANCAR::Module::List>

Also: L<Module::List::Tiny>, L<Module::List::Wildcard>.


=item * L<Sys::RunAlone::Flexible>

Also: L<Sys::RunAlone::Flexible2>.

But since I have co-maint on L<Sys::RunAlone>, I plan to merge all these.


=item * L<File::Slurper::Dash>

=item * L<anywhere>

=item * L<App::HTTPSThis>

=item * L<Date::Extract::PERLANCAR>

=back

=head1 FAQ

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries PERLANCAR::Forked | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::Forked -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::Forked -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::Forked::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-Forked>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-Forked>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PERLANCAR-Forked>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
