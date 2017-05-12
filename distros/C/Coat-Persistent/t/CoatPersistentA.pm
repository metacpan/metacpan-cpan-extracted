package CoatPersistentA;
use Coat;
use Coat::Persistent table_name => 'table_a';
use Coat::Persistent::Meta;

has_p x => (isa => 'Num');

sub model_meta { Coat::Persistent::Meta->model($_[0]) }

1;
