use ExtUtils::MakeMaker;

# script to write out the makefile.  Note that we list both
# Test::Builder and Test::Builder::Tester as needed modules.
WriteMakefile( NAME         => "Acme::Test::Buffy",
               VERSION_FROM => "lib/Acme/Test/Buffy.pm",
               PREREQ_PM    => { Test::Builder => 0.12,
			         Test::Builder::Tester => 0.09},
);
