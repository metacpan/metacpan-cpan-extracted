package Whatever::WH;
use strict;

use Moo;
with 'Bot::ChatBots::Role::Source';
with 'Bot::ChatBots::Role::WebHook';

sub class_custom_pairs {
   return wow => 'people';
}

sub normalize_record { return $_[1] }
sub parse_request { return $_[1]->json }

1;
