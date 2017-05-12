use strict;
use warnings;

use Test::More;
use Data::Paging::Collection;

BEGIN {
    use_ok 'Data::Paging::Renderer::Base';
}

subtest 'new' => sub {
    my $renderer = Data::Paging::Renderer::Base->new;
    isa_ok $renderer, 'Data::Paging::Renderer::Base';
};

subtest 'render' => sub {
    my $renderer = Data::Paging::Renderer::Base->new;
    can_ok $renderer, 'render';
};

done_testing;
