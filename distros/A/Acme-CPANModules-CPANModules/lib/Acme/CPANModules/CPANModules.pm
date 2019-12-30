package Acme::CPANModules::CPANModules;

our $DATE = '2019-11-19'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules related to Acme::CPANModules',
    description => <<'_',

## Specification

<pm:Acme::CPANModules> is the specification.


## CLIs

<pm:App::cpanmodules> distribution contains the `cpanmodules` CLI to view lists
and entries from the command-line.

<pm:App::lcpan::CmdBundle::cpanmodules> distribution provides `cpanmodules-*`
subcommands for <pm:App::lcpan> which, like `cpanmodules` CLI, lets you view
lists and entries from the command-line.

<pm:App::CPANModulesUtils> distribution contains more CLI utilities related to
Acme::CPANModules, e.g. `acme-cpanmodules-for` to find whether a module is
mentioned in some Acme::CPANModules::* modules.

<pm:App::CreateAcmeCPANModulesImportModules>

<pm:App::CreateAcmeCPANModulesImportCPANRatingsModules>


## Dist::Zilla (and Pod::Weaver)

If you develop CPAN modules with Dist::Zilla, you can use
<pm:Dist::Zilla::Plugin::Acme::CPANModules> and
<pm:Pod::Weaver::Plugin::Acme::CPANModules>. There is also
<pm:Dist::Zilla::Plugin::Acme::CPANModules::Blacklist> to prevent adding
blacklisted dependencies into your distribution.


## Other modules

<pm:Acme::CPANLists> is an older, deprecated specification.

<pm:Pod::From::Acme::CPANModules>


## Snippets

Acme::CPANModules::CPANModules contains this snippet to create entries by
extracting `<pm:...>` in the description:

    $LIST->{entries} = [
        map { +{module=>$_} }
            ($LIST->{description} =~ /<pm:(.+?)>/g)
    ];

This does not prevent duplicates. To do so:

    $LIST->{entries} = [
        map { +{module=>$_} }
            do { my %seen; grep { !$seen{$_}++ }
                 ($LIST->{description} =~ /<pm:(.+?)>/g)
             }
    ];

_
    'x.app.cpanmodules.show_entries' => 0,
};

$LIST->{entries} = [
    map { +{module=>$_} }
        do { my %seen; grep { !$seen{$_}++ }
             ($LIST->{description} =~ /<pm:(\w+(?:::\w+)*)>/g)
         }
];

1;
# ABSTRACT: Modules related to Acme::CPANModules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CPANModules - Modules related to Acme::CPANModules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CPANModules (from Perl distribution Acme-CPANModules-CPANModules), released on 2019-11-19.

=head1 DESCRIPTION

Modules related to Acme::CPANModules.

=head2 Specification

L<Acme::CPANModules> is the specification.

=head2 CLIs

L<App::cpanmodules> distribution contains the C<cpanmodules> CLI to view lists
and entries from the command-line.

L<App::lcpan::CmdBundle::cpanmodules> distribution provides C<cpanmodules-*>
subcommands for L<App::lcpan> which, like C<cpanmodules> CLI, lets you view
lists and entries from the command-line.

L<App::CPANModulesUtils> distribution contains more CLI utilities related to
Acme::CPANModules, e.g. C<acme-cpanmodules-for> to find whether a module is
mentioned in some Acme::CPANModules::* modules.

L<App::CreateAcmeCPANModulesImportModules>

L<App::CreateAcmeCPANModulesImportCPANRatingsModules>

=head2 Dist::Zilla (and Pod::Weaver)

If you develop CPAN modules with Dist::Zilla, you can use
L<Dist::Zilla::Plugin::Acme::CPANModules> and
L<Pod::Weaver::Plugin::Acme::CPANModules>. There is also
L<Dist::Zilla::Plugin::Acme::CPANModules::Blacklist> to prevent adding
blacklisted dependencies into your distribution.

=head2 Other modules

L<Acme::CPANLists> is an older, deprecated specification.

L<Pod::From::Acme::CPANModules>

=head2 Snippets

Acme::CPANModules::CPANModules contains this snippet to create entries by
extracting C<< E<lt>pm:...E<gt> >> in the description:

 $LIST->{entries} = [
     map { +{module=>$_} }
         ($LIST->{description} =~ /<pm:(.+?)>/g)
 ];

This does not prevent duplicates. To do so:

 $LIST->{entries} = [
     map { +{module=>$_} }
         do { my %seen; grep { !$seen{$_}++ }
              ($LIST->{description} =~ /<pm:(.+?)>/g)
          }
 ];

=head1 INCLUDED MODULES

=over

=item * L<Acme::CPANModules>

=item * L<App::cpanmodules>

=item * L<App::lcpan::CmdBundle::cpanmodules>

=item * L<App::lcpan>

=item * L<App::CPANModulesUtils>

=item * L<App::CreateAcmeCPANModulesImportModules>

=item * L<App::CreateAcmeCPANModulesImportCPANRatingsModules>

=item * L<Dist::Zilla::Plugin::Acme::CPANModules>

=item * L<Pod::Weaver::Plugin::Acme::CPANModules>

=item * L<Dist::Zilla::Plugin::Acme::CPANModules::Blacklist>

=item * L<Acme::CPANLists>

=item * L<Pod::From::Acme::CPANModules>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CPANModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
