package mycache;

use threads;
use threads::shared;

our %cache : shared = (dummy=>'ok');

1;
