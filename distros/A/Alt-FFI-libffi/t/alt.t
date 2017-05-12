use strict;
use warnings;
use FFI;
use Test::More;
#use YAML ();

my %types = map { $_ => 1 } FFI::Platypus->types;

foreach my $c (sort keys %FFI::typemap)
{
  my $type = $FFI::typemap{$c};
  my $meta = FFI::Platypus->type_meta($type);
  note "$c => $type => ";
  #note YAML::Dump($meta);
  ok $types{$type};
}

done_testing;
