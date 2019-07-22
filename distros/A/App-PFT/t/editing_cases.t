#!/bin/perl

use strict;
use warnings;
use utf8;
use v5.16;

use Test::More tests => 4;
use Cwd;
use File::Temp qw(tempdir);
use IPC::Run 'run';
use Encode;
use Encode::Locale;

my $pft = getcwd . '/bin/pft';
my ($in, $out, $err);

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die "Could not chdir $dir: $!";

run ["$pft-init"], \undef, \$out, \$err;
ok $? == 0 => 'Site constructed';

run ["$pft-edit", qw(-B Hello world --stdin)], \<<IN, \$out, \$err;
This is today's blog post.

Yada yada.

Sincerely, Your Bottom.
IN

my $filename;
run ["$pft-ls", qw(blog --pretty=%p)], \undef, \$filename, \$err;
chomp($filename);
ok -e $filename => "File exists ($filename)";

# Breaking header
subtest 'breaking header' => sub {
    open my $content, '+< :encoding(locale)', $filename or die "$!";
    scalar <$content>;
    my $second = <$content>;
    seek $content, -length($second), 1;
    ok $second =~ s/:/_/ => "Replaced second line: $second";
    print $content $second;
    seek $content, 0, 0;
    diag($_) foreach <$content>;
    close $content;
};

subtest 'Verify failure' => sub {
    run ["$pft-edit", qw(--resume)], \undef, \$out, \$err;
    ok $? != 0 => 'Problems in editing file with broken header';

    chomp($err);
    cmp_ok $err => '=~' => $filename => "Error references filename";
    cmp_ok $err => '=~' => 'has corrupt header' => 'Error explains';
};

