#!/usr/bin/perl
use warnings;
use strict;

use Alien::Font::Vera;

use Test::More tests => 1;

my $path = Alien::Font::Vera::path;
like $path, qr{Vera\.ttf$}, 'path';
