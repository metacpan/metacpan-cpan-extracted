use strict;
use warnings;
use autodie;
use Data::FlexSerializer;
use Test::More;
use File::Spec;
use File::Temp qw/tmpnam/;
use Data::Dumper;

BEGIN {
  unshift @INC, -d 't' ? File::Spec->catdir(qw(t lib)) : 'lib';
}
use Data::FlexSerializer::EmptySubclass;

foreach my $class ('Data::FlexSerializer', 'Data::FlexSerializer::EmptySubclass') {

  foreach my $format ('json', 'storable', 'sereal') {

    foreach my $compression (0, 1) {

      my $serializer = $class->new(
        output_format => $format,
        assume_compression => $compression,
        compress_output => $compression,
        detect_storable => $format eq 'storable' ? 1 : 0,
        detect_sereal => $format eq 'sereal' ? 1 : 0,
      );

      isa_ok($serializer, $class);

      my %data = (
        key1 => "string",
        key2 => 1,
      );
      my %deserialized_data;

      my $filename = tmpnam();
      open my $fh, '+>', $filename;

      # Test (de)serialization to/from file handle
      $serializer->serialize_to_fh(\%data, $fh);

      # reset file handle
      seek($fh, 0, 0);

      %deserialized_data = %{ $serializer->deserialize_from_fh($fh) };

      close $fh;

      is_deeply(\%data, \%deserialized_data, "deserialized data must be the same as original");


      # Test (de)serialization to/from filename
      $serializer->serialize_to_file(\%data, $filename);

      %deserialized_data = %{ $serializer->deserialize_from_file($filename) };

      is_deeply(\%data, \%deserialized_data, "deserialized data must be the same as original");

    } # $compression

  } # $format

} # $class

done_testing();
