package Acme::CPANModules::Parse::UnixCommands;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-01-21'; # DATE
our $DIST = 'Acme-CPANModules-Parse-UnixCommands'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => "Modules that parse output of Unix commands",
    entries => [
        {module=>'Cisco::ShowIPRoute::Parser', summary=>'Parse Cisco "show ip route" command'},
        {module=>'IPTables::Parse', summary=>'Parse iptables output'},
        {module=>'Parse::IPCommand', summary=>'Parse linux "ip" command output'},
        {module=>'Parse::Netstat::darwin', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::freebsd', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::linux', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::solaris', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat', summary=>'Parse netstat output'},
        {module=>'Parse::Netstat::win32', summary=>'Parse netstat output'},
        {module=>'Parse::nm', summary=>'Parse nm output'},
        {module=>'Proc::ProcessTable', summary=>'Parse "ps ax" output'},
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

This document describes version 0.003 of Acme::CPANModules::Parse::UnixCommands (from Perl distribution Acme-CPANModules-Parse-UnixCommands), released on 2022-01-21.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Cisco::ShowIPRoute::Parser>

Parse Cisco "show ip route" command.

Author: L<MARKPF|https://metacpan.org/author/MARKPF>

=item L<IPTables::Parse>

Parse iptables output.

Author: L<MRASH|https://metacpan.org/author/MRASH>

=item L<Parse::IPCommand>

Parse linux "ip" command output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Netstat::darwin>

Parse netstat output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Netstat::freebsd>

Parse netstat output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Netstat::linux>

Parse netstat output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Netstat::solaris>

Parse netstat output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Netstat>

Parse netstat output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::Netstat::win32>

Parse netstat output.

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Parse::nm>

Parse nm output.

Author: L<DOLMEN|https://metacpan.org/author/DOLMEN>

=item L<Proc::ProcessTable>

Parse "ps ax" output.

Author: L<JWB|https://metacpan.org/author/JWB>

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

 % cpanm-cpanmodules -n Parse::UnixCommands

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Parse::UnixCommands | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Parse::UnixCommands -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Parse::UnixCommands -E'say $_->{module} for @{ $Acme::CPANModules::Parse::UnixCommands::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Parse-UnixCommands>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Parse-UnixCommands>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::Parse::UnixConfigs>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Parse-UnixCommands>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
