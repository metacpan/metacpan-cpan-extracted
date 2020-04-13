use strict;
use warnings;
use Test::More;
use Encode qw//;

# Specify ot override Dumper function as same as eDumper
use Data::Dumper::AutoEncode '-dumper';

{
    my $decoded_str = Encode::decode_utf8('復活祭');
    like eDumper($decoded_str), qr/復活祭/;
    is Dumper($decoded_str), eDumper($decoded_str);
}

done_testing;
