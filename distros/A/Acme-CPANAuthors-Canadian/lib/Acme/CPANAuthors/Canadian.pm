package Acme::CPANAuthors::Canadian; # git description: v0.0107-9-g9055405
# ABSTRACT: We are Canadian CPAN authors

use warnings;
use strict;

our $VERSION = '0.0108';

use Acme::CPANAuthors::Register (
  ZOFFIX => 'Zoffix Znet',
  ETHER => 'Karen Etheridge',
  ROMANF => 'Roman F.',
  GTERMARS => 'Graham TerMarsch',
  OALDERS => 'Olaf Alders',
  TIMLEGGE => 'Timothy Legge',
  STASH => 'Jeremy Stashewsky',
  LUKEC => 'Luke Closs',
  KEVINJ => 'Kevin Jones',
  MDMS => 'Mike Smith',
);

1;

#pod =pod
#pod =head1 SYNOPSIS
#pod
#pod     use strict;
#pod     use warnings;
#pod     use Acme::CPANAuthors;
#pod
#pod     my $authors  = Acme::CPANAuthors->new("Canadian");
#pod
#pod     my $number   = $authors->count;
#pod     my @ids      = $authors->id;
#pod     my @distros  = $authors->distributions("ZOFFIX");
#pod     my $url      = $authors->avatar_url("ZOFFIX");
#pod     my $kwalitee = $authors->kwalitee("ZOFFIX");
#pod     my $name     = $authors->name("ZOFFIX");
#pod
#pod See documentation for L<Acme::CPANAuthors> for more details.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class provides a hash of Canadian CPAN authors' PAUSE ID and name to
#pod the C<Acme::CPANAuthors> module.
#pod
#pod =head1 US PEOPLE
#pod
#pod We are Canadian CPAN authors:
#pod
#pod =for :list
#pod * Zoffix Znet
#pod * Karen Etheridge
#pod * Roman F.
#pod * Graham TerMarsch
#pod * Olaf Alders
#pod * Timothy Legge
#pod * Jeremy Stashewsky
#pod * Luke Closs
#pod * Kevin Jones
#pod * Mike Smith
#pod
#pod =head1 MAINTENANCE
#pod
#pod If you are a Canadian CPAN author not listed here, please send me your ID/name
#pod via RT or pull request so we can always keep this module up to date.
#pod
#pod =cut

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::Canadian - We are Canadian CPAN authors

=head1 VERSION

version 0.0108

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

=over 4

=item *

Zoffix Znet

=item *

Karen Etheridge

=item *

Roman F.

=item *

Graham TerMarsch

=item *

Olaf Alders

=item *

Timothy Legge

=item *

Jeremy Stashewsky

=item *

Luke Closs

=item *

Kevin Jones

=item *

Mike Smith

=back

=head1 MAINTENANCE

If you are a Canadian CPAN author not listed here, please send me your ID/name
via RT or pull request so we can always keep this module up to date.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-Canadian>
(or L<bug-Acme-CPANAuthors-Canadian@rt.cpan.org|mailto:bug-Acme-CPANAuthors-Canadian@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Zoffix Znet <cpan@zoffix.com>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Timothy Legge

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2008 by Zoffix Znet <cpan@zoffix.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
ZOFFIX Zoffix Znet
ETHER Karen Etheridge
ROMANF Roman F.
GTERMARS Graham TerMarsch
OALDERS Olaf Alders
TIMLEGGE Timothy Legge
# the following four authors have been submitted by GTERMARS
STASH Jeremy Stashewsky
LUKEC Luke Closs
KEVINJ Kevin Jones
MDMS Mike Smith
