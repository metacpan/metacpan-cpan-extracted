package App::financeta::gui;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.11';
$VERSION = eval $VERSION;

use App::financeta::mo;
use App::financeta::utils qw(dumper log_filter get_icon_path);
use Carp ();
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use Try::Tiny;
use File::Spec;
use File::HomeDir;
use File::Path ();
use DateTime;
if ($^O !~ /win32/i) {
    eval {
        require POE;
        require POE::Kernel;
        POE::Kernel->import({loop => 'Prima'});
        require POE::Session;
    } or die "Unable to load POE::Loop::Prima";
}
use Prima qw(
    Application Buttons MsgBox Calendar ComboBox Notebooks
    Widget::ScrollWidget DetailedList Dialog::ColorDialog
    Dialog::FileDialog Dialog::FindDialog ScrollBar
    Dialog::PrintDialog Dialog::ImageDialog Dialog::FontDialog
);
use Prima::Utils ();
use Capture::Tiny ();
use Finance::QuoteHist;
use PDL::Lite;
use PDL::IO::Misc;
use PDL::NiceSlice;
use PDL::Graphics::Gnuplot;
use App::financeta::indicators;
use App::financeta::editor;
use Scalar::Util qw(blessed);
use Browser::Open ();
use YAML::Any ();

$PDL::doubleformat = "%0.6lf";
$| = 1;
has debug => 0;
has timezone => 'America/New_York';
has brand => __PACKAGE__;
has main => (builder => '_build_main');
has tmpdir => ( default => sub {
    return $ENV{TEMP} || $ENV{TMP} if $^O =~ /Win32|Cygwin/i;
    return $ENV{TMPDIR} || '/tmp';
});
has datadir => ( default => sub {
    my $dir = $ENV{DATADIR} || File::Spec->catfile(File::HomeDir->my_home, '.financeta');
    File::Path::make_path($dir) unless -d $dir;
    return $dir;
});
has plot_engine => 'gnuplot';
has current => {};
has indicator => (builder => '_build_indicator');
has tab_was_closed => 0;
has editors => {};
has tradereports => {};

sub _build_indicator {
    my $self = shift;
    return App::financeta::indicators->new(debug => $self->debug,
                                            plot_engine => $self->plot_engine);
}

sub _build_editor {
    my $self = shift;
    my $name = shift || '';
    $name =~ s/tab_//g if length $name;
    return App::financeta::editor->new(debug => $self->debug,
        parent => $self, brand => $self->brand . " Rules Editor for $name");
}

sub _build_tradereport {
    my $self = shift;
    my $name = shift || '';
    $name =~ s/tab_//g if length $name;
    return App::financeta::tradereport->new(debug => $self->debug,
        parent => $self, brand => $self->brand . " Trade Report for $name");
}

sub icon {
    my $icon_path = get_icon_path(__PACKAGE__);
    return (defined $icon_path) ? Prima::Icon->load($icon_path) : undef;
}

sub _build_main {
    my $self = shift;
    my $mw = Prima::MainWindow->new(
        name => 'main',
        text => $self->brand,
        size => [800, 600],
        centered => 1,
        menuItems => $self->_menu_items,
        # force border styles for consistency
        borderIcons => bi::All,
        borderStyle => bs::Sizeable,
        windowState => ws::Normal,
        icon => $self->icon,
        #ownerIcon => 0,
        # origin
        left => 10,
        top => 0,
    );
    $mw->maximize;
    $log->debug("Creating main window");
    return $mw;
}

sub _menu_items {
    my $self = shift;
    $log->debug("Creating menu items");
    my $help_menu = [
        '~Help' => [
            [
                'help_viewer', 'Documentation', 'F1', kb::F1,
                sub {
                    my $url = 'https://vikasnkumar.github.io/financeta/';
                    $log->info("Opening $url in your default browser.");
                    my $ok = Browser::Open::open_browser($url, 1);
                    if (not defined $ok) {
                        message("Error finding a browser to open $url");
                        $log->warn("Error finding a default browser to open $url");
                    } elsif ($ok != 0) {
                        message("Error opening $url");
                        $log->warn("Error opening $url in default browser");
                    }
                }, $self,
            ],
        ],
    ];
    my $security_menu = [
        '~Security' => [
            [
                'security_new', '~New', 'Ctrl+N', '^N',
                sub {
                    my ($win, $item) = @_;
                    ## as of Prima 1.58 .data was renamed to .options
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    if ($gui->security_wizard($win)) {
                        my $bar = $gui->progress_bar_create($win, 'Downloading...');
                        # download security data
                        my ($data, $symbol, $csv) = $gui->download_data($bar);
                        if (defined $data) {
                            $gui->display_data($win, $data);
                            my ($info, $tname) = $gui->get_tab_info($win);
                            if ($info and $csv) {
                                $info->{csv} = $csv;
                                $gui->set_tab_info($win, $info);
                            }
                            my $type = $gui->current->{plot_type} || 'OHLC';
                            $gui->plot_data($win, $data, $symbol, $type);
                            $gui->enable_menu_options($win);
                        }
                        $gui->progress_bar_close($bar);
                    }
                },
                $self,
            ],
            [
                'security_open', '~Open', 'Ctrl+O', '^O',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    $gui->load_new_tab($win);
                },
                $self,
            ],
            [
                '-security_save', '~Save', 'Ctrl+S', '^S',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    $gui->save_current_tab($win, 0);
                },
                $self,
            ],
            [
                '-security_saveas', 'Save As', '', '',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    $gui->save_current_tab($win, 1);
                },
                $self,
            ],
            [
                '-security_close', '~Close', 'Ctrl+W', '^W',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    $gui->close_current_tab($win);
                },
                $self,
            ],
            [
                'app_exit', 'E~xit', 'Ctrl+Q', '^Q',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    $gui->close_all($win);
                },
                $self,
            ],
        ],
    ];
    my $plot_menu = [
            '~Plot' => [
                [
                    '-*plot_ohlc', 'OHLC', '', '',
                    sub {
                        my ($win, $item) = @_;
                        my $gui = $win->menu->options($item);
                        unless (ref $gui eq __PACKAGE__) {
                            $log->error("Invalid gui object passed to menu item $item");
                            return;
                        }
                        my ($data, $symbol, $indicators, $h, $bs) = $gui->get_tab_data($win);
                        $gui->plot_data($win, $data, $symbol, 'OHLC', $indicators, $bs);
                        $win->menu->check('plot_ohlc');
                        $win->menu->uncheck('plot_ohlcv');
                        $win->menu->uncheck('plot_close');
                        $win->menu->uncheck('plot_closev');
                        $win->menu->uncheck('plot_cdl');
                        $win->menu->uncheck('plot_cdlv');
                    },
                    $self,
                ],
                [
                    '-plot_ohlcv', 'OHLC & Volume', '', '',
                    sub {
                        my ($win, $item) = @_;
                        my $gui = $win->menu->options($item);
                        unless (ref $gui eq __PACKAGE__) {
                            $log->error("Invalid gui object passed to menu item $item");
                            return;
                        }
                        my ($data, $symbol, $indicators, $h, $bs) = $gui->get_tab_data($win);
                        $gui->plot_data($win, $data, $symbol, 'OHLCV', $indicators, $bs);
                        $win->menu->check('plot_ohlcv');
                        $win->menu->uncheck('plot_ohlc');
                        $win->menu->uncheck('plot_close');
                        $win->menu->uncheck('plot_closev');
                        $win->menu->uncheck('plot_cdl');
                        $win->menu->uncheck('plot_cdlv');
                    },
                    $self,
                ],
                [
                    '-plot_close', 'Close Price', '', '',
                    sub {
                        my ($win, $item) = @_;
                        my $gui = $win->menu->options($item);
                        unless (ref $gui eq __PACKAGE__) {
                            $log->error("Invalid gui object passed to menu item $item");
                            return;
                        }
                        my ($data, $symbol, $indicators, $h, $bs) = $gui->get_tab_data($win);
                        $gui->plot_data($win, $data, $symbol, 'CLOSE', $indicators, $bs);
                        $win->menu->check('plot_close');
                        $win->menu->uncheck('plot_ohlc');
                        $win->menu->uncheck('plot_ohlcv');
                        $win->menu->uncheck('plot_closev');
                        $win->menu->uncheck('plot_cdl');
                        $win->menu->uncheck('plot_cdlv');
                    },
                    $self,
                ],
                [
                    '-plot_closev', 'Close Price & Volume', '', '',
                    sub {
                        my ($win, $item) = @_;
                        my $gui = $win->menu->options($item);
                        unless (ref $gui eq __PACKAGE__) {
                            $log->error("Invalid gui object passed to menu item $item");
                            return;
                        }
                        my ($data, $symbol, $indicators, $h, $bs) = $gui->get_tab_data($win);
                        $gui->plot_data($win, $data, $symbol, 'CLOSEV', $indicators, $bs);
                        $win->menu->check('plot_closev');
                        $win->menu->uncheck('plot_ohlc');
                        $win->menu->uncheck('plot_ohlcv');
                        $win->menu->uncheck('plot_close');
                        $win->menu->uncheck('plot_cdl');
                        $win->menu->uncheck('plot_cdlv');
                    },
                    $self,
                ],
                [
                    '-plot_cdl', 'Candlesticks', '', '',
                    sub {
                        my ($win, $item) = @_;
                        my $gui = $win->menu->options($item);
                        unless (ref $gui eq __PACKAGE__) {
                            $log->error("Invalid gui object passed to menu item $item");
                            return;
                        }
                        my ($data, $symbol, $indicators, $h, $bs) = $gui->get_tab_data($win);
                        $gui->plot_data($win, $data, $symbol, 'CANDLE', $indicators, $bs);
                        $win->menu->check('plot_cdl');
                        $win->menu->uncheck('plot_ohlc');
                        $win->menu->uncheck('plot_ohlcv');
                        $win->menu->uncheck('plot_close');
                        $win->menu->uncheck('plot_closev');
                        $win->menu->uncheck('plot_cdlv');
                    },
                    $self,
                ],
                [
                    '-plot_cdlv', 'Candlesticks & Volume', '', '',
                    sub {
                        my ($win, $item) = @_;
                        my $gui = $win->menu->options($item);
                        unless (ref $gui eq __PACKAGE__) {
                            $log->error("Invalid gui object passed to menu item $item");
                            return;
                        }
                        my ($data, $symbol, $indicators, $h, $bs) = $gui->get_tab_data($win);
                        $gui->plot_data($win, $data, $symbol, 'CANDLEV', $indicators, $bs);
                        $win->menu->check('plot_cdlv');
                        $win->menu->uncheck('plot_ohlc');
                        $win->menu->uncheck('plot_ohlcv');
                        $win->menu->uncheck('plot_close');
                        $win->menu->uncheck('plot_closev');
                        $win->menu->uncheck('plot_cdl');
                    },
                    $self,
                ],
            ],
        ];
    my $analysis_menu = [
        '~Analysis' => [
            [
                '-add_indicator', 'Add Indicator', 'Ctrl+I', '^I',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    my ($data, $symbol, $indicators) = $gui->get_tab_data($win);
                    # ok add an indicator which also plots it
                    if ($gui->add_indicator($win, $data, $symbol)) {
                        $win->menu->remove_indicator->enabled(1);
                    }
                },
                $self,
            ],
            [
                '-remove_indicator', 'Remove Indicator', 'Ctrl+Shift+I', '^#I',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    # ok remove the indicator and update the plots and
                    # display tables
                    $gui->remove_indicator($win);
                },
                $self,
            ],
            [
                '-edit_rules', '~Edit Rules', 'Ctrl+E', '^E',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    my ($info, $tabname) = $self->get_tab_info($win);
                    $self->open_editor($win, $info->{rules}, $tabname);
                },
                $self,
            ],
            [
                '-execute_rules', 'Execute ~Rules', 'Ctrl+R', '^R',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    my ($info, $tabname) = $self->get_tab_info($win);
                    $self->execute_rules_no_editor($win, $tabname, $info->{rules});
                    $win->menu->trade_report->enabled(1);
                },
                $self,
            ],
            [
                '-trade_report', 'Trade Report', '', '',
                sub {
                    my ($win, $item) = @_;
                    my $gui = $win->menu->options($item);
                    unless (ref $gui eq __PACKAGE__) {
                        $log->error("Invalid gui object passed to menu item $item");
                        return;
                    }
                    my ($info, $tabname) = $self->get_tab_info($win);
                    my $buysells = $self->get_tab_buysells_for_name($win, $tabname);
                    $self->open_tradereport($win, $tabname, $buysells);
                },
                $self,
            ],
        ],
    ];
    return [ $security_menu, $plot_menu, $analysis_menu, $help_menu ];
}

sub close_all {
    my ($self, $win) = @_;
    my $pwin = $win->{plot};
    $pwin->close if $pwin;
    $log->info("Closing all open windows");
    $win->close if $win;
    $::application->close;
}

sub run {
    my $self = shift;
    $self->main->show;
    $self->disable_menu_options; # to be safe
    my $stack_sub = sub {
        Carp::confess();
    };
    local $SIG{__DIE__} = $stack_sub;
    local $SIG{SEGV} = $stack_sub;
    run Prima;
}

sub progress_bar_create {
    my ($self, $win, $text) = @_;
    $text = $text || 'Loading...';
    my $bar = Prima::Window->create(
        name => 'progress_bar',
        text => $text,
        size => [160, 100],
        origin => [0, 0],
        widgetClass => wc::Dialog,
        borderStyle => bs::Dialog,
        borderIcons => 0,
        centered => 1,
        owner => $win,
        visible => 1,
        pointerType => cr::Wait,
        onPaint => sub {
            my ($w, $canvas) = @_;
            $canvas->color(cl::Blue);
            $canvas->bar(0, 0, $w->{-progress}, $w->height);
            $canvas->color(cl::Back);
            $canvas->bar($w->{-progress}, 0, $w->size);
            $canvas->color(cl::Yellow);
            $canvas->font(size => 16, style => fs::Bold);
            $canvas->text_out($w->text, 0, 10);
        },
        syncPaint => 1,
        onTop => 1,
    );
    $bar->{-progress} = 0;
    $bar->repaint;
    $win->pointerType(cr::Wait);
    $win->repaint;
    return $bar;
}

sub progress_bar_update {
    my ($self, $bar) = @_;
    if ($bar and defined $bar->{-progress}) {
        $bar->{-progress} += 5;
        $bar->repaint;
    }
}

sub progress_bar_close {
    my ($self, $bar) = @_;
    if ($bar) {
        $bar->owner->pointerType(cr::Default);
        $bar->close;
    }
}

sub security_wizard {
    my ($self, $win) = @_;
    my $w = Prima::Dialog->new(
        name => 'sec_wizard',
        centered => 1,
        origin => [200, 200],
        size => [640, 480],
        text => 'Security Wizard',
        icon => $self->icon,
        visible => 1,
        taskListed => 0,
        onExecute => sub {
            my $dlg = shift;
            my $sec = $self->current->{symbol} || '';
            $dlg->input_symbol->text($sec);
            $dlg->btn_ok->enabled(length($sec) ? 1 : 0);
            $dlg->btn_cancel->enabled(1);
            if ($self->current->{start_date}) {
                my $dt = $self->current->{start_date};
                $dlg->cal_start->date($dt->day, $dt->month - 1, $dt->year - 1900);
            } else {
                $dlg->cal_start->date_from_time(gmtime);
                # reduce 1 year
                my $yr = $dlg->cal_start->year;
                $dlg->cal_start->year($yr - 1);
            }
            if ($self->current->{end_date}) {
                my $dt = $self->current->{end_date};
                $dlg->cal_end->date($dt->day, $dt->month - 1, $dt->year - 1900);
            } else {
                $dlg->cal_end->date_from_time(gmtime);
            }
            $dlg->chk_force_download->checked(0);
            $self->current->{force_download} = 0;
        },
    );
    $w->owner($win) if defined $win;
    $w->insert(
        Label => text => 'Enter Security Symbol',
        name => 'label_symbol',
        alignment => ta::Left,
        autoHeight => 1,
        origin => [ 20, 440],
        autoWidth => 1,
        font => { height => 14, style => fs::Bold },
        hint => 'Stock symbols are available at Yahoo! Finance',
    );
    $w->insert(
        InputLine => name => 'input_symbol',
        alignment => ta::Left,
        autoHeight => 1,
        width => 100,
        autoTab => 1,
        maxLen => 10,
        origin => [ 200, 440],
        font => { height => 16 },
        onChange => sub {
            my $inp = shift;
            my $owner = $inp->owner;
            unless (length $inp->text) {
                $owner->btn_ok->enabled(0);
            } else {
                $owner->btn_ok->enabled(1);
            }
        },
    );
    $w->insert(
        Button => name => 'btn_help',
        text => 'Symbol Search',
        height => 20,
        autoWidth => 1,
        origin => [340, 440],
        default => 0,
        enabled => 1,
        font => { height => 12, style => fs::Bold },
        onClick => sub {
            my $url = 'http://finance.yahoo.com';
            my $ok = Browser::Open::open_browser($url, 1);
            if (not defined $ok) {
                message("Error finding a browser to open $url");
            } elsif ($ok != 0) {
                message("Error opening $url");
            }
        },
    );
    $w->insert(
        Label => text => 'Select Start Date',
        name => 'label_enddate',
        alignment => ta::Center,
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, 410 ],
        font => { height => 14, style => fs::Bold },
    );
    $w->insert(
        Calendar => name => 'cal_start',
        useLocale => 1,
        size => [ 220, 200 ],
        origin => [ 20, 200 ],
        font => { height => 16 },
        onChange => sub {
            my $cal = shift;
            $self->current->{start_date} = DateTime->new(
                year => 1900 + $cal->year(),
                month => 1 + $cal->month(),
                day => $cal->day(),
                time_zone => $self->timezone,
            );
        },
    );
    $w->insert(
        Label => text => 'Select End Date',
        name => 'label_enddate',
        alignment => ta::Center,
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 260, 410 ],
        font => { height => 14, style => fs::Bold },
    );
    $w->insert(
        Calendar => name => 'cal_end',
        useLocale => 1,
        size => [ 220, 200 ],
        origin => [ 260, 200 ],
        font => { height => 16 },
        onChange => sub {
            my $cal = shift;
            $self->current->{end_date} = DateTime->new(
                year => 1900 + $cal->year(),
                month => 1 + $cal->month(),
                day => $cal->day(),
                time_zone => $self->timezone,
            );
        },
    );
    $w->insert(
        CheckBox => name => 'chk_force_download',
        text => 'Force Download',
        origin => [ 20, 170 ],
        font => { height => 14, style => fs::Bold },
        onCheck => sub {
            my $chk = shift;
            my $owner = $chk->owner;
            if ($chk->checked) {
                $self->current->{force_download} = 1;
            } else {
                $self->current->{force_download} = 0;
            }
        },
    );
    $w->insert(
        Button => name => 'btn_csv',
        text => 'Load from CSV',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, 120 ],
        default => 0,
        enabled => 1,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            my $btn = shift;
            my $owner = $btn->owner;
            $owner->hide;
            my $dlg = Prima::Dialog::OpenDialog->new(
                filter => [
                    ['CSV files' => '*.csv'],
                    ['All files' => '*'],
                ],
                filterIndex => 0,
                fileMustExist => 1,
                multiSelect => 0,
                directory => $self->tmpdir,
            );
            my $csv = $dlg->fileName if $dlg->execute;
            if (defined $csv and -e $csv) {
                $log->info("You have selected $csv to load");
                $owner->label_csv->text($csv);
                $self->current->{csv} = $csv;
            }
            $owner->show;
        },
    );
    $w->insert(
        Label => text => '',
        name => 'label_csv',
        alignment => ta::Left,
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, 90 ],
        font => { height => 13, style => fs::Bold },
    );
    $w->insert(
        Button => name => 'btn_cancel',
        text => 'Cancel',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, 40 ],
        modalResult => mb::Cancel,
        default => 0,
        enabled => 1,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            delete $self->current->{symbol};
            delete $self->current->{start_date};
            delete $self->current->{end_date};
            delete $self->current->{force_download};
            delete $self->current->{csv};
        },
    );
    $w->insert(
        Button => name => 'btn_ok',
        text => 'OK',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 150, 40 ],
        modalResult => mb::Ok,
        default => 1,
        enabled => 0,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            my $btn = shift;
            my $owner = $btn->owner;
            $self->current->{symbol} = $owner->input_symbol->text;
            unless (defined $self->current->{start_date}) {
                my $cal = $owner->cal_start;
                $self->current->{start_date} = DateTime->new(
                    year => 1900 + $cal->year(),
                    month => 1 + $cal->month(),
                    day => $cal->day(),
                    time_zone => $self->timezone,
                );
            }
            unless (defined $self->current->{end_date}) {
                my $cal = $owner->cal_end;
                $self->current->{end_date} = DateTime->new(
                    year => 1900 + $cal->year(),
                    month => 1 + $cal->month(),
                    day => $cal->day(),
                    time_zone => $self->timezone,
                );
            }
        },
    );
    my $res = $w->execute();
    $w->end_modal;
    return $res == mb::Ok;
}

sub remove_indicator($) {
    my ($self, $win) = @_;
    my $result = $self->remove_indicator_wizard($win);
    if ($result and ref $result eq 'HASH') {
        $log->debug("Removing indicator: ", dumper($result));
        # we know here the name of the indicator, the index of the indicator and
        # the columns in the data to remove.
        # let's do that.
        my ($data, $symbol, $indicators, $headers) = $self->get_tab_data_by_name($win, $result->{tab});
        return unless $headers;
        my $total_cols = $data->dim(1);
        my @ncols = (0 .. $total_cols - 1); # get a list of column numbers
        my @nhdrs = (@$headers);
        return unless $result->{columns};
        my @cols2rem = @{$result->{columns}};
        foreach my $c (@cols2rem) {
            $ncols[$c] = undef;
            $nhdrs[$c] = undef;
        }
        @nhdrs = grep { defined $_ } @nhdrs;
        @ncols = grep { defined $_ } @ncols;
        $log->debug("New Headers: ", dumper(\@nhdrs));
        $log->debug("Remaining columns: ", dumper(\@ncols));
        my $ndata = $data->dice('X', \@ncols);
        my $nindics = [];
        if ($indicators) {
            my $index = $result->{indicator_index};
            for (0 .. scalar(@$indicators) - 1) {
                next if $_ == $index;
                push @$nindics, $indicators->[$_];
            }
        }
        if ($self->set_tab_data_by_name($win, $result->{tab}, $ndata, $symbol, $nindics, \@nhdrs)) {
            $log->debug("Successfully set data");
            $self->display_data($win, $ndata, $symbol);
            my ($adata, $asymbol, $aindicators, $ahdr, $abysl) = $self->get_tab_data($win);
            my $type = $self->current->{plot_type} || 'OHLC';
            $self->plot_data($win, $adata, $asymbol, $type, $aindicators, $abysl);
            # disable remove indicator if there are no indicators left
            unless (scalar @$aindicators) {
                #$self->main->menu->remove_indicator->enabled(0);
            }
        }
    }
}

sub remove_indicator_wizard {
    my ($self, $win) = @_;
    my $w = Prima::Dialog->new(
        name => 'rem_ind_wizard',
        centered => 1,
        origin => [200, 200],
        size => [640, 280],
        text => 'Remove Indicator Wizard',
        icon => $self->icon,
        visible => 1,
        taskListed => 0,
        onExecute => sub {
            my $dlg = shift;
            $dlg->cbox_tabs->List->focusedItem(-1);
            $dlg->cbox_inds->List->focusedItem(-1);
            $dlg->btn_cancel->enabled(1);
            $dlg->btn_ok->enabled(0);
        },
    );
    $w->owner($win) if defined $win;
    my %tabs = $self->get_tab_names($win);
    $log->debug("Current tabs: ", dumper(\%tabs));
    my $result = {};
    $w->insert(Label => name => 'label_tabs',
        text => 'Select Security',
        font => { style => fs::Bold, height => 16 },
        alignment => ta::Left,
        autoHeight => 1,
        autoWidth => 1,
        origin => [20, 240],
        hint => 'This is a list of already open tabs',
        hintVisible => 1,
    );
    $w->insert(ComboBox =>
        name => 'cbox_tabs',
        style => cs::DropDownList,
        height => 30,
        width => 360,
        hScroll => 0,
        multiSelect => 0,
        multiColumn => 0,
        dragable => 0,
        focusedItem => -1,
        font => { height => 14 },
        items => ['', keys %tabs],
        origin => [180, 240],
        onChange => sub {
            my $cbox = shift;
            my $owner = $cbox->owner;
            my $lbox = $cbox->List;
            my $index = $lbox->focusedItem;
            my $txt = $lbox->get_item_text($index);
            if (defined $txt and length $txt) {
                my $indicators = $self->get_tab_indicators($owner->owner, $txt);
                my @inds = ();
                if ($indicators) {
                    foreach (@$indicators) {
                        push @inds, $_->{indicator}->{func};
                    }
                }
                $log->debug("Current indicators for tab $txt: ", dumper(\@inds));
                if (scalar @inds) {
                    $owner->cbox_inds->items(\@inds);
                    $owner->btn_ok->enabled(1);
                } else {
                    $owner->cbox_inds->items([]);
                    $owner->btn_ok->enabled(0);
                }
                $result->{tab} = $txt;
            } else {
                $owner->cbox_inds->items([]);
                $owner->cbox_inds->focusedItem(-1);
                $owner->cbox_inds->text('');
                $owner->btn_ok->enabled(0);
                delete $result->{tab};
            }
        },
    );
    $w->cbox_tabs->text('');
    $w->insert(Label => name => 'label_inds',
        text => 'Select Indicator',
        font => { style => fs::Bold, height => 16 },
        alignment => ta::Left,
        autoHeight => 1,
        autoWidth => 1,
        origin => [20, 200],
        hint => 'These indicators are already present in the selected tab',
        hintVisible => 1,
    );
    $w->insert(ComboBox =>
        name => 'cbox_inds',
        style => cs::DropDownList,
        height => 30,
        width => 360,
        hScroll => 0,
        font => { height => 14 },
        multiSelect => 0,
        multiColumn => 0,
        dragable => 0,
        focusedItem => -1,
        text => '',
        items => [],
        origin => [180, 200],
        onChange => sub {
            my $cbox = shift;
            my $owner = $cbox->owner;
            my $lbox = $cbox->List;
            my $index = $lbox->focusedItem;
            my $txt = $lbox->get_item_text($index);
            if (defined $txt) {
                $owner->btn_ok->enabled(1);
                $result->{indicator} = $txt;
                $result->{indicator_index} = $index;
            } else {
                $owner->btn_ok->enabled(0);
                $cbox->items([]);
                $cbox->focusedItem(-1);
                $cbox->text('');
                delete $result->{indicator};
                delete $result->{indicator_index};
            }
        },
    );
    $w->insert(
        Button => name => 'btn_cancel',
        text => 'Cancel',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, 20 ],
        modalResult => mb::Cancel,
        default => 0,
        enabled => 1,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            $result = {};
        },
    );
    $w->insert(
        Button => name => 'btn_ok',
        text => 'OK',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 150, 20 ],
        modalResult => mb::Ok,
        default => 1,
        enabled => 0,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            my $btn = shift;
            my $owner = $btn->owner;
            my $indicators = $self->get_tab_indicators($owner->owner, $result->{tab});
            my @inds = ();
            if ($indicators) {
                my $iref = $indicators->[$result->{indicator_index}]->{indicator};
                if ($iref->{func} eq $result->{indicator}) {
                    $result->{columns} = $indicators->[$result->{indicator_index}]->{columns};
                } else {
                    $log->warn("Cannot find the columns to remove");
                }
            } else {
                $log->warn("Invalid indicators for tab: ", $result->{tab});
            }
            $log->debug("Result: ", dumper($result));
        },
    );
    my $res = $w->execute();
    $w->end_modal;
    return ($res == mb::Ok) ? $result : undef;
}

sub run_and_display_indicator {
    my ($self, $win, $data, $symbol, $indicators) = @_;
    return unless $win;
    if (defined $data and defined $symbol and defined $indicators and
        ref $indicators eq 'ARRAY') {
        my $icount = scalar @$indicators;
        foreach my $iref (@$indicators) {
            $log->debug("Trying to run indicator for :", dumper($iref));
            my $output;
            if (exists $iref->{params} and exists $iref->{params}->{CompareWith}) {
                # ok this is a security.
                # we need to download the data for this and store it
                my $bar = $self->progress_bar_create($win, 'Downloading...');
                my $current = $self->current;
                $iref->{params}->{CompareWith} =~ s/\s//g;
                $current->{symbol} = $iref->{params}->{CompareWith};
                my $tz = $self->timezone;
                unless ($current->{start_date}) {
                    my $sd = $data->at(0, 0); # time in 0th column
                    my $dt = DateTime->from_epoch(epoch => $sd, time_zone => $tz);
                    $current->{start_date} = $dt;
                }
                unless ($current->{end_date}) {
                    my $ed = $data->at($data->dim(0) - 1, 0); # time in 0th column
                    my $dt = DateTime->from_epoch(epoch => $ed, time_zone => $tz);
                    $current->{end_date} = $dt;
                }
                my ($data2, $symbol2, $csv2) = $self->download_data($bar, $current);
                $self->progress_bar_close($bar);
                return unless (defined $data2 and defined $symbol2);
                $log->debug("Successfully downloaded data for $symbol2");
                $iref->{params}->{CompareWith} = $symbol2;
                $output = $self->indicator->execute_ohlcv($data, $iref, $data2);
            } else {
                $output = $self->indicator->execute_ohlcv($data, $iref);
            }
            unless (defined $output) {
                message_box('Indicator Error',
                    "Unable to run the indicator on data.",
                    mb::Ok | mb::Error);
                return;
            }
            my ($next_data) = $self->display_data($win, $data, $symbol, $iref, $output);
            $icount--;
            $data = $next_data if $icount > 0;
        }
        return 1;
    }
    return 0;
}

sub add_indicator($$$) {
    my ($self, $win, $data, $symbol) = @_;
    if ($self->add_indicator_wizard($win)) {
        my $iref = $self->current->{indicator};
        if ($self->run_and_display_indicator($win, $data, $symbol, [$iref])) {
            my ($ndata, $nsymbol, $indicators, $ndhr, $nbs) = $self->get_tab_data($win);
            my $type = $self->current->{plot_type} || 'OHLC';
            $self->plot_data($win, $ndata, $nsymbol, $type, $indicators, $nbs);
            return 1;
        }
    }
    return 0;
}

sub indicator_parameter_wizard {
    my ($self, $gbox, $fn_name, $grp, $params) = @_;
    if ($gbox) {
        # remove the current parameter screen
        my @widgets = $gbox->get_widgets;
        if (@widgets) {
            map { $_->close() } @widgets;
        }
    } else {
        return;
    }
    # if all are defined create the parameter screen
    if (defined $fn_name and defined $grp and defined $params) {
        $gbox->text("$fn_name Parameters");
        my @origin = $gbox->origin;
        my @size = $gbox->size;
        $log->debug("Gbox: Origin: @origin  Size: @size");
        my $num = scalar @$params;
        my $sz_x = $size[0] / 2; # label and value
        my $sz_y = $size[1] / ($num + 1);
        my $count = 0;
        $self->current->{indicator}->{params} = {};
        # if no params just write that
        unless (scalar @$params) {
            $gbox->insert('Label',
                text => "There are no parameters to configure.",
                name => "label_$grp\_noparams",
                alignment => ta::Left,
                autoHeight => 1,
                autoWidth => 1,
                origin => [$origin[0] + 10,
                    $origin[1] + $count * $sz_y - 40],
                font => {height => 16},
            );
        }
        foreach my $p (reverse @$params) {
            next unless ref $p eq 'ARRAY';
            my $hkey = $p->[0];
            my $label = $p->[1];
            my $type = $p->[2];
            my $typeclass = blessed($type) if $type;
            my $value = $p->[3];
            if (defined $type and $type eq 'ARRAY' and ref $value eq 'ARRAY') {
                # use ComboBox
                $self->current->{indicator}->{params}->{$hkey} = $value->[0];
                $self->current->{indicator}->{params}->{$hkey . '_index'} = 0;
                $gbox->insert(Label => text => $label,
                    name => "label_$grp\_$count",
                    alignment => ta::Left,
                    autoHeight => 1,
                    autoWidth => 1,
                    origin => [$origin[0] + 10,
                                $origin[1] + $count * $sz_y - 40],
                    font => {height => 13},
                );
                $gbox->insert(ComboBox => style => cs::DropDownList,
                    name => "cbox_$grp\_$count",
                    height => 30,
                    width => $sz_x - 50,
                    autoHeight => 1,
                    font => { height => 16 },
                    hScroll => 0,
                    multiSelect => 0,
                    multiColumn => 0,
                    dragable => 0,
                    focusedItem => -1,
                    items => $value,
                    autoTab => 1,
                    origin => [$origin[0] + 10 + $sz_x,
                                $origin[1] + $count * $sz_y - 40],
                    onChange => sub {
                        my $cbox = shift;
                        my $lbox = $cbox->List;
                        my $index = $lbox->focusedItem;
                        $self->current->{indicator}->{params}->{$hkey} = $lbox->get_item_text($index);
                        $self->current->{indicator}->{params}->{$hkey . '_index'} = $index;
                    },
                );
            } elsif (defined $typeclass and $typeclass eq 'PDL::Type') {
                # use InputLine for all numbers
                $self->current->{indicator}->{params}->{$hkey} = $value;
                $gbox->insert(Label => text => $label,
                    name => "label_$grp\_$count",
                    alignment => ta::Left,
                    autoHeight => 1,
                    autoWidth => 1,
                    origin => [$origin[0] + 10,
                                $origin[1] + $count * $sz_y - 40],
                    font => {height => 13},
                );
                $gbox->insert(InputLine => name => "input_$grp\_$count",
                    alignment => ta::Left,
                    autoHeight => 1,
                    width => $sz_x - 50,
                    autoTab => 1,
                    maxLen => 20,
                    origin => [$origin[0] + 10 + $sz_x,
                                $origin[1] + $count * $sz_y - 40],
                    text => $value,
                    font => {height => 16},
                    onChange => sub {
                        my $il = shift;
                        my $val = undef;
                        my $txt = $il->text;
                        return unless length $txt;
                        if ($type->symbol eq 'PDL_B') {
                            # byte buffer
                            $val = $txt;
                        } elsif ($type->symbol eq 'PDL_F' or $type->symbol eq 'PDL_D') {
                            # is a real number
                            if ($txt =~ /^(\d+\.?\d*)|(\.\d+)$/) {
                                $val = sprintf "%0.04f", $txt;
                            } else {
                                message_box('Parameter Error',
                                    "$label has to be a real number",
                                    mb::Ok | mb::Error);
                                return;
                            }
                        } else {
                            # is an integer form
                            if ($txt =~ /^([+-]?\d+)$/) {
                                $val = sprintf "%d", $txt;
                            } else {
                                message_box('Parameter Error',
                                    "$label has to be an integer",
                                    mb::Ok | mb::Error);
                                return;
                            }
                        }
                        $self->current->{indicator}->{params}->{$hkey} = $val;
                    },
                );
            } elsif (defined $type and $type eq 'PDL') {
                # use InputLine for all numbers
                $self->current->{indicator}->{params}->{$hkey} = $value;
                $self->current->{indicator}->{params}->{$hkey . '_pdl'} = 1;
                $gbox->insert(Label => text => $label,
                    name => "label_$grp\_$count",
                    alignment => ta::Left,
                    autoHeight => 1,
                    autoWidth => 1,
                    origin => [$origin[0] + 10,
                                $origin[1] + $count * $sz_y - 40],
                    font => {height => 13},
                    hint => 'This should be a comma-separated list of integers',
                );
                $gbox->insert(InputLine => name => "input_$grp\_$count",
                    alignment => ta::Left,
                    autoHeight => 1,
                    width => $sz_x - 50,
                    autoTab => 1,
                    maxLen => 256,
                    origin => [$origin[0] + 10 + $sz_x,
                                $origin[1] + $count * $sz_y - 40],
                    text => $value,
                    font => {height => 16},
                    onChange => sub {
                        my $il = shift;
                        my $val = undef;
                        my $txt = $il->text;
                        return unless length $txt;
                        if ($txt !~ /\d[\d,\s]*/) {
                            message_box('Parameter Error',
                                "$label has to be a comma-separated list of integers",
                                mb::Ok | mb::Error);
                            return;
                        }
                        $self->current->{indicator}->{params}->{$hkey} = $txt;
                        $self->current->{indicator}->{params}->{$hkey . '_pdl'} = 1;
                    },
                );
            } else {
                # use checkbox
                $self->current->{indicator}->{params}->{$hkey} = ($value) ? 1 : 0;
                $gbox->insert(CheckBox => name => "chk_$grp\_$count",
                    alignment => ta::Left,
                    autoTab => 1,
                    origin => [$origin[0] + 10,
                                $origin[1] + $count * $sz_y - 40],
                    text => $label,
                    font => {height => 13},
                    onCheck => sub {
                        my $chk = shift;
                        $self->current->{indicator}->{params}->{$hkey} =
                                $chk->checked ? 1 : 0;
                    },
                );
            }
            $count++;
        }
    } else {
        $gbox->text("Indicator Parameters");
        delete $self->current->{indicator}->{params};
    }
}

sub add_indicator_wizard {
    my ($self, $win) = @_;
    my $w = Prima::Dialog->new(
        name => 'add_ind_wizard',
        centered => 1,
        origin => [200, 200],
        size => [640, 480],
        text => 'Technical Analysis Indicator Wizard',
        icon => $self->icon,
        visible => 1,
        taskListed => 0,
        onExecute => sub {
            my $dlg = shift;
            $dlg->cbox_groups->List->focusedItem(-1);
            $dlg->cbox_funcs->List->focusedItem(-1);
            $dlg->btn_cancel->enabled(1);
            $dlg->btn_ok->enabled(0);
        },
    );
    $w->owner($win) if defined $win;
    $self->current->{indicator} = {}; # reset
    my @groups = $self->indicator->get_groups;
    $w->insert(Label => name => 'label_groups',
        text => 'Select Group',
        font => { style => fs::Bold, height => 16 },
        alignment => ta::Left,
        autoHeight => 1,
        autoWidth => 1,
        origin => [20, 440],
        hint => 'This is a list of indicator groups',
        hintVisible => 1,
    );
    $w->insert(ComboBox =>
        name => 'cbox_groups',
        style => cs::DropDownList,
        height => 30,
        width => 360,
        hScroll => 0,
        multiSelect => 0,
        multiColumn => 0,
        dragable => 0,
        focusedItem => -1,
        font => { height => 14 },
        items => [ '', @groups],
        origin => [180, 440],
        onChange => sub {
            my $cbox = shift;
            my $owner = $cbox->owner;
            my $lbox = $cbox->List;
            my $index = $lbox->focusedItem;
            my $txt = $lbox->get_item_text($index);
            if (defined $txt and length $txt) {
                my @funcs = $self->indicator->get_funcs($txt);
                if (scalar @funcs) {
                    $owner->cbox_funcs->items(\@funcs);
                } else {
                    $owner->cbox_funcs->items([]);
                }
                $owner->btn_ok->enabled(1);
                $self->current->{indicator}->{group} = $txt;
            } else {
                $owner->cbox_funcs->items([]);
                $owner->cbox_funcs->focusedItem(-1);
                $self->indicator_parameter_wizard($owner->gbox_params);
                $owner->cbox_funcs->text('');
                $owner->btn_ok->enabled(0);
                delete $self->current->{indicator}->{group};
            }
        },
    );
    $w->cbox_groups->text('');
    $w->insert(Label => name => 'label_funcs',
        text => 'Select Function',
        font => { style => fs::Bold, height => 16 },
        alignment => ta::Left,
        autoHeight => 1,
        autoWidth => 1,
        origin => [20, 400],
        hint => 'Each indicator group has multiple indicators it supports',
        hintVisible => 1,
    );
    $w->insert(ComboBox =>
        name => 'cbox_funcs',
        style => cs::DropDownList,
        height => 30,
        width => 360,
        hScroll => 0,
        font => { height => 14 },
        multiSelect => 0,
        multiColumn => 0,
        dragable => 0,
        focusedItem => -1,
        text => '',
        items => [],
        origin => [180, 400],
        onChange => sub {
            my $cbox = shift;
            my $owner = $cbox->owner;
            my $lbox = $cbox->List;
            my $index = $lbox->focusedItem;
            my $txt = $lbox->get_item_text($index);
            my $grp = $self->current->{indicator}->{group};
            if (defined $grp) {
                # $params is an array-ref
                my $params = $self->indicator->get_params($txt, $grp);
                $self->current->{indicator}->{func} = $txt;
                $log->debug("Params: ", dumper($params));
                $owner->btn_ok->enabled(1);
                $self->indicator_parameter_wizard($owner->gbox_params,
                        $txt, $grp, $params);
            } else {
                $owner->btn_ok->enabled(0);
                $cbox->items([]);
                $cbox->focusedItem(-1);
                delete $self->current->{indicator}->{func};
                $self->indicator_parameter_wizard($owner->gbox_params);
                $cbox->text('');
            }
        },
    );
    $w->insert(
        Button => name => 'btn_cancel',
        text => 'Cancel',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, 20 ],
        modalResult => mb::Cancel,
        default => 0,
        enabled => 1,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            delete $self->current->{indicator};
        },
    );
    $w->insert(
        Button => name => 'btn_ok',
        text => 'OK',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 360, 20 ],
        modalResult => mb::Ok,
        default => 1,
        enabled => 0,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            $log->debug("Final parameters selected: ", dumper($self->current->{indicator}));
        },
    );
    $w->insert(
        Button => name => 'btn_help',
        text => 'Indicator Help',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 150, 20 ],
        default => 0,
        enabled => 1,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            my $url = 'https://vikasnkumar.github.io/financeta/indicators.html';
            my $ok = Browser::Open::open_browser($url, 1);
            if (not defined $ok) {
                message("Error finding a browser to open $url");
            } elsif ($ok != 0) {
                message("Error opening $url");
            }
        },
    );
    $w->insert(GroupBox => name => 'gbox_params',
        text => 'Indicator Parameters',
        size => [600, 300],
        origin => [20, 60],
        font => { height => 16, style => fs::Bold },
    );
    my $res = $w->execute();
    $w->end_modal;
    return $res == mb::Ok;
}

sub download_data {
    my ($self, $pbar, $current) = @_;
    $self->progress_bar_update($pbar) if $pbar;
    $current = $self->current unless $current;
    my $start = $current->{start_date};
    my $end = $current->{end_date};
    my $symbol = $current->{symbol};
    #TODO: check symbol validity
    my $csv = sprintf "%s_%d_%d.csv", $symbol, $start->ymd(''), $end->ymd('');
    $csv = File::Spec->catfile($self->tmpdir, $csv);
    if (defined $current->{csv}) {
        $csv = $current->{csv};
        $log->debug("Using $csv as it was chosen");
    }
    $self->progress_bar_update($pbar) if $pbar;
    my $data;
    unlink $csv if $current->{force_download};
    unless (-e $csv) {
        my $fq = Finance::QuoteHist->new(
            symbols => [ $symbol ],
            start_date => $start->mdy('/'),
            end_date => $end->mdy('/'),
            auto_proxy => 1,
        );
        $self->progress_bar_update($pbar) if $pbar;
        open my $fh, '>', $csv or die "$!";
        my @quotes = ();
        foreach my $row ($fq->quotes) {
            my ($sym, $date, $o, $h, $l, $c, $vol) = @$row;
            my ($yy, $mm, $dd) = split /\//, $date;
            my $epoch = DateTime->new(
                year => $yy,
                month => $mm,
                day => $dd,
                hour => 16, minute => 0, second => 0,
                time_zone => $self->timezone,
            )->epoch;
            print $fh "$epoch,$o,$h,$l,$c,$vol\n";
            push @quotes, pdl($epoch, $o, $h, $l, $c, $vol);
        }
        $self->progress_bar_update($pbar) if $pbar;
        $fq->clear_cache;
        close $fh;
        unless (scalar @quotes) {
            message_box('Error',
                "Failed to download $symbol data. Check if '$symbol' is correct",
                mb::Ok | mb::Error);
            unlink $csv;
            return;
        }
        $log->info("$csv has downloaded data for analysis");
        $self->progress_bar_update($pbar) if $pbar;
        $data = pdl(@quotes)->transpose;
        $self->progress_bar_update($pbar) if $pbar;
    } else {
        ## now read this back into a PDL using rcol
        $self->progress_bar_update($pbar) if $pbar;
        $log->info("$csv already present. loading it...");
        $data = PDL->rcols($csv, [], { COLSEP => ',', DEFTYPE => PDL::double});
        $self->progress_bar_update($pbar) if $pbar;
    }
    return ($data, $symbol, $csv);
}

sub display_data {
    my ($self, $win, $data, $symbol, $iref, $output) = @_;
    return unless defined $win and defined $data;
    my @tabsize = $win->size();
    $symbol = $self->current->{symbol} unless defined $symbol;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    $log->debug("Tabs: @tabs");
    unless (@tabs) {
        $win->insert('Prima::TabbedNotebook',
            name => 'data_tabs',
            size => \@tabsize,
            origin => [ 0, 0 ],
            style => tns::Simple,
            growMode => gm::Client,
            visible => 1,
            onChange => sub {
                my ($w, $oldidx, $newidx) = @_;
                my $owner = $w->owner;
                $log->debug("Tab changed from $oldidx to $newidx");
                return if ($oldidx == $newidx and !$self->tab_was_closed);
                $self->tab_was_closed(0);
                # ok find the detailed-list object and use it
                my ($data, $symbol, $indicators, $h, $bs) = $self->_get_tab_data($w, $newidx);
                my $type = $self->current->{plot_type} || 'OHLC';
                $self->plot_data($owner, $data, $symbol, $type, $indicators, $bs);
            },
        );
    }
    my $nt = $win->data_tabs;
    my $nt_tabs = $nt->tabs;
    # create unique tab-names
    if (scalar @$nt_tabs) {
        my %tabnames = map { $_ => 1 } @$nt_tabs;
        $log->debug("$symbol tab already exists") if exists $tabnames{$symbol};
        $log->debug("$symbol tab will be added") if not exists $tabnames{$symbol};
        $nt->tabs([@$nt_tabs, $symbol]) if not exists $tabnames{$symbol};
    } else {
        $log->debug("$symbol tab will be added");
        $nt->tabs([$symbol]);
    }
    my $pc = $nt->pageCount;
    $log->debug("TabCount: $pc");
    my $pageno = $pc;
    # find the existing tab with the same symbol info and remove the widget
    # there and get that page number
    # default headers
    my $headers = ['Date', 'Open', 'High', 'Low', 'Close', 'Volume'];
    my $existing_indicators = [];
    my ($info, $buysells);
    for my $idx (0 .. $pc) {
        my @wids = $nt->widgets_from_page($idx);
        next unless @wids;
        my @dls = grep { $_->name eq "tab_$symbol" } @wids;
        if (@dls) {
            foreach (@dls) {
                $log->debug("Found existing " . $_->name . " at $idx");
                $headers = $_->headers if defined $_->headers;
                push @$existing_indicators, @{$_->{-indicators}} if exists $_->{-indicators};
                $info = $_->{-info} if exists $_->{-info};
                $buysells = $_->{-buysells} if exists $_->{-buysells};
                $nt->delete_widget($_);
            }
            $pageno = $idx;
            last;
        }
    }
    # handle the current indicator first
    if ($output and scalar @$output) {
        my @cols = ();
        foreach my $a (@$output) {
            # add the DetailedList column number
            push @cols, scalar(@$headers);
            # add the header
            push @$headers, $a->[0];
            # splice the indicator PDL into $data
            $data = $data->glue(1, $a->[1]) if ref $a->[1] eq 'PDL';
        }
        # add the current indicator to the bottom of the list
        push @$existing_indicators, {indicator => $iref, data => $output, columns => \@cols};
    }
    $log->debug("Data dimension: ", dumper([$data->dims]));
    $log->debug("Updated headers: ", dumper($headers));
    my $items;
    if (defined $buysells and ref $buysells eq 'HASH' and
        defined $buysells->{buys} and
        defined $buysells->{sells}) {
        my $buys = $buysells->{buys};
        my $sells = $buysells->{sells};
        if (ref $buys eq 'PDL' and ref $sells eq 'PDL') {
            my $ldata = $data->copy;
            $ldata = $ldata->glue(1, $buys);
            $ldata = $ldata->glue(1, $sells);
            push @$headers, 'Buys', 'Sells' unless grep {/Buys|Sells/} @$headers;
            $items = $ldata->transpose->unpdl;
        } else {
            $log->warn("Buy-sells object is corrupt. Not using.");
            $items = $data->transpose->unpdl;
        }
    } else {
        $items = $data->transpose->unpdl;
    }
    my $tz = $self->timezone;
    # reformat
    foreach my $arr (@$items) {
        my $dt = DateTime->from_epoch(epoch => $arr->[0], time_zone => $tz)->ymd('-');
        $arr->[0] = $dt;
        for (my $i = 1; $i < scalar @$arr; ++$i) {
            $arr->[$i] = '' if $arr->[$i] =~ /BAD/i;
        }
    }
    $tabsize[0] *= 0.98;
    $tabsize[1] *= 0.96;
    my $dl = $nt->insert_to_page($pageno, 'DetailedList',
        name => "tab_$symbol",
        pack => { expand => 1, fill => 'both' },
        items => $items,
        origin => [ 10, 10 ],
        headers => $headers,
        hScroll => 1,
        growMode => gm::Client | gm::GrowHiX | gm::GrowHiY,
        columns => scalar @$headers,
        onSort => sub {
            my ($p, $col, $dir) = @_;
            return if $col != 1;
            if ($dir) {
                $p->{items} = [
                    sort {$$a[$col] <=> $$b[$col]}
                    @{$self->{items}}
                ];
            } else {
                $p->{items} = [
                    sort {$$b[$col] <=> $$a[$col]}
                    @{$self->{items}}
                ];
            }
            $p->clear_event;
        },
        title => $symbol,
        titleSpace => 30,
        size => \@tabsize,
        visible => 1,
    );
    $nt->pageIndex($pageno);
    $dl->{-pdl} = $data;
    $dl->{-symbol} = $symbol;
    $dl->{-indicators} = $existing_indicators if defined $existing_indicators;
    $dl->{-info} = $info || {};
    $dl->{-buysells} = $buysells if defined $buysells;
    return wantarray ? ($data) : 1;
}

sub enable_menu_options {
    my $self = shift;
    my $win = shift || $self->main;
    # enable the menu option now that we have something open
    $win->menu->security_save->enabled(1);
    $win->menu->security_saveas->enabled(1);
    $win->menu->security_close->enabled(1);
    $win->menu->plot_ohlc->enabled(1);
    $win->menu->plot_ohlcv->enabled(1);
    $win->menu->plot_close->enabled(1);
    $win->menu->plot_closev->enabled(1);
    $win->menu->plot_cdl->enabled(1);
    $win->menu->plot_cdlv->enabled(1);
    $win->menu->add_indicator->enabled(1);
    $win->menu->edit_rules->enabled(1);
    $win->menu->execute_rules->enabled(1);
#    $win->menu->trade_report->enabled(1);
}

sub disable_menu_options {
    my $self = shift;
    my $win = $self->main;
    # disable the menu option now that we have nothing open
    $win->menu->security_save->enabled(0);
    $win->menu->security_saveas->enabled(0);
    $win->menu->security_close->enabled(0);
    $win->menu->plot_ohlc->enabled(0);
    $win->menu->plot_ohlcv->enabled(0);
    $win->menu->plot_close->enabled(0);
    $win->menu->plot_closev->enabled(0);
    $win->menu->plot_cdl->enabled(0);
    $win->menu->plot_cdlv->enabled(0);
    $win->menu->add_indicator->enabled(0);
    $win->menu->remove_indicator->enabled(0);
    $win->menu->edit_rules->enabled(0);
    $win->menu->execute_rules->enabled(0);
    $win->menu->trade_report->enabled(0);
}

#rudimentary
sub get_model {
    my ($self, $data, $symbol, $indicators) = @_;
    if (defined $data and defined $symbol) {
        my $sd = $data->at(0, 0);
        my $ed = $data->at($data->dim(0) - 1, 0);
        my $tz = $self->timezone;
        my %saved = (
            start_date => $sd,
            end_date => $ed,
            symbol => $symbol,
        );
        if ($indicators and ref $indicators eq 'ARRAY') {
            my $arr = [];
            foreach (@$indicators) {
                push @$arr, $_->{indicator};
            }
            $saved{indicators} = $arr;
        } elsif ($indicators and ref $indicators eq 'HASH') {
            $saved{indicators} = [$indicators->{indicator}];
        }
        return wantarray ? %saved : \%saved;
    }
}

#rudimentary
sub save_current_tab {
    my ($self, $win, $save_as, $name) = @_;
    return unless $win;
    my ($data, $symbol, $indicators) = (defined $name) ?
            $self->get_tab_data_by_name($win, $name) :
            $self->get_tab_data($win);
    # in save-as mode do not get historical file name
    my ($info, $tname) = (defined $name) ?
        $self->get_tab_info_by_name($win, $name) :
        $self->get_tab_info($win);
    my $saved = $self->get_model($data, $symbol, $indicators);
    return unless $saved;
    my $tz = $self->timezone;
    $saved->{saved_at} = DateTime->now(time_zone => $tz)->iso8601();
    $log->debug("Saving the model: ", dumper($saved));
    my $mfile;
    if ($info and $info->{filename} and not $save_as) {
        $mfile = $info->{filename};
        $log->info(sprintf "Saving tab %s to %s", ($name ? $name : ''), $mfile);
    } else {
        my $dlg = Prima::Dialog::SaveDialog->new(
            fileName => "$symbol.yml",
            filter => [
                ['financeta files' => '*.yml'],
                ['All files' => '*'],
            ],
            filterIndex => 0,
            multiSelect => 0,
            overwritePrompt => 1,
            pathMustExist => 1,
            directory => $self->datadir,
        );
        $mfile = $dlg->fileName if $dlg->execute;
        if ($mfile) {
            if ($^O !~ /Win32/) {
                $mfile = File::Spec->catfile($self->datadir, $mfile) unless ($mfile =~ /^\//);
            } else {
                $mfile .= '.yml' unless $mfile =~ /\.yml$/; #windows is weird
            }
            $log->info("Saving tab $name to $mfile");
        } else {
            $log->warn("Saving the tab $name was canceled.");
            return;
        }
    }
    if ($info and defined $info->{rules}) {
        $saved->{rules} = $info->{rules};
    } else {
        if (exists $self->editors->{$tname}) {
            $saved->{rules} = $self->editors->{$tname}->get_text;
        }
    }
    $saved->{old_filename} = $info->{old_filename} if defined $info and defined $info->{old_filename};
    $saved->{csv} = $info->{csv} if defined $info and defined $info->{csv};
    if ($mfile) {
        $saved->{filename} = $mfile;
        $log->debug("You have selected $mfile to save the tab info into.");
        YAML::Any::DumpFile($mfile, $saved) or message("Unable to save to $mfile");
        $self->set_tab_info($win, $saved);
        1;
    } else {
        $log->warn("Saving the tab was canceled.");
    }
}

#rudimentary
sub load_new_tab {
    my ($self, $win) = @_;
    return unless $win;
    my $dlg = Prima::Dialog::OpenDialog->new(
        filter => [
            ['financeta files' => '*.yml'],
            ['All files' => '*'],
        ],
        filterIndex => 0,
        fileMustExist => 1,
        multiSelect => 0,
        directory => $self->datadir,
    );
    my $mfile = $dlg->fileName if $dlg->execute;
    $log->info("requesting file $mfile to be opened");
    return unless $mfile;
    return unless -e $mfile;
    my $saved = YAML::Any::LoadFile($mfile);
    return unless $saved;
    my $tz = $self->timezone;
    my $current = {
        start_date => DateTime->from_epoch(epoch => $saved->{start_date}, time_zone => $tz),
        end_date => DateTime->from_epoch(epoch => $saved->{end_date}, time_zone => $tz),
        symbol => $saved->{symbol},
        force_download => 0,
    };
    $current->{csv} = $saved->{csv} if defined $saved->{csv};
    my $bar = $self->progress_bar_create($win, 'Loading...');
    my ($data, $symbol, $csv) = $self->download_data($bar, $current);
    $log->debug("Loading the data into tab");
    $saved->{csv} = $csv if defined $csv;
    # overwrite the filename for saving
    if (defined $saved->{filename} and $mfile ne $saved->{filename}) {
        $saved->{old_filename} = $saved->{filename};
    }
    $saved->{filename} = $mfile;
    $self->display_data($win, $data, $symbol);
    $self->enable_menu_options($win);
    $self->set_tab_info($win, $saved);
    $log->debug("Running the indicators and updating tab");
    $self->progress_bar_close($bar);
    if ($self->run_and_display_indicator($win, $data, $symbol,
            $saved->{indicators})) {
        # this is specially done
        $win->menu->remove_indicator->enabled(1);
    }
    my ($adata, $asym, $aind, $ahdr, $abysl) = $self->get_tab_data($win);
    my $type = $self->current->{plot_type} || 'OHLC';
    $self->plot_data($win, $adata, $asym, $type, $aind, $abysl);
}

sub close_current_tab {
    my ($self, $win) = @_;
    return unless $win;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $nt = $win->data_tabs;
    my $idx = $nt->pageIndex;
    if ($nt->pageCount == 1) {
        foreach my $e (keys %{$self->editors}) {
            my $ed = $self->editors->{$e};
            $ed->close;
        }
        $self->editors({});
        foreach my $t (keys %{$self->tradereports}) {
            my $trw = $self->tradereports->{$t};
            $trw->close;
        }
        $self->tradereports({});
        if ($win->{plot}) {
            $win->{plot}->close();
        }
        $nt->close;
        $self->disable_menu_options;
    } else {
        $self->tab_was_closed(1);
        # find corresponding editors and close them
        my @wids = $win->data_tabs->widgets_from_page($idx);
        if (@wids) {
            my ($dl) = grep { $_->name =~ /^tab_/i } @wids;
            if ($dl and exists $self->editors->{$dl->name}) {
                $log->debug("Closing the rules editor for " . $dl->name);
                $self->editors->{$dl->name}->close;
                delete $self->editors->{$dl->name};
            }
            if ($dl and exists $self->tradereports->{$dl->name}) {
                $log->debug("Closing the trade report for " . $dl->name);
                $self->tradereports->{$dl->name}->close;
                delete $self->tradereports->{$dl->name};
            }
        }
        $nt->delete_page($idx);
        $nt->pageIndex($idx >= $nt->pageCount ?
            $nt->pageCount - 1 : $idx);
    }
}

sub _get_tab_data {
    my ($self, $nb, $idx) = @_;
    my @nt = $nb->widgets_from_page($idx);
    return unless @nt;
    my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
    if ($dl) {
        $log->debug("Found " . $dl->name);
        return ($dl->{-pdl}, $dl->{-symbol}, $dl->{-indicators},
                    [$dl->headers],
                    $dl->{-buysells});
    }
}

sub get_tab_data {
    my ($self, $win) = @_;
    return unless $win;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $idx = $win->data_tabs->pageIndex;
    return $self->_get_tab_data($win->data_tabs, $idx);
}

sub get_tab_data_by_name($$) {
    my ($self, $win, $name) = @_;
    return unless $win;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    $log->debug("Looking for $name");
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        if ($dl and ($dl->{-symbol} eq $name) or ($dl->name eq $name)) {
            $log->debug("Found $name on page $idx");
            return ($dl->{-pdl},
                    $dl->{-symbol},
                    $dl->{-indicators},
                    [$dl->headers],
                    $dl->{-buysells});
        }
    }
    return undef;
}

sub get_tab_info {
    my ($self, $win) = @_;
    return unless $win;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $idx = $win->data_tabs->pageIndex;
    my @nt = $win->data_tabs->widgets_from_page($idx);
    return unless @nt;
    my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
    if ($dl) {
        $log->debug("Getting info for " . $dl->name);
        return wantarray ? ($dl->{-info}, $dl->name) : $dl->{-info};
    }
}

sub set_tab_info($$) {
    my ($self, $win, $info) = @_;
    return unless $win;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $idx = $win->data_tabs->pageIndex;
    my @nt = $win->data_tabs->widgets_from_page($idx);
    return unless @nt;
    my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
    if ($dl) {
        $log->debug("Setting info for " . $dl->name);
        $dl->{-info} = $info;
        return 1;
    }
}

sub set_tab_data_by_name($$) {
    my ($self, $win, $name, $p, $s, $ind, $hdr) = @_;
    return unless $win;
    return unless $name;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    my $found;
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        if ($dl and $dl->{-symbol} eq $name) {
            $log->debug("Found $name on page $idx");
            $dl->{-pdl} = $p;
            $dl->{-indicators}= $ind;
            $dl->headers($hdr);
            return 1;
        }
    }
}

sub get_tab_info_by_name {
    my ($self, $win, $name) = @_;
    return unless $win;
    return unless $name;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        if ($dl and $dl->name eq $name) {
            $log->debug("Getting info for " . $dl->name);
            return wantarray ? ($dl->{-info}, $dl->name) : $dl->{-info};
        }
    }
}

sub set_tab_info_by_name {
    my ($self, $win, $name, $info) = @_;
    return unless $win;
    return unless $name;
    return unless $info;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        if ($dl and $dl->name eq $name) {
            $log->debug("Setting info for " . $dl->name);
            $dl->{-info} = $info;
            return 1;
        }
    }
}

sub set_tab_buysells_by_name {
    my ($self, $win, $name, $buysells) = @_;
    return unless $win;
    return unless $name;
    return unless $buysells;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        if ($dl and $dl->name eq $name) {
            $log->debug("Setting buy-sells for " . $dl->name);
            $dl->{-buysells} = $buysells;
            return 1;
        }
    }
}

sub get_tab_buysells_for_name {
    my ($self, $win, $name) = @_;
    return unless $win;
    return unless $name;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        if ($dl and $dl->name eq $name) {
            $log->debug("Getting buy-sells for " . $dl->name);
            return wantarray ? ($dl->{-buysells}, $dl->name) : $dl->{-buysells};
        }
    }
}

sub get_tab_names($) {
    my ($self, $win) = @_;
    return unless $win;
    my @tabs = grep { $_->name =~ /data_tabs/ } $win->get_widgets();
    return unless @tabs;
    my $pc = $win->data_tabs->pageCount - 1;
    return unless $pc >= 0;
    my %names = ();
    for my $idx (0 .. $pc) {
        my @nt = $win->data_tabs->widgets_from_page($idx);
        next unless @nt;
        my ($dl) = grep { $_->name =~ /^tab_/i } @nt;
        $names{$dl->{-symbol}} = $dl->name if ($dl);
    }
    return wantarray ? %names : \%names;
}

sub get_tab_indicators {
    my ($self, $win, $txt) = @_;
    my ($data, $sym, $indicators, $headers) = $self->get_tab_data_by_name($win, $txt);
    return $indicators;
}

sub open_editor {
    my ($self, $win, $rules, $tabname, $hidden) = @_;
    # update the editor window with rules
    # once the editor window saves something update the parent tab's rules
    # object
    my $editor = $self->editors->{$tabname} || $self->_build_editor($tabname);
    unless (defined $editor) {
        $log->error("Unable to create the editor window.");
        return;
    }
    # find the list of indicators and the variable names
    my $indicators = $self->get_tab_indicators($win, $tabname) || [];
    my @vars = qw(open high low close);
    foreach (@$indicators) {
        my $iref = $_->{indicator};
        my $idata = $_->{data};
        next unless defined $idata;
        foreach (@$idata) {
            push @vars, $_->[3];
        }
    }
    my @varcomm = map { "### \$$_" } @vars;
    my $varstr = join ("\n", @varcomm);
    my $autogen = <<"AUTOGEN";
### START OF AUTOGENERATED CODE - DO NOT EDIT
### The list of variables that you can use is below:
$varstr
### END OF AUTOGENERATED CODE
AUTOGEN
    $log->debug("New Auto comment block:\n$autogen");
    if (defined $rules and length $rules) {
        if ($rules =~ /(.*###\sEND\sOF\sAUTOGENERATED\sCODE\s+)(.*)/s) {
            $log->debug("Old Auto comment block:\n$1");
            $log->debug("User block:\n$2");
            $rules = $autogen . "\n" . $2;
        } else {
            $rules = $autogen . "\n" . $rules;
        }
    } else {
        $rules = $autogen . "\n";
    }
    if ($editor->update_editor($rules, $tabname, \@vars, $hidden)) {
    }
    $self->editors->{$tabname} = $editor;
}

sub save_editor {
    my ($self, $txt, $tabname, $is_closing) = @_;
    unless (defined $tabname) {
        $log->error("Tab-name not retrieved. not sure which tab to save it for.");
        return;
    }
    # ok we have a tab for which we need to save info
    my $info = $self->get_tab_info_by_name($self->main, $tabname);
    $info->{rules} = $txt if $info;
    $log->debug("Retrieved info - ", dumper($info), " for tab($tabname)") if $info;
    $log->warn("Unable to retrieve info for $tabname") unless $info;
    if ($self->set_tab_info_by_name($self->main, $tabname, $info)) {
        $log->debug("Saving tab($tabname) info to file");
        my $rc = $self->save_current_tab($self->main, 0, $tabname);
        $log->warn("Unable to save information for $tabname") unless $rc;
    } else {
        $log->warn("Unable to save editor rules for tab $tabname");
    }
    delete $self->editors->{$tabname} if $is_closing;
}

sub close_editor {
    my ($self, $tabname) = @_;
    delete $self->editors->{$tabname} if defined $tabname;
}

sub open_tradereport {
    my ($self, $win, $tabname, $buysells) = @_;
    return unless defined $buysells;
    my $trw = $self->tradereports->{$tabname} || $self->_build_tradereport($tabname);
    unless (defined $trw) {
        $log->error("Unable to create the trade report window.");
        return;
    }
    $trw->update($tabname, $buysells);
    $self->tradereports->{$tabname} = $trw;
}

sub close_tradereport {
    my ($self, $tabname) = @_;
    delete $self->tradereports->{$tabname} if defined $tabname;
}

sub execute_rules_no_editor {
    my ($self, $win, $tabname, $code_txt) = @_;
    return unless ($win and $tabname and $code_txt);
    return unless length $code_txt;
    $self->open_editor($win, $code_txt, $tabname, 1);
    my $editor = $self->editors->{$tabname};
    $editor->execute($editor->get_text);
}

sub execute_rules {
    my ($self, $tabname, $coderef, $win_in) = @_;
    if (defined $tabname) {
        return unless ref $coderef eq 'CODE';
        # ok now we have the code ready.
        # let's make sure the variables needed by the code
        # are in the same order as the code expects them to be in
        # then we invoke the code, and retrieve the buy-sell results
        # and update the display
        my $win = $win_in || $self->main;
        # find the list of indicators and the variable names
        my ($data, $sym, $indicators, $headers) =
            $self->get_tab_data_by_name($win, $tabname);
        my @var_pdls = ();
        $indicators = [] unless defined $indicators;
        push @var_pdls, $data(, (1)); # open
        push @var_pdls, $data(, (2)); # high
        push @var_pdls, $data(, (3)); # low
        push @var_pdls, $data(, (4)); # close
        foreach (@$indicators) {
            my $iref = $_->{indicator};
            my $idata = $_->{data};
            next unless defined $idata;
            foreach (@$idata) {
                push @var_pdls, $_->[1]; # this is the PDL
            }
        }
        my $buysells = &$coderef(@var_pdls); # invoke the rules sub
        if (defined $buysells and ref $buysells eq 'HASH') {
            $log->debug("Retrieved buy-sells successfully from code-ref");
            $buysells = $self->indicator->calculate_pnl($data(, (0)), $buysells);
            if ($buysells) {
                $log->debug("Done applying P&L calcs to buy-sells");
                if ($self->set_tab_buysells_by_name($win, $tabname, $buysells)) {
                    $log->debug("Successully set buy-sells for tab $tabname\n");
                }
                $log->debug("BUYS: ", $buysells->{buys});
                $log->debug("SELLS: ", $buysells->{sells});
                $log->debug("Longs PnL: ", $buysells->{longs_pnl});
                $log->debug("Shorts PnL: ", $buysells->{shorts_pnl});
            } else {
                $log->warn("Failed to calculate P&L on executed rules");
            }
            # this $data should not change theoretically
            $self->display_data($win, $data, $sym);
            my ($adata, $asym, $aind, $ahdr, $abysl) = $self->get_tab_data_by_name($win, $tabname);
            my $type = $self->current->{plot_type} || 'OHLC';
            $self->plot_data($win, $adata, $asym, $type, $aind, $abysl);
            $self->main->menu->trade_report->enabled(1);
            $self->open_tradereport($win, $tabname, $abysl);
        } else {
            $log->warn("Unable to execute rules strategy code-ref");
            return;
        }
    } else {
        $log->warn("Code for non-existent tab $tabname was being executed");
    }
}

sub plot_data {
    my $self = shift;
    if (lc($self->plot_engine) eq 'gnuplot') {
        $log->info("Using Gnuplot to do plotting");
        $log->info("PDL::Graphics::Gnuplot $PDL::Graphics::Gnuplot::VERSION is being used");
        return $self->plot_data_gnuplot(@_);
    }
    $log->warn($self->plot_engine . " is not supported yet.");
}

sub plot_data_gnuplot {
    my ($self, $win, $data, $symbol, $type, $indicators, $buysell) = @_;
    return unless defined $data;
    # use the x11 term by default first
    my $term = 'x11';
    # if the wxt term is there use that instead since it is just better
    # if the aqua term is there use that if wxt isn't there
    if ($^O =~ /Darwin/i) {
        Capture::Tiny::capture {
            my @terms = PDL::Graphics::Gnuplot::terminfo();
            $term = 'aqua' if grep {/aqua/} @terms;
            $term = 'wxt' if grep {/wxt/} @terms;
        };
    } elsif ($^O =~ /Win32|Cygwin/i) {
        Capture::Tiny::capture {
            my @terms = PDL::Graphics::Gnuplot::terminfo();
            $term = 'wxt' if (grep {/wxt/} @terms) > 0;
            $term = 'windows' if (grep {/windows/} @terms) > 0;
            # on Cygwin it may be x11
        };
    }
    $log->debug("Using term $term");
    my $pwin = $win->{plot} || gpwin($term, size => [1024, 768, 'px']);
    $win->{plot} = $pwin;
    $symbol = $self->current->{symbol} unless defined $symbol;
    $type = $self->current->{plot_type} unless defined $type;
    my @general_plot = ();
    my @volume_plot = ();
    my @addon_plot = ();
    my @candle_plot = ();
    $self->indicator->color_idx(0); # reset color index
    if (defined $indicators and scalar @$indicators) {
        # ok now create a list of indicators to plot
        foreach (@$indicators) {
            my $iref = $_->{indicator};
            my $idata = $_->{data};
            my $iplot = $self->indicator->get_plot_args($data(,(0)), $idata, $iref);
            next unless $iplot;
            if (ref $iplot eq 'ARRAY') {
                push @general_plot, @$iplot if scalar @$iplot;
            } elsif (ref $iplot eq 'HASH') {
                my $iplot_gen = $iplot->{general};
                push @general_plot, @$iplot_gen if $iplot_gen and scalar @$iplot_gen;
                my $iplot_vol = $iplot->{volume};
                push @volume_plot, @$iplot_vol if $iplot_vol and scalar @$iplot_vol;
                my $iplot_addon = $iplot->{additional};
                push @addon_plot, @$iplot_addon if $iplot_addon and scalar @$iplot_addon;
                my $iplot_cdl = $iplot->{candle};
                push @candle_plot, @$iplot_cdl if $iplot_cdl and scalar @$iplot_cdl;
            } else {
                $log->warn('Unable to handle plot arguments in ' . ref($iplot) . ' form!');
            }
        }
    }
    if (defined $buysell and ref $buysell eq 'HASH' and
        defined $buysell->{buys} and defined $buysell->{sells}) {
        my $buys = $buysell->{buys};
        my $sells = $buysell->{sells};
        if (ref $buys eq 'PDL' and ref $sells eq 'PDL') {
            my $bsplot = $self->indicator->get_plot_args_buysell(
                $data(,(0)), $buys, $sells);
            if (defined $bsplot and ref $bsplot eq 'ARRAY') {
                push @general_plot, @$bsplot if scalar @$bsplot;
            } elsif (ref $bsplot eq 'HASH') {
                my $bsplot_gen = $bsplot->{general};
                if ($bsplot_gen) {
                    push @general_plot, @$bsplot_gen if scalar @$bsplot_gen;
                }
            }
        } else {
            $log->warn("Unable to plot invalid buy-sell data");
        }
    }
    $pwin->reset();
    # use multiplot
    $pwin->multiplot();
    my %binmode = ();
    if ($^O !~ /Win32/ and $Alien::Gnuplot::version < 4.6) {
        $log->debug("Binary mode is set to 0 due to gnuplot $Alien::Gnuplot::version");
        $binmode{binary} = 0;
    }
    if ($type eq 'OHLC') {
        my %addon_gen = ();
        if (@addon_plot) {
            $addon_gen{size} = ["1, 0.7"];
            $addon_gen{origin} = [0, 0.3];
            $addon_gen{bmargin} = 0;
            $addon_gen{lmargin} = 9;
            $addon_gen{rmargin} = 2;
        }
        $pwin->plot({
                %binmode,
                object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
                title => ["$symbol Open-High-Low-Close", textcolor => 'rgb "white"'],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                xlabel => ['Date', textcolor => 'rgb "yellow"'],
                ylabel => ['Price', textcolor => 'rgb "yellow"'],
                xdata => 'time',
                xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
                ytics => {textcolor => 'orange'},
                label => [1, $self->brand, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
                %addon_gen,
            },
            {
                with => 'financebars',
                linecolor => 'white',
                legend => 'Price',
            },
            $data(,(0)), $data(,(1)), $data(,(2)), $data(,(3)), $data(,(4)),
            @general_plot,
        );
        if (@addon_plot) {
            $pwin->plot({
                    %binmode,
                    object => '1',
                    title => '',
                    key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                    border => 'linecolor rgbcolor "white"',
                    ylabel => '',
                    xlabel => '',
                    xtics => '',
                    ytics => {textcolor => 'orange'},
                    bmargin => 0,
                    tmargin => 0,
                    lmargin => 9,
                    rmargin => 2,
                    size => ["1,0.3"], #bug in P:G:G
                    origin => [0, 0],
                    label => [1, "", at => "graph 0.90,0.03"],
                },
                @addon_plot,
            );
        }
    } elsif ($type eq 'OHLCV') {
        my %addon_gen = ();
        my %addon_vol = ();
        if (@addon_plot) {
            $addon_gen{size} = ["1, 0.6"]; #bug in P:G:G
            $addon_gen{origin} = [0, 0.4];
            $addon_vol{size} = ["1, 0.2"]; #bug in P:G:G
            $addon_vol{origin} = [0, 0];
        } else {
            $addon_gen{size} = ["1, 0.7"]; #bug in P:G:G
            $addon_gen{origin} = [0, 0.3];
            $addon_vol{size} = ["1, 0.3"]; #bug in P:G:G
            $addon_vol{origin} = [0, 0];
            $addon_vol{object} = '1'; # needed as otherwise the addon plot does it
        }
        $pwin->plot({
                %binmode,
                object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
                xlabel => ['Date', textcolor => 'rgb "yellow"'],
                ylabel => ['Price', textcolor => 'rgb "yellow"'],
                title => ["$symbol Price & Volume", textcolor => "rgb 'white'"],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                xdata => 'time',
                xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
                ytics => {textcolor => 'orange'},
                bmargin => 0,
                lmargin => 9,
                rmargin => 2,
                %addon_gen,
                label => [1, $self->brand, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
            },
            {
                with => 'financebars',
                linecolor => 'white',
                legend => 'Price',
            },
            $data(,(0)), $data(,(1)), $data(,(2)), $data(,(3)), $data(,(4)),
            @general_plot,
        );
        if (@addon_plot) {
            $pwin->plot({
                    %binmode,
                    object => '1',
                    title => '',
                    key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                    border => 'linecolor rgbcolor "white"',
                    ylabel => '',
                    xlabel => '',
                    xtics => '',
                    ytics => {textcolor => 'orange'},
                    bmargin => 0,
                    tmargin => 0,
                    lmargin => 9,
                    rmargin => 2,
                    size => ["1,0.2"], #bug in P:G:G
                    origin => [0, 0.2],
                    label => [1, "", at => "graph 0.90,0.03"],
                },
                @addon_plot,
            );
        }
        $pwin->plot({
                %binmode,
                title => '',
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                ylabel => ['Volume (in 1M)', textcolor => 'rgb "yellow"'],
                xlabel => '',
                xtics => '',
                ytics => {textcolor => 'orange'},
                bmargin => 0,
                tmargin => 0,
                lmargin => 9,
                rmargin => 2,
                %addon_vol,
                label => [1, "", at => "graph 0.90,0.03"],
            },
            {
                with => 'impulses',
                legend => 'Volume',
                linecolor => 'cyan',
            },
            $data(,(0)), $data(,(5)) / 1e6,
            @volume_plot,
        );
    } elsif ($type eq 'CANDLE') {
        my %addon_gen = ();
        if (@addon_plot) {
            $addon_gen{size} = ["1, 0.7"];
            $addon_gen{origin} = [0, 0.3];
            $addon_gen{bmargin} = 0;
            $addon_gen{lmargin} = 9;
            $addon_gen{rmargin} = 2;
        }
        # use candlesticks feature of Gnuplot
        $pwin->plot({
                %binmode,
                object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
                title => ["$symbol Open-High-Low-Close", textcolor => 'rgb "white"'],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                xlabel => ['Date', textcolor => 'rgb "yellow"'],
                ylabel => ['Price', textcolor => 'rgb "yellow"'],
                ytics => {textcolor => 'orange'},
                xdata => 'time',
                xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
                label => [1, $self->brand, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
                %addon_gen,
            },
            {
                with => 'candlesticks',
                linecolor => 'white',
                legend => 'Price',
            },
            $data(,(0)), $data(,(1)), $data(,(2)), $data(,(3)), $data(,(4)),
            @general_plot,
            @candle_plot,
        );
        if (@addon_plot) {
            $pwin->plot({
                    %binmode,
                    object => '1',
                    title => '',
                    key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                    border => 'linecolor rgbcolor "white"',
                    ylabel => '',
                    xlabel => '',
                    xtics => '',
                    ytics => {textcolor => 'orange'},
                    bmargin => 0,
                    tmargin => 0,
                    lmargin => 9,
                    rmargin => 2,
                    size => ["1,0.3"], #bug in P:G:G
                    origin => [0, 0],
                    label => [1, "", at => "graph 0.90,0.03"],
                },
                @addon_plot,
            );
        }
    } elsif ($type eq 'CANDLEV') {
        my %addon_gen = ();
        my %addon_vol = ();
        if (@addon_plot) {
            $addon_gen{size} = ["1, 0.6"]; #bug in P:G:G
            $addon_gen{origin} = [0, 0.4];
            $addon_vol{size} = ["1, 0.2"]; #bug in P:G:G
            $addon_vol{origin} = [0, 0];
        } else {
            $addon_gen{size} = ["1, 0.7"]; #bug in P:G:G
            $addon_gen{origin} = [0, 0.3];
            $addon_vol{size} = ["1, 0.3"]; #bug in P:G:G
            $addon_vol{origin} = [0, 0];
            $addon_vol{object} = '1'; # needed as otherwise the addon plot does it
        }
        $pwin->plot({
                %binmode,
                object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
                title => ["$symbol Price & Volume", textcolor => "rgb 'white'"],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                xlabel => ['Date', textcolor => 'rgb "yellow"'],
                ylabel => ['Price', textcolor => 'rgb "yellow"'],
                xdata => 'time',
                ytics => {textcolor => 'orange'},
                xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
                tmargin => '',
                bmargin => 0,
                lmargin => 9,
                rmargin => 2,
                %addon_gen,
                label => [1, $self->brand, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
            },
            {
                with => 'candlesticks',
                linecolor => 'white',
                legend => 'Price',
            },
            $data(,(0)), $data(,(1)), $data(,(2)), $data(,(3)), $data(,(4)),
            @general_plot,
            @candle_plot,
        );
        if (@addon_plot) {
            $pwin->plot({
                    %binmode,
                    object => '1',
                    title => '',
                    key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                    border => 'linecolor rgbcolor "white"',
                    ylabel => '',
                    xlabel => '',
                    xtics => '',
                    ytics => {textcolor => 'orange'},
                    bmargin => 0,
                    tmargin => 0,
                    lmargin => 9,
                    rmargin => 2,
                    size => ["1,0.2"], #bug in P:G:G
                    origin => [0, 0.2],
                    label => [1, "", at => "graph 0.90,0.03"],
                },
                @addon_plot,
            );
        }
        $pwin->plot({
                %binmode,
                title => '',
                ylabel => ['Volume (in 1M)', textcolor => 'rgb "yellow"'],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                xtics => '',
                xlabel => '',
                ytics => {textcolor => 'orange'},
                bmargin => 0,
                tmargin => 0,
                lmargin => 9,
                rmargin => 2,
                %addon_vol,
                label => [1, "", at => "graph 0.90,0.03"],
            },
            {
                with => 'impulses',
                legend => 'Volume',
                linecolor => 'cyan',
            },
            $data(,(0)), $data(,(5)) / 1e6,
            @volume_plot,
        );
    } elsif ($type eq 'CLOSEV') {
        my %addon_gen = ();
        my %addon_vol = ();
        if (@addon_plot) {
            $addon_gen{size} = ["1, 0.6"]; #bug in P:G:G
            $addon_gen{origin} = [0, 0.4];
            $addon_vol{size} = ["1, 0.2"]; #bug in P:G:G
            $addon_vol{origin} = [0, 0];
        } else {
            $addon_gen{size} = ["1, 0.7"]; #bug in P:G:G
            $addon_gen{origin} = [0, 0.3];
            $addon_vol{size} = ["1, 0.3"]; #bug in P:G:G
            $addon_vol{origin} = [0, 0];
            $addon_vol{object} = '1'; # needed as otherwise the addon plot does it
        }
        $pwin->plot({
                %binmode,
                object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
                title => ["$symbol Price & Volume", textcolor => "rgb 'white'"],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                ylabel => ['Close Price', textcolor => 'rgb "yellow"'],
                xlabel => ['Date', textcolor => 'rgb "yellow"'],
                xdata => 'time',
                xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
                ytics => {textcolor => 'orange'},
                bmargin => 0,
                lmargin => 9,
                rmargin => 2,
                %addon_gen,
                label => [1, $self->brand, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
            },
            {
                with => 'lines',
                linecolor => 'white',
                legend => 'Close Price',
            },
            $data(,(0)), $data(,(4)),
            @general_plot,
        );
        if (@addon_plot) {
            $pwin->plot({
                    %binmode,
                    object => '1',
                    title => '',
                    key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                    border => 'linecolor rgbcolor "white"',
                    ylabel => '',
                    xlabel => '',
                    xtics => '',
                    ytics => {textcolor => 'orange'},
                    bmargin => 0,
                    tmargin => 0,
                    lmargin => 9,
                    rmargin => 2,
                    size => ["1,0.2"], #bug in P:G:G
                    origin => [0, 0.2],
                    label => [1, "", at => "graph 0.90,0.03"],
                },
                @addon_plot,
            );
        }
        $pwin->plot({
                %binmode,
                title => '',
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                ylabel => ['Volume (in 1M)', textcolor => 'rgb "yellow"'],
                xlabel => '',
                xtics => '',
                ytics => {textcolor => 'orange'},
                bmargin => 0,
                tmargin => 0,
                lmargin => 9,
                rmargin => 2,
                %addon_vol,
                label => [1, "", at => "graph 0.90,0.03"],
            },
            {
                with => 'impulses',
                legend => 'Volume',
                linecolor => 'cyan',
            },
            $data(,(0)), $data(,(5)) / 1e6,
            @volume_plot,
        );
    } else {
        $type = 'CLOSE';
        my %addon_gen = ();
        if (@addon_plot) {
            $addon_gen{size} = ["1, 0.7"];
            $addon_gen{origin} = [0, 0.3];
            $addon_gen{bmargin} = 0;
            $addon_gen{lmargin} = 9;
            $addon_gen{rmargin} = 2;
        }
        $pwin->plot({
                %binmode,
                object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
                title => ["$symbol Close Price", textcolor => 'rgb "white"'],
                key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                border => 'linecolor rgbcolor "white"',
                xlabel => ['Date', textcolor => 'rgb "yellow"'],
                ylabel => ['Close Price', textcolor => 'rgb "yellow"'],
                xdata => 'time',
                xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
                ytics => {textcolor => 'orange'},
                label => [1, $self->brand, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
                %addon_gen,
            },
            {
                with => 'lines',
                linecolor => 'white',
                legend => 'Close Price',
            },
            $data(,(0)), $data(,(4)),
            @general_plot,
        );
        if (@addon_plot) {
            $pwin->plot({
                    %binmode,
                    object => '1',
                    title => '',
                    key => ['on', 'outside', textcolor => 'rgb "yellow"'],
                    border => 'linecolor rgbcolor "white"',
                    ylabel => '',
                    xlabel => '',
                    xtics => '',
                    ytics => {textcolor => 'orange'},
                    bmargin => 0,
                    tmargin => 0,
                    lmargin => 9,
                    rmargin => 2,
                    size => ["1,0.3"], #bug in P:G:G
                    origin => [0, 0],
                    label => [1, "", at => "graph 0.90,0.03"],
                },
                @addon_plot,
            );
        }
    }
    $pwin->end_multi;
    # make the current plot type the type
    $self->current->{plot_type} = $type if defined $type;
}

1;
__END__
### COPYRIGHT: 2013-2023. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 3rd Jan 2014
### LICENSE: Refer LICENSE file
