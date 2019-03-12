package Acme::CPANModules::Parse::UnixConfigs;

our $DATE = '2019-03-10'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules that parse Unix config (or related) files",
    entries => [
        {module=>'Config::Model'},
        {module=>'Parse::Hosts', summary=>'Parse /etc/hosts'},
        {module=>'Parse::Services', summary=>'Parse /etc/services'},
        {module=>'Parse::Sums', summary=>'Parse checksums file, e.g. MD5SUMS, SHA1SUMS'},
        {module=>'Data::SSHPubkey', summary=>'Parse SSH public keys'},
    ],
};

1;
# ABSTRACT: Modules that parse Unix config (or related) files

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Parse::UnixConfigs - Modules that parse Unix config (or related) files

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Parse::UnixConfigs (from Perl distribution Acme-CPANModules-Parse-UnixConfigs), released on 2019-03-10.

=head1 DESCRIPTION

Modules that parse Unix config (or related) files.

=head1 INCLUDED MODULES

=over

=item * L<Config::Model>

=item * L<Parse::Hosts> - Parse /etc/hosts

=item * L<Parse::Services> - Parse /etc/services

=item * L<Parse::Sums> - Parse checksums file, e.g. MD5SUMS, SHA1SUMS

=item * L<Data::SSHPubkey> - Parse SSH public keys

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Parse-UnixConfigs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Parse-UnixConfigs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Parse-UnixConfigs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::Parse::UnixCommands>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
