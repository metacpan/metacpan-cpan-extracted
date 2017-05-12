#!/usr/bin/env perl
#
# This file is part of Dancer-Plugin-FormValidator
#
# This software is copyright (c) 2013 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use strict;
use warnings;

use Test::More import => ['!pass'];

use Dancer;
use Dancer::Test;

use lib 't/lib';
use TestApp;
use Data::FormValidator;

plan tests => 7;

setting appdir => setting('appdir') . '/t';
setting plugins => { FormValidator => { profile_file => 'profile.pl'}};

my $dfv = Data::FormValidator->new({
    profile_contact => {
        'required' => [ qw(
                name subject body
             )],
         msgs => {
              missing => 'Not Here',
         }
    },
});
my $results = $dfv->check({}, 'profile_contact');

my $res = dancer_response GET => '/';
is $res->{status}, 200, "Get / get 200";

$res = dancer_response POST => '/contact';
is_deeply $results->{missing}, $res->{content}->{missing}, 'all fields is missing, with dfv function';

$res = dancer_response POST => '/other_contact';
my $missing_fields = {
    body    => 'Not here',
    subject => 'Not here',
    name    => 'Not here'
};
is_deeply $missing_fields, $res->{content}, 'all fields is missing, with form_validator_error function';

$res = dancer_response(POST  => '/contact', {
    params => { name => 'contact', subject => 'foo' }
});
$results = $dfv->check({
        name => 'contact', subject => 'foo'
}, 'profile_contact');
is_deeply $results->{missing}, $res->{content}->{missing}, 'few fields is missing, with dfv function';

$res = dancer_response(POST  => '/other_contact', {
    params => { name => 'contact', subject => 'foo' }
});
$missing_fields = {
    body    => 'Not here',
};
is_deeply $missing_fields, $res->{content}, 'few fields is missing, with form_validator_error function';

$res = dancer_response(POST  => '/contact', {
    params => {
        name    => 'contact',
        subject => 'foo',
        body    => 'Simple text'
    }
});
$results = $dfv->check({
        name    => 'contact',
        subject => 'foo',
        body    => 'Simple text'
}, 'profile_contact');
is $res->{content}, 'The form is validate', 'all fields is valid, with dfv function';

$res = dancer_response(POST  => '/other_contact', {
    params => {
        name    => 'contact',
        subject => 'foo',
        body    => 'Simple text'
    }
});
is_deeply $res->{content}, 'The form is validate', 'all fields is valid, with form_validator_error function';
