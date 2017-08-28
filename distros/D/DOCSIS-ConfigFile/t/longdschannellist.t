use strict;
use warnings;
use Test::More;
use DOCSIS::ConfigFile qw(decode_docsis encode_docsis);

my $input = {
  DsChannelList => {
    SingleDsChannel => [
      {SingleDsFrequency => 100000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 200000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 300000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 400000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 400000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 500000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 600000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 700000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 800000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 900000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 910000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 920000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 930000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 940000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 950000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 960000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 970000000, SingleDsTimeout   => 1},
      {SingleDsTimeout   => 1,         SingleDsFrequency => 980000000},
      {SingleDsFrequency => 990000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 810000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 820000000, SingleDsTimeout   => 1},
      {SingleDsFrequency => 830000000, SingleDsTimeout   => 1},
    ]
  }
};

eval { encode_docsis($input) };
like $@, qr{pack}, 'encode_docsis failed';

done_testing;
