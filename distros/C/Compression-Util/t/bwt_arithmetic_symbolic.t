#!perl -T

use utf8;
use 5.036;
use Test::More;
use Compression::Util qw(:all);

plan tests => 2;

foreach my $file (__FILE__) {

    my $str = do {
        local $/;
        open my $fh, '<:utf8', $file;
        <$fh>;
    };

    my $enc = bwt_compress_symbolic([map { ord($_) } $str =~ /(\X)/g], \&create_ac_entry);
    my $dec = bwt_decompress_symbolic($enc, \&decode_ac_entry);

    ok(length($enc) < length($str));
    is($str, join('', map { chr($_) } @$dec));
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
