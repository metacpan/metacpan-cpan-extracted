package Complete::Dpkg;

our $DATE = '2015-11-30'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_dpkg
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to Debian packages',
};

1;
# ABSTRACT: Completion routines related to Debian packages

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Dpkg - Completion routines related to Debian packages

=head1 VERSION

This document describes version 0.02 of Complete::Dpkg (from Perl distribution Complete-Dpkg), released on 2015-11-30.

=head1 DESCRIPTION

B<NAME GRAB. NOT YET IMPLEMENTED.>

=for Pod::Coverage .+

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Dpkg>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Dpkg>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Dpkg>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
