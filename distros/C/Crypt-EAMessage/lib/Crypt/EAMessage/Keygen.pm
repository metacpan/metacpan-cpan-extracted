#
# Copyright (C) 2015-2022 Joelle Maslak
# All Rights Reserved - See License
#

package Crypt::EAMessage::Keygen;
$Crypt::EAMessage::Keygen::VERSION = '1.220391';
use v5.22;

use strict;
use warnings;
use autodie;

use feature "signatures";

use Carp;

no warnings "experimental::signatures";

use Crypt::EAMessage;


say Crypt::EAMessage->generate_key();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::EAMessage::Keygen

=head1 VERSION

version 1.220391

=head1 SYNOPSIS

  perl -MCrypt::EAMessage::Keygen -e 1

=head1 DESCRIPTION

Added in version 1.220390

This module should never be used in a C<use> statement or included in your
code.

It is intended to be used in one-liners from the command line to generate
usable, secure AES256 keys.

When the module is loaded, it will print the hex key to the screen.

It uses L<Crypt::EAMessage->generate_key()> to generate the key.

=head1 BUGS

None known, however it is certainly possible that I am less than perfect!
If you find any bug you believe has security implications, I would
greatly appreciate being notified via email sent to jmaslak@antelope.net
prior to public disclosure. In the event of such notification, I will
attempt to work with you to develop a plan for fixing the bug.

All other bugs can be reported via email to jmaslak@antelope.net or by
using the Git Hub issue tracker
at L<https://github.com/jmaslak/Crypt-EAMessage/issues>

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
