package App::CompleteCLIs;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'App-CompleteCLIs'; # DIST
our $VERSION = '0.152'; # VERSION

1;
# ABSTRACT: CLI front-end for the complete_*() functions from Complete::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CompleteCLIs - CLI front-end for the complete_*() functions from Complete::* modules

=head1 VERSION

This document describes version 0.152 of App::CompleteCLIs (from Perl distribution App-CompleteCLIs), released on 2023-01-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution comes with the following CLI's from the various C<Complete::*>
modules. They are meant for convenient testing of the various C<complete_*>
functions on the command-line.

=over

=item * L<complete-acme-metasyntactic-meta-category>

=item * L<complete-acme-metasyntactic-meta-theme>

=item * L<complete-acme-metasyntactic-meta-theme-and-category>

=item * L<complete-array-elem>

=item * L<complete-chrome-profile-name>

=item * L<complete-country-code>

=item * L<complete-currency-code>

=item * L<complete-cwalitee-indicator>

=item * L<complete-dist>

=item * L<complete-dzil-bundle>

=item * L<complete-dzil-plugin>

=item * L<complete-dzil-role>

=item * L<complete-env>

=item * L<complete-env-elem>

=item * L<complete-file>

=item * L<complete-firefox-profile-name>

=item * L<complete-float>

=item * L<complete-from-schema>

=item * L<complete-gid>

=item * L<complete-group>

=item * L<complete-hash-key>

=item * L<complete-idx-listed-stock-code>

=item * L<complete-int>

=item * L<complete-kernel>

=item * L<complete-known-host>

=item * L<complete-known-mac>

=item * L<complete-language-code>

=item * L<complete-locale>

=item * L<complete-manpage>

=item * L<complete-manpage-section>

=item * L<complete-module>

=item * L<complete-path-env-elem>

=item * L<complete-perl-builtin-function>

=item * L<complete-perl-builtin-symbol>

=item * L<complete-perl-version>

=item * L<complete-perlmv-scriptlet>

=item * L<complete-pid>

=item * L<complete-pod>

=item * L<complete-ppr-subpattern>

=item * L<complete-proc-name>

=item * L<complete-program>

=item * L<complete-random-string>

=item * L<complete-rclone-remote>

=item * L<complete-regexp-pattern-module>

=item * L<complete-regexp-pattern-pattern>

=item * L<complete-riap-url>

=item * L<complete-riap-url-clientless>

=item * L<complete-service-name>

=item * L<complete-service-port>

=item * L<complete-tz-name>

=item * L<complete-tz-offset>

=item * L<complete-uid>

=item * L<complete-user>

=item * L<complete-vivaldi-profile-name>

=item * L<complete-weaver-bundle>

=item * L<complete-weaver-plugin>

=item * L<complete-weaver-role>

=item * L<complete-weaver-section>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CompleteCLIs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CompleteCLIs>.

=head1 SEE ALSO

L<Complete>

C<Complete::*> modules

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

This software is copyright (c) 2023, 2021, 2020, 2019, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CompleteCLIs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
