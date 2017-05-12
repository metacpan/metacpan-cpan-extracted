package Borang;

our $DATE = '2015-09-22'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;

1;
# ABSTRACT: Function-oriented form framework

__END__

=pod

=encoding UTF-8

=head1 NAME

Borang - Function-oriented form framework

=head1 VERSION

This document describes version 0.02 of Borang (from Perl distribution Borang), released on 2015-09-22.

=head1 DESCRIPTION

B<EARLY RELEASE, WORK IN PROGRESS, MANY THINGS ARE NOT YET IMPLEMENTED>.

Borang is a function-oriented form framework. Borang can generate forms using
information from L<Rinci> function metadata. After you fill out and submit a
form, the form submission will be converted into function arguments and sent to
the function via function call.

Borang is environment-agnostic: it can target HTML forms as well as CLI/CUI/GUI.

=head1 FAQ

=head2 What does "borang" mean?

Borang means form in Indonesian and is currently seldom used in daily
conversations.

=head1 SEE ALSO

L<Rinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Borang>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Borang>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Borang>

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
