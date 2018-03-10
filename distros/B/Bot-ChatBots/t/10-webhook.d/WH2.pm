package WH2;
use strict;

use Moo;
with 'Bot::ChatBots::Role::WebHook';

# requires 'normalize_record' - AVOIDING ON PURPOSE FOR TRIGGERING ERROR
# sub normalize_record { }

# requires 'pack_source';
sub pack_source { }

1;
