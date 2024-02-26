package App::CompleteCLIs;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-01'; # DATE
our $DIST = 'App-CompleteCLIs'; # DIST
our $VERSION = '0.153'; # VERSION

1;
# ABSTRACT: CLI front-end for the complete_*() functions from Complete::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CompleteCLIs - CLI front-end for the complete_*() functions from Complete::* modules

=head1 VERSION

This document describes version 0.153 of App::CompleteCLIs (from Perl distribution App-CompleteCLIs), released on 2023-12-01.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution comes with the following CLI's from the various C<Complete::*>
modules. They are meant for convenient testing of the various C<complete_*>
functions on the command-line.

=over

=item 1. L<complete-acme-metasyntactic-meta-category>

=item 2. L<complete-acme-metasyntactic-meta-theme>

=item 3. L<complete-acme-metasyntactic-meta-theme-and-category>

=item 4. L<complete-array-elem>

=item 5. L<complete-chrome-profile-name>

=item 6. L<complete-color-name>

=item 7. L<complete-color-rgb24-hexcode>

=item 8. L<complete-country-code>

=item 9. L<complete-currency-code>

=item 10. L<complete-cwalitee-indicator>

=item 11. L<complete-dist>

=item 12. L<complete-dzil-bundle>

=item 13. L<complete-dzil-plugin>

=item 14. L<complete-dzil-role>

=item 15. L<complete-env>

=item 16. L<complete-env-elem>

=item 17. L<complete-file>

=item 18. L<complete-firefox-profile-name>

=item 19. L<complete-float>

=item 20. L<complete-from-schema>

=item 21. L<complete-gid>

=item 22. L<complete-group>

=item 23. L<complete-hash-key>

=item 24. L<complete-idx-listed-stock-code>

=item 25. L<complete-int>

=item 26. L<complete-kernel>

=item 27. L<complete-known-host>

=item 28. L<complete-known-mac>

=item 29. L<complete-language-code>

=item 30. L<complete-locale>

=item 31. L<complete-manpage>

=item 32. L<complete-manpage-section>

=item 33. L<complete-module>

=item 34. L<complete-path-env-elem>

=item 35. L<complete-perl-builtin-function>

=item 36. L<complete-perl-builtin-symbol>

=item 37. L<complete-perl-version>

=item 38. L<complete-perlmv-scriptlet>

=item 39. L<complete-pid>

=item 40. L<complete-pod>

=item 41. L<complete-ppr-subpattern>

=item 42. L<complete-proc-name>

=item 43. L<complete-program>

=item 44. L<complete-random-string>

=item 45. L<complete-rclone-remote>

=item 46. L<complete-regexp-pattern-module>

=item 47. L<complete-regexp-pattern-pattern>

=item 48. L<complete-riap-url>

=item 49. L<complete-riap-url-clientless>

=item 50. L<complete-service-name>

=item 51. L<complete-service-port>

=item 52. L<complete-tz-name>

=item 53. L<complete-tz-offset>

=item 54. L<complete-uid>

=item 55. L<complete-user>

=item 56. L<complete-vivaldi-profile-name>

=item 57. L<complete-weaver-bundle>

=item 58. L<complete-weaver-plugin>

=item 59. L<complete-weaver-role>

=item 60. L<complete-weaver-section>

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
