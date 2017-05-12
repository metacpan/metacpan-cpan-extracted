# Copyright (c) 2010 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a 
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

use strict;
use warnings;

use Net::Amazon::Config;
use Test::More; 

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

local $ENV{NET_AMAZON_CONFIG_DIR} = 't/config';

my $aws = Net::Amazon::Config->new->get_profile("cpantesters");

my $class = "CPAN::Testers::Metabase::AWS";

my $bucket = "testing";
my $namespace = "dev";

require_ok( $class );
my $mb = new_ok( $class, [ bucket => $bucket, namespace => $namespace ] );

for my $zone ( qw/public private/ ) {
  my $method = "${zone}_librarian";
  my $librarian = $mb->$method;

  # check archive
  isa_ok( my $archive = $librarian->archive, "Metabase::Archive::S3",
    "$zone: archive class"
  );
  is( $archive->access_key_id, $aws->access_key_id , 
    "$zone: correct access key ID"
  );
  is( $archive->secret_access_key, $aws->secret_access_key, 
    "$zone: correct secret access key"
  );
  is( $archive->bucket, $bucket, 
    "$zone: correct S3 bucket"
  );
  is( $archive->prefix, "metabase/${namespace}/${zone}/", 
    "$zone: correct S3 prefix"
  );

  # check index
  isa_ok( my $index = $librarian->index, "Metabase::Index::SimpleDB",
    "$zone: index class"
  );
  is( $archive->access_key_id, $aws->access_key_id , 
    "$zone: correct access key ID"
  );
  is( $archive->secret_access_key, $aws->secret_access_key, 
    "$zone: correct secret access key"
  );
  is( $index->domain, "${bucket}.metabase.${namespace}.${zone}", 
    "$zone: correct SimpleDB domain"
  );
}

done_testing;
