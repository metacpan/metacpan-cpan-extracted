use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache2::S3',
    VERSION_FROM      => 'lib/Apache2/S3.pm', # finds $VERSION
    PREREQ_PM         => {
        'Apache2::Const'      => 0,
        'Apache2::RequestRec' => 0,
        'Apache2::Filter'     => 0,
        'Apache2::FilterRec'  => 0,
        'APR::Table'          => 0,
        'APR::String'         => 0,
        'MIME::Base64'        => 0,
        'Digest::SHA1'        => 0,
        'Digest::HMAC'        => 0,
        'URI::Escape'         => 0,
        'HTML::Entities'      => 0,
        'XML::Parser'         => 0,
        'Time::Local'         => 0,
        'POSIX'               => 0,
        'CGI'                 => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache2/S3.pm', # retrieve abstract from module
       AUTHOR         => 'Iain Wade <iwade@optusnet.com.au>') : ()),
);
