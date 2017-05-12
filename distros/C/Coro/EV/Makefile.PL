use ExtUtils::MakeMaker;
use EV::MakeMaker;

use 5.008;

use Config;

$|=1;

WriteMakefile(EV::MakeMaker::ev_args(
  NAME         => "Coro::EV",
  VERSION_FROM => "EV.pm",
  DEFINE       => $DEFINE,
  DIR          => [],
  PM           => {
                       'EV.pm'	=> '$(INST_LIBDIR)/EV.pm',
                  },
));



