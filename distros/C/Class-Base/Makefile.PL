use ExtUtils::MakeMaker;

my %opts = (
    'NAME'	   => 'Class::Base',
    'VERSION_FROM' => 'lib/Class/Base.pm',
    'PREREQ_PM' => { },
    'TEST_REQUIRES' => {
        'Test::More' => 0.47,
    },
    LICENSE  => 'perl',
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                web  => 'https://github.com/szabgab/Class-Base',
                url  => 'https://github.com/szabgab/Class-Base',
                type => 'git',
            },
        },
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andy Wardley <abw@kfs.org>';
    $opts{ ABSTRACT } = 'useful base class for other modules',
}
if ($ExtUtils::MakeMaker::VERSION <= 6.64) {
  if ($ExtUtils::MakeMaker::VERSION >= 6.55_01) {
    $opts{ BUILD_REQUIRES } = delete $opts{ TEST_REQUIRES };
  } else {
    $opts{ PREREQ_PM }      = delete $opts{ TEST_REQUIRES };
  }
}
WriteMakefile( %opts );
