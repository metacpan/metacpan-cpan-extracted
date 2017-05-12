#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
use Data::Transpose::EmailValid;


my %valid = (
    'uwe@uwevoelker.de'                            => '',
    'racke+test@linuxia.de'                        => '',
    '"Stefan Hornburg (Racke)" <racke@linuxia.de>' => 'racke@linuxia.de',
    'fast_typer@gmail.ocm'                         => 'fast_typer@gmail.com',
    ' pit@bull.de '                                => 'pit@bull.de',
    'funny@web..de'                                => 'funny@web.de',
    "o'brian\@gmail.com" => '',
    'victorochieng\'679@yahoo.com'            => '',

);

my %invalid = (
    'beckyd_sp@yahoo.com/beckydned@gmail.com' => 'rfc822',
    'Nour_e;mahdy@yahoo.com'                  => 'rfc822',
    'jneira@academia.usbbog.edu.co.'          => 'rfc822',
    'Ahmed Mohammed6684@gmail.com'            => 'rfc822',
    'foo,bar@test.de'                         => 'rfc822',
    'uwe@no-mx.uwevoelker-does-not-exist.de'  => 'mxcheck',
);


my $email = Data::Transpose::EmailValid->new;

while (my ($input, $output) = each %valid) {
    ok($email->is_valid($input), "$input is valid");
    is($email->suggestion || '', $output, "$input -> $output");
}

while (my ($input, $reason) = each %invalid) {
    ok(! $email->is_valid($input), "$input is invalid");
    is($email->reason, $reason, "$input ($reason)");
}

done_testing;

