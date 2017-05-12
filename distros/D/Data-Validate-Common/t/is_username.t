#!/usr/bin/perl

use lib './lib';
use strict;
use Test::More tests => 12;

BEGIN { use_ok( 'Data::Validate::Common' ); }

my $validate = Data::Validate::Common->new();
isa_ok($validate, 'Data::Validate::Common');

my $users = [
    'ich',
    'ich+mail',
    'ich-mail',
    'ich_mail',
    'ich.mail',
];

foreach my $user (@{$users}) {
    is($validate->is_username($user), $user, 'testing: is_username '.$user);
    is(Data::Validate::Common->is_valid_username($user), 1, 'testing: is_valid_username '.$user);
}
