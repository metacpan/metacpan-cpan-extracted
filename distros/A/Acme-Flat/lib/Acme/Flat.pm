use 5.006;    # our
use strict;
use warnings;

package Acme::Flat;

our $VERSION = '0.001001';

# ABSTRACT: A Pure Perl reimplementation of B Internals

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Flat - A Pure Perl reimplementation of B Internals

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

This module is mostly a learning experiment to help me understand the mechanics
behind perl's C<B> internals, and hopefully making more friendly documentation for C<B>
components in the process.

At present, it only contains the implemented hierarchy present in C<< >5.18 >>, with
no more than stub classes to represent each C<OP>, each with descriptions.

But it is hoped alone that having a description for each C<OP> gives some improvement on its own.

=head1 NAMING

The name is an approximation of

  Acme::♭

Which was a cutesy way of saying C<B> without saying C<B>

Alas, C<♭> is character C<U+266d>, a I<Symbol>, not an C<AlphaNumeric> included in the
C<XID_Start> or C<XID_Continue> Regular Expression ranges.

I fully intend to capitalize on that name however in the event that:

=over 4

=item 1. MooseX::Types::Perl::DistName allows symbols in distribution names.

=item 2. PAUSE itself is proven to accept them.

=item 3. Perl itself supports such a character in identifiers

=back

However, due to L<<
C<#3> being now required to appease PAUSE Indexing rules
|http://www.dagolden.com/index.php/2414/this-distribution-name-can-only-be-used-by-users-with-permission/
>>, it seems unlikely C<Acme::♭> will exist in the near future.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
