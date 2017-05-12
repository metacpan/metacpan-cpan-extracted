#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 5;

use CatalystX::Starter;
use Directory::Scratch;
use Test::Exception;

my $src = CatalystX::Starter::_boilerplate();
ok -e $src, "source of files, $src, exists";
my $tmp = Directory::Scratch->new;
my $dest = $tmp->mkdir('My-Module');
CatalystX::Starter::_copy_files($dest);
ok scalar $tmp->ls('My-Module') > 10, 'copied some files';

lives_ok {
    CatalystX::Starter::_mk_module('My::Module', $tmp->exists('My-Module'));
} 'files fixed without dying';

my $module = $tmp->read('My-Module/lib/My/Module.pm');
like $module, qr/package \s+ My::Module/x, 'module is a module';

lives_ok {
    require $tmp->exists('My-Module/lib/My/Module.pm');
} 'module even compiles!';
