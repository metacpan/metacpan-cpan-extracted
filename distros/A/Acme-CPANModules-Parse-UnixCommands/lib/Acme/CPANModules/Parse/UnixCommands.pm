package Acme::CPANModules::Parse::UnixCommands;

our $DATE = '2019-03-10'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules that parse output of Unix commands",
    entries => [
        {module=>'Parse::Netstat', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::win32', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::linux', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::freebsd', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::darwin', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::solaris', summary=>'Parse netstat output'},
        {module=>'Cisco::ShowIPRoute::Parser', summary=>'Parse Cisco "show ip route" command'},
        {module=>'IPTables::Parse', summary=>'Parse iptables output'},
        {module=>'Proc::ProcessTable', summary=>'Parse "ps ax" output'},
        {module=>'Parse::IPCommand', summary=>'Parse linux "ip" command output'},
    ],
};

1;
# ABSTRACT: Modules that parse output of Unix commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Parse::UnixCommands - Modules that parse output of Unix commands

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Parse::UnixCommands (from Perl distribution Acme-CPANModules-Parse-UnixCommands), released on 2019-03-10.

=head1 DESCRIPTION

Modules that parse output of Unix commands.

=head1 INCLUDED MODULES

=over

=item * L<Parse::Netstat> - Parse netstat output

=item * L<Parse::Netstat::win32> - Parse netstat output

=item * L<Parse::Netstat::linux> - Parse netstat output

=item * L<Parse::Netstat::freebsd> - Parse netstat output

=item * L<Parse::Netstat::darwin> - Parse netstat output

=item * L<Parse::Netstat::solaris> - Parse netstat output

=item * L<Cisco::ShowIPRoute::Parser> - Parse Cisco "show ip route" command

=item * L<IPTables::Parse> - Parse iptables output

=item * L<Proc::ProcessTable> - Parse "ps ax" output

=item * L<Parse::IPCommand> - Parse linux "ip" command output

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Parse-UnixCommands>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Parse-UnixCommands>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Parse-UnixCommands>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::Parse::UnixConfigs>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
