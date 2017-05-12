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
use Data::Dumper;

plan tests => 1;

setting appdir => setting('appdir') . '/t';
setting plugins => { FormValidator => { profile_file => 'profile.pm'}};

my $res = dancer_response POST => '/contact';
is $res->{status}, 500, 'unknow format';
