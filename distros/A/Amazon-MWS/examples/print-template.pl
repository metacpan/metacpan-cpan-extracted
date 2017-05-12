#!/usr/bin/env perl


use warnings;
use strict;

use XML::Compile::Schema;

my $schema = XML::Compile::Schema->new([glob "schemas/*.xsd"]);

print $schema->template(PERL => 'AmazonEnvelope');

