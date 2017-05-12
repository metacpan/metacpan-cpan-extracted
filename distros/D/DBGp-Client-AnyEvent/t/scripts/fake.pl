#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;

my ($port, $path) = @ARGV;

my $sock;
if ($port) {
    $sock = IO::Socket::INET->new(
        RemotePeer => '127.0.0.1',
        RemotePort => $port,
    );
} elsif ($path) {
    $sock = IO::Socket::UNIX->new(
        Peer => $path,
    );
}

die "Error during connect: $!" unless $sock;

my $init = <<'EOT';
<init appid="test"
      idekey="idekey"
      session="cookie"
      thread="1"
      parent="123"
      language="Perl"
      protocol_version="1.0"
      fileuri="file://none">
</init>
EOT

my $res1 = <<'EOT';
<response command="stack_depth"
          depth="7"
          transaction_id="1"/>
EOT

my $res2 = <<'EOT';
<response command="stack_depth"
          depth="7"
          transaction_id="2"/>
EOT

my $res3 = <<'EOT';
<response command="stack_depth"
          depth="7"
          transaction_id="3"/>
EOT

my $out = <<'EOT';
<stream type="stdout"
        encoding="base64">
U29tZSBvdXRwdXQK
</stream>
EOT

syswrite $sock, length($init) . "\x00" . $init . "\x00";

eatline();

syswrite $sock, length($res1) . "\x00" . $res1 . "\x00";

eatline();

syswrite $sock, length($out) . "\x00" . $out . "\x00";

# async, so no command expected here

syswrite $sock, length($res2) . "\x00" . $res2 . "\x00";

eatline();

syswrite $sock, length($res3) . "\x00" . $res3 . "\x00";

exit 0;

sub eatline {
    my $buf;

    for (;;) {
        sysread $sock, $buf, 1;
        last if $buf eq "\x00";
    }
}
