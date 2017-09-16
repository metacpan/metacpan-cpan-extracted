use strict;
use warnings;
use Test::More 0.88;
use Data::Dumper::AutoEncode;
use Encode qw//;

{
    my $decoded_str = Encode::decode_utf8('富士は日本一の山');
    like(
        Dumper($decoded_str),
        qr/\Q\x{5bcc}\x{58eb}\x{306f}\x{65e5}\x{672c}\x{4e00}\x{306e}\x{5c71}/,
        'Dumper'
    );

    like eDumper($decoded_str), qr/富士は日本一の山/, 'eDumper';
}

{
    my $decoded_str = Encode::decode_utf8('富士は日本一の山');
    my @hoge = ($decoded_str, $decoded_str);
    like(
        eDumper($decoded_str, $decoded_str),
        qr/^\$VAR1 = '富士は日本一の山';\n\$VAR2 = '富士は日本一の山';\n$/,
        'eDumper few args'
    );
}

{
    my $str = '富士は日本一の山';
    Encode::from_to($str, 'utf8', 'CP932');
    my $decoded_str = Encode::decode('CP932', $str);
    like(
        Dumper($decoded_str),
        qr/\Q\x{5bcc}\x{58eb}\x{306f}\x{65e5}\x{672c}\x{4e00}\x{306e}\x{5c71}/,
        'Dumper CP932'
    );
    local $Data::Dumper::AutoEncode::ENCODING = 'CP932';
    like eDumper($decoded_str), qr/\$VAR1.+/, 'eDumper CP932';
}

{
    like(
        eDumper({ foo => 123 }),
        qr/'foo' => 123/,
        'numeric value'
    );
}

{
    my $ret = eDumper({ Encode::decode_utf8('富士は日本一の山') => 'エベレストは世界一の山' });
    like $ret, qr/富士は日本一の山/, 'ex decoded';
    like $ret, qr/エベレストは世界一の山/, 'ex encoded';
}

done_testing;
