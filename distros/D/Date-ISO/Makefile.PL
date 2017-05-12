use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Date::ISO',
  'VERSION_FROM' => 'lib/Date/ISO.pm',    # finds $VERSION
  'PREREQ_PM'    => {
      'Date::Leapyear' => 0,
      'Date::ICal'     => '1.54',
      'Test::More'     => 0,
      'Test::Inline'   => 0,
      'Memoize'        => 0,
  },
  'realclean' => { FILES => 't/embedded-*' },
);

open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
    chomp $file;
    my($module) = $file =~ m|^(.*)\.pm$|;
    $module =~ s|/|-|g;
    system("pod2test $file t/embedded-$module.t");
}

