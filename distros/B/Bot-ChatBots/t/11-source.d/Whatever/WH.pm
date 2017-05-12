package Whatever::WH;
use strict;

use Moo;
with 'Bot::ChatBots::Role::Source';

sub normalize_record { return $_[1] }

sub class_custom_pairs {
   return (wow => 'people', this => 'goes');
}

1;
