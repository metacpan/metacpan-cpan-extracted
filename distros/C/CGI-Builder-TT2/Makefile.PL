use ExtUtils::MakeMaker;

my $dist = 'CGI::Builder::TT2';
my $vers = '0.03';

WriteMakefile(
    NAME      => $dist,
    VERSION   => $vers,
    ( $] ge '5.005' ) ? ( AUTHOR => 'Stefano Rodighiero',
                          ABSTRACT => 'CGI::Builder integration with TT2'
                        )
                      : (),
    PREREQ_PM => { 'CGI::Builder' => '1.12',
                   'Template'     => '2.0',
                   'Scalar::Util' => '0'
                 }
);

