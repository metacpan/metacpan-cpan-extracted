use strict;
use warnings;
use ExtUtils::MakeMaker;

my $primary_module = 'lib/Class/Agreement.pm';

my %config = (
    NAME          => 'Class::Agreement',
    AUTHOR        => 'Ian Langworth <ian@cpan.org>',
    VERSION_FROM  => $primary_module,
    ABSTRACT_FROM => $primary_module,
    PREREQ_PM     => {
        'Test::More'       => '0.54',
        'Test::Exception'  => '0.20',
        'Class::Inspector' => '1.13',
        'Scalar::Util'     => '1.17',
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        PREOP    => "pod2text $primary_module >README",
    },
    clean => { FILES => 'Class-Agreement-* .lwpcookies' },
);

# By default, tests in t/private are not run.
# You shouldn't care about them, either. :)

WriteMakefile(%config);

