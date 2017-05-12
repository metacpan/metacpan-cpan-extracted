#!/usr/bin/perl
use lib('../lib');
use strict;
use Config::Universal;

my $conf=new Config::Universal();
$conf->ReadConfigFile("sample5.conf") && die ("ReadConfigFile failed");
foreach my $objtype ($conf->GetObject()){
   printf("\nobjects of type '$objtype':\n");
   foreach my $objectname ($conf->GetObject($objtype)){
      foreach my $object ($conf->GetObject($objtype,$objectname)){
         printf(" %-15s%s\n",$objectname.":",
                join(",",map({$_."=".$object->{$_}} sort(keys(%$object)))));
         if (my $p=$conf->FindParentObject($object)){
            printf(" %15sparent=%s\n","",$conf->ObjectInfo($p,'FQNAME'));
         }
         if ($objtype eq "server"){
            foreach my $subobj ($conf->FindSubordinate($object,'vg')){
               printf(" %15svg=%s\n","",$conf->ObjectInfo($subobj,'FQNAME'));
            }
         }
      }
   }
}
printf("\n");
