use ExtUtils::MakeMaker;

my %opts = (
    'NAME'          => 'Class::Observable',
    'VERSION_FROM'  => 'lib/Class/Observable.pm',
    'PREREQ_PM'     => {
        Class::ISA   => 0.32,
        Scalar::Util => 1.00,
        Test::More   => 0.40,
    }
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com';
    $opts{ABSTRACT} = 'Allow any number of items to respond to changes in your class/object'
}

WriteMakefile( %opts );
