package App::financeta::gui::editor;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.15';
$VERSION = eval $VERSION;
use App::financeta::mo;
use App::financeta::utils qw(dumper log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use File::ShareDir 'dist_file';
if ($^O !~ /win32/i) {
    eval {
        require POE;
        require POE::Kernel;
        POE::Kernel->import({loop => 'Prima'});
        require POE::Session;
    } or die "Unable to load POE::Loop::Prima";
}
use Prima qw(Application Edit MsgBox sys::GUIException);
use Try::Tiny;
use App::financeta::language;

$| = 1;
has debug => 0;
has parent => undef;
has main => (builder => '_build_main');
has brand => __PACKAGE__;
has tab_name => undef;
has compiler => (default => sub {
    return App::financeta::language->new(debug => 0);
});

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
                        my $ed = $win->menu->options($item);
                        my $txt = $win->editor_edit->text;
                        $ed->parent->save_editor($txt, $ed->tab_name, 0);
                    },
                    $self,
                ],
                [
                    'close_rules', '~Close', 'Ctrl+W', '^W',
                    sub {
                        my ($win, $item) = @_;
                        my $ed = $win->menu->options($item);
                        my $txt = $win->editor_edit->text;
                        $ed->parent->save_editor($txt, $ed->tab_name, 1);
                        $ed->parent->close_editor($ed->tab_name); # force it
                        $win->close;
                    },
                    $self,
                ],
                [],
                [
                    'compile_rules', 'Compile', 'Ctrl+B', '^B',
                    sub {
                        my ($win, $item) = @_;
                        my $ed = $win->menu->options($item);
                        my $txt = $win->editor_edit->text;
                        $ed->parent->save_editor($txt, $ed->tab_name, 0);
                        my $output = $ed->compile($txt);
                        #TODO: do something with the output
                        message_box('Compiled Output', $output,
                            mb::Ok | mb::Information) if defined $output;
                    },
                    $self,
                ],
                [
                    'execute_rules', 'Execute', 'Ctrl+R', '^R',
                    sub {
                        my ($win, $item) = @_;
                        my $ed = $win->menu->options($item);
                        my $txt = $win->editor_edit->text;
                        $ed->parent->save_editor($txt, $ed->tab_name, 0);
                        $ed->execute($txt);
                    },
                    $self,
                ],
            ]], [
            '~Edit' => [
                [
                    'edit_cut', 'Cut', 'Ctrl+X', '^X',
                    sub { $_[0]->editor_edit->cut },
                ],
                [
                    'edit_copy', 'Copy', 'Ctrl+C', '^C',
                    sub { $_[0]->editor_edit->copy },
                ],
                [
                    'edit_paste', 'Paste', 'Ctrl+V', '^V',
                    sub { $_[0]->editor_edit->paste},
                ],
                [
                    'edit_del', 'Delete', 'Ctrl+Del', '',
                    sub { $_[0]->editor_edit->delete_block },
                ],
                [],
                [
                    'edit_undo', 'Undo', '', '',
                    sub { $_[0]->editor_edit->undo },
                ],
                [
                    'edit_redo', 'Redo', '', '',
                    sub { $_[0]->editor_edit->redo },
                ],
                [
                    'edit_select', 'Select All', 'Ctrl+A', '^A',
                    sub { $_[0]->editor_edit->select_all },
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
    my $ed = $mw->insert(Edit => name => 'editor_edit',
        text => '#This line is auto-generated',
        pack => { expand => 1, fill => 'both' },
        syntaxHilite => 1,
        hScroll => 1,
        growMode => gm::Client | gm::GrowHiX | gm::GrowHiY,
        hiliteNumbers => cl::Red,
        hiliteQStrings => cl::Red,
        hiliteQQStrings => cl::Red,
        #    hiliteIDs => [$keywords, cl::Green],
        tabIndent => 4,
        size => \@sz,
        visible => 1,
        # check these
        cursorWrap => 1,
        persistentBlock => 1,
        wantTabs => 1,
    );
    my $regexes = $self->compiler->get_grammar_regexes;
    my @arr = ();
    foreach my $k (keys %$regexes) {
        if (ref $regexes->{$k} eq 'ARRAY') {
            push @arr, '(?i:(' . join('|', @{$regexes->{$k}}) . '))';
        } else {
            push @arr, $regexes->{$k};
        }
        $k = ucfirst $k;
        my $color = eval "cl::$k" or cl::Black; # ignore error
        push @arr, $color;
    }
    my $hlres = $ed->hiliteREs;
    $ed->hiliteREs([@arr, @$hlres]);
    return $mw;
}

sub update_editor {
    my ($self, $rules, $tabname, $vars, $hidden) = @_;
    $self->tab_name($tabname) if defined $tabname;
    $self->compiler->preset_vars($vars) if defined $vars;
    $self->main->editor_edit->text($rules);
    unless ($hidden) {
        $self->main->show;
        $self->main->bring_to_front;
    }
    1;
}

sub close {
    my $self = shift;
    #my $win = $self->main;
    #my $txt = $win->editor_edit->text;
    #$self->parent->save_editor($txt, $self->tab_name, 1);
    if ($self->parent) {
        $self->parent->close_editor($self->tab_name);
    }
    $self->main->close;
}

sub get_text {
    my $self = shift;
    return $self->main->editor_edit->text;
}

sub compile {
    my ($self, $txt) = @_;
    my $output;
    try {
        $output = $self->compiler->compile($txt);
    } catch {
        my $err = $_;
        $log->error("Compiler error:\n$err");
        #TODO: create a better window
        message("Compiler Error\n$err");
    };
    return $output;
}

sub execute {
    my ($self, $txt) = @_;
    my $code = $self->compile($txt);
    return unless $code;
    try {
        my $coderef = $self->compiler->generate_coderef($code);
        if ($self->parent) {
            $log->info("Executing rules for tab name: ", $self->tab_name);
            $self->parent->execute_rules($self->tab_name, $coderef);
        }
    } catch {
        my $err = $_;
        $log->error("Error executing generated code:\n$err");
        $log->debug("Erroneous code: $code");
        #TODO: create a better window
        message("Error executing generated code:\n$err");
    };
}

1;
__END__
### COPYRIGHT: 2013-2023. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 30th Aug 2014
### LICENSE: Refer LICENSE file
