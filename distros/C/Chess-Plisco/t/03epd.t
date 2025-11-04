#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More tests => 18;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

use Chess::Plisco::EPD;

my $t_dir = dirname abs_path __FILE__;
my $epd_dir = "$t_dir/epd";

eval { Chess::Plisco::EPD->new('not-existing') };
ok $@, 'exception for non-existing file';

my $filename = "$epd_dir/dm1.epd";
open my $fh, '<', $filename or die "$filename: $!";
my @lines = <$fh>;
my $contents = join '', @lines;

my $epd = Chess::Plisco::EPD->new($filename);
ok $epd, 'load epd from file';
is ((scalar $epd->records), (scalar @lines), "records in file");

open my $fh, '<', $filename or die "$filename: $!";
$epd = Chess::Plisco::EPD->new($fh);
ok $epd, 'load epd from file handle';
is ((scalar $epd->records), (scalar @lines), "records in file handle");

$epd = Chess::Plisco::EPD->new(\@lines);
ok $epd, 'load epd from array';
is ((scalar $epd->records), (scalar @lines), "records from array");

$epd = Chess::Plisco::EPD->new(\$contents);
ok $epd, 'load epd from string';
is ((scalar $epd->records), (scalar @lines), "records from string");

my @records = $epd->records;
my $record = $records[0];
isa_ok $record, 'Chess::Plisco::EPD::Record';

my $position = $record->position;
ok $position, 'position';

my @bms = $record->operation('bm');
is ((scalar @bms), 1, "sizeof bm");
ok $bms[0], 'operation bm';
ok $position->moveLegal($bms[0]);

my @dms = $record->operation('dm');
is ((scalar @bms), 1, "sizeof dm");
is $dms[0], 1, 'operation dm is 1';

my $id = $record->operation('id');
ok $id, 'operation id';

ok !defined $record->operation('foobar'), 'non-existing operation';