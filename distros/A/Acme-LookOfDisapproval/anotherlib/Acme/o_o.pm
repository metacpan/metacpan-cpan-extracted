use strict;
use warnings;
use utf8;
package Acme::ಠ_ಠ;
# vim: set ts=8 sts=2 sw=2 tw=100 et :
# ABSTRACT: Send warnings with ಠ_ಠ

our $VERSION = '0.007';

use Acme::LookOfDisapproval;
our @EXPORT = ('ಠ_ಠ');

sub import {
  goto &Acme::LookOfDisapproval::import;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::ಠ_ಠ - Send warnings with ಠ_ಠ

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use utf8;
    use Acme::ಠ_ಠ;
    ಠ_ಠ 'you did something dumb';

=head1 DESCRIPTION

See L<Acme::LookOfDisapproval>.

=for stopwords unicode

This module also serves as a test of unicode module names. I have no idea if
this will work -- let's find out!!!

=head1 FUNCTIONS

=head2 C<ಠ_ಠ>

Behaves identically to L<perlfunc/warn>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-LookOfDisapproval>
(or L<bug-Acme-LookOfDisapproval@rt.cpan.org|mailto:bug-Acme-LookOfDisapproval@rt.cpan.org>).

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
