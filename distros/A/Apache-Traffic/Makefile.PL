use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Apache::Traffic',
    'VERSION_FROM' => 'Traffic.pm', # finds $VERSION
     'dist'        => {
        COMPRESS   => 'gzip', SUFFIX => 'gz',
    },
    'CONFIGURE'    => \&Apache::Traffic::Configure::configure, 
);

# taken from Andreas Konig and/or Jochen Wiedmann
package Apache::Traffic::Configure;
use FileHandle;
use Config;

sub modify ($$$$) {
  my($source, $dest, $mysub, $perms) = @_;
  my($infile, $outfile, $line);

  unless ($infile = new FileHandle "<$source") {
    print STDERR "Cannot read $source: $!\n";
    exit 10;
  }
  unless ($outfile = new FileHandle ">$dest.new") {
    print STDERR "Cannot create $dest.new: $!\n";
    exit 10;
  }
  while (defined($line = <$infile>)) {
    $line = &$mysub($line);
    if (!(print $outfile $line)) {
      print STDERR "Cannot write $dest.new: $!\n";
    }
  }
  close($infile);
  close($outfile);
  if (-f "$dest.bak"  &&  !unlink "$dest.bak") {
    print STDERR "Cannot remove $dest.bak: $!\n";
    exit 10;
  }
  if (!rename("$dest", "$dest.bak")) {
    print STDERR "Cannot rename $file to $dest.bak\n";
    exit 10;
  }
  if (!rename("$dest.new", "$dest")) {
    print STDERR "Cannot rename $dest.new to $dest: $!\n";
    exit 10;
  }
  unlink "$dest.bak";
  unless (chmod $perms, $dest) {
    print STDERR "Cannot change permissions on $dest: $!\n";
  }
  1;
}

sub configure {
  my $perlpath = sub {
    $line = shift;

    $line =~ s/^#!.*/#!$Config{perlpath}/;
    $line;
  };
  modify('traffic', 'traffic', $perlpath, 0755); # CHANGE PATH TO PERL
  1;
}

