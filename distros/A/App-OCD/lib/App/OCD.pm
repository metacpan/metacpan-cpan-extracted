package App::OCD;

use strict;
use warnings;

our $VERSION = '0.01';


1;

__END__


=head1 NAME

App::OCD - A collection of "Online Code" Demos

=head1 SYNOPSIS

 perldoc App::OCD

=head1 DESCRIPTION

This page is intented as a top-level introduction to various packages
available in the App::OCD::* name space. I am using this name space to
present various applications and demos that use my Net::OnlineCode
module. That module can be used to implement reliable multicast data
transmission across a network.

The Net::OnlineCode module implements only the basic algorithm
required to enable a sender to be able to construct a series of
"check" blocks from an original message and for the receiver to be
able to combine these check blocks in a certain way to recover the
original message. It does not cover details such as:

=over

=item * how and where the message is stored on the sending side;

=item * XORing of data blocks (the Online Code algorithm is based
completely on such XORs);

=item * the sending and receiving of data blocks over the network;

=item * other network protocol details (such as how transfers are
initiated and how acknowledgements are handled); and

=item * storage (and caching) of check blocks and other intermediate
data needed on the receiving side

=back

Because these data manipulation and networking parts are completely
decoupled from the algorithmic parts, I feel that I need to give some
example applications that include I<all> the parts. Rather than
clutter up the Net::OnlineCode module with these examples, I've
decided to release them as separate modules. This will also allow me
to add new demos and evolve them without requiring pointless version
updates to the original module.

For the most part, the demos in this name space will be focused on
I<multicast> applications, which is to say that one machine will be
sending data (eg, a data structure or a file) over a network, where it
may be received by multiple receivers at once. Using multicast to send
to multiple receivers like this is very efficient since it only
requires slightly more bandwidth than the equivalent unicast (single
sender, single reciever) file transfers would take.

Some of the demos here will have a single "master" host that does the
sending, while others will focus on more peer-to-peer type
arrangements that don't have any distinguished "master" hosts. Or, to
put it another way, some of the programs will demo "one to many"
transfers, while other will be more "many to many".

I think that multicast (and reliable multicast in particular) is a
very interesting building block for network-based applications, so in
addition to some of the demos that are included simply to provide
examples of how to use the Net::OnlineCode module, I'll also be adding
more complex and feature-laden examples intended as a showcase of the
kinds of cool things that you can do with multicast in general (and
the Online Code algorithm in particular).

=head1 DEMO LIST

None ... yet!

=head1 SEE ALSO

Related links:

=over

=item * the Net::OnlineCode module

=item * the papers describing the Online Code algorithms (see Net::OnlineCode man page)

=item * the udpcast application home page (another provide
implementing a reliable multicast protocol)

=item * the flamethrowerd application home page (which uses udpcast)

=item * my App::Diskd demo application (a simple Perl/POE-based
peer-to-peer network daemon, which I will use as a template for
various demos presented here)

=item * my top-level github repository
(https://github.com/declanmalone/gnetraid.git) where the latest
versions of the App::OCD::*, Net::OnlineCode modules (and other
programs and documentation) may be found

=back


=head1 AUTHOR

Declan Malone, E<lt>idablack@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Declan Malone

This program is free software; you can redistribute it and/or modify
it under the terms of version 2 (or, at your discretion, any later
version) of the "GNU General Public License" ("GPL").

Please refer to L<http://www.gnu.org/licenses/gpl.html> for the full
text of this license.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

