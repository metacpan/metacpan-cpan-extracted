package JSON::RPC::Client::Any;

use strict;
use warnings;

our $VERSION = 1.28;

our @ISA;

BEGIN {
    if ( eval { require JSON::RPC::Legacy::Client } ) {
        push @ISA, 'JSON::RPC::Legacy::Client';
   }
   elsif ( eval { require JSON::RPC::Client } ) {
        push @ISA, 'JSON::RPC::Client';
   }
   else {
       die "Unable to find JSON RPC Client implementation";
   }
};

=head1 NAME

JSON::RPC::Client::Any -- wrap in an available JSON RPC Client implementation

=head1 SYNOPSIS

 use JSON::RPC::Client::Any;

 my $c = JSON::RPC::Client::Any->new()
 ...

=head1 DESCRIPTION

B<JSON::RPC::Client::Any> is a simple class, which finds an available JSON RPC
client implementation and descends from it. It saves you the hassle of checking
whether you have C<JSON::RPC::Client> or C<JSON::RPC::Legacy::Client>
available.

=head1 SEE ALSO

=over

=item L<JSON::RPC::Client>

=item L<JSON::RPC::Legacy::Client>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Damyan Ivanov L<dmn@debian.org>

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version.

=cut
