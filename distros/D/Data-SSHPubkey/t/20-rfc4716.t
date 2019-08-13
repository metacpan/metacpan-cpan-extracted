#!perl
use 5.010;
use strict;
use warnings;
use Data::SSHPubkey qw(pubkeys);
use File::Spec ();
use Test::Most;    # plan is down at bottom

# probably good to be able to parse at least some of the example keys
# from RFC 4716

my $keys = <<'EOF';
---- BEGIN SSH2 PUBLIC KEY ----
Comment: "1024-bit RSA, converted from OpenSSH by me@example.com"
x-command: /home/me/bin/lock-in-guest.sh
AAAAB3NzaC1yc2EAAAABIwAAAIEA1on8gxCGJJWSRT4uOrR13mUaUk0hRf4RzxSZ1zRb
YYFw8pfGesIFoEuVth4HKyF8k1y4mRUnYHP1XNMNMJl1JcEArC2asV8sHf6zSPVffozZ
5TT4SfsUu/iKy9lUcCfXzwre4WWZSXXcPff+EHtWshahu3WzBdnGxm5Xoi89zcE=
---- END SSH2 PUBLIC KEY ----

---- BEGIN SSH2 PUBLIC KEY ----
Comment: This is my public key for use on \
servers which I don't like.
AAAAB3NzaC1kc3MAAACBAPY8ZOHY2yFSJA6XYC9HRwNHxaehvx5wOJ0rzZdzoSOXxbET
W6ToHv8D1UJ/z+zHo9Fiko5XybZnDIaBDHtblQ+Yp7StxyltHnXF1YLfKD1G4T6JYrdH
YI14Om1eg9e4NnCRleaqoZPF3UGfZia6bXrGTQf3gJq2e7Yisk/gF+1VAAAAFQDb8D5c
vwHWTZDPfX0D2s9Rd7NBvQAAAIEAlN92+Bb7D4KLYk3IwRbXblwXdkPggA4pfdtW9vGf
J0/RHd+NjB4eo1D+0dix6tXwYGN7PKS5R/FXPNwxHPapcj9uL1Jn2AWQ2dsknf+i/FAA
vioUPkmdMc0zuWoSOEsSNhVDtX3WdvVcGcBq9cetzrtOKWOocJmJ80qadxTRHtUAAACB
AN7CY+KKv1gHpRzFwdQm7HK9bb1LAo2KwaoXnadFgeptNBQeSXG1vO+JsvphVMBJc9HS
n24VYtYtsMu74qXviYjziVucWKjjKEb11juqnF0GDlB3VVmxHLmxnAz643WK42Z7dLM5
sY29ouezv4Xz2PuMch5VGPP+CDqzCM4loWgV
---- END SSH2 PUBLIC KEY ----
EOF

chomp $keys;

my @ret = pubkeys(\$keys);

is(scalar @ret, 2);

ok($ret[0][1] =~ m{^---- BEGIN SSH2 PUBLIC KEY ----${/}AAAAB3NzaC1y});
ok($ret[1][1] =~ m{^---- BEGIN SSH2 PUBLIC KEY ----${/}AAAAB3NzaC1k});

dies_ok { pubkeys(\"---- BEGIN SSH2 PUBLIC KEY ----\n") };
dies_ok { pubkeys(\"---- BEGIN SSH2 PUBLIC KEY ----\nx: \\\nbar \\") };

# filename parse
dies_ok { pubkeys(File::Spec->catfile(qw{t toolong.pub})) };

$Data::SSHPubkey::max_lines = 640;

lives_ok { pubkeys(File::Spec->catfile(qw{t toolong.pub})) };

plan tests => 7
