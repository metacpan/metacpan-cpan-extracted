package Acme::CPANAuthors::Polish;
use utf8;

use strict;
use warnings;

our $VERSION = '0.03';

use Acme::CPANAuthors::Register (
    ADAMOWSKI => 'Aleksander Adamowski',
    AJGB      => 'Alex J. G. Burzyński',
    ANNIHITEK => 'Mateusz Szczyrzyca',
    BIESZCZAD => 'Krzysztof Bieszczad',
    DADAMK    => 'Darek Adamkiewicz',
    DEPESZ    => 'Hubert depesz Lubaczewski',
    DEXTER    => 'Piotr Roszatycki',
    GBSHOUSE  => 'Piotr Ginalski',
    GLITCHMR  => 'Konrad Borowski',
    IZI       => 'Krzysztof Suchomski',
    MCEGLOWS  => 'Maciej Ceglowski',
    ODYNIEC   => 'Michał Wojciechowski',
    PAPKALA   => 'Grzegorz Papkala',
    PCZERKAS  => 'Przemek Czerkas',
    PKALUSKI  => 'Piotr Kałuski',
    PWES      => 'Przemysław Wesołek',
    SEBNOW    => 'Sebastian Nowicki',
    STRZELEC  => 'Łukasz Strzelecki',
    TADZIK    => 'Tadeusz Sośnierz',
    XAERXESS  => 'Grzegorz Rożniecki',
    XENU      => 'Tomasz Konojacki',
    ZBY       => 'Zbigniew Łukasiak',
    ZBYS      => 'Zbigniew Sroczynski',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Polish - We are Polish CPAN authors

Acme::CPANAuthors::Polish - jesteśmy autorami-Polakami modułów na CPAN

=head1 VERSION

version 0.03

=head1 SYNOPSIS

	use Acme::CPANAuthors->new('Polish');
	
	my $number = $authors->count;
	my @ids = $authors->id;
	my @distros = $authors->distributions("ZBY");
	my $url = $authors->avatar_url("PWES");
	my $kwalitee = $authors->kwalitee("TADZIK");
	my $name = $authors->name("PMURIAS");

See documentation for L<Acme::CPANAuthors> for more details.

=head1 DESCRIPTION

This class provides a hash of Polish CPAN authors' PAUSE ID and name to
be used with the C<Acme::CPANAuthors> module.

=head1 MAINTENANCE

If you are a Polish CPAN author not listed here, please send us your ID/name
via email or bug tracer so we can keep this module up to date.

Also, if you are not a Polish CPAN author listed here, also notify us and
we will remove your name.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate the authors, also in this module

Module code inspired by:

L<Acme::CPANAuthors::British>

L<Acme::CPANAuthors::Russian>

=head1 AUTHOR

Przemyslaw Wesolek <jest@go.art.pl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Przemyslaw Wesolek.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
