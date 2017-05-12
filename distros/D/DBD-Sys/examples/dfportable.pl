 use Filesys::DfPortable;

  my $ref = dfportable("C:\\"); # Default block size is 1, which outputs bytes
  if(defined($ref)) {
     print"Total bytes: $ref->{blocks}\n";
     print"Total bytes free: $ref->{bfree}\n";
     print"Total bytes avail to me: $ref->{bavail}\n";
     print"Total bytes used: $ref->{bused}\n";
     print"Percent full: $ref->{per}\%\n"
  }


  my $ref = dfportable("/tmp", 1024); # Display output in 1K blocks
  if(defined($ref)) {
     print"Total 1k blocks: $ref->{blocks}\n";
     print"Total 1k blocks free: $ref->{bfree}\n";
     print"Total 1k blocks avail to me: $ref->{bavail}\n";
     print"Total 1k blocks used: $ref->{bused}\n";
     print"Percent full: $ref->{per}\%\n"
  }
