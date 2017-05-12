# perl Makefile.PL && nmake realclean && cls && perl Makefile.PL && nmake test
# cpan-upload -mailto yo@yo.yo -verbose -user podmaster Acme-MJD-0.02.tar.gz


use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::MJD',
    VERSION_FROM => 'lib/Acme/MJD.pm', # finds \$VERSION
    AUTHOR       => 'D. H. (PodMaster)',
    ABSTRACT     => 'Mark Jason Dominus does perl',
    PREREQ_PM    => {
                     'Text::Wrap' => 0,
                    },
);

__END__

# -*- perl -*-
print "1..1\n";
eval {
    require Acme::MJD;
    print "ok 1\n";
} or print "not ok 1 - $@\n";
