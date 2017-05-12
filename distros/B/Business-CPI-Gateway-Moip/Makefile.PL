
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::CPI::Gateway::Moip',
    VERSION_FROM => 'lib/Business/CPI/Gateway/Moip.pm',    # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernan@cpan.org)',
    ABSTRACT     => 'Inteface para pagamentos moip',
    PREREQ_PM    => {
        'Test::Simple'          => 0.44,
        'Data::Printer'         => 0,
        'Business::CPI'         => 0,
        'HTTP::Tiny'            => 0,
        'Moo'                   => 0,
        'MIME::Base64'          => 0,
        'Carp'                  => 0,
        'bareword::filehandles' => 0,
        'indirect'              => 0,
        'multidimensional'      => 0,
        'HTTP::Tiny'            => 0,
        'Data::Dumper'          => 0,
        'bareword::filehandles' => 0,
        'Email::Valid'          => 0,
        'IO::Socket::SSL'       => 0,
        'Locale::Codes'         => 3.25,
    },
);
