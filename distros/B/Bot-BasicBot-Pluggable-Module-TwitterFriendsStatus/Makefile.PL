use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bot::BasicBot::Pluggable::Module::TwitterFriendsStatus',
    VERSION_FROM      => 'lib/Bot/BasicBot/Pluggable/Module/TwitterFriendsStatus.pm',
    PREREQ_PM         => {
        'LWP::UserAgent'                   => 0,
        'XML::Simple'                      => 0,
        'Bot::BasicBot::Pluggable::Module' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
        ABSTRACT_FROM  => 'lib/Bot/BasicBot/Pluggable/Module/TwitterFriendsStatus.pm',
        AUTHOR         => join(', ',
            'Gryphon Shafer <gryphon@cpan.org>',
            'David Precious <davidp@preshweb.co.uk>',
        )
      ) : ()),

     # include the LICENSE param, as long as EU::MM is new enough to support it:
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => "perl") : () ),
);

