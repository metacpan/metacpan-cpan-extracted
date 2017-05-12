use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'CGI::SSI',
    'VERSION_FROM' => 'SSI.pm', # finds $VERSION
    'PREREQ_PM'    => {
                         HTML::SimpleParse => 0,
                         File::Spec        => 0,
                         LWP::UserAgent    => 0,
                         HTTP::Response    => 0,
                         HTTP::Cookies     => 0,
                         URI               => 0,
                         Date::Format      => 0,
                      },
);
