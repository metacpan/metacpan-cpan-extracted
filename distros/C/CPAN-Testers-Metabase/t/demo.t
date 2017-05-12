# Copyright (c) 2010 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use File::Temp ();
use Path::Class qw/dir file/;
use Test::More; 

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

my $class = "CPAN::Testers::Metabase::Demo";

my $data_dir = File::Temp->newdir();

require_ok( $class );
my $mb = new_ok( $class, [ data_directory => "$data_dir" ] );

for my $zone ( qw/public private/ ) {
  my $method = "${zone}_librarian";
  my $librarian = $mb->$method;

  # check archive
  isa_ok( my $archive = $librarian->archive, "Metabase::Archive::SQLite",
    "$zone: archive class"
  );
  is( $archive->filename, dir($data_dir)->file($zone,"archive.sqlite"),
    "$zone: correct SQLite filename"
  );

  # check index
  isa_ok( my $index = $librarian->index, "Metabase::Index::FlatFile",
    "$zone: index class"
  );
  is( $index->index_file, dir($data_dir)->file($zone,"index.json"),
    "$zone: correct flatfile filename"
  );
}

done_testing;
