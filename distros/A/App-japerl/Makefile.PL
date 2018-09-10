use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'App::japerl',
    'VERSION_FROM'  => 'bin/japerl.bat',
    'ABSTRACT_FROM' => 'bin/japerl.bat',
    'PREREQ_PM'     => { },
    'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
);

__END__
