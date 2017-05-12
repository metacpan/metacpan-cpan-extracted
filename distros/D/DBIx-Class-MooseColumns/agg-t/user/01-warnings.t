#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->parent->parent->subdir('t', 'lib')->stringify;

use IO::All;

{
  my $code = join "", map { $_->slurp }
    ( io('t/lib/TestSchema.pm'), io('t/lib/TestSchema')->deep->all_files );
  $code =~ s/\bTestSchema\b/TestSchema::WarningTest/g;

  warnings_are {
    eval $code or die;
  } [], "No warnings while loading the test schema";
}

done_testing;
