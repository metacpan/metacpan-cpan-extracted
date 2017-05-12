package Acme::CPANAuthors::Icelandic;
BEGIN {
  $Acme::CPANAuthors::Icelandic::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $Acme::CPANAuthors::Icelandic::VERSION = '0.04';
}

use strict;
use warnings FATAL => 'all';
use utf8;

use Acme::CPANAuthors::Register (
    ADDI      => 'Arnar Mar Hrafnkelsson',
    AVAR      => 'Ævar Arnfjörð Bjarmason',
    BALDUR    => 'Baldur Kristinsson',
    HINRIK    => 'Hinrik Örn Sigurðsson',
    HRAFNKELL => 'Hrafnkell Freyr Hlöðversson',
);

1;

=encoding utf8

=head1 NAME

Acme::CPANAuthors::Icelandic - We are Icelandic CPAN authors

=head1 SYNOPSIS

    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new('Icelandic');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions("HINRIK");
    my $url      = $authors->avatar_url("HINRIK");
    my $kwalitee = $authors->kwalitee("HINRIK");
    my $name     = $authors->name("HINRIK");

See documentation for L<Acme::CPANAuthors|Acme::CPANAuthors> for more details.

=head1 DESCRIPTION

This class provides a hash of Icelandic CPAN authors' PAUSE ID and name to
the C<Acme::CPANAuthors|Acme::CPANAuthors> module.

=head1 MAINTENANCE

If you are an Icelandic CPAN author not listed here, please send me your
ID/name via email or RT so I can keep this module up to date.

And if you are not and Icelandic CPAN author but still listed here, please
send me your ID/name via email or RT and I will remove your name.

=head1 CONTAINED AUTHORS

Now listing B<5> Icelandic CPAN authors:

 ADDI      => 'Arnar Mar Hrafnkelsson',
 AVAR      => 'Ævar Arnfjörð Bjarmason',
 BALDUR    => 'Baldur Kristinsson',
 HINRIK    => 'Hinrik Örn Sigurðsson',
 HRAFNKELL => 'Hrafnkell Freyr Hlöðversson',

=head1 SEE ALSO

L<Acme::CPANAuthors::Acme::CPANAuthors::Authors>

L<http://search.cpan.org/search?query=Acme%3A%3ACPANAuthors&mode=all>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-cpanauthors-icelandic at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-CPANAuthors-Icelandic>.
I will be notified, and then you'll automatically be notified of progress
on your bug as we make changes.

=head1 AUTHOR

Hinrik Örn Sigurðsson, <L<hinrik.sig@gmail.com>>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 by Hinrik Örn Sigurðsson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
