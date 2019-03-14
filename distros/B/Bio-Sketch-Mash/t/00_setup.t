#!/usr/bin/env perl

# Hack the testing framework to install Mash locally

use strict;
use warnings;
use File::Spec;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use Test::More tests=>1;

my $mashExe = which("mash");
my $numcpus = 2;

# This whole thing will be one test:
# either mash is found, or we will install mash.
if($mashExe){
  pass("Found mash and will not rebuild.");
} else {
  subtest "Install prerequisites" => sub{
    plan tests => 2;
    diag "uncompressing capnproto";
    system("cd lib && tar zxvf capnproto-c++-0.7.0.tar.gz");
    if($?){
      BAIL_OUT("Failed the untarring of capnp");
    }
    diag "Configuring capnproto";
    system("cd lib/capnproto-c++-0.7.0 && ./configure --prefix=$RealBin/../lib/capnproto");
    if($?){
      BAIL_OUT("Failed the configuration of capnp");
    }
    diag "making capnproto";
    system("cd lib/capnproto-c++-0.7.0 && make -j $numcpus check && make install
    ");
    if($?){
      BAIL_OUT("Failed the installation of capnp");
    }
    my $capnpExe = "lib/capnproto/bin/capnp";
    if(-e $capnpExe && -x $capnpExe){
      pass("Installed capnp");
    } else {
      BAIL_OUT("Could not install capnp");
    }
    diag "Installing Mash";
    system("
      cd bin && tar zxvf v2.1.1.tar.gz && cd Mash-2.1.1 && sh bootstrap.sh && ./configure --prefix=$RealBin/../bin/Mash --with-capnp=$RealBin/../lib/capnproto && make -j $numcpus
    ");
    if($?){
      BAIL_OUT("Failed the installation of mash");
    }
    $mashExe = "$RealBin/../bin/Mash-2.1.1/mash";
    if(-e $mashExe && -x $mashExe){
      pass("Installed mash");
    } else {
      fail("Could not find mash at $mashExe");
    }
  };
}

diag "Mash executable was found at $mashExe";

sub which{
  my($exec)=@_;

  return undef unless $exec;

  my @path = File::Spec->path;
  for my $p(@path){
    if( -e "$p/$exec" && -x "$p/$exec"){
      return "$p/$exec";
    }
  }
  return undef;
}
