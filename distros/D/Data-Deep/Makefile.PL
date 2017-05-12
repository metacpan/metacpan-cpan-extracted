use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME' => 'Data::Deep',
    'VERSION_FROM' => 'lib/Data/Deep.pm', # finds $VERSION
    'LICENSE' => 'perl',
    ($] ge '5.004') ? (
        'AUTHOR' => 'Matthieu Damerose (damo@cpan.org)',
        'ABSTRACT' => 'Manipulation of Deep perl structure',
    ) : (),
);
