package App::lcpan::Bootstrap;

our $DATE = '2019-05-20'; # DATE
our $VERSION = '20190520.0.0'; # VERSION

1;
# ABSTRACT: Bootstrap database for lcpan

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Bootstrap - Bootstrap database for lcpan

=head1 VERSION

This document describes version 20190520.0.0 of App::lcpan::Bootstrap (from Perl distribution App-lcpan-Bootstrap), released on 2019-05-20.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution contains the database for L<lcpan> (updated periodically), so
you can save time when setting up your local CPAN mirror the first time. Without
a boostrap database, indexing the mirror for the first time can take several
hours. With a fairly recent bootstrap database, indexing time can be reduced to
an hour or much less.

The compressed bootstrap database is stored in the distribution's share
directory. lcpan will search for this bootstrap database the first time it is
run.

If you run lcpan before installing this distribution, your empty database will
already be created. To use the bootstrap database, install this distribution,
remove the empty created F<index.db>, then run lcpan again.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-Bootstrap>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-Bootstrap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-Bootstrap>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::lcpan>, L<lcpan>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
