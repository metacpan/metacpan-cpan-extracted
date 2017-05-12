package Child::Socket;
use strict;
use warnings;

use Child::IPC::Socket;

our $VERSION = '0.003';

use base 'Child';
our @EXPORT_OK = qw/
    child
    proc_connect
/;

*child = Child->can( 'child' );

sub proc_connect {
    my ( $file ) = @_;
    Child::IPC::Socket->child_class->new_from_file( $file );
}

1;

__END__

=head1 NAME

Child::Socket - Socket based IPC plugin for L<Child>

=head1 DESCRIPTION

Lets you create a Child object, disconnect from it, and reconnect later in the
same or different process.

=head1 REQUIREMENT NOTE

Requires UNIX socket support.

=head1 SYNOPSIS

    use Child qw/child/;

    # Build with Socket IPC
    my $proc = child {
        my $parent = shift;
        $parent->say("message1");
        my $reply = $parent->read();
    } socket => 1;

    my $message1 = $proc->read();
    $proc->say("reply");

=head1 DISCONNECTING AND RECONNECTING

sript1.pl:

    #!/usr/bin/perl;
    use Child qw/child/;

    $proc = child {
        my $parent = shift;

        # detach will remove the child from the parents process group.
        $parent->detach;

        $parent->disconnect;

        # $parent->connect accepts a client connection
        # argument is timeout in seconds
        $parent->connect(10);

        $parent->say( "Hi" );
    } socket => '/tmp/my-socket';

    $proc->disconnect;

script2.pl:

    #!/usr/bin/perl;
    use Child qw/proc_connect/;

    my $proc = proc_connect( '/tmp/my-socket' );

    my $msg = $proc->read; # "Hi\n"

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child-Socket is free software; Standard perl licence.

Child-Socket is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
