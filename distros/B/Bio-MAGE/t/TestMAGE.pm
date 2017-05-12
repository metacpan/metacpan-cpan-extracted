package TestMAGE;

use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(result is_object);
sub result {
  my ($cond) = @_;
  print STDOUT "not " unless $cond;
  print STDOUT "ok ", $main::i++, "\n";
}
sub is_object {
  my ($obj) = @_;
  my $ref = ref($obj);
  return $ref
    && $ref ne 'ARRAY'
    && $ref ne 'SCALAR'
    && $ref ne 'HASH'
    && $ref ne 'CODE'
    && $ref ne 'GLOB'
    && $ref ne 'REF';
}

