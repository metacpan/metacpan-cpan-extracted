package App::financeta::editor;
use strict;
use warnings;
use 5.10.0;
use feature 'say';

our $VERSION = '0.10';
$VERSION = eval $VERSION;

use App::financeta::mo;
use Carp;
use File::ShareDir 'dist_file';
use POE 'Loop::Prima';
use Prima qw(Application Edit MsgBox);

$| = 1;
has debug => 0;
has parent => undef;
has main => (builder => '_build_main');
has icon => (builder => '_build_icon');
has brand => __PACKAGE__;
has tab_name => undef;

sub _build_icon {
    my $self = shift;
    my $icon_path = dist_file('App-financeta', 'icon.gif');
    my $icon = Prima::Icon->create;
    say "Icon path: $icon_path" if $self->debug;
    $icon->load($icon_path) or carp "Unable to load $icon_path";
    return $icon;
}

sub _build_main {
    my $self = shift;
    my $mw = new Prima::Window(
        name => 'editor',
        text => $self->brand,
        size => [640, 480],
        owner => $self->parent->main,
        centered => 1,
        # force border styles for consistency
        borderIcons => bi::All,
        borderStyle => bs::Sizeable,
        windowState => ws::Normal,
        icon => $self->icon,
        # origin
        left => 10,
        top => 0,
        visible => 0,
        menuItems => [[
            '~Action' => [
                [
                    'save_rules', '~Save', 'Ctrl+S', '^S',
                    sub {
                        my ($win, $item) = @_;
                        my $ed = $win->menu->data($item);
                        my $txt = $win->editor_edit->text;
                        $ed->parent->update_editor($txt, $ed->tab_name, 0);
                    },
                    $self,
                ],
                [
                    'close_window', '~Close', 'Ctrl+W', '^W',
                    sub {
                        my ($win, $item) = @_;
                        my $ed = $win->menu->data($item);
                        my $txt = $win->editor_edit->text;
                        $ed->parent->update_editor($txt, $ed->tab_name, 1);
                        $ed->parent->close_editor($ed->tab_name); # force it
                        $win->close;
                    },
                    $self,
                ],
            ],
        ]],
        onDestroy => sub {
            if ($self->parent and $self->tab_name) {
                $self->parent->close_editor($self->tab_name);
            }
        },
    );
    my @sz = $mw->size;
    $sz[0] *= 0.98;
    $sz[1] *= 0.98;
    $mw->insert(Edit => name => 'editor_edit',
        text => '#This line is auto-generated',
        pack => { expand => 1, fill => 'both' },
        syntaxHilite => 1,
        hScroll => 1,
        growMode => gm::Client | gm::GrowHiX | gm::GrowHiY,
        hiliteNumbers => cl::Green,
        hiliteQStrings => cl::Red,
        hiliteQQStrings => cl::Red,
        tabIndent => 4,
        size => \@sz,
        visible => 1,
    );
    return $mw;
}

sub update_editor {
    my ($self, $rules, $tabname) = @_;
    $self->tab_name($tabname) if defined $tabname;
    $self->main->editor_edit->text($rules);
    $self->main->show;
    $self->main->bring_to_front;
    1;
}

sub close {
    my $self = shift;
    #my $win = $self->main;
    #my $txt = $win->editor_edit->text;
    #$self->parent->update_editor($txt, $self->tab_name, 1);
    if ($self->parent) {
        $self->parent->close_editor($self->tab_name);
    }
    $self->main->close;
}

sub get_text {
    my $self = shift;
    return $self->main->editor_edit->text;
}

1;
__END__
### COPYRIGHT: 2014 Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 30th Aug 2014
### LICENSE: Refer LICENSE file
