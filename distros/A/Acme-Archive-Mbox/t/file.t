#!perl -T

use Test::More tests => 8;
use strict;

use Acme::Archive::Mbox::File;

my $time = time();
my $name = '/a/b//c';
my $contents = 'a'x20;
my %attr = ( mode => 0644,
             uid  => 1000,
             gid  => 1001,
             mtime => $time,
           );

# No contents, this should fail.
my $file = Acme::Archive::Mbox::File->new( $name );
is($file, undef, "fail to create object without required args");

$file = Acme::Archive::Mbox::File->new( $name, $contents, %attr );

isa_ok($file, 'Acme::Archive::Mbox::File', "Object created");
is($file->name, $name, "name $name");
is($file->contents, $contents, "contents");
is($file->mode, 0644, "mode");
is($file->uid, 1000, "uid");
is($file->gid, 1001, "gid");
is($file->mtime, $time, "mtime");
