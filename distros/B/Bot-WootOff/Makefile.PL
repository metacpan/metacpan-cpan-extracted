######################################################################
# Makefile.PL for Bot::WootOff
# 2009, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/bot-wootoff',
        },
    }
};
WriteMakefile(
    'NAME'         => 'Bot::WootOff',
    'VERSION_FROM' => 'WootOff.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Log::Log4perl                => 1.0,
        Bot::BasicBot                => 0.81,
        HTTP::Request::Common        => 0,
        POE                          => 0.99,
        POE::Component::Client::HTTP => 0,
    },
    'EXE_FILES'     => ['eg/wootbot'],
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'WootOff.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
