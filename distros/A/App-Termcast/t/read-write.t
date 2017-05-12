#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::TCP', 'IO::Pty::Easy';

use App::Termcast;

pipe(my $cread, my $swrite);
pipe(my $sread, my $cwrite);

alarm 60;

my $crlf = "\x0d\x0a";

test_tcp(
    client => sub {
        my $port = shift;

        close $swrite;
        close $sread;

        { sysread($cread, my $buf, 1) }

        my $client_script = <<EOF;
        use App::Termcast;

        no warnings 'redefine';
        local *App::Termcast::_termsize = sub { return (80, 24) };
        use warnings 'redefine';

        my \$tc = App::Termcast->new(
            host     => '127.0.0.1',
            port     => $port,
            user     => 'test',
            password => 'tset',
        );
        \$tc->run(\$^X, '-ple', q[last if /^\$/]);
EOF
        my $pty = IO::Pty::Easy->new;
        $pty->spawn($^X, (map {; '-I', $_ } @INC), '-e', $client_script);
        syswrite($cwrite, 'a');
        { sysread($cread, my $buf, 1) }

        $pty->write("foo\n");
        syswrite($cwrite, 'a');
        { sysread($cread, my $buf, 1) }

        is(full_read($pty), "foo${crlf}foo${crlf}");

        $pty->write("bar\n");
        syswrite($cwrite, 'a');
        { sysread($cread, my $buf, 1) }

        is(full_read($pty), "bar${crlf}bar${crlf}");

        $pty->write("\n");
        syswrite($cwrite, 'a');
        { sysread($cread, my $buf, 1) }

        is(full_read($pty), "$crlf");
    },
    server => sub {
        my $port = shift;
        close $cwrite;
        close $cread;
        my $sock = IO::Socket::INET->new(LocalAddr => '127.0.0.1',
                                         LocalPort => $port,
                                         Listen    => 1);
        $sock->accept; # signal to the client that the port is available
        syswrite($swrite, 'a');
        my $client = $sock->accept;
        { sysread($sread, my $buf, 1) }
        is(full_read($client),
           "hello test tset\n\e\]499;{\"geometry\":[80,24]}\x07",
           "got the correct login info");
        $client->send("hello, test\n");

        syswrite($swrite, 'a');
        my $total_out = '';
        while (1) {
            { sysread($sread, my $buf, 1) }
            my $output = full_read($client);
            last unless defined($output) && length($output);
            $total_out .= $output;
            syswrite($swrite, 'a');
        }
        is($total_out, "foo${crlf}foo${crlf}bar${crlf}bar${crlf}${crlf}",
           'sent the right data to the server');
        syswrite($swrite, 'a');
        sleep 1 while $client->connected;
    },
);

sub full_read {
    my ($fh) = @_;

    my $select = IO::Select->new($fh);
    return if $select->has_exception(0.1);

    1 while !$select->can_read(1);

    my $ret;
    while ($select->can_read(1)) {
        my $new;
        sysread($fh, $new, 4096);
        last unless defined($new) && length($new);
        $ret .= $new;
        return $ret if $select->has_exception(0.1);
    }

    return $ret;
}

done_testing;
