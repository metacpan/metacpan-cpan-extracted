package Acme::CPANModules::UnixCommandImplementations;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-13'; # DATE
our $DIST = 'Acme-CPANModules-UnixCommandImplementations'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "List of various CLIs that try to reimplement traditional Unix commands",
    description => <<'MARKDOWN',

MARKDOWN
    entries => [
        {
            module => 'PerlPowerTools',
            script => [qw/

                addbib apply ar arch arithmetic asa awk banner base64 basename
                bc bcd cal cat chgrp ching chmod chown clear cmp col colrm comm
                cp cut date dc deroff diff dirname du echo ed env expand expr
                factor false file find fish fmt fold fortune from glob grep
                hangman head hexdump id install join kill ln lock look ls mail
                maze mimedecode mkdir mkfifo moo morse nl od par paste patch pig
                ping pom ppt pr primes printenv printf pwd rain random rev rm
                rmdir robots rot13 seq shar sleep sort spell split strings sum
                tac tail tar tee test time touch tr true tsort tty uname
                unexpand uniq units unlink unpar unshar uudecode uuencode wc
                what which whoami whois words wump xargs yes

                         /],
            'x.command' => [qw/

                addbib apply ar arch arithmetic asa awk banner base64 basename
                bc bcd cal cat chgrp ching chmod chown clear cmp col colrm comm
                cp cut date dc deroff diff dirname du echo ed env expand expr
                factor false file find fish fmt fold fortune from glob grep
                hangman head hexdump id install join kill ln lock look ls mail
                maze mimedecode mkdir mkfifo moo morse nl od par paste patch pig
                ping pom ppt pr primes printenv printf pwd rain random rev rm
                rmdir robots rot13 seq shar sleep sort spell split strings sum
                tac tail tar tee test time touch tr true tsort tty uname
                unexpand uniq units unlink unpar unshar uudecode uuencode wc
                what which whoami whois words wump xargs yes

                              /],
        },
    ],
};

1;
# ABSTRACT: List of various CLIs that try to reimplement traditional Unix commands

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::UnixCommandImplementations - List of various CLIs that try to reimplement traditional Unix commands

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::UnixCommandImplementations (from Perl distribution Acme-CPANModules-UnixCommandImplementations), released on 2024-08-13.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<PerlPowerTools>

Scripts: L<addbib>, L<apply>, L<ar>, L<arch>, L<arithmetic>, L<asa>, L<awk>, L<banner>, L<base64>, L<basename>, L<bc>, L<bcd>, L<cal>, L<cat>, L<chgrp>, L<ching>, L<chmod>, L<chown>, L<clear>, L<cmp>, L<col>, L<colrm>, L<comm>, L<cp>, L<cut>, L<date>, L<dc>, L<deroff>, L<diff>, L<dirname>, L<du>, L<echo>, L<ed>, L<env>, L<expand>, L<expr>, L<factor>, L<false>, L<file>, L<find>, L<fish>, L<fmt>, L<fold>, L<fortune>, L<from>, L<glob>, L<grep>, L<hangman>, L<head>, L<hexdump>, L<id>, L<install>, L<join>, L<kill>, L<ln>, L<lock>, L<look>, L<ls>, L<mail>, L<maze>, L<mimedecode>, L<mkdir>, L<mkfifo>, L<moo>, L<morse>, L<nl>, L<od>, L<par>, L<paste>, L<patch>, L<pig>, L<ping>, L<pom>, L<ppt>, L<pr>, L<primes>, L<printenv>, L<printf>, L<pwd>, L<rain>, L<random>, L<rev>, L<rm>, L<rmdir>, L<robots>, L<rot13>, L<seq>, L<shar>, L<sleep>, L<sort>, L<spell>, L<split>, L<strings>, L<sum>, L<tac>, L<tail>, L<tar>, L<tee>, L<test>, L<time>, L<touch>, L<tr>, L<true>, L<tsort>, L<tty>, L<uname>, L<unexpand>, L<uniq>, L<units>, L<unlink>, L<unpar>, L<unshar>, L<uudecode>, L<uuencode>, L<wc>, L<what>, L<which>, L<whoami>, L<whois>, L<words>, L<wump>, L<xargs>, L<yes>

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

 % cpanm-cpanmodules -n UnixCommandImplementations

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries UnixCommandImplementations | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=UnixCommandImplementations -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::UnixCommandImplementations -E'say $_->{module} for @{ $Acme::CPANModules::UnixCommandImplementations::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-UnixCommandImplementations>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-UnixCommandImplementations>.

=head1 SEE ALSO

L<Acme::CPANModules::UnixCommandVariants>

L<Acme::CPANModules::UnixCommandWrappers>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-UnixCommandImplementations>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
