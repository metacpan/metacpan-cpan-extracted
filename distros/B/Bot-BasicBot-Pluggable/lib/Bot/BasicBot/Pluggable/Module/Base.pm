package Bot::BasicBot::Pluggable::Module::Base;
$Bot::BasicBot::Pluggable::Module::Base::VERSION = '1.30';
use warnings;
use strict;
use base qw( Bot::BasicBot::Pluggable::Module );

BEGIN {
    warn
"* Please do not use Bot::BasicBot::Pluggable::Module::Base as base class of your module\n"
      . "* Its usage is deprecated and the module will be removed in a few releases\n";
}

1;

__END__
