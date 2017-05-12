#!/usr/bin/perl
use lib('../lib');
use Config::Universal;

my $conf=new Config::Universal();
if ($conf->ReadConfigFile("sample2.conf")){
   printf STDERR ("ERROR: can't open configfile\n");
   exit(1);
}
printf("\nobject types in configfile:%s\n",join(",",$conf->GetObject()));
printf("\nobjects of type 'node':\n");
foreach my $objectname ($conf->GetObject("box")){
   printf(" %-18s%s\n",$objectname.":");
   my $obj=$conf->GetObject("box",$objectname);
   my $val=$obj->{'disknames'};
   if (ref($val) eq "ARRAY"){
      printf("   - %s\n",join(",",@{$val}));
   }
   else{
      printf("   - %s\n",$val);
   }
}
printf("\n");
