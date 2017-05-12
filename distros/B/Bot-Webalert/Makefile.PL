######################################################################
# Makefile.PL for Bot::Webalert
# 2008, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Bot::Webalert',
    'VERSION_FROM' => 'Webalert.pm', # finds $VERSION
    'PREREQ_PM'    => {
        HTTP::Request::Common => 5,
        Bot::BasicBot                => 0.81,
        Log::Log4perl                => 1,
        POE                          => 1.003,
        POE::Component::Client::HTTP => 0.85,
        HTTP::Cookies                => 5,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Webalert.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
