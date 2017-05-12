#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use t::DB;
use <% dist_module %>::Util::Primer qw(prime_database);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => '<% dist_module %>');
subtest 'root page' => sub {
    $mech->get_ok('/');
    is $mech->ct, 'text/html', 'Content-Type is text/html';
    $mech->title_is('<% dist_module %>', 'On the root page');
    ok defined($mech->find_link(text => 'Login')), 'has a "Login" link';
    ok !defined($mech->find_link(text => 'Logout')),
      'does not have a "Logout" link';
};
$mech->follow_link_ok({ text => 'Login' }, 'follow the "Login" link');
subtest 'attempt to login as "admin" with a wrong password' => sub {
    $mech->submit_form_ok(
        { fields => { username => 'admin', password => 'wrongpassword' } },
        'submit the login form');
    $mech->content_contains('Wrong username or password', 'login failed');
};
subtest 'login as "admin" with the correct password' => sub {
    $mech->submit_form_ok(
        { fields => { username => 'admin', password => 'admin' } },
        'submit the login form with the right password'
    );
    ok defined($mech->find_link(text => 'Logout (admin)')),
      'has a "Logout" link and the right username';
    ok !defined($mech->find_link(text => 'Login')),
      'does not have a "Login" link';
};
done_testing();
