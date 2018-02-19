#!/usr/bin/env perl

use warnings;
use strict;

use lib './';

use Test::More;

plan skip_all =>
    'On-line tests. Set API_MIKROTIK_ONLINE to "host:user:pass:tls" to run.'
    unless $ENV{API_MIKROTIK_ONLINE};

use API::MikroTik;
use API::MikroTik::Response;
use API::MikroTik::Sentence;

my ($h, $u, $p, $tls) = split ':', ($ENV{API_MIKROTIK_ONLINE} || '');
my $a = API::MikroTik->new(
    user     => ($u   // 'admin'),
    password => ($p   // ''),
    host     => ($h   // '192.168.88.1'),
    tls      => ($tls // 1),
);

my $res;
$res = $a->cmd(
    '/interface/print',
    {'.proplist' => '.id,name,type,running'},
);
ok !$a->error, 'no error';
my @keys = sort keys %{$res->[0]};
is_deeply [@keys], [qw(.id name running type)], 'right result';

done_testing();

