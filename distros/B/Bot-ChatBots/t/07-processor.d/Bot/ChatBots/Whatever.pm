package Bot::ChatBots::Whatever;
use Moo;
with 'Bot::ChatBots::Role::Processor';

sub process {
   my ($self, $record) = @_;
   $record->{foo} = 'bar';
   return $record;
}

1;
