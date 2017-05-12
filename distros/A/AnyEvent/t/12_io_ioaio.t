BEGIN { eval q{use AnyEvent::IO::IOAIO;1} or ((print qq{1..0 # SKIP AnyEvent::IO::IOAIO not loadable\n}), exit 0) }
require "./t/io_common";
