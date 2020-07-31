package App;

use Catalyst qw/ DetachIfNotModified /;

use Term::Size::Any qw();
use Test::Log::Dispatch;  # suppress stderr log

use namespace::autoclean;

__PACKAGE__->log( Test::Log::Dispatch->new );

__PACKAGE__->setup();

1;
