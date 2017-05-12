package Acme::Boom; no warnings;
$VERSION = 0xdeadbeef + 1;

sub import {
  unpack "p", pack "L!", 1;
}

Earth-Shattering-Kaboom-!!1;

__END__

=head1 NAME

Acme::Boom - BOOM!

=head1 SYNOPSIS

  $ perl -MAcme::Boom
  Segmentation fault

=head1 DESCRIPTION

Sometimes you just want things to go B<BOOM>. This module does just that.

(Seriously, using this module should cause a segfault.)

=for html <img src="http://upload.wikimedia.org/wikipedia/commons/f/fb/Bomba_atomica.gif" />

=head1 LICENSE

This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2, as
published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING or
L<Software::License::WTFPL_2> for more details.

(Except the image, that's CC-attribution-sharealike, from
L<Wikipedia|http://en.wikipedia.org/wiki/File:Bomba_atomowa.gif>.)

=head1 AUTHOR

David Leadbeater E<lt>dgl@dgl.cxE<gt>, 2011

=cut
