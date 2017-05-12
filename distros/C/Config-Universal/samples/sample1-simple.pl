#!/usr/bin/perl
use lib('../lib');
use Config::Universal;

my $conf=new Config::Universal();
if ($conf->ReadConfigFile("sample1.conf")){
   printf STDERR ("ERROR: can't open configfile\n");
   exit(1);
}
printf("\nobject types in configfile:%s\n",join(",",$conf->GetObject()));
printf("\nobjects of type 'node':\n");
foreach my $objectname ($conf->GetObject("node")){
   foreach my $object ($conf->GetObject("node",$objectname)){
      printf(" %-18s%s\n",$objectname.":",
             join(",",map({$_."=".$object->{$_}} sort(keys(%$object)))));
   }
}
printf("\nglobal variables:\n");
foreach my $varname ($conf->GetVarValue()){
   my $val=$conf->GetVarValue($varname);
   printf(" %-18s%s\n",$varname.":",$val);
}
printf("\n");
