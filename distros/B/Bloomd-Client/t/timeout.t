#!perl
#
# This file is part of Bloomd-Client
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

BEGIN { 
    use Config;
    if ( $Config{osname} eq 'netbsd' || $Config{osname} eq 'solaris') {
        require Test::More;
        Test::More::plan( skip_all =>
              'should not test Bloomd::Client under Solaris OR Netbsd'
        );
    }
}

use feature ':5.10';

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More;
use Test::Exception;
use Test::TCP;
use Socket qw(:crlf);
use POSIX qw(ETIMEDOUT ECONNRESET strerror);
use Bloomd::Client;

sub create_server_with_timeout {
    my $in_timeout = shift;

    Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $socket = IO::Socket::INET->new(
                Listen    => 5,
                Timeout   => 1,
                Reuse     => 1,
                Blocking  => 1,
                LocalPort => $port
            ) or die "ops $!";

            my $buffer;
            while (1) {
                my $client = $socket->accept();

                if ( my $line = $client->getline() ) {
                    $line =~ s/$CR?$LF?$//;
#                    say STDERR " --- DEBUG line [$line]";
                    if ($in_timeout && $line ne 'info foo' ) {
                        sleep($in_timeout);
                    }

                    # When the client has a timeout, it'll never consume this
                    # print, until the Timeout of the IO::Socket::INET
                    $client->print('foo bar');
                }

                $client->close();
            }
        },
    );
}

my $server = create_server_with_timeout(2);

my $b = Bloomd::Client->new(
    host             => '127.0.0.1',
    port             => $server->port,
    timeout          => 0.5,
);

ok $b, 'client created';

my $etimeout = strerror(ETIMEDOUT);

throws_ok { $b->list() } qr/$etimeout/, "got timeout croak";

# give time to the server to finish sleeping

sleep 2;
# now reissue an other command on the same object, which will not timeout. We
# check that the socket is properly recreated.

lives_ok {
    is_deeply $b->info('foo'), { foo => 'bar'}, "fake info returns proper results";
} "doesn't die without timeout";

done_testing;
