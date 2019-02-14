#!/usr/bin/env perl
use Test2::V0;
use strict;
use warnings;

use Data::Xslate;

my $xslate = Data::Xslate->new();

my $actual = $xslate->render(
    {
        color_names => ['red', 'blue', 'orange'],
        user => {
            login => 'john',
            email => '<: $login :>@example.com',
            name  => 'John',
            color_id => 2,
            color_name => '<: node("color_names")[$color_id] :>',
        },
        email => {
            to      => '=user.email',
            subject => 'Hello <: $user.name :>!',
            message => 'Do you like the color <: $user.color_name :>?',
        },
        'email.from=' => 'george@example.com',
    },
);

#use Data::Dumper; print Dumper( $actual ); ok 1; done_testing; exit;

my $expected = {
          'email' => {
                       'from' => 'george@example.com',
                       'subject' => 'Hello John!',
                       'message' => 'Do you like the color orange?',
                       'to' => 'john@example.com'
                     },
          'user' => {
                      'name' => 'John',
                      'login' => 'john',
                      'color_id' => '2',
                      'email' => 'john@example.com',
                      'color_name' => 'orange'
                    },
          'color_names' => [
                             'red',
                             'blue',
                             'orange'
                           ]
};

is( $actual, $expected );

done_testing;
