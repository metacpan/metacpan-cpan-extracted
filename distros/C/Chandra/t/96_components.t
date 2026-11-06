#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::Component;
use Chandra::Theme;
use Chandra::Notify;
use Chandra::Tabs;
use Chandra::Nav;
use Chandra::Breadcrumb;
use Chandra::Table;
use Chandra::Form;
use Chandra::Form::Validator;

# An app that records what the components ask of it.
package MockCompApp;
our (%bound, @updates, @evals, @navigated, @css);
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }
sub update { my ($self, $sel, $html) = @_; push @updates, [$sel, $html]; return $self }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }
sub navigate { my ($self, $route) = @_; push @navigated, $route; return $self }
sub css { my ($self, $css) = @_; push @css, $css; return $self }

package MockNoNav;
sub new { bless {}, shift }
sub bind { $_[0] }
sub update { $_[0] }
sub eval { 1 }

package Widget;
use Object::Proto;
BEGIN {
    Object::Proto::define('Widget', extends => 'Chandra::Component', 'label:Str:default(w)');
    Object::Proto::import_accessors('Widget');
}
our @events;
sub render { my ($self) = @_; return '<div class="widget"><button data-action="poke:1">' . $self->label . '</button><input data-action="typed"><select data-action="picked"></select></div>' }
sub on_mount { push @events, 'mount' }
sub on_unmount { push @events, 'unmount' }
sub on_update { push @events, 'update' }
sub on_poke { push @events, "poke:@_[1..$#_]"; return 'poked' }

package main;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

# --- the component life cycle with a mock app ---
{
    Chandra::Component->reset;
    %MockCompApp::bound = ();
    @MockCompApp::updates = ();
    @MockCompApp::evals = ();
    my $app = MockCompApp->new;
    my $parent = Chandra::Component->new;
    my $child = Widget->new(label => 'kid');
    is($parent->child($child), $parent, 'child returns the parent');
    like($parent->render, qr/<div id="_comp_\d+"><div id="_comp_\d+" class="widget">/, 'the base render wraps the children, each stamped with its id');
    is($parent->update, $parent, 'update before mounting does nothing');
    is($parent->update_part('x', '<b>'), $parent, 'and so does update_part');
    is($parent->mount($app, '#root'), $parent, 'mount returns the component');
    is(scalar @MockCompApp::updates, 2, 'the parent and the child were rendered into the app');
    is($MockCompApp::updates[0][0], '#root', 'the parent into the selector');
    like($MockCompApp::updates[1][0], qr/^#_comp_\d+$/, 'the child into its own id');
    is_deeply(\@Widget::events, ['mount'], 'the child saw on_mount');
    my ($action) = grep { /^_comp_action_/ } keys %MockCompApp::bound;
    ok($action, 'an action dispatcher is bound per component');
    my $child_cid = $child->_cid;
    is($MockCompApp::bound{"_comp_action_$child_cid"}->('poke', 7), 'poked', 'an action reaches its handler with its arguments');
    is($Widget::events[-1], 'poke:7', 'and the handler saw them');
    ok(!defined $MockCompApp::bound{"_comp_action_$child_cid"}->('missing'), 'an unknown action gives undef');
    like($warned[-1], qr/no handler 'on_missing' on Widget/, 'and warns');
    like($MockCompApp::updates[1][1], qr/onclick="window\.chandra\.invoke\(&quot;_comp_action_$child_cid&quot;,\[&quot;poke&quot;,&quot;1&quot;\]\)"/, 'a button action becomes an onclick');
    like($MockCompApp::updates[1][1], qr/oninput="clearTimeout/, 'an input action is debounced');
    like($MockCompApp::updates[1][1], qr/onchange="var _a=/, 'a select action fires on change');
    is($child->update, $child, 'update on a mounted component');
    is($MockCompApp::updates[-1][0], "#$child_cid", 'replaces its own element');
    is($Widget::events[-1], 'update', 'and runs on_update');
    $child->update_part('sub', '<b data-action="poke:2">x</b>');
    like($MockCompApp::updates[-1][1], qr/onclick=/, 'update_part rewrites the actions in the html given');
    is($child->_rewrite_actions('<p>plain</p>'), '<p>plain</p>', 'html without actions is left alone');
    is(Chandra::Component->find_component($child_cid), $child, 'the registry finds a component by id');
    is($parent->unmount, $parent, 'unmount returns the component');
    is($Widget::events[-1], 'unmount', 'the child saw on_unmount');
    ok(scalar(grep { /getElementById\('$child_cid'\)/ } @MockCompApp::evals), 'and its element is removed');
    ok(!defined Chandra::Component->find_component($child_cid), 'and it leaves the registry');
    my $orphan = Chandra::Component->new;
    $orphan->unmount;
    pass('unmounting an unmounted component is harmless');
    Chandra::Component::comp__cid($orphan, '');
    like($orphan->_ensure_cid, qr/^_comp_\d+$/, 'a component that lost its id gets a new one');
    my $plain = Chandra::Component->new;
    {
        no warnings 'redefine';
        local *Chandra::Component::render = sub { 'bare text' };
        is($plain->_wrap_render, 'bare text', 'a render without a tag is left unstamped');
        local *Chandra::Component::render = sub { '<p>x</p>' };
        like($plain->_wrap_render, qr/^<p id="_comp_\d+">x<\/p>$/, 'a render with a tag but no id is stamped');
    }
}

# --- themes ---
{
    @MockCompApp::css = ();
    my $app = MockCompApp->new;
    is(Chandra::Theme->apply($app, 'auto'), $app, 'the auto theme applies');
    like($MockCompApp::css[-1], qr/prefers-color-scheme: dark/, 'with a dark media block');
    Chandra::Theme->apply($app, { primary => '#000' });
    like($MockCompApp::css[-1], qr/--chandra-primary: #000/, 'a custom theme merges over light');
    Chandra::Theme->apply($app, 'dark');
    like($MockCompApp::css[-1], qr/#14181b/, 'the dark theme');
    @warned = ();
    Chandra::Theme->apply($app, 'nope');
    like($warned[0], qr/unknown theme 'nope', using light/, 'an unknown theme warns and uses light');
    is_deeply([ sort Chandra::Theme->themes ], ['dark', 'light'], 'two built-in themes');
    is(Chandra::Theme->get('light')->{bg}, '#ffffff', 'get returns a copy of a theme');
    ok(!defined Chandra::Theme->get('nope'), 'and undef for an unknown one');
}

# --- notifications without a title ---
{
    @warned = ();
    is(Chandra::Notify->send({ body => 'no title' }), 0, 'send with a hash and no title is 0');
    is(Chandra::Notify->send(body => 'no title'), 0, 'and with a list');
    is(Chandra::Notify->send(title => ''), 0, 'and with an empty title');
    my $n = Chandra::Notify->new(body => 'default body');
    is($n->notify({ title => '' }), 0, 'notify with a hash merges the defaults');
    is($n->notify(title => ''), 0, 'and with a list');
    is(scalar(grep { /title is required/ } @warned), 5, 'each warned');
}

# --- tabs ---
{
    my $app = MockCompApp->new;
    my @changes;
    my $tabs = Chandra::Tabs->new(tabs => [ { label => 'A', content => sub { '<i>a</i>' }, badge => 2 }, { content => '<b>b</b>' }, {} ], on_change => sub { push @changes, [@_] });
    like($tabs->render, qr/<i>a<\/i>/, 'the first tab renders its code content');
    like($tabs->render, qr/Tab 1/, 'a tab without a label is numbered');
    $tabs->mount($app, '#t');
    $tabs->on_select_tab(1);
    is($tabs->active_index, 1, 'selecting a tab moves the index');
    is_deeply(\@changes, [[1, undef]], 'and runs on_change with the index and label');
    like($tabs->render, qr/<b>b<\/b>/, 'a string content renders raw');
    $tabs->on_select_tab(2);
    unlike($tabs->render, qr/<b>b<\/b>/, 'a tab without content renders none');
    $tabs->on_select_tab(-1);
    $tabs->on_select_tab(9);
    is($tabs->active_index, 2, 'indexes out of range are ignored');
    my $quiet = Chandra::Tabs->new(tabs => [ { label => 'only' } ]);
    Chandra::Tabs::tabs__active_index($quiet, 5);
    unlike($quiet->render, qr/chandra-tabs-body"><div/, 'an active index past the tabs renders an empty body');
    $quiet->on_select_tab(0);
    pass('selecting without on_change is fine');
    like(Chandra::Tabs->css, qr/chandra-tabs/, 'tabs have css');
}

# --- navigation ---
{
    @MockCompApp::navigated = ();
    my $app = MockCompApp->new;
    my $nav = Chandra::Nav->new(items => [ { label => 'Home', route => '/', icon => 'h', badge => 1 }, { separator => 1 }, { label => "It's", route => "/it's" }, {} ], collapsible => 1, collapsed => 1);
    like($nav->render, qr/chandra-nav-collapsed/, 'a collapsed nav says so');
    like($nav->render, qr/chandra-nav-toggle/, 'and a collapsible sidebar has a toggle');
    $nav->mount($app, '#n');
    $nav->on_navigate('/');
    is_deeply(\@MockCompApp::navigated, ['/'], 'on_navigate navigates the app');
    like($nav->render, qr/chandra-nav-active/, 'and marks the active item');
    $nav->on_toggle;
    ok(!$nav->collapsed, 'toggle expands');
    $nav->on_toggle;
    ok($nav->collapsed, 'and collapses again');
    my $top = Chandra::Nav->new(items => [ { label => 'x' } ], type => 'topbar', collapsible => 1);
    unlike($top->render, qr/chandra-nav-toggle/, 'a topbar has no toggle');
    my $nonav = Chandra::Nav->new(items => []);
    $nonav->mount(MockNoNav->new, '#x');
    $nonav->on_navigate('/x');
    pass('an app that cannot navigate is left alone');
    like(Chandra::Nav->css, qr/chandra-nav/, 'nav has css');
}

# --- breadcrumbs ---
{
    @MockCompApp::navigated = ();
    my $app = MockCompApp->new;
    my $bc = Chandra::Breadcrumb->new(items => [ { label => 'Home', route => '/' }, { route => "/a'b" }, { label => 'Here' } ]);
    is($bc->separator, "\x{203A}", 'the default separator');
    like($bc->render, qr/chandra-breadcrumb-link.*chandra-breadcrumb-current/s, 'links before the current item');
    my $sep = Chandra::Breadcrumb->new(items => [], separator => '/');
    is($sep->separator, '/', 'a given separator is kept');
    $bc->mount($app, '#b');
    $bc->on_navigate('/');
    is_deeply(\@MockCompApp::navigated, ['/'], 'on_navigate navigates the app');
    my $nonav = Chandra::Breadcrumb->new(items => []);
    $nonav->on_navigate('/x');
    $nonav->mount(MockNoNav->new, '#x');
    $nonav->on_navigate('/x');
    pass('without an app, or one that cannot navigate, nothing happens');
    like(Chandra::Breadcrumb->css, qr/chandra-breadcrumb/, 'breadcrumbs have css');
}

# --- validator script ---
{
    my $f = Chandra::Form->new(id => 'v');
    is(Chandra::Form::Validator->validation_js($f), '', 'no fields, no script');
    $f->{_fields} = 'not a list';
    is(Chandra::Form::Validator->validation_js($f), '', 'fields that are not a list, no script');
    $f->{_fields} = [ 'not a hash', { type => 'text' }, { name => 'h', type => 'hidden' }, { name => 'noopts' }, { name => 'plain', opts => {} } ];
    is(Chandra::Form::Validator->validation_js($f), '', 'fields without rules, no script');
    my $g = Chandra::Form->new(id => 'g');
    $g->text('req', { required => 1 });
    $g->text('labelled', { required => 1, label => 'The label' });
    $g->text('msg', { required => 1, required_msg => 'Say it' });
    $g->text('len', { minlength => 2, maxlength => 4, min => 1, max => 9, pattern => 'a\d', pattern_msg => 'nope' });
    $g->text('len2', { minlength => 2, minlength_msg => 'short', maxlength => 4, maxlength_msg => 'long', min => 1, min_msg => 'low', max => 9, max_msg => 'high', pattern => qr/x/ });
    $g->email('mail', { email_msg => 'bad mail' });
    $g->email('mail2', {});
    my $js = Chandra::Form::Validator->validation_js($g);
    like($js, qr/'req':\[\{type:'required',msg:'req is required'\}\]/, 'a required field is named');
    like($js, qr/The label is required/, 'or labelled');
    like($js, qr/Say it/, 'or given its message');
    like($js, qr/pattern.*a\\\\d.*nope/, 'a string pattern is escaped with its message');
    like($js, qr/short.*long.*low.*high/, 'every length and range message');
    like($js, qr/bad mail/, 'an email message');
    like($js, qr/Invalid email address/, 'and the default one');
    like($js, qr/Must be at least 1\b/, 'the default min message');
    is(Chandra::Form::Validator->validate($g, { req => 'x' })->{labelled}, 'The label is required', 'validate hands to the form');
}

# --- tables ---
{
    @MockCompApp::updates = ();
    my $app = MockCompApp->new;
    my @clicked;
    my @sorted;
    my @selected;
    my @data = map { { n => $_, name => "row $_", flag => $_ % 2, note => ($_ == 3 ? "has, comma \"and quotes\"" : "note$_") } } 1 .. 7;
    my $t = Chandra::Table->new(
        columns => [ { key => 'n', label => 'N', sortable => 1, width => 40 }, { key => 'name', filterable => 1, label => 'Name', filter_options => ['row 1', 'row 2'] }, { key => 'flag', type => 'boolean', label => 'Flag' }, { key => 'note', filterable => 1, label => 'Note', render => sub { uc $_[0] } } ],
        data => \@data, page_size => 3, selectable => 'multi', striped => 1,
        on_row_click => sub { push @clicked, $_[0]{n} }, on_sort => sub { push @sorted, [@_] }, on_selection => sub { push @selected, [@_] },
    );
    like($t->render, qr/chandra-table-filters/, 'filters render');
    like($t->render, qr/Filter Note\.\.\./, 'a text filter has a placeholder');
    like($t->render, qr/All Name/, 'a select filter has an all option');
    like($t->render, qr/width: 40px/, 'a column width');
    like($t->render, qr/\x{e2}\x{9c}\x{93}|\x{2713}/, 'a true boolean is a tick');
    like($t->render, qr/NOTE1/, 'a column renderer runs');
    like($t->render, qr/7 rows, page 1 of 3/, 'pagination counts');
    $t->mount($app, '#t');
    $t->on_sort_column('n');
    $t->on_sort_column('n');
    is_deeply(\@sorted, [['n', 'asc'], ['n', 'desc']], 'sorting a column twice flips it');
    like($t->render, qr/N (?:\x{e2}\x{96}\xbc|\x{25BC})/, 'the arrow shows the direction');
    $t->on_sort_column('name');
    is($t->_visible_data->[0]{name}, 'row 1', 'a text sort');
    $t->on_filter('name', 'row 1');
    is(scalar @{ $t->_visible_data }, 1, 'a filter narrows the rows');
    like($t->render, qr/selected="selected"/, 'the chosen filter option is selected');
    $t->on_filter('name', '');
    $t->on_filter('note', 'NOPE');
    $t->on_filter('note', undef);
    is(scalar @{ $t->_filtered_data }, 7, 'clearing the filters restores the rows');
    $t->_filters->{name} = '';
    is(scalar @{ $t->_filtered_data }, 7, 'an empty filter value matches everything');
    $t->on_page(0);
    is($t->_current_page, 1, 'a page below one is page one');
    $t->on_page(99);
    is($t->_current_page, 3, 'and one past the end is the last');
    like($t->render, qr/&laquo;/, 'the last page has a first-page button');
    $t->on_page(2);
    like($t->render, qr/&raquo;/, 'a middle page has a last-page button');
    $t->on_select_row(0);
    $t->on_select_row(0);
    $t->on_select_row(1);
    is_deeply($selected[-1], [1], 'selecting twice unselects, and the callback sees the selection');
    $t->on_select_all;
    is(scalar($t->selected_rows), 3, 'select all selects the page');
    like($t->render, qr/checked="checked"/, 'and the header box is checked');
    $t->on_select_all;
    is(scalar($t->selected_rows), 0, 'select all again clears');
    $t->on_click_row(0);
    $t->on_click_row(9);
    is(scalar @clicked, 1, 'a click on a row runs the callback once, out of range does not');
    like($t->to_csv, qr/"has, comma ""and quotes"""/, 'csv quotes and doubles');
    $t->set_data([]);
    like($t->render, qr/No data/, 'no rows shows the empty message');
    $t->loading(1);
    like($t->render, qr/Loading\.\.\./, 'and loading shows its row');
    $t->loading(0);

    my $single = Chandra::Table->new(columns => [ { key => 'k' } ], data => [ { k => 'a' }, { k => 'b' } ], selectable => 'single', page_size => 0, striped => 0);
    like($single->render, qr/chandra-table-select/, 'a single-select table has a select column');
    $single->on_select_row(1);
    is_deeply([ $single->selected_rows ], [1], 'single selection replaces');
    $single->on_click_row(0);
    is($single->_total_pages, 1, 'no paging means one page');
    my $none = Chandra::Table->new(columns => [ { key => 'k', label => 'K' } ], data => [ { k => 1 }, { k => 2 } ], selectable => 0);
    $none->on_select_row(0);
    is(scalar($none->selected_rows), 0, 'an unselectable table selects nothing');
    $none->on_sort_column('k');
    is($none->_sorted_data->[0]{k}, 1, 'a numeric sort');
    $none->_sort_key('k');
    $none->_sort_dir('desc');
    is($none->_sorted_data->[0]{k}, 2, 'descending');
    like(Chandra::Table->css, qr/chandra-table/, 'tables have css');
}

done_testing;
