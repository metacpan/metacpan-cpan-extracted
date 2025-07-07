#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Long qw(:config no_ignore_case);
use Crypt::OpenSSL::BaseFunc;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
#use Data::Dumper;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my %opt;
GetOptions(
  \%opt,
  'group|g=s', 
  'in|i=s', 
  'out|o=s', 
  'hex|h=s', 
  'pubx|x=s',
  'puby|y=s', 
  'compressed', 
  'pubin',
  'pubout', 
  'pkcs8', 
);

#my $nid = OBJ_sn2nid($group_name);
#my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name($nid);
#my $ctx   = Crypt::OpenSSL::Bignum::CTX->new();

my %res;
if(defined $opt{pubin}){
    if(defined $opt{in} and -f $opt{in}){
        if($opt{in}=~/\.pem$/i){
            $res{pub} = read_pubkey_from_pem($opt{in});
        }elsif($opt{in}=~/\.der$/i){
            $res{pub} = read_pubkey_from_der($opt{in});
        }
    }elsif(defined $opt{hex} and defined $opt{group}){
        $res{pub} = gen_ec_pubkey($opt{group},  $opt{hex});
    }
}else{
    if(defined $opt{in} and -f $opt{in}){
        if($opt{in}=~/\.pem$/i){
            $res{priv} = read_key_from_pem($opt{in});
        }elsif($opt{in}=~/\.der$/i){
            $res{priv} = read_key_from_der($opt{in});
        }
    }elsif(defined $opt{hex} and defined $opt{group}){
        $res{priv} = gen_ec_key($opt{group},  $opt{hex});
    }
    #my $priv_bn = read_key_bn($res{priv});
    #print "xxx priv: ", $priv_bn->to_hex, "\n";
}

if(defined $res{priv}){
    my $priv_hex = read_key($res{priv});
    print "priv: ", $priv_hex, "\n";
}

if((! defined $opt{pubin}) and (! defined $opt{pubout})){
    if(defined $opt{out}){
        if($opt{out}=~/\.pem$/i){
            write_key_to_pem($opt{out}, $res{priv});
        }elsif($opt{out}=~/\.der$/i){
            write_key_to_der($opt{out}, $res{priv});
        }
    }
}else{
    $res{pub} = export_ec_pubkey($res{priv}) if($res{priv});
    my $pub_hex = read_ec_pubkey($res{pub}, $opt{compressed} // 0);
    print "pub: ", $pub_hex, "\n";

    if(defined $opt{out}){
        if($opt{out}=~/\.pem$/i){
            write_pubkey_to_pem($opt{out}, $res{pub});
        }elsif($opt{out}=~/\.der$/i){
            write_pubkey_to_der($opt{out}, $res{pub});
        }
    }
}

