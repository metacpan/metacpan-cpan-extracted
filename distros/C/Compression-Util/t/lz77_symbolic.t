#!perl -T

use utf8;
use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 3;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:utf8', $file;
        <$fh>;
    };

    my @symbols = map { ord($_) } $str =~ /(\X)/g;

    my $enc = lz77_compress_symbolic(\@symbols);
    my $dec = lz77_decompress_symbolic($enc);

    my $dec2 = lz77_decode_symbolic(lz77_encode_symbolic(\@symbols));

    ok(length($enc) < length($str));
    is($str, join('', map { chr($_) } @$dec));
    is($str, join('', map { chr($_) } @$dec2));
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
