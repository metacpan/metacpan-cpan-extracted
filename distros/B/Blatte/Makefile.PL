use strict;

use ExtUtils::MakeMaker;

my %PM = (map { ("lib/$_" => "\$(INST_LIBDIR)/$_") } qw(Blatte.pm
                                                        Blatte/Builtins.pm
                                                        Blatte/Compiler.pm
                                                        Blatte/Parser.pm
                                                        Blatte/Syntax.pm
                                                        Blatte/Ws.pm));
my %PL = (map { ("$_.PL" => "$_") } qw(bin/blatte));

&WriteMakefile(NAME         => 'Blatte',
               VERSION_FROM => 'lib/Blatte.pm',
               PM           => \%PM,
               PL_FILES     => \%PL,
               EXE_FILES    => ['bin/blatte'],
               PREREQ_PM    => {'File::Basename'    => 0},
               clean        => {FILES => join(' ', values %PL)});
