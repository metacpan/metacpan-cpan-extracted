use strict;
use warnings;
use Test::More 0.88;
use Data::Dumper::AutoEncode;
use Encode qw//;

{
    $Data::Dumper::AutoEncode::BEFORE_HOOK = sub {
        my $value = $_[0];
        $value =~ s/\x{2019}/'/g;
        return $value;
    };

    $Data::Dumper::AutoEncode::AFTER_HOOK = sub {
        my $value = $_[0];
        $value =~ s/$/!/g;
        return $value;
    };

    my $decoded_str = Encode::decode_utf8('But April’s instant stardom');
    like eDumper($decoded_str), qr/But April\\'s instant stardom!/, 'eDumper';
}

done_testing;