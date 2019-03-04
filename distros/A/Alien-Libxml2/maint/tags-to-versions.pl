use strict;
use warnings;
use version;

my @tags = `git tag`;
chomp @tags;

my %v;

foreach my $version (@tags)
{
  next if $version =~ /-rc[0-9]$/; # ignore rc
  next if $version =~ /^CVE/;
  next if $version =~ /^PRE_MUCKUP/;
  next if $version eq 'help';
  next if $version =~ /^(help|GNUMERIC_FIRST_PUBLIC_RELEASE|ChangeLog|EAZEL-NAUTILUS-MS-AUG07|FOR_GNOME_0_99_1|GNOME_0_30|GNOME_PRINT_0_24|LIBXML2_2_5_x|LIB_XML_1_X)$/;
  
  my @v;
  
  if($version =~ /^LIBXML([0-9]+)\.([0-9]+)\.([0-9]+)$/)
  {
    @v = ($1,$2,$3);
  }
  elsif($version =~ /^LIBXML2_([0-9]+)_([0-9]+)_([0-9]+)$/)
  {
    @v = ($1,$2,$3);
  }
  elsif($version =~ /^LIBXML_?([0-9]+)_([0-9]+)_([0-9]+)(_REAL)?$/)
  {
    @v = ($1,$2,$3);
  }
  elsif($version =~ /^LIBXML_TEST_([0-9]+)_([0-9]+)_([0-9]+)?$/)
  {
    @v = ($1,$2,$3);
  }
  elsif($version =~ /^LIB_?XML_([0-9]+)_([0-9]+)$/)
  {
    @v = ($1,$2,$3);
  }
  elsif($version =~ /^LIB_?XML_([0-9]+)_([0-9]+)_([0-9]+)$/)
  {
    @v = ($1,$2,$3);
  }
  elsif($version =~ /^v([0-9]+)\.([0-9]+)\.([0-9]+)$/)
  {
    @v = ($1,$2,$3);
  }
  else
  {
    die "unrecognized tag format: $version";
  }
  
  next if $v[0] != 2;

  for(0..$3)
  {
    $v{"$v[0].$v[1].$_"} = 1;
  }  
}

my $bl = [
  # format X,Y,Z,is_ok, X,Y,Z is version,
  # is_ok applies also to *preceding* versions
  [2,4,22,0],
  [2,4,25,0], # broken XPath
  [2,4,28,0], # unsupported, may work fine with earlier XML::LibXML versions
  [2,4,29,0], # broken
  [2,4,30,0], # broken
  [2,5,0,0], # unsupported
  [2,5,1,0], # all pre 2.5.4 version have broken attr output
  [2,5,5,0], # tests pass, but known as broken
  [2,5,11,0], # will partially work
  [2,6,0,0], # unsupported
  [2,6,4,0], # schema error
  [2,6,5,0], # broken xincludes
  [2,6,15,0],
# [2,6,16,1], # first version to pass all tests
  [2,6,18,1], # up to 2.6.18 all ok
  [2,6,19,0], # broken c14n
  [2,6,20,0], # broken schemas
  [2,6,24,1], # all tests pass
  [2,6,25,0], # broken XPath
  [2,6,32,1], # tested, works ok
  [2,7,1,0], # broken release, broken utf-16
  [2,7,6,1], # tested, ok
  [2,7,8,1], # tested, ok
  [2,9,3,1], # schema regression
  [2,9,4,0], # schema regression
  [2,9,6,1],
];

my @bad;

foreach my $ver (sort map { version->parse($_) } keys %v)
{
  my($major, $minor, $point) = $ver =~ /([0-9]+).([0-9]+)\.([0-9]+)/g;

  my $state = undef;

  foreach my $i (@$bl)
  {
    $state = $i->[3];
    last if $major <  $i->[0];
    next if $major >  $i->[0];
    last if $minor <  $i->[1];
    next if $minor >  $i->[1];
    last if $point <= $i->[2];
    $state = undef;
  }
  
  if(defined $state and $state == 0)
  {
    print "'$ver',";
  }
}

print "\n";

