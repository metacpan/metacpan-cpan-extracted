#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';

use App::Environ;
use App::Environ::Mojo::Pg;

App::Environ->send_event('initialize');

my $pg = App::Environ::Mojo::Pg->pg('main');

say $pg->db->query('SELECT 1')->array->[0];

App::Environ->send_event('finalize:r');
