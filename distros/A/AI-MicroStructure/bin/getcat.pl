#!/usr/bin/env perl
use File::Find::Rule;
use strict;
use warnings;
use JSON;
use Cache::Memcached::Fast;
use Try::Tiny;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex md5_base64);

our $memd = new Cache::Memcached::Fast({
 servers => [ { address => 'localhost:11211', weight => 2.5 }],
 namespace => 'my:',
 connect_timeout => 0.2,
 io_timeout => 0.1,
 close_on_error => 1,
 compress_threshold => 100_000,
 compress_ratio => 0.9,
 max_failures => 1,
 max_size => 512 * 1024,
});



our $all = {};
our $json = JSON->new->allow_nonref;

sub mytry{
  my $cmd = shift;

try {

  #if($cmd){
  my @ret = split "\n",`$cmd`;

  return [@ret];
  #}

  };
}
sub trim
{

  my $string = shift;
  $string =  "" unless  $string;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/\t//;
  $string =~ s/^\n//;
  $string =~ s/^\s//;
  $string =~s/\x{ef}//g;
  return $string;
}



sub check {

 my $name = shift;
 my $prog = shift;
 my $ret  = "";



 if(defined(my $ret = $memd->get(md5_hex(sprintf("%s_%s",$name,$prog))))){
    return $ret;
  }else{
    my $cmd = sprintf("%s %s",$prog,$name);
     my $ret = mytry($cmd);

     $memd->set(md5_hex(sprintf("%s_%s",$name,$prog)),$ret);
     return $ret;
  }
}

die() unless(@ARGV);

my @cat = check(shift,"getcat");

printf("%s\n",join("\n",reverse sort @{$cat[0]}));

1;

