#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use Test::More tests => 9;

use CatalystX::Starter;
use Directory::Scratch;
use Test::Exception;

my $src = CatalystX::Starter::_boilerplate();
ok -e $src, "source of files, $src, exists";
my $tmp = Directory::Scratch->new;
my $dest = $tmp->mkdir('My-Module');
CatalystX::Starter::_copy_files($dest);
ok scalar $tmp->ls('My-Module') > 10, 'copied some files';

my ($mk) = grep { /Makefile.PL/ } $tmp->ls('My-Module');
ok $tmp->exists($mk), 'Makefile.PL exists';

my $mkfile = $tmp->read($mk);
unlike $mkfile, qr/My::Module/, 'no My::Module yet';
like $mkfile, qr/\[% \w+ %\]/, 'makefile has placeholder';

lives_ok {
    CatalystX::Starter::_fix_files('My::Module', $tmp->exists('My-Module'));
} 'files fixed without dying';

$mkfile = $tmp->read($mk);
like $mkfile, qr/My-Module/, 'My-Module is in there';
like $mkfile, qr{lib/My/Module.pm}, 'path to My/Module.pm is in there';
unlike $mkfile, qr/\[% \w+ %\]/, 'makefile has no placeholders';
