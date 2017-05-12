# Copyright (c) 2010 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Test::More; 

my $class = "CPAN::Testers::Metabase::MongoDB";

my $db_prefix = "testing";
my $host = "mongodb://localhost:27017";

require_ok( $class );
my $mb = new_ok( $class, [ db_prefix => $db_prefix, host => $host ] );

for my $zone ( qw/public private/ ) {
  my $method = "${zone}_librarian";
  my $librarian = $mb->$method;

  # check archive
  isa_ok( my $archive = $librarian->archive, "Metabase::Archive::MongoDB",
    "$zone: archive class"
  );

  # check index
  isa_ok( my $index = $librarian->index, "Metabase::Index::MongoDB",
    "$zone: index class"
  );
}

done_testing;
