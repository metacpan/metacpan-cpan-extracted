package TestApp::View::TSV;

use base qw ( Catalyst::View::CSV );
use strict;
use warnings;

__PACKAGE__->config ( sep_char => "\t", suffix => "tsv" );

1;
