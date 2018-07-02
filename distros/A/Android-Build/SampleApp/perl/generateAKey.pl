#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Generate a key with which to sign an Android app.
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Carp;

my $keyStore = "../keys/genApp.keystore";

if (-e $keyStore)
 {confess "Keystore $keyStore already exists";
 }

#-------------------------------------------------------------------------------
# Generate key
#-------------------------------------------------------------------------------

makePath($keyStore);
my $c = << "END" =~ s/\n/ /gsr;
keytool
  -genkey -v
  -keystore ${keyStore}
  -alias xxx
  -dname "cn=com.appaapps.genapp"
  -keyalg RSA -keysize 2048 -validity 10000
  -keypass xxx
  -storepass xxx
END

say STDERR "$c\n", qx($c);
