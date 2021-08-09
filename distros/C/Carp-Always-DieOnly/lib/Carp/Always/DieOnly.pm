package Carp::Always::DieOnly;

our $DATE = '2021-08-09'; # DATE
our $VERSION = '0.020'; # VERSION

use 5.006;

use Carp::Always 0.15 ();
BEGIN { our @ISA = qw(Carp::Always) }

sub _warn { warn @_ }

1;
# ABSTRACT: Like Carp::Always, but only print stacktrace on die()

__END__

=pod

=encoding UTF-8

=head1 NAME

Carp::Always::DieOnly - Like Carp::Always, but only print stacktrace on die()

=head1 VERSION

This document describes version 0.020 of Carp::Always::DieOnly (from Perl distribution Carp-Always-DieOnly), released on 2021-08-09.

=head1 SYNOPSIS

 % perl -MCarp::Always::DieOnly script.pl

=head1 CONTRIBUTOR

=for stopwords Adriano Ferreira

Adriano Ferreira <a.r.ferreira@gmail.com>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Carp-Always-DieOnly>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Carp-Always-DieOnly>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Always-DieOnly>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Carp::Always>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
