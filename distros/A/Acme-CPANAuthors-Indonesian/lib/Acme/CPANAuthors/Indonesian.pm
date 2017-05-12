package Acme::CPANAuthors::Indonesian;

our $DATE = '2014-09-09'; # DATE
our $VERSION = '0.04'; # VERSION

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    DNS         => 'Daniel Sirait',
    EDPRATOMO   => 'Edwin Pratomo',
    HASANT      => 'Hasanuddin Tamir',
    PERLANCAR   => 'perlancar',
    SHARYANTO   => 'Steven Haryanto',
);

1;
# ABSTRACT: We are Indonesian CPAN authors (Kami para penulis CPAN Indonesia)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Indonesian - We are Indonesian CPAN authors (Kami para penulis CPAN Indonesia)

=head1 VERSION

This document describes version 0.04 of Acme::CPANAuthors::Indonesian (from Perl distribution Acme-CPANAuthors-Indonesian), released on 2014-09-09.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::Indonesian;

   my $authors = Acme::CPANAuthors->new('Indonesian');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('HASANT');
   my $url      = $authors->avatar_url('EDPRATOMO');
   my $kwalitee = $authors->kwalitee('SHARYANTO');

=head1 DESCRIPTION

This class is used to provide a hash of Indonesian CPAN author's PAUSE id/name
to Acme::CPANAuthors.

=head1 MAINTENANCE

If you are an Indonesian CPAN author not listed here, please send me your
id/name via email or RT so we can always keep this module up to date. If there's
a mistake and you're listed here but are not Indonesian (or just don't want to
be listed), sorry for the inconvenience: please contact me and I'll remove the
entry right away.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-Indonesian>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-Indonesian>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-Indonesian>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
