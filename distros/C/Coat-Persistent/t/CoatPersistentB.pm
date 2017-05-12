package CoatPersistentB;
use Coat;
use Coat::Persistent table_name => 'table_b';

use Coat::Persistent::Meta;
use CoatPersistentA;

has_p x => (isa => 'Num');

sub model_meta { Coat::Persistent::Meta->model($_[0]) }

1;
