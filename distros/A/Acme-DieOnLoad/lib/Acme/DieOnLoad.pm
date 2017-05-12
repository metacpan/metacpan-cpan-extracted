use strict;
use warnings;
package Acme::DieOnLoad; # git description: 740e729
# ABSTRACT: A module that dies when loaded
# KEYWORDS: toolchain module distribution experimental test die broken
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.001';

die 'I told you so. What did you expect?';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::DieOnLoad - A module that dies when loaded

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    require Acme::DieOnLoad;

    <kaboom>

=head1 DESCRIPTION

This module installs cleanly, passing its tests, but dies when it is loaded.
This is useful for toolchain testing.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-DieOnLoad>
(or L<bug-Acme-DieOnLoad@rt.cpan.org|mailto:bug-Acme-DieOnLoad@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
