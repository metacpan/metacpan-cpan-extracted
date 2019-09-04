#! /usr/bin/perl -w

use strict;
use warnings;
use Dir::Self;

use lib File::Spec->catdir(__DIR__, '../', 't', 'lib');
use DigestTest::Schema;

my $var = File::Spec->catdir(__DIR__, '../', 't', 'var');
DigestTest::Schema->load_classes(qw/SHA PGP Bcrypt Whirlpool/);
my $schema = DigestTest::Schema->connect("dbi:SQLite:");
$schema->create_ddl_dir(['SQLite',], undef, $var, undef, {add_drop_table => 0});
