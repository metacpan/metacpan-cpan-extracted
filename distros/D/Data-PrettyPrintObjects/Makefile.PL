
use ExtUtils::MakeMaker;
use 5.00000;
use strict;
use warnings;
my %requires = (
                 'Exporter'                 => '0',
                 'Scalar::Util'             => '0',
                 'YAML::Syck'               => '0',
                 'Archive::Zip'             => '0',
                 'Date::Manip::Date'        => '0',
                 'Test::Inter'              => '0',
                 'Test::Pod'                => '1.0',
                 'Test::Pod::Coverage'      => '1.0',
               );


WriteMakefile(
        NAME             => 'Data::PrettyPrintObjects',
        VERSION          => '1.00',
        ($] >= 5.00000
        ? (ABSTRACT=>'a pretty printing module with better support for objects',
           AUTHOR  =>'Sullivan Beck (sbeck@cpan.org)')
        : ()),
        'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
        PL_FILES  => {},
        PREREQ_PM => \%requires,
);
