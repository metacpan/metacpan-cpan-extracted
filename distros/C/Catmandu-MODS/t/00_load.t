#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok 'Catmandu::Importer::MODS';
}

require_ok 'Catmandu::Importer::MODS';

done_testing 2;
