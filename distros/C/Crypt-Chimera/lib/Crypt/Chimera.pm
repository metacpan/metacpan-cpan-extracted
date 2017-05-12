package Crypt::Chimera;

use strict;
use warnings;
use vars qw($VERSION);

use Crypt::Chimera::Object;
use Crypt::Chimera::Event;
use Crypt::Chimera::World;
use Crypt::Chimera::User;
use Crypt::Chimera::Cracker;

$VERSION = "1.01";

1;

=head1 NAME

Crypt::Chimera - An implementation of the Chimera key exchange protocol

=head1 DESCRIPTION

The Chimera key exchange protocol generates a shared key between two
parties. The protocol was shown to be INSECURE by Frank Niedermeyer
and Werner Schindler of the Bundesamt für Sicherheit in der
Informationstechnik (BSI), Bonn, Germany. This module is therefore
released for purely academic curiosity.

Anyone interested in more details should read the source code and the
examples in the eg/ subdirectory.

=cut
