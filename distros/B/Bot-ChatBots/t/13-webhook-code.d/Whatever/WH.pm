package Whatever::WH;
use strict;

use Moo;
with 'Bot::ChatBots::Role::WebHook';

sub BUILD_code { return 202 } # instead of default 204

sub normalize_record { return $_[1] }
sub parse_request { return $_[1]->json }

1;
