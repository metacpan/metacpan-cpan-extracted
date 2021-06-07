package
  LibarchiveRef;

use strict;
use warnings;
use Path::Tiny qw( path );
use base qw( Exporter );
use 5.020;

our @EXPORT = qw( ref_config );

sub ref_config
{
  state $config;

  $config ||= do {
    my %config = map { m/^export REF_(.*?)=(.*)$/ ? ($1 => $2) : () } path(__FILE__)->parent->parent->child('ref-config')->lines_utf8({ chomp => 1 });
    \%config;
  };
}

;
