use ExtUtils::MakeMaker;

print qq~
Please note that this module is long-since abandoned. While I do accept
patches, and occasionally apply them, for the most part it is
recommended that you move off of this module and use the various modules
developed by the datetime project. You can find out more about the
datetime project at http://datetime.perl.org/

Rich Bowen - RBOW@CPAN.ORG
~;

WriteMakefile(
  'NAME'         => 'Date::ICal',
  'VERSION_FROM' => 'lib/Date/ICal.pm',    # finds $VERSION
  'PREREQ_PM'    => {
      Test::Harness => '2.25',
      Test::More    => '0.45',
      #     Test::Inline => 0,
      Date::Leapyear => '1.03',
      Time::Local    => 0,
      Time::HiRes    => 0,
      Storable       => 0,
  },    # e.g., Module::Name => 1.1
);

# Don't currently have any inline tests
# open(MANIFEST, "MANIFEST");
# foreach my $file (grep /\.pm$/, <MANIFEST>) {
#    chomp $file;
#    my($module) = $file =~ m|^(.*)\.pm$|;
#    $module =~ s|/|-|g;
#    system("pod2test $file t/embedded-$module.t");
#}

sub MY::postamble {
    package MY;
    "\npredist: all\n" .
    "\tcvs2cl -r -b -t -f Changes\n".
    "\techo '# vim: filetype=changelog' >> Changes\n".
    "\tpod2text lib/Date/ICal.pm >! README\n".
    "\techo '------------------------------------------------' >> README\n".
    "\tpod2text lib/Date/ICal/Duration.pm >> README\n"
}

