#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# The arms of the Perl conditions and the mock-side XS branches that the
# other tests leave untaken.

use Chandra::App;
use Chandra::Breadcrumb;
use Chandra::Component;
use Chandra::Form;
use Chandra::Form::Validator;
use Chandra::Nav;
use Chandra::Notify;
use Chandra::Table;
use Chandra::Tabs;
use Chandra::Window;

package MockWV;
sub new { my ($class, %o) = @_; bless { eval_js => [], dispatch_eval_js => [], bound => {}, loops => $o{loops} || 0 }, $class }
sub eval_js          { push @{ $_[0]{eval_js} }, $_[1] }
sub dispatch_eval_js { push @{ $_[0]{dispatch_eval_js} }, $_[1] }
sub init             { $_[0]{inits}++ }
sub loop             { my $self = shift; return $self->{loops}-- > 0 ? 0 : 1 }
sub exit             { $_[0]{exits}++ }
sub terminate        { $_[0]{terminated}++ }
sub bind             { $_[0]{bound}{ $_[1] } = $_[2] }
sub set_title        { push @{ $_[0]{titles} }, $_[1] }
sub title            { 'Mock' }

package MockCompApp;
our @updates;
sub new { bless {}, shift }
sub bind { $_[0] }
sub update { my ($self, $sel, $html) = @_; push @updates, [$sel, $html]; return $self }
sub eval { 1 }

package main;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

sub mock_app {
    my %o = @_;
    my $app = Chandra::App->new(title => 'Branches');
    $app->{_webview} = MockWV->new(%o);
    return $app;
}

# --- a component whose app is set but which is not mounted ---
{
    my $c = Chandra::Component->new;
    Chandra::Component::comp__app($c, MockCompApp->new);
    Chandra::Component::comp__mounted($c, 0);
    @MockCompApp::updates = ();
    is($c->update, $c, 'update with an app but unmounted returns the component');
    is($c->update_part('part', '<i>x</i>'), $c, 'and so does update_part');
    is(scalar @MockCompApp::updates, 0, 'neither reached the app');
}

# --- breadcrumb items without a label or a route ---
{
    my $bc = Chandra::Breadcrumb->new(items => [ {}, { route => '/x' }, { label => 'B' }, { route => '/last' } ]);
    my $html = $bc->render;
    like($html, qr/chandra-breadcrumb-current"><\/span>/, 'an item without a route or label renders an empty current span');
    like($html, qr/navigate:\/x/, 'an item with a route links');
    ok(scalar(() = $html =~ /chandra-breadcrumb-current/g) >= 2, 'the last item is current even with a route');
}

# --- tabs with a negative active index ---
{
    my $t = Chandra::Tabs->new(tabs => [ { label => 'only', content => 'c' } ]);
    Chandra::Tabs::tabs__active_index($t, -1);
    unlike($t->render, qr/chandra-tabs-body"><div/, 'a negative active index renders an empty body');
}

# --- a nav navigating while unmounted ---
{
    my $nav = Chandra::Nav->new(items => [ { label => 'x', route => '/x' } ]);
    $nav->on_navigate('/x');
    is(Chandra::Nav::nav__active($nav), '/x', 'navigating without an app still records the route');
}

# --- validator fields of every shape ---
{
    my $f = Chandra::Form->new(id => 'q');
    $f->{_fields} = undef;
    is(Chandra::Form::Validator->validation_js($f), '', 'no field list, no script');
    $f->{_fields} = { not => 'a list' };
    is(Chandra::Form::Validator->validation_js($f), '', 'a field hash, no script');
    $f->{_fields} = [
        { name => 's', type => 'submit' },
        { name => 'g', type => 'group' },
        { name => 'p', opts => { pattern => '\d+' } },
        { name => 'o', opts => 'not a hash' },
    ];
    my $js = Chandra::Form::Validator->validation_js($f);
    unlike($js, qr/'s'|'g'/, 'submit and group fields have no rules');
    like($js, qr/Invalid format/, 'a pattern without a message gets the default');
}

# --- notify with a lone argument that is not a hash ---
{
    @warned = ();
    is(Chandra::Notify->send('just a title'), 0, 'a single string is not a title');
    like($warned[-1], qr/title is required/, 'and is refused');
    {
        no warnings 'redefine';
        local *Chandra::Notify::_xs_send = sub { 42 };
        is(Chandra::Notify->send(title => 'T'), 42, 'a titled notification reaches the sender');
    }
    my $n = Chandra::Notify->new(sound => 1);
    @warned = ();
    is($n->notify('lone'), 0, 'the object form refuses a lone string too');
}

# --- table rows and columns with gaps ---
{
    my @clicked;
    my @rows = ({ n => 1, name => 'b' }, { n => 'x', name => 'a' }, { name => 'c' }, { n => 3 }, { n => 2, name => 'd' }, { n => 4, name => 'e' });
    my $t = Chandra::Table->new(
        columns => [ { key => 'n', label => 'N', sortable => 1 }, { key => 'name', filterable => 1 }, { key => 'flag', type => 'text' }, {} ],
        data => \@rows, page_size => 1,
        on_row_click => sub { push @clicked, $_[0] },
    );
    my $html = $t->render;
    like($html, qr/<th[^>]*>name<\/th>/, 'a column without a label is headed by its key');
    like($html, qr/chandra-table-page-btn/, 'with six pages the page buttons render');
    Chandra::Table::tbl__filters($t)->{name} = undef;
    is(scalar @{ $t->_filtered_data }, 6, 'an undefined filter value filters nothing');
    $t->on_filter('name', 'a');
    is(scalar @{ $t->_filtered_data }, 1, 'and a value filters rows without that key too');
    $t->on_filter('name', '');
    Chandra::Table::tbl__sort_key($t, '');
    is(scalar @{ $t->_sorted_data }, 6, 'an empty sort key leaves the order');
    $t->on_sort_column('n');
    $t->on_sort_column('n');
    $t->on_sort_column('n');
    is(Chandra::Table::tbl__sort_dir($t), 'asc', 'sorting the same column three times is ascending again');
    my @order = map { $_->{n} // '' } @{ $t->_sorted_data };
    is($order[0], '', 'a row without the sort key sorts first');
    $t->on_click_row(-1);
    is(scalar @clicked, 0, 'a click below the first row is ignored');
    my $csv = $t->to_csv;
    like($csv, qr/^N,name,flag,/, 'the csv heads a column by its key when it has no label');
    like($csv, qr/^,c,,/m, 'and leaves a missing cell empty');
}

# --- app paths on the mock side ---
{
    my $app = mock_app();
    like($app->toast('hello', duration => 5), qr/^toast_/, 'a toast with options');
    $app->devtools->enable;
    @{ $app->{_webview}{eval_js} } = ();
    $app->_inject_post_content_js(0);
    ok(scalar @{ $app->{_webview}{eval_js} }, 'enabled devtools inject their script');

    my $empty = mock_app();
    $empty->shortcuts;
    $empty->drag_drop;
    $empty->context_menu_instance;
    $empty->tray(icon => 'i.png');
    $empty->_inject_post_content_js(1);
    pass('empty widgets are walked without a script of their own');
    $empty->run;
    is($empty->tray->{_pending}, 0, 'a tray not shown before run stays down');

    my $quiet = mock_app(loops => 2);
    $quiet->run;
    is($quiet->{_webview}{exits}, 1, 'a polling run without a tick callback ends');

    my $long = mock_app();
    my $name = 'n' x 300;
    is($long->store($name), $long->store($name), 'a store name longer than the cache key is truncated consistently');

    my $gone = mock_app();
    delete $gone->{_webview};
    ok(!defined $gone->webview, 'without a webview entry there is no webview');
    $gone->navigate('/nowhere');
    is($gone->set_title('T'), $gone, 'set_title without a webview entry returns the app');
    $gone->update('#x', 'y');
    $gone->eval('1');
    $gone->dispatch_eval('1');
    $gone->inject_css('a{}');
    $gone->fullscreen(1);
    $gone->set_color(1, 2, 3);
    $gone->refresh;
    pass('the webview-less paths return quietly');

    {
        no warnings 'redefine';
        local *Chandra::Window::new = sub { undef };
        my $w = mock_app();
        ok(!defined $w->open_window(title => 'x'), 'a window that fails to open is undef');
        is($w->window_count, 0, 'and is not tracked');
    }

    my $bare = bless {}, 'Chandra::Window';
    is_deeply([ $bare->get_size ], [0, 0], 'a window without a size reports zeros');
    is_deeply([ $bare->get_position ], [0, 0], 'and without a position too');
}

done_testing;
