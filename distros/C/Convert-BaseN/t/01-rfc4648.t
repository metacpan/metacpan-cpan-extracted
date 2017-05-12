#!perl -T
#
# $Id: 01-rfc4648.t,v 0.1 2008/06/16 17:34:27 dankogai Exp dankogai $
#

use strict;
use warnings;
use Test::More tests => 56;
#use Test::More qw/no_plan/;
use Convert::BaseN;

my %test_vector = (
    base64 => {
        ''     => '',
        f      => "Zg==",
        fo     => "Zm8=",
        foo    => "Zm9v",
        foob   => "Zm9vYg==",
        fooba  => "Zm9vYmE=",
        foobar => "Zm9vYmFy",
    },
    base32 => {
        ''     => '',
        f      => "MY======",
        fo     => "MZXQ====",
        foo    => "MZXW6===",
        foob   => "MZXW6YQ=",
        fooba  => "MZXW6YTB",
        foobar => "MZXW6YTBOI======",
    },
    base32hex => {
        ''     => '',
        f      => "CO======",
        fo     => "CPNG====",
        foo    => "CPNMU===",
        foob   => "CPNMUOG=",
        fooba  => "CPNMUOJ1",
        foobar => "CPNMUOJ1E8======",
    },
    base16 => {
        ''     => '',
        f      => "66",
        fo     => "666F",
        foo    => "666F6F",
        foob   => "666F6F62",
        fooba  => "666F6F6261",
        foobar => "666F6F626172"
    },
);

for my $base (sort keys %test_vector){
    my $cb  = Convert::BaseN->new($base);
    my %kv  = %{$test_vector{$base}};
    for my $k ( sort keys %kv ) {
	my $v = $kv{$k};
	# make sure not to insert \n
	is $cb->encode( $k, "" ), $v, qq($base: "$k" -> "$v");
	is $cb->decode( $v ),     $k, qq($base: "$v" -> "$k");
    }
}

