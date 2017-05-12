use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	 => 'Authen::Ticket',
    VERSION_FROM => 'lib/Authen/Ticket.pm', # finds $VERSION
    PREREQ_PM    => { 
                      'Apache'            => "1.26",
                      'Apache::Constants' => "1.09",
                      'Apache::URI'       => "1.00",
                      'Apache::Util'      => "1.01",
                      'CGI'               => "2.46",
                      'CGI::Cookie'       => "1.06",
                      'MIME::Base64'      => "2.11",
                    },
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
