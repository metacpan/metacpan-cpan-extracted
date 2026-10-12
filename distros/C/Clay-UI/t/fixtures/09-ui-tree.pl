use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib 't/lib';

use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Test::Box;
use Clay::UI::Test::Grid;
use Clay::UI::Test::Text;

# A small tree built through Clay::UI: a padded page Box holding a title
# Text and a 2x2 Grid whose cells mix Text leaves and an anonymous Box.
# Locks down the walker's output: anonymous element ids, the contributor
# slices of Box, Grid and Text, and the Grid's equalized columns and rows.
# userData (a refaddr) is replaced by the originating widget's class and
# id so the output is stable across runs.

sub {
    my $page = Clay::UI::Test::Box->new(
        id               => 'page',
        layout           => { layout_direction => CLAY_TOP_TO_BOTTOM, padding => padding_all(8), child_gap => 4 },
        background_color => [240, 240, 240, 255],
    );
    my $grid = Clay::UI::Test::Grid->new(
        id               => 'table',
        row_gap          => 2,
        cell_gap         => 3,
        background_color => [200, 210, 220, 255],
    );
    $grid->append_row([
        Clay::UI::Test::Text->new(text => 'name', font_size => 10),
        Clay::UI::Test::Text->new(text => 'value', font_size => 10),
    ]);
    $grid->append_row([
        Clay::UI::Test::Box->new(
            layout           => { sizing => { width => sizing_fixed(30), height => sizing_fixed(12) } },
            background_color => [10, 20, 30, 255],
        ),
        Clay::UI::Test::Text->new(text => '42', font_size => 16),
    ]);
    $page->add_child(Clay::UI::Test::Text->new(text => 'Report', font_size => 12), $grid);

    my $ui = Clay::UI->new(width => 300, height => 200, root => $page);
    my $commands = $ui->render;
    for my $command (@$commands) {
        my $widget = $ui->widget_for($command->{userData});
        my $name   = defined $widget && $widget->can('id') ? $widget->id : undef;
        $command->{userData} = defined $widget ? ref($widget) . '/' . ($name // 'anonymous') : 0;
    }
    return $commands;
};
