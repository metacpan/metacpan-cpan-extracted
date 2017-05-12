#!/usr/bin/perl
#
# version 2.00 9-22.02 Michael Robinton, BizSystems michael@bizsystems.com
# Copyright, all rights reserved
#
# input:	ModuleSrc modulename inst_libdir [optional id]
#
use AutoSplit;

my $ENCRYPTIT = 1;		# turn off for debugging

my($src,$mod,$insdir,$id,$method);

if ( @ARGV > 2 ) {	# License module
  ($src,$mod,$insdir,$id) = @ARGV;
  $method = 'license';
} else { 		# Loader module
  ($mod,$insdir) = @ARGV;
  $method = 'loader';
}

$id = 1 unless $id;
my $nocrypt = ! $ENCRYPTIT;

@_ = split('::',$mod);
my $tgt = (pop @_);
my $xpath = join('/',@_);

$src = "$tgt.PM" unless @ARGV > 2;	# if Loader

undef @ARGV;		# for mod_parser

die "no source file" unless $src && open(S,$src);
read(S,$_,(stat(S))[7]);
close S;
open(T,">$insdir/$xpath/$tgt.pm") or die "could not open target";
print T $_;
close T;

do './mod_parser.pl';

$sdir = "$insdir/auto";
if ($sdir && -e $sdir) {
  autosplit("$insdir/$xpath/$tgt.pm","$sdir",0,1,0);
  $sdir .= "/$xpath/$tgt";
  opendir(S,$sdir);
  @_ = grep(/\.al$/,readdir(S));
  closedir S;
  foreach(@_) {
    &crypt_mod("$sdir/$_","$sdir/$_",$method,$id,$nocrypt);
  }
  open(S,">>$sdir/autosplit.ix");
  close S;				# touched
}
&crypt_mod($src,"$tgt.pm",$method,$id,$nocrypt);
open(S,"$tgt.pm");
read(S,$_,(stat(S))[7]);
close S;
open(T,">$insdir/$xpath/$tgt.pm");
print T $_;
close T;
