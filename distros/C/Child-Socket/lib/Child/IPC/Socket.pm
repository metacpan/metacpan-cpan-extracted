package Child::IPC::Socket;
use strict;
use warnings;
use Child::Util;

use Child::Link::IPC::Socket::Proc;
use Child::Link::IPC::Socket::Parent;

use base 'Child';

add_accessors qw/name shared_data started/;

sub child_class  { 'Child::Link::IPC::Socket::Proc'   }
sub parent_class { 'Child::Link::IPC::Socket::Parent' }

sub new {
    my ( $class, $code, $file ) = @_;
    return bless(
        {
            _code => $code,
            _shared_data => $file,
        },
        $class
    );
}

1;

=head1 NAME

Child::IPC::Socket - Socket based IPC plugin for L<Child>

=head1 DESCRIPTION

Procs have a listen UNIX socket, parent connects to it. You can reconnect to a
proc later, or from another process.

See L<Child::Socket>.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
