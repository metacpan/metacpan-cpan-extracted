package Acme::CPANAuthors::Malaysian;

use 5.008_005;
use strict;
use warnings;

our $VERSION = '0.01';

use Acme::CPANAuthors::Register (
    KIANMENG => 'Kian Meng, Ang',
);

1;

__END__

=encoding utf-8

=head1 NAME

Acme::CPANAuthors::Malaysian - We are Malaysian CPAN authors (Kami para penulis
CPAN Malaysia).

=head1 SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::Malaysian;

    my $authors = Acme::CPANAuthors->new('Malaysian');

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions('KIANMENG');
    my $url      = $authors->avatar_url('KIANMENG');
    my $kwalitee = $authors->kwalitee('KIANMENG');

=head1 DESCRIPTION

This module provides a list of Malaysian CPAN author's Pause ID mapped to name
for L<Acme::CPANAuthors|Acme::CPANAuthors>.

=head1 MAINTENANCE
Send email, open a ticket, or make a pull request to add your own Pause ID and
name.

=head1 REPOSITORY

Source repository at L<https://github.com/kianmeng/acme-cpanauthors-malaysian|https://github.com/kianmeng/acme-cpanauthors-malaysian>.

How to contribute? Follow through the L<CONTRIBUTING.md|https://github.com/kianmeng/acme-cpanauthors-malaysian/blob/master/CONTRIBUTING.md> document to setup your development environment.

=head1 AUTHOR

Kian Meng, Ang E<lt>kianmeng@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019- Kian Meng, Ang.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Acme::CPANAuthors|Acme::CPANAuthors> - The parent module that handles all.

L<Acme::CPANAuthors::Indonesian|Acme::CPANAuthors::Indonesian> - Our neighbouring country.

=cut
