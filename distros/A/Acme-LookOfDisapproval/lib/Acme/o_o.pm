use strict;
use warnings;
use utf8;
package Acme::ಠ_ಠ;
{
  $Acme::ಠ_ಠ::VERSION = '0.006';
}
BEGIN {
  $Acme::ಠ_ಠ::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: send warnings with ಠ_ಠ

use Acme::LookOfDisapproval;
our @EXPORT = ('ಠ_ಠ');

sub import
{
    goto &Acme::LookOfDisapproval::import;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Karen Etheridge unicode irc

=head1 NAME

Acme::ಠ_ಠ - send warnings with ಠ_ಠ

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use utf8;
    use Acme::ಠ_ಠ;
    ಠ_ಠ 'you did something dumb';

=head1 DESCRIPTION

See L<Acme::LookOfDisapproval>.

This module also serves as a test of unicode module names. I have no idea if
this will work -- let's find out!!!

=head1 FUNCTIONS

=head2 C<ಠ_ಠ>

Behaves identically to L<perlfunc/warn>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-LookOfDisapproval>
(or L<bug-Acme-LookOfDisapproval@rt.cpan.org|mailto:bug-Acme-LookOfDisapproval@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
