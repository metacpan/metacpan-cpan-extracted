use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# A grid nested in a grid cell. The inner grid's columns (groups 101/102)
# equalize to 50 + 50; that widens outer cell O00, which must then be
# equalized with O10 (outer group 1): both end up 100 wide, and the inner
# content stays inside its cell.
#
#   outer row 0: O00 = [ inner grid: I00(10) I01(50) / I10(50) I11(10) ]
#   outer row 1: O10 = [ filler 70 ]

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 400, height => 300 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    my $box = sub ($name, $decl, @children) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ backgroundColor => [20, 40, 60, 255], %$decl });
        $_->() for @children;
        Clay__CloseElement();
    };
    my $filler = sub ($name, $width) {
        return sub {
            $box->($name, { layout => { sizing => { width => sizing_fixed($width), height => sizing_fixed(10) } } });
        };
    };
    my $cell = sub ($name, $group, @children) {
        return sub { $box->($name, { sizingGroup => { width => $group } }, @children) };
    };
    my $row = sub ($name, @cells) {
        return sub { $box->($name, { layout => { layoutDirection => CLAY_LEFT_TO_RIGHT } }, @cells) };
    };

    Clay_BeginLayout();
    $box->('outer', { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } },
        $row->('orow0',
            $cell->('O00', 1,
                sub {
                    $box->('inner', { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } },
                        $row->('irow0', $cell->('I00', 101, $filler->('f00', 10)), $cell->('I01', 102, $filler->('f01', 50))),
                        $row->('irow1', $cell->('I10', 101, $filler->('f10', 50)), $cell->('I11', 102, $filler->('f11', 10))),
                    );
                },
            ),
        ),
        $row->('orow1', $cell->('O10', 1, $filler->('f2', 70))),
    );
    return Clay_EndLayout(0);
};
