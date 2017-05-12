package WH2;
use strict;

use Moo;
with 'Bot::ChatBots::Role::WebHook';

# requires 'normalize_record';
sub normalize_record { }

# requires 'pack_source';
sub pack_source { }

# requires 'parse_request' - AVOIDING ON PURPOSE FOR TRIGGERING ERROR
#sub parse_request { }

1;
