use strict;
use warnings;
use Test::More;
use Encode qw//;

# Specify ot override Dumper function as same as eDumper
use Data::Dumper::AutoEncode 'eDumper';

{
    my $decoded_str = Encode::decode_utf8('復活祭');
    like eDumper($decoded_str), qr/復活祭/;
}

{
    eval { Dumper('復活祭') };
    like $@, qr/Undefined subroutine [^\s]+::Dumper called/;
}

done_testing;
