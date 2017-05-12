#!/usr/bin/perl -w

use utf8;
use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;

my $hellos = {
  arabic  => {
    original  => 'مرحبا ، العالم!',
    encoded => 'JiMxNjA1OyYjMTU4NTsmIzE1ODE7JiMxNTc2OyYjMTU3NTsgJiMxNTQ4OyAmIzE1NzU7JiMxNjA0
OyYjMTU5MzsmIzE1NzU7JiMxNjA0OyYjMTYwNTsh'
  },
  armenian  => {
    original  => 'Բարեւ, աշխարհի.',
    encoded   => 'JiMxMzMwOyYjMTM3NzsmIzE0MDg7JiMxMzgxOyYjMTQxMDssICYjMTM3NzsmIzEzOTk7JiMxMzg5
OyYjMTM3NzsmIzE0MDg7JiMxMzkyOyYjMTM4Nzsu',
  },
  russian   => {
    original  => 'Здравствуй, мир!',
    encoded   => 'JiMxMDQ3OyYjMTA3NjsmIzEwODg7JiMxMDcyOyYjMTA3NDsmIzEwODk7JiMxMDkwOyYjMTA3NDsm
IzEwOTE7JiMxMDgxOywgJiMxMDg0OyYjMTA4MDsmIzEwODg7IQ=='
  },
  chinese_simplified  => {
    original  => '你好，世界！',
    encoded   => 'JiMyMDMyMDsmIzIyOTA5OyYjNjUyOTI7JiMxOTk5MDsmIzMwMDI4OyYjNjUyODE7',
  },
  foo => {
    original  => 'Bjòrknù',
  }
};

my $api = ASP4::API->new;

for my $lang (qw( arabic chinese_simplified armenian foo ))
{
  ok( my $res = $api->ua->get("/handlers/dev.encoding.hello?lang=$lang"), "GET /handlers/dev.encoding.hello?lang=$lang" );
  is $res->decoded_content, $hellos->{$lang}->{original};
}# end for()

