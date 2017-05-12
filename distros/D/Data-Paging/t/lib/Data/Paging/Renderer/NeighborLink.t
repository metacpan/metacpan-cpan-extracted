use strict;
use warnings;

use Test::More;
use Data::Paging::Collection;

BEGIN {
    use_ok "Data::Paging::Renderer::NeighborLink";
}

my $TRUE  = (1 == 1);
my $FALSE = (1 == 2);

subtest "new" => sub {
    my $renderer = Data::Paging::Renderer::NeighborLink->new;
    isa_ok $renderer, 'Data::Paging::Renderer::NeighborLink';
};

subtest "render" => sub {
    my $renderer = Data::Paging::Renderer::NeighborLink->new;
    my $collection = Data::Paging::Collection->new(
        entries      => [qw/a b c d e/],
        per_page     => 5,
        total_count  => 10,
        current_page => 1,
        base_url     => '/foo.pl'
    );

    is_deeply $renderer->render($collection), {
        entries      => [qw/a b c d e/],
        has_next     => $TRUE,
        has_prev     => $FALSE,
        next_page    => 2,
        current_page => 1,
        prev_page    => 0,
        begin_count  => 1,
        end_count    => 5,
        base_url     => '/foo.pl',
    };
};

done_testing;
