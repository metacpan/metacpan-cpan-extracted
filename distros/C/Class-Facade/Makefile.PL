use ExtUtils::MakeMaker;

my %opts = (
    'NAME'	   => 'Class::Facade',
    'VERSION_FROM' => 'lib/Class/Facade.pm',
    'PREREQ_PM'    =>  {
         Class::Base => 0.01,
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andy Wardley <abw@kfs.org>';
    $opts{ ABSTRACT } = 'facade class for delegating to other objects',
}

WriteMakefile( %opts );
