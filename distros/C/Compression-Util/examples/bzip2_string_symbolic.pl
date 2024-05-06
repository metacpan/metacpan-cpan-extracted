#!/usr/bin/perl

# Bzip2-like (symbolic) compressor/decompressor, for compressing a given string.

use utf8;
use 5.036;
use lib               qw(../lib);
use Compression::Util qw(:all);

local $Compression::Util::VERBOSE = 0;

foreach my $file (__FILE__) {

    say "Compressing: $file";

    my $str = do {
        local $/;
        open my $fh, '<:utf8', $file;
        <$fh>;
    };

    my $enc = bz2_compress_symbolic([map { ord($_) } $str =~ /(\X)/g]);
    my $dec = bz2_decompress_symbolic($enc);

    say "Original size  : ", length($str);
    say "Compressed size: ", length($enc);

    if ($str ne join('', map { chr($_) } @$dec)) {
        die "Decompression error";
    }

    say '';
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
