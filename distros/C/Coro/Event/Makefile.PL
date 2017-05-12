use ExtUtils::MakeMaker;
use Event::MakeMaker;

use 5.005;

use Config;

$|=1;

WriteMakefile(Event::MakeMaker::event_args(
  NAME         => "Coro::Event",
  VERSION_FROM => "Event.pm",
  DEFINE       => $DEFINE,
  DIR          => [],
  PM           => {
                       'Event.pm'	=> '$(INST_LIBDIR)/Event.pm',
                  },
));



