use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'AxKit::XSP::BasicSession',
    'VERSION_FROM' => 'lib/AxKit/XSP/BasicSession.pm',
    'PREREQ_PM'    => {
        AxKit                 => 1.6,
        Apache::Session::Flex => 0,
        Apache::AxKit::Language::XSP::TaglibHelper => 0,
        Date::Format          => 0,
        Apache::Cookie        => 0,
        Apache::AuthCookie    => 0,
        Digest::MD5           => 0,
    },
);
