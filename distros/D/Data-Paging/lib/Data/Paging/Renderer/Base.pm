package Data::Paging::Renderer::Base;
use common::sense;

use Class::Accessor::Lite (
    new => 1,
);

sub render {
    die 'implement me';
}

1;
