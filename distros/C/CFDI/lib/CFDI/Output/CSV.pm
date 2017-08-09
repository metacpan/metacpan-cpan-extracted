package CFDI::Output::CSV;

use strict;

require Exporter;
our @EXPORT = qw(output);
our @ISA = qw(Exporter);
our $VERSION = 0.2;


sub output(_){
  local $_ = shift;
  return unless defined && ref eq 'ARRAY';
  join$/,map{join',',map{defined$_?'"'.$_.'"':'""'}@$_}@$_;
}


1;