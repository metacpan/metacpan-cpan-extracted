use 5.016;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use App::AnteREPL;
use Encode qw(decode);

{
    package BoundedScreen;
    our @ISA = ('App::AnteREPL::Screen');
    sub key { shift @{ $_[0]{keys} } || 'EOF' }
    sub _cursor_time { exists $_[0]{clock} ? $_[0]{clock} : $_[0]->SUPER::_cursor_time }
}
sub screen {
    my ($w, $h) = @_;
    my $s = BoundedScreen->new;
    @{$s}{qw(width height)} = ($w, $h);
    return $s;
}
sub texts { [map { $_->{text} } @{ $_[0]{rows} }] }
sub bounded {
    my ($s, $label) = @_;
    cmp_ok scalar(@{$s->{rows}}), '<=', $s->{height}, "$label: rows fit";
    ok !grep(length($_->{text}) > $s->{width}, @{$s->{rows}}), "$label: columns fit";
    cmp_ok $s->{row}, '<', $s->{height}, "$label: cursor row fits";
    cmp_ok $s->{col}, '<', $s->{width}, "$label: cursor column fits";
    is_deeply [@{$s}{qw(top left)}], [0, 0], "$label: no hidden viewport";
}
sub fails (&) { my ($code) = @_; local $@; eval { $code->(); 1 }; return $@; }

my $s = screen(40, 4);
$s->append("row $_\n") for 1 .. 20;
is_deeply texts($s), ['row 18', 'row 19', 'row 20', ''], 'scrolling discards rows beyond the visible screen';
$s->edit_key('PAGEUP') for 1 .. 3;
is $s->{row}, 0, 'PageUp cannot reach discarded rows';
$s->edit_key('LEFT');
is_deeply [@{$s}{qw(row col)}], [0, 0], 'Left cannot leave the upper left corner';
ok !$s->{resize_bank}, 'ordinary scrolling does not create a recovery bank';
bounded($s, 'scroll');

$s = screen(10, 8);
my $code = 'say "a long wrapped line"';
$s->edit_key(['TEXT', $_]) for split //, $code;
is(($s->entry)[0], $code, 'soft wrapping preserves Perl source without inserting newlines');
bounded($s, 'typing across right edge');
$s->edit_key('TOP');
$s->edit_key(['TEXT', 'prefix']);
is(($s->entry)[0], 'prefix' . $code, 'insertion pushes characters into the next wrapped row');
bounded($s, 'insert into wrapped input');

$s = screen(10, 8);
$s->edit_key(['TEXT', 'abcdefghij']);
$s->edit_key('BACKSPACE');
is(($s->entry)[0], 'abcdefghi', 'Backspace crosses a soft wrap without deleting a source newline');

$s = screen(10, 8);
$s->append('abcdefghij');
$s->append('klm');
$s->append("\n");
is_deeply texts($s), ['abcdefghij', 'klm', ''], 'partial output writes wrap without losing or duplicating characters';
bounded($s, 'wrapped output');

my $r = App::AnteREPL->new;
$r->dispatch('5     say "a long listed line"');
$r->dispatch('100 say "other"');
$s = screen(12, 20);
$r->{screen} = $s;
$r->dispatch('LIST 5');
$s->edit_key('TOP');
is(($s->entry)[0], '5     say "a long listed line";', 'wrapped LIST preserves source indentation and removes only number padding');
my $source = $r->source;
$r->dispatch(($s->entry)[0]);
is $r->source, $source, 'wrapped listing can be resubmitted unchanged';

$s = screen(80, 12);
$s->append("row $_ : abcdefghijklmnopqrstuvwxyz\n") for 1 .. 7;
my $original = texts($s);
$s->resize(20, 6);
bounded($s, 'shrink both dimensions');
ok $s->{resize_bank}, 'shrinking saves an inactive screen copy';
like join('', @{texts($s)}), qr/Screen clipped; RECOVER/, 'shrinking prints a warning and recovery command';
is_deeply [map { $_->{text} } @{$s->{resize_bank}{rows}}], $original, 'bank preserves pre-shrink rows and columns';
my $small = texts($s);
like fails { $s->recover_display }, qr/at least 80x12/, 'RECOVER refuses a terminal that is still too small';
is_deeply texts($s), $small, 'failed recovery leaves active screen alone';
$s->resize(100, 18);
is_deeply texts($s), $small, 'growing adds space without restoring lost cells or printing a warning';
$s->edit_key('TOP');
isnt $s->{rows}[0]{text}, $original->[0], 'navigation cannot enter the inactive bank';
$s->recover_display;
is_deeply texts($s), $original, 'explicit RECOVER restores the complete saved screen';
ok !$s->{resize_bank}, 'successful recovery consumes the bank';
$s->fresh;
is_deeply texts($s), $original, 'session fresh step preserves the recovered screen';

$s->resize(40, 10);
my $bank = $s->{resize_bank};
$s->resize(30, 8);
is $s->{resize_bank}, $bank, 'repeated shrink events keep the first unclaimed bank';
$s->resize(100, 18);
$s->recover_display;
is_deeply texts($s), $original, 'resize drag does not replace the bank with already-clipped content';
$s->fresh;
$s->resize(20, 6);
$s->clear_display;
ok !$s->{resize_bank}, 'CLS forgets the inactive bank as well as the active display';
like fails { $s->recover_display }, qr/No saved screen/, 'RECOVER after CLS reports there is no copy';

$s = screen(80, 10);
$s->edit_key(['TEXT', 'say "this source is wider than the new window"']);
$s->resize(30, 10);
$s->edit_key('TOP');
like fails { $s->entry }, qr/entry was clipped/, 'cropped source cannot execute as a partial command';
$s->edit_key('CLEAR');
$s->edit_key(['TEXT', 'say 7']);
is(($s->entry)[0], 'say 7', 'clearing the damaged row allows a fresh complete command');

$s = screen(40, 3);
$s->edit_key(['PASTE', "EVAL do {\nsay 1;\nsay 2;\nsay 3;\n}"]);
bounded($s, 'oversized multiline paste');
like fails { $s->entry }, qr/entry was clipped/, 'a multiline entry that scrolls off screen is not submitted partially';

$s = screen(10, 8);
$s->append('Name: ');
$s->{keys} = [map({ ['TEXT', $_] } split //, 'abcdefghijklmnop'), 'ENTER'];
is $s->read_data, "abcdefghijklmnop\n", 'program input survives visible wrapping';
bounded($s, 'program input');
$s = screen(10, 8);
$s->append('Name: ');
$s->{keys} = [map({ ['TEXT', $_] } split //, 'abcd'), 'BACKSPACE', ['TEXT', 'Z'], 'ENTER'];
is $s->read_data, "abcZ\n", 'program input can backspace across a wrapped row without changing its prompt';
$s = screen(10, 2);
$s->append('Name: ');
$s->{keys} = [map({ ['TEXT', $_] } split //, 'a' x 30), 'ENTER'];
like fails { $s->read_data }, qr/Input was clipped/, 'program input larger than the screen is not silently truncated';

my $plain = App::AnteREPL->new;
like fails { $plain->dispatch('RECOVER') }, qr/requires screen mode/, 'RECOVER is explicit about plain-mode limits';
for my $bad ('RECOVER extra', 'RECOVER!') {
    like fails { $plain->dispatch($bad) }, qr/Usage|suffix/, "$bad is rejected";
}
{
    my $s = BoundedScreen->new;
    $s->terminal_size(80, 24);
    is_deeply [@{$s}{qw(width height)}], [78, 21], 'frame and legend leave 78x20 VRAM in an 80x24 terminal';
    $s->append("row $_\n") for 1 .. 30;
    bounded($s, 'framed scrolling');
    is_deeply texts($s), [map("row $_", 11 .. 30), ''], 'scrolling uses only the frame interior';
    $s->terminal_size(60, 18);
    is_deeply [@{$s}{qw(width height)}], [58, 15], 'resizing reserves the frame and legend again';
    like join('', @{texts($s)}), qr/RECOVER at 80x24/, 'recovery warning gives physical terminal dimensions';
    like fails { $s->recover_display }, qr/at least 80x24/, 'recovery error gives physical dimensions';
    $s->terminal_size(80, 24);
    $s->recover_display;
    is_deeply texts($s), [map("row $_", 11 .. 30), ''], 'framed recovery restores only VRAM rows';
    $s->clear_display;
    my $bytes = '';
    open my $out, '>:encoding(UTF-8)', \$bytes or die $!;
    $out->autoflush(1);
    $s->{out} = $out;
    $s->{clock} = 0;
    $s->{entered} = 1;
    $s->render;
    my $frame = decode('UTF-8', $bytes);
    like $frame, qr/\e\[97;40m\x{250c} VRAM /, 'frame requests white and draws the top border';
    like $frame, qr/\e\[2;1H\e\[2K\e\[97;40m\x{2502}/, 'first VRAM row is inside the border';
    like $frame, qr/\e\[23;1H.*\x{2514}/s, 'bottom border precedes legend';
    like $frame, qr/\e\[24;1H.*H\e\[27m Help/s, 'first legend row has highlighted command keys';
    like $frame, qr/\e\[24;1H.*Q\e\[27m Quit/s, 'second legend row shows quit';
    like $frame, qr/\e\[2;2H\e\[6 q\e\[\?25h\z/, 'cursor blinks inside the upper-left VRAM cell';
    is_deeply texts($s), [''], 'border and legend never enter editable rows';
    my $end = length $bytes;
    $s->{clock} = 0.6;
    $s->render;
    is substr($bytes, $end), "\e[?25l", 'idle blink hides cursor without repainting VRAM';
    $end = length $bytes;
    $s->{clock} = 1.1;
    $s->render;
    is substr($bytes, $end), "\e[?25h", 'idle blink shows cursor again without terminal blink support';
    $s->edit_key('INSERT');
    $s->render;
    like $bytes, qr/\e\[2 q\e\[\?25h\z/, 'overwrite mode requests a blinking block';
    $s->{entered} = 0;
    $s->terminal_size(18, 8);
    my @legend = $s->legend_lines;
    is scalar @legend, 1, 'legend occupies exactly one row';
    ok !grep(length($_) > 18, @legend), 'narrow legend stays within terminal columns';
    like $legend[0], qr/^H Help/, 'narrow legend keeps HELP';
    like $legend[0], qr/Q Quit/, 'narrow legend keeps QUIT';
    $s->terminal_size(2, 2);
    bounded($s, 'very small terminal');
    ok !$s->{framed}, 'very small terminal omits chrome instead of using invalid coordinates';
    for my $sizes ([80, 3, 80, 4], [2, 24, 3, 24]) {
        my $tiny = BoundedScreen->new;
        $tiny->terminal_size(@$sizes[0,1]);
        $tiny->edit_key(['TEXT', 'x']);
        my $before = texts($tiny);
        $tiny->terminal_size(@$sizes[2,3]);
        is_deeply texts($tiny), $before, 'growing a tiny terminal to show its frame retains VRAM';
        ok !$tiny->{resize_bank}, 'showing the frame on growth does not crop or warn';
    }
}
done_testing;
