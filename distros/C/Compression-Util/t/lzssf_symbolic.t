#!perl -T

use utf8;
use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 6;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:utf8', $file;
        <$fh>;
    };

    my @symbols = (map { ord($_) } $str =~ /(\X)/g);

    my $enc1 = lzss_compress(\@symbols, \&create_huffman_entry, \&lzss_encode_fast);
    my $dec1 = lzss_decompress_symbolic($enc1, \&decode_huffman_entry);

    my $enc2 = lz77_compress(\@symbols, \&create_huffman_entry, \&lzss_encode_fast);
    my $dec2 = lz77_decompress_symbolic($enc2);

    my $dec3 = lzss_decode_symbolic(lzss_encode_fast(\@symbols));
    my $dec4 = lz77_decode_symbolic(lz77_encode(\@symbols, \&lzss_encode_fast));

    ok(length($enc1) < length($str));
    ok(length($enc2) < length($str));

    is($str, join('', map { chr($_) } @$dec1));
    is($str, join('', map { chr($_) } @$dec2));
    is($str, join('', map { chr($_) } @$dec3));
    is($str, join('', map { chr($_) } @$dec4));
}

__END__
# International class; name and street
class 国際( なまえ, Straße ) {

    # Say who am I!
    method 言え {
        say "I am #{self.なまえ} from #{self.Straße}";
    }
}

# all the people of the world!
var 民族 = [
              国際( "高田　Friederich", "台湾" ),
              国際( "Smith Σωκράτης", "Cantù" ),
              国際( "Stanisław Lec", "południow" ),
          ];

民族.each { |garçon|
    garçon.言え;
}
