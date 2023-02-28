use ExtUtils::Manifest qw(mkmanifest skipcheck manicheck maniread);
 
 mkmanifest();
 
my $manifest = maniread();

#foreach my $key (keys %$manifest) {
#	
#   print (" key is $key\n");
#   
#}
