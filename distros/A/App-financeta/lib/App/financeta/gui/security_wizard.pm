package App::financeta::gui::security_wizard;
use strict;
use warnings;
use 5.10.0;

use App::financeta::mo;
use App::financeta::utils qw(dumper log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use Prima qw(
    Application Buttons MsgBox Calendar Label InputLine ComboBox
    sys::GUIException Utils
);
use Try::Tiny;
use DateTime;
use Browser::Open ();

$|=1;

has owner => undef;
has gui => (required => 1);
has wizard => ( builder => '_build_wizard' );

sub run {
    my $self = shift;
    my $w = $self->wizard;
    my $res = $w->execute();
    $w->end_modal;
    return $res;
}

sub _build_wizard {
    my $self = shift;
    my $gui = $self->gui;
    $log->debug("GUI reference in security_wizard: " . ref($gui));
    my $w_x0 = 50;
    my $w_y0 = 50;
    my $sz_x = 800;
    my $sz_y = 600;
    my $w = Prima::Dialog->new(
        name => 'sec_wizard',
        centered => 1,
        origin => [$w_x0, $w_y0],
        size => [$sz_x, $sz_y],
        text => 'Security Wizard',
        icon => $gui->icon,
        visible => 1,
        taskListed => 0,
        onExecute => sub {
            my $dlg = shift;
            $dlg->input_source->focusedItem($gui->current->{source_index} // 0);
            my $sec = $gui->current->{symbol} || '';
            $dlg->input_symbol->text($sec);
            $dlg->btn_ok->enabled(length($sec) ? 1 : 0);
            $dlg->btn_cancel->enabled(1);
            if ($gui->current->{start_date}) {
                my $dt = $gui->current->{start_date};
                $dlg->cal_start->date($dt->day, $dt->month - 1, $dt->year - 1900);
            } else {
                $dlg->cal_start->date_from_time(gmtime);
                # reduce 1 year
                my $yr = $dlg->cal_start->year;
                $dlg->cal_start->year($yr - 1);
            }
            if ($gui->current->{end_date}) {
                my $dt = $gui->current->{end_date};
                $dlg->cal_end->date($dt->day, $dt->month - 1, $dt->year - 1900);
            } else {
                $dlg->cal_end->date_from_time(gmtime);
            }
            $dlg->chk_force_download->checked(0);
            $gui->current->{force_download} = 0;
        },
    );
    my $pwin = $self->owner;
    $w->owner($pwin) if defined $pwin;
    $w->insert(
        Label => text => 'Select Source',
        name => 'label_source',
        alignment => ta::Left,
        autoHeight => 1,
        origin => [ 20, $sz_y - 40],
        autoWidth => 1,
        font => { height => 14, style => fs::Bold },
        hint => 'Stock symbols are available at Yahoo! Finance',
    );
    $w->insert(
        ComboBox => name => 'input_source',
        style => cs::DropDownList,
        multiSelect => 0,
        alignment => ta::Left,
        width => 200,
        height => 30,
        autoTab => 1,
        origin => [ 200, $sz_y - 40],
        font => { height => 16 },
        items => $gui->list_sources_pretty,
        selectedItems => [0],
        onChange => sub {
            my $inp = shift;
            my $idx = $inp->focusedItem;
            $gui->current->{source_index} = $idx;
            $log->info("Selected input source index: $idx");
        },
    );
    $w->insert(
        Label => text => 'Enter Security Symbol',
        name => 'label_symbol',
        alignment => ta::Left,
        autoHeight => 1,
        origin => [ 20, $sz_y - 80],
        autoWidth => 1,
        font => { height => 14, style => fs::Bold },
        hint => 'Stock symbols are available at Yahoo! Finance',
    );
    $w->insert(
        InputLine => name => 'input_symbol',
        alignment => ta::Left,
        autoHeight => 1,
        width => 160,
        autoTab => 1,
        maxLen => 10,
        origin => [ 200, $sz_y - 80],
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
        origin => [$sz_x - 100, $sz_y - 80],
        default => 0,
        enabled => 1,
        font => { height => 12, style => fs::Bold },
        onClick => sub {
            my $owner = shift->owner;
            my $arr = $gui->list_sources_urls;
            my $idx = $owner->input_source->focusedItem;
            my $url = $arr->[$idx // 0];
            $log->info("Opening URL $url");
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
        origin => [ 20, $sz_y - 220 ],
        font => { height => 14, style => fs::Bold },
    );
    $w->insert(
        Calendar => name => 'cal_start',
        useLocale => 1,
        size => [ 220, 200 ],
        origin => [ 20, $sz_y - 440 ],
        font => { height => 16 },
        onChange => sub {
            my $cal = shift;
            $gui->current->{start_date} = DateTime->new(
                year => 1900 + $cal->year(),
                month => 1 + $cal->month(),
                day => $cal->day(),
                time_zone => $gui->timezone,
            );
        },
    );
    $w->insert(
        Label => text => 'Select End Date',
        name => 'label_enddate',
        alignment => ta::Center,
        autoHeight => 1,
        autoWidth => 1,
        origin => [ $sz_x / 2, $sz_y - 220 ],
        font => { height => 14, style => fs::Bold },
    );
    $w->insert(
        Calendar => name => 'cal_end',
        useLocale => 1,
        size => [ 220, 200 ],
        origin => [ $sz_x / 2, $sz_y - 440 ],
        font => { height => 16 },
        onChange => sub {
            my $cal = shift;
            $gui->current->{end_date} = DateTime->new(
                year => 1900 + $cal->year(),
                month => 1 + $cal->month(),
                day => $cal->day(),
                time_zone => $gui->timezone,
            );
        },
    );
    $w->insert(
        CheckBox => name => 'chk_force_download',
        text => 'Force Download',
        origin => [ 20, $sz_y - 500 ],
        font => { height => 14, style => fs::Bold },
        onCheck => sub {
            my $chk = shift;
            my $owner = $chk->owner;
            if ($chk->checked) {
                $gui->current->{force_download} = 1;
            } else {
                $gui->current->{force_download} = 0;
            }
        },
    );
    $w->insert(
        Button => name => 'btn_csv',
        text => 'Load from CSV',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 200, $sz_y - 500 ],
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
                directory => $gui->tmpdir,
            );
            my $csv = $dlg->fileName if $dlg->execute;
            if (defined $csv and -e $csv) {
                $log->info("You have selected $csv to load");
                if ($owner->label_csv) {
                    $owner->label_csv->text($csv);
                }
                $gui->current->{csv} = $csv;
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
        origin => [ 360, $sz_y - 500 ],
        font => { height => 13, style => fs::Bold },
    );
    $w->insert(
        Button => name => 'btn_cancel',
        text => 'Cancel',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 20, $sz_y - 550 ],
        modalResult => mb::Cancel,
        default => 0,
        enabled => 1,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            delete $gui->current->{symbol};
            delete $gui->current->{start_date};
            delete $gui->current->{end_date};
            delete $gui->current->{force_download};
            delete $gui->current->{csv};
        },
    );
    $w->insert(
        Button => name => 'btn_ok',
        text => 'OK',
        autoHeight => 1,
        autoWidth => 1,
        origin => [ 150, $sz_y - 550 ],
        modalResult => mb::Ok,
        default => 1,
        enabled => 0,
        font => { height => 16, style => fs::Bold },
        onClick => sub {
            my $btn = shift;
            my $owner = $btn->owner;
            $gui->current->{source_index} = $owner->input_source->focusedItem;
            $log->info("Selected input source index: " . $gui->current->{source_index});
            $gui->current->{symbol} = $owner->input_symbol->text;
            $log->info("Selected input symbol: " . $gui->current->{symbol});
            unless (defined $gui->current->{start_date}) {
                my $cal = $owner->cal_start;
                $gui->current->{start_date} = DateTime->new(
                    year => 1900 + $cal->year(),
                    month => 1 + $cal->month(),
                    day => $cal->day(),
                    time_zone => $gui->timezone,
                );
            }
            unless (defined $gui->current->{end_date}) {
                my $cal = $owner->cal_end;
                $gui->current->{end_date} = DateTime->new(
                    year => 1900 + $cal->year(),
                    month => 1 + $cal->month(),
                    day => $cal->day(),
                    time_zone => $gui->timezone,
                );
            }
        },
    );
    return $w;
}


1;
__END__
### COPYRIGHT: 2013-2025. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 30th Aug 2014
### LICENSE: Refer LICENSE file
