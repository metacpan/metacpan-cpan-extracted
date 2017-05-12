use Win32::TieRegistry();

$\ = "\n";

$Win32::TieRegistry::Registry->Delimiter('/');

$t = $Win32::TieRegistry::Registry->{'Classes/CLSID/'};

for my $k ( $t->SubKeyNames )
{
  next unless $t->{"$k/OLE DB Provider/"};
  print $k;
  print '  ', $t->{"$k/"}{''};
  print '  ', $t->{"$k/$_/"}{''}
    for 'OLE DB Provider','InprocServer32','ProgID','VersionIndependentProgID';
}
