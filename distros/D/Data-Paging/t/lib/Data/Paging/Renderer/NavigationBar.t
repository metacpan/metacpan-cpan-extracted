use strict;
use warnings;

use Test::More;
use Data::Paging::Collection;

BEGIN {
    use_ok "Data::Paging::Renderer::NavigationBar";
}

my $TRUE  = (1 == 1);
my $FALSE = (1 == 2);

subtest "new" => sub {
    my $renderer = Data::Paging::Renderer::NavigationBar->new;
    isa_ok $renderer, 'Data::Paging::Renderer::NavigationBar';
};

subtest "render" => sub {
    subtest 'render at las_page < window condition' => sub {
        my $renderer = Data::Paging::Renderer::NavigationBar->new;
        my $collection = Data::Paging::Collection->new(
            entries      => [qw/a b c d e/],
            per_page     => 5,
            total_count  => 10,
            current_page => 1,
            base_url     => '/home.pl',
            window       => 5,
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
            base_url     => '/home.pl',
            total_count  => 10,
            begin_navigation_page => 1,
            end_navigation_page   => 2,
            navigation            => [
                { page_number => 1 },
                { page_number => 2 },
            ],
        };
    };

    subtest 'render at las_page > window condition' => sub {
        my $renderer = Data::Paging::Renderer::NavigationBar->new;
        my $collection = Data::Paging::Collection->new(
            entries      => [qw/a b c d e/],
            per_page     => 5,
            total_count  => 50,
            current_page => 1,
            base_url     => '/home.pl',
            window       => 5,
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
            base_url     => '/home.pl',
            total_count  => 50,
            begin_navigation_page => 1,
            end_navigation_page   => 5,
            navigation            => [
                { page_number => 1 },
                { page_number => 2 },
                { page_number => 3 },
                { page_number => 4 },
                { page_number => 5 },
            ],
        };
    };
};

done_testing;
