#!/usr/bin/perl
use lib('../lib');
use Config::Universal;

my $conf=new Config::Universal();
if ($conf->ReadConfigFile("sample4-a.conf")){
   printf STDERR ("ERROR: can't open configfile\n");
   exit(1);
}
printf("\nobject types in configfile:%s\n",join(",",$conf->GetObject()));
printf("global variables          :%s\n",join(",",$conf->GetVarValue()));
printf("\nobjects of type 'node':\n");
foreach my $objectname ($conf->GetObject("node")){
   foreach my $object ($conf->GetObject("node",$objectname)){
      printf(" %-18s%s\n",$objectname.":",
             join(",",map({$_."=".$object->{$_}} sort(keys(%$object)))));
   }
}
printf("\n");
