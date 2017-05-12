package Acme::CPANAuthors::Canadian; # git description: v0.0106-5-gcc89265
# ABSTRACT: We are Canadian CPAN authors

use warnings;
use strict;

our $VERSION = '0.0107';

use Acme::CPANAuthors::Register (
    ZOFFIX => 'Zoffix Znet',
    ETHER  => 'Karen Etheridge',
    ROMANF => 'Roman F.',
    GTERMARS    => 'Graham TerMarsch',
    OALDERS => 'Olaf Alders',

    # the following four authors have been submitted by GTERMARS
    STASH   => 'Jeremy Stashewsky',
    LUKEC   => 'Luke Closs',
    KEVINJ  => 'Kevin Jones',
    MDMS    => 'Mike Smith',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Canadian - We are Canadian CPAN authors

=head1 VERSION

version 0.0107

=head1 DESCRIPTION

This class provides a hash of Canadian CPAN authors' PAUSE ID and name to
the C<Acme::CPANAuthors> module.

    use strict;
    use warnings;
    use Acme::CPANAuthors;

    my $authors  = Acme::CPANAuthors->new("Canadian");

    my $number   = $authors->count;
    my @ids      = $authors->id;
    my @distros  = $authors->distributions("ZOFFIX");
    my $url      = $authors->avatar_url("ZOFFIX");
    my $kwalitee = $authors->kwalitee("ZOFFIX");
    my $name     = $authors->name("ZOFFIX");

See documentation for L<Acme::CPANAuthors> for more details.

=head1 US PEOPLE

We are Canadian CPAN authors:

    Graham 'GTERMARS' TerMarsch
    Jeremy 'STASH' Stashewsky
    Karen 'ETHER' Etheridge
    Kevin 'KEVINJ' Jones
    Luke 'LUKEC' Closs
    Mike 'MDMS' Smith
    Roman 'ROMANF' F.
    Zoffix 'ZOFFIX' Znet

=head1 MAINTENANCE

If you are a Canadian CPAN author not listed here, please send me your ID/name
via email or RT so we can always keep this module up to date.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-Canadian>
(or L<bug-Acme-CPANAuthors-Canadian@rt.cpan.org|mailto:bug-Acme-CPANAuthors-Canadian@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Zoffix Znet <cpan@zoffix.com>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Zoffix Znet <cpan@zoffix.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
