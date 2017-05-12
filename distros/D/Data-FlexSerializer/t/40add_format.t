use strict;
use warnings;
use Test::More tests => 3;
use Data::FlexSerializer;
use Data::Dumper ();

Data::FlexSerializer->add_format(
    data_dumper => {
        serialize   => sub { shift; goto \&Data::Dumper::Dumper },
        deserialize => sub { shift; my $VAR1; eval "$_[0]" },
        detect      => sub { $_[1] =~ /\$[\w]+\s*=/ },
    }
);

ok(Data::FlexSerializer->has_format('data_dumper'), "We have a data_dumper format");
is(scalar Data::FlexSerializer->supported_formats, 4, "We have 4 formats now");

my $flex_to_dd = Data::FlexSerializer->new(
  detect_data_dumper => 1,
  output_format => 'data_dumper',
);

my $value = [];
my $serialize = $flex_to_dd->serialize($value);
my $deserialize = $flex_to_dd->deserialize($serialize);
is_deeply($value, $deserialize, "We can serialize/deserialize with Data::Dumper");
