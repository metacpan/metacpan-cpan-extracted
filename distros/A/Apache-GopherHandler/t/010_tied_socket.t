
package TestSocket;
use strict;
use warnings;

sub new    { bless [ ], $_[0] }
sub recv   { die "recv\n"     }
sub send   { die "send\n"     }


package main;
use Test::More tests => 2;
use Apache::GopherHandler::TiedSocket;

my $socket = TestSocket->new();
tie( *FH, 'Apache::GopherHandler::TiedSocket' => $socket );

eval { print FH "Foo" };
ok( $@ eq "send\n", "printing goes to send" );

eval { read( FH, my $buf, 1024 ) };
ok( $@ eq "recv\n", "reading goes to recv" );

