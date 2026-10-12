use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# Grid rows sized sizing_grow() inside a FIT table. Equalizing the column
# groups (A/C in group 1, B/D in group 2) widens GROW rows exactly like FIT
# rows: the table becomes 200 wide and no cell overflows its row.
#
#   row 0: A(50)  B(100)
#   row 1: C(100) D(50)

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 400, height => 300 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    my $box = sub ($name, $decl, @children) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ backgroundColor => [60, 40, 20, 255], %$decl });
        $_->() for @children;
        Clay__CloseElement();
    };
    my $cell = sub ($name, $group, $width) {
        return sub {
            $box->($name, { sizingGroup => { width => $group } }, sub {
                $box->("$name-filler", { layout => { sizing => { width => sizing_fixed($width), height => sizing_fixed(10) } } });
            });
        };
    };
    my $row = sub ($name, @cells) {
        return sub { $box->($name, { layout => { sizing => { width => sizing_grow() } } }, @cells) };
    };

    Clay_BeginLayout();
    $box->('table', { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } },
        $row->('row0', $cell->('A', 1, 50),  $cell->('B', 2, 100)),
        $row->('row1', $cell->('C', 1, 100), $cell->('D', 2, 50)),
    );
    return Clay_EndLayout(0);
};
