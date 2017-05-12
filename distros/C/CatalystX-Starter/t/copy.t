#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 7;

use CatalystX::Starter;
use Directory::Scratch;
use Test::Exception;

my $src = CatalystX::Starter::_boilerplate();
ok -e $src, "source of files, $src, exists";

my $tmp = Directory::Scratch->new;
my $dest = $tmp->mkdir('My-Module');

is scalar $tmp->ls('My-Module'), 0, 'no files yet';

lives_ok {
    CatalystX::Starter::_copy_files($dest);
} 'copy_files lives';

ok scalar $tmp->ls('My-Module') > 10, 'copied some files';

my ($readme) = grep { /README/ } $tmp->ls('My-Module');
ok $tmp->exists($readme), 'README exists';
ok -r $tmp->exists($readme), 'README is readable';
ok -x $tmp->exists('My-Module'), 'director is executable';
