#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

use FindBin qw($Bin);
use lib "$Bin/lib";

use MySchema;
use DBD::SQLite;
use DBICx::Deploy;
use File::Temp qw(tempfile);

my (undef, $temp) = tempfile;

my $dsn = "DBI:SQLite:$temp";
DBICx::Deploy->deploy(MySchema => $dsn);

my $schema = MySchema->connect($dsn);
ok $schema, 'got connection';

my $obj = $schema->resultset('Foo')->create({ value => 'foo' });
ok $obj->in_storage, 'something i created is in storage; it must work';

# try a dir
my (undef, $tempdir) = tempfile;

unlink $tempdir;
ok !-e $tempdir, "no $tempdir yet";
DBICx::Deploy->deploy(MySchema => $tempdir);
ok -d $tempdir, 'directory created';

END { unlink $temp }
