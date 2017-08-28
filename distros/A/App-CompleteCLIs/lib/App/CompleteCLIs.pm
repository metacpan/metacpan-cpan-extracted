package App::CompleteCLIs;

our $DATE = '2017-08-18'; # DATE
our $VERSION = '0.13'; # VERSION

use 5.010001;
use strict;
use warnings;

1;
# ABSTRACT: CLI wrappers for complete_*() functions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CompleteCLIs - CLI wrappers for complete_*() functions

=head1 VERSION

This document describes version 0.13 of App::CompleteCLIs (from Perl distribution App-CompleteCLIs), released on 2017-08-18.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution comes with the following CLI's from the various C<Complete::*>
modules. They are meant for convenient testing of the various C<complete_*>
functions on the command-line.

=over

=item * L<complete-array-elem>

=item * L<complete-dist>

=item * L<complete-dzil-bundle>

=item * L<complete-dzil-plugin>

=item * L<complete-dzil-role>

=item * L<complete-env>

=item * L<complete-env-elem>

=item * L<complete-file>

=item * L<complete-float>

=item * L<complete-gid>

=item * L<complete-group>

=item * L<complete-hash-key>

=item * L<complete-int>

=item * L<complete-kernel>

=item * L<complete-known-host>

=item * L<complete-known-mac>

=item * L<complete-locale>

=item * L<complete-manpage>

=item * L<complete-manpage-section>

=item * L<complete-module>

=item * L<complete-path-env-elem>

=item * L<complete-perl-builtin-function>

=item * L<complete-perl-builtin-symbol>

=item * L<complete-perl-version>

=item * L<complete-pid>

=item * L<complete-ppr-subpattern>

=item * L<complete-proc-name>

=item * L<complete-program>

=item * L<complete-regexp-pattern-module>

=item * L<complete-regexp-pattern-pattern>

=item * L<complete-riap-url>

=item * L<complete-riap-url-clientless>

=item * L<complete-service-name>

=item * L<complete-service-port>

=item * L<complete-tz>

=item * L<complete-uid>

=item * L<complete-user>

=item * L<complete-weaver-bundle>

=item * L<complete-weaver-plugin>

=item * L<complete-weaver-role>

=item * L<complete-weaver-section>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CompleteCLIs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CompleteCLIs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CompleteCLIs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

C<Complete::*> modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
