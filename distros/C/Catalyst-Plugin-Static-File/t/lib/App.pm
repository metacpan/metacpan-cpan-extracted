package App;

use v5.14;
use warnings;

use Catalyst qw/ Static::File /;

use Test::Log::Dispatch; # suppress stderr log

use namespace::autoclean;

__PACKAGE__->log( Test::Log::Dispatch->new );

__PACKAGE__->setup();

1;
