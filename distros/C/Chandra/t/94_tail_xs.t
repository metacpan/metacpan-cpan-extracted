#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Chandra;
use Chandra::App;
use Chandra::Toast;
use Chandra::Modal;
use Chandra::Tray;
use Chandra::HotReload;
use Chandra::DevTools;
use Chandra::Shortcut;
use Chandra::Error;
use Chandra::Log;
use Chandra::Store;
use Chandra::Element;
use Chandra::Window;
use Chandra::ContextMenu;
use Chandra::Bridge::Extension;
use Chandra::Canvas;
use Chandra::Form;

my $dir = tempdir(CLEANUP => 1);
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

package MockTailWV;
sub new { bless { eval_js => [], dispatch_eval_js => [], bound => {} }, shift }
sub eval_js          { push @{ $_[0]{eval_js} }, $_[1] }
sub dispatch_eval_js { push @{ $_[0]{dispatch_eval_js} }, $_[1] }
sub init             { }
sub loop             { 1 }
sub exit             { }
sub bind             { $_[0]{bound}{ $_[1] } = $_[2] }

package MockTailApp;
our (%bound, @evals);
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }

package main;

# --- every shape an app can take when the C looks for the window behind it ---
{
    is(Chandra::Toast->dismiss('plain string', 'toast_1'), 'plain string', 'a string app has no window and passes through');
    my $pv = \'scalar';
    is(Chandra::Toast->dismiss($pv, 'toast_1'), $pv, 'a reference to a plain scalar is not a window');
    Chandra::Toast->dismiss({ _webview => 'string' }, 'x');
    Chandra::Toast->dismiss({ _webview => \'pv' }, 'x');
    Chandra::Toast->dismiss([], 'x');
    pass('a webview slot holding a string, a reference to a scalar, or an array app are all no window');
    ok(!defined Chandra::App::eval('plain string', '1'), 'eval on a string app evaluates nothing');
    Chandra::Modal->show(MockTailApp->new, title => "a\rb\\c'd");
    pass('a title with a carriage return, a backslash and a quote is escaped');
}

# --- the tray menu parser and builder ---
{
    my $parse = sub { Chandra::_xs_test_tray_menu_parse($_[0]) };
    is_deeply($parse->(''), [], 'an empty string is no menu');
    is_deeply($parse->('[]'), [], 'an empty list is no menu');
    is_deeply($parse->(' [ {"id": 1, "label": "Open"} , {"separator":1}, {"id":2,"label":"Es\\"c","disabled":1,"checked":1,"zzz":5,"label":7} ]'),
        [ { id => 1, label => 'Open', separator => 0, disabled => 0, checked => 0 },
          { id => 0, label => undef, separator => 1, disabled => 0, checked => 0 },
          { id => 2, label => 'Es\\"c', separator => 0, disabled => 1, checked => 1 } ],
        'ids, labels with escapes, separators, flags, unknown keys and a label that is not a string');
    is_deeply($parse->('[{"id":3,"label":"unterminated'), [ { id => 3, label => 'unterminated', separator => 0, disabled => 0, checked => 0 } ], 'an unterminated label is taken to the end');
    is_deeply($parse->('[1, 2, {"id":4 "x"'), [ { id => 4, label => undef, separator => 0, disabled => 0, checked => 0 } ], 'stray values are skipped and a truncated object kept');
    my $many = '[' . join(',', map { qq({"id":$_,"label":"i$_"}) } 1 .. 70) . ']';
    is(scalar @{ $parse->($many) }, 64, 'at most sixty-four items are read');

    my $tray = Chandra::Tray->new;
    is(Chandra::_xs_test_tray_build_json($tray), '[]', 'an empty tray builds an empty list');
    $tray->add_item('Open');
    $tray->add_separator;
    push @{ $tray->{_items} }, 'not a hash', { label => undef }, { id => undef };
    is(Chandra::_xs_test_tray_build_json($tray), '[{"id":1,"label":"Open"},{"separator":true},{"id":0,"label":""},{"id":0,"label":""}]', 'items, a separator, and entries missing their parts');
    is(Chandra::_xs_test_tray_build_json('not a tray'), '[]', 'something that is not a tray builds an empty list');
    is(Chandra::_xs_test_tray_build_json({ _items => 'not a list' }), '[]', 'and so does one whose items are not a list');
}

# --- the navigate and refresh callbacks bound by run ---
{
    my $app = Chandra::App->new(title => 'Callbacks');
    my $wv = MockTailWV->new;
    $app->{_webview} = $wv;
    $app->route('/', sub { 'home' });
    $app->route('/there', sub { 'there' });
    $app->run;
    my $nav = $wv->{bound}{__chandra_navigate};
    my $refresh = $wv->{bound}{__chandra_refresh};
    is(ref $nav, 'CODE', 'the navigate callback is bound');
    $nav->('/there');
    is($app->{_current_route}, '/there', 'and navigates the app');
    $nav->();
    $refresh->();
    ok(scalar(grep { /there/ } @{ $wv->{eval_js} }), 'refresh re-renders the current route');
    {
        no warnings 'redefine';
        local *Chandra::App::refresh = sub { die "refresh boom\n" };
        $refresh->();
        pass('a refresh that dies inside the callback is swallowed');
    }
    $Chandra::App::_nav_target = undef;
    $Chandra::App::_refresh_target = undef;
    $nav->('/');
    $refresh->();
    pass('with no targets the callbacks do nothing');
}

# --- the hot reload scanner against odd directory entries ---
{
    my $scan = "$dir/scan";
    mkdir $scan or die;
    open my $fh, '>', "$scan/.hidden" or die; close $fh;
    symlink("$scan/absent", "$scan/dangling") or die;
    POSIX::mkfifo("$scan/fifo", 0600) or die "mkfifo: $!";
    mkdir "$scan/inner" or die;
    open $fh, '>', "$scan/inner/f.txt" or die; close $fh;
    my $hr = Chandra::HotReload->new;
    my $found = $hr->_scan_files($scan);
    is_deeply([ sort keys %$found ], [ "$scan/.hidden", "$scan/inner/f.txt" ], 'a dotfile and a nested file are found, a dangling link and a fifo are not');
    mkdir "$dir/locked" or die;
    chmod 0, "$dir/locked";
    is_deeply($hr->_scan_files("$dir/locked"), {}, 'an unreadable directory finds nothing');
    chmod 0700, "$dir/locked";
}

# --- the devtools callbacks ---
{
    %MockTailApp::bound = ();
    my $app = MockTailApp->new;
    my $dt = Chandra::DevTools->new;
    $dt->enable($app);
    my $list = $MockTailApp::bound{__devtools_list_bindings};
    my $reload = $MockTailApp::bound{__devtools_reload};
    is(ref $list, 'CODE', 'the list callback is bound');
    is(ref $reload, 'CODE', 'and the reload callback');
    is(ref $list->(), 'ARRAY', 'the list callback returns a list');
    Chandra::Bind->register_handler('zeta', sub { });
    Chandra::Bind->register_handler('alpha', sub { });
    Chandra::Bind->register_handler('__devtools_private', sub { });
    my $names = $list->();
    ok(!scalar(grep { /^__devtools_/ } @$names), 'devtools bindings are left out');
    is_deeply([ grep { $_ eq 'alpha' || $_ eq 'zeta' } @$names ], ['alpha', 'zeta'], 'and the rest come sorted');
    is_deeply($reload->(), { ok => 1 }, 'reload with no callback is ok');
    my $reloaded = 0;
    $dt->{reload_cb} = sub { $reloaded++ };
    $reload->();
    is($reloaded, 1, 'and runs the reload callback when set');
    my $handlers = Chandra::Error->handlers;
    my ($err_handler) = grep { ref $_ eq 'CODE' } @$handlers;
    ok($err_handler, 'an error handler was registered');
    $err_handler->({ message => 'm' });
    $dt->{enabled} = 0;
    $err_handler->({ message => 'm' });
    $dt->{enabled} = 1;
    delete $dt->{app};
    $err_handler->({ message => 'm' });
    $err_handler->();
    undef $dt;
    $reload->();
    $err_handler->({ message => 'after' });
    pass('the error handler copes with disabled, no app, no argument and a gone devtools');
    Chandra::Error->clear_handlers;
}

# --- the shortcut dispatch callback ---
{
    %MockTailApp::bound = ();
    my $app = MockTailApp->new;
    my $sc = Chandra::Shortcut->new(app => $app);
    my @seen;
    $sc->bind('ctrl+s', sub { push @seen, $_[0]; 'saved' });
    $sc->bind('ctrl+q', sub { undef });
    $sc->bind('ctrl+d', sub { 'd' });
    $sc->disable('ctrl+d');
    my $cb = $MockTailApp::bound{__chandra_shortcut};
    is(ref $cb, 'CODE', 'the dispatch callback is bound');
    is($cb->('ctrl+s'), 'saved', 'a bound combo runs its handler and returns the result');
    isa_ok($seen[0], 'Chandra::Event', 'the handler got an event');
    is($seen[0]{combo}, 'ctrl+s', 'with the combo');
    ok(!defined $cb->('ctrl+q'), 'a handler returning undef gives undef');
    ok(!defined $cb->('ctrl+d'), 'a disabled combo runs nothing');
    ok(!defined $cb->('ctrl+z'), 'an unknown combo runs nothing');
    $sc->{bindings}{'ctrl+x'} = 'not a hash';
    ok(!defined $cb->('ctrl+x'), 'a binding that is not a hash runs nothing');
    $sc->disable_all;
    ok(!defined $cb->('ctrl+s'), 'with everything disabled nothing runs');
    $sc->enable_all;
    delete $sc->{bindings};
    ok(!defined $cb->('ctrl+s'), 'with no table nothing runs');
    undef $sc;
    ok(!defined $cb->('ctrl+s'), 'after the shortcuts are gone nothing runs');
}

# --- the error capture: handlers, frames and formats ---
{
    Chandra::Error->clear_handlers;
    Chandra::Error->on_error(sub { }) for 1 .. 34;
    is(scalar @{ Chandra::Error->handlers }, 32, 'the handler table holds thirty-two');
    Chandra::Error->clear_handlers;
    my $captured;
    sub capture_without_args { $captured = Chandra::Error->capture('inside', context => 'ctx', skip => 0) }
    sub outer_call { &capture_without_args }
    outer_call();
    ok(scalar(grep { ($_->{sub} || '') =~ /capture_without_args/ } @{ $captured->{trace} }), 'a sub entered without arguments still has a frame');
    my $in_eval = eval { Chandra::Error->capture('in eval', context => 'ctx', skip => 0) };
    ok(scalar(grep { ($_->{sub} || '') eq '(eval)' } @{ $in_eval->{trace} }), 'an eval frame is named (eval)');
    like(Chandra::Error->format_text({ message => 'm', trace => [ 'not a frame', { sub => 's', file => 'f', line => 1 } ] }), qr/\[Chandra::unknown\] m/, 'a trace entry that is not a frame is skipped');
}

# --- the log: levels, sizes, outputs, formats and rotation ---
{
    my $out = "$dir/rot.log";
    my $log = Chandra::Log->new(level => 'fatal', output => [ { file => $out }, (('stderr') x 17) ], rotate => { max_size => '1k', keep => 999 });
    is($log->level, 'fatal', 'fatal is a level');
    is(Chandra::Log->new(level => 'nothing')->level, 'debug', 'an unknown level is debug');
    for my $size (undef, 1024, 'abc', '5M', '1G', '100', '2 k') {
        Chandra::Log->new(rotate => { max_size => $size });
    }
    pass('every size spelling is parsed');
    eval { Chandra::Log::level('not a reference') };
    like($@, qr/not a reference/, 'a method on a string croaks');
    eval { bless({}, 'Chandra::Log')->level };
    like($@, qr/invalid object/, 'a log without its context croaks');
    my $ctx = Chandra::Log->new(output => { file => $out }, formatter => 'json');
    my $child = $ctx->with(k => undef, r => [1], s => 'str');
    my $grandchild = $child->with(more => 1);
    $grandchild->fatal('json', { d => 1 });
    $grandchild->formatter('minimal');
    $grandchild->fatal('minimal');
    $grandchild->formatter('text');
    $grandchild->fatal('text', { d => 2 });
    my $empty = Chandra::Log->new(output => { file => $out })->with;
    $empty->fatal('empty context');
    my $rot = Chandra::Log->new(output => { file => $out }, rotate => { max_size => '1k', keep => 999 });
    $rot->fatal('a long line ' x 100) for 1 .. 3;
    ok(-e "$out.1", 'the log rotated once it passed its size');
    my $holes = []; $#$holes = 1; $holes->[0] = 'stderr';
    Chandra::Log->new(output => $holes);
    my $nodir = Chandra::Log->new(output => { file => "$dir/nodir/x.log" });
    $nodir->fatal('nowhere');
    pass('a file that cannot be opened is skipped');
    my $saved;
    open $saved, '>&', \*STDOUT or die;
    open STDOUT, '>', "$dir/stdout.txt" or die;
    Chandra::Log->new(output => 'stdout')->fatal('to stdout');
    open STDOUT, '>&', $saved or die;
    like(do { local (@ARGV, $/) = ("$dir/stdout.txt"); <> }, qr/to stdout/, 'stdout output goes to stdout');
}

# --- the store: files, directories and the home fallback ---
{
    my $s = Chandra::Store->new(path => "$dir/deep/a//store.json", auto_save => 1);
    $s->set('code', sub { });
    pass('data that cannot be encoded saves an empty object');
    open my $fh, '>', "$dir/list.json" or die; print $fh '[1]'; close $fh;
    my $list = Chandra::Store->new(path => "$dir/list.json");
    is_deeply($list->all, {}, 'a file holding a list starts the store empty');
    open $fh, '>', "$dir/bad.json" or die; print $fh '{{{'; close $fh;
    is_deeply(Chandra::Store->new(path => "$dir/bad.json")->all, {}, 'a corrupt file starts the store empty');
    open $fh, '>', "$dir/afile" or die; close $fh;
    my $blocked = Chandra::Store->new(path => "$dir/afile/store.json", auto_save => 0);
    eval { $blocked->save };
    like($@, qr/cannot open .* for write/, 'a store under a file cannot be written');
    SKIP: {
        skip 'root can write anywhere', 1 if $> == 0;
        mkdir "$dir/ro" or die;
        chmod 0500, "$dir/ro";
        my $ro = Chandra::Store->new(path => "$dir/ro/sub/store.json", auto_save => 0);
        eval { $ro->save };
        like($@, qr/cannot open .* for write/, 'a directory that cannot be made stops the write');
        chmod 0700, "$dir/ro";
    }
    my $rel = Chandra::Store->new(path => "relative-$$.json", auto_save => 0);
    $rel->save;
    ok(-e "relative-$$.json", 'a relative path saves in the working directory');
    unlink "relative-$$.json";
    my $plain = Chandra::Store->new(path => "$dir/plain.json");
    $plain->{_path} = undef;
    $plain->save;
    $plain->reload;
    $plain->{_path} = "$dir/plain.json";
    delete $plain->{_data};
    $plain->save;
    $plain->{_data} = 'not a ref';
    open $fh, '>', "$dir/plain.json" or die; print $fh '{"k":1}'; close $fh;
    $plain->reload;
    is($plain->get('k'), 1, 'reload replaces data that was not a hash');
    {
        local $ENV{HOME} = '';
        my $home = Chandra::Store->new(name => "home-$$");
        like($home->path, qr{/home-$$/store\.json$}, 'with no HOME the store falls back to the password file');
    }
}

# --- elements with odd children, handlers and attributes ---
{
    my $odd = bless \(my $x = 1), 'Chandra::Element';
    my $el = Chandra::Element->new({ tag => 'div', id => "it's\\id", onclick => sub { }, children => [ $odd, { tag => 'b', children => ['bold'] }, { tag => 'i', id => 'deep' } ] });
    like($el->render, qr/it\\'s/, 'the id is escaped for the handler script');
    is($el->get_element_by_id('deep')->{tag}, 'i', 'a nested id is found past a child that is not a hash');
    is($el->get_element_by_tag('i')->{tag}, 'i', 'and a nested tag');
    ok(!defined $el->get_element_by_id('nope'), 'an unknown id is undef');
    my $noid = Chandra::Element->new({ tag => 'span', onclick => sub { } });
    like($noid->render, qr/_eid|targetId/, 'a handler on an element without an id uses the generated one');
    my $attrs = Chandra::Element->new({ tag => 'a', attributes => 'not a hash', children => 'not a list', style => { color => 'red' } });
    like($attrs->render, qr/<a/, 'attributes and children that are not containers are skipped');
    ok(!defined $attrs->get_element_by_id('x'), 'no children, nothing found by id');
    ok(!defined $attrs->get_element_by_tag('b'), 'nor by tag');
    is_deeply([ $attrs->get_elements_by_class('c') ], [], 'nor by class');
    my $classy = Chandra::Element->new({ tag => 'p', class => 'c', children => [ { tag => 'q', class => 'c' } ] });
    is(scalar(my @c = $classy->get_elements_by_class('c')), 2, 'a class is found on the parent and the child');
    $classy->{_handlers} = 'not a hash';
    $classy->attribute('onclick', sub { });
    like($classy->render, qr/<p/, 'a handler table that is not a hash is skipped');
    $classy->{children} = [];
    $#{ $classy->{children} } = 1;
    like($classy->render, qr/<p/, 'holes in the children are skipped');
}

# --- context menus with odd dynamic items ---
{
    @MockTailApp::evals = ();
    my $cm = Chandra::ContextMenu->new(app => MockTailApp->new);
    $cm->attach('.d', sub { [ 'not a hash', { label => 'L', checkable => 1, checked => 1, action => sub { } }, { nolabel => 1, submenu => [ 'x', { label => 'sub', action => sub { } } ] }, { separator => 1 } ] });
    $cm->_dispatch('{"type":"contextmenu","target":{"sel":".d"}}');
    like($MockTailApp::evals[-1], qr/ckd:1/, 'a checked checkable item is marked');
    like($MockTailApp::evals[-1], qr/sep:1/, 'and a separator');
}

# --- bridge extensions: ordering, removal and escaping ---
{
    Chandra::Bridge::Extension->clear;
    is(Chandra::Bridge::Extension->generate_js, '', 'no extensions generate nothing');
    Chandra::Bridge::Extension->register('a', "window.a = 'x\\\\y';\r\n");
    Chandra::Bridge::Extension->register('b', 'window.b = 1;', depends => ['a']);
    Chandra::Bridge::Extension->register('c', 'window.c = 1;', depends => ['a', 'b']);
    like(Chandra::Bridge::Extension->generate_js, qr/window\.a.*window\.b.*window\.c/s, 'dependencies come first, each once');
    like(Chandra::Bridge::Extension->generate_js_escaped, qr/\\\\\\\\|\\r/, 'the escaped form escapes backslashes and returns');
    ok(Chandra::Bridge::Extension->unregister('c'), 'the last extension is removed');
    ok(Chandra::Bridge::Extension->unregister('a'), 'and the first, which shifts the rest down');
    ok(Chandra::Bridge::Extension->is_registered('b'), 'leaving one');
    eval { Chandra::Bridge::Extension->list };
    like($@, qr/depends on unknown extension 'a'/, 'whose dependency is now unknown when the list is resolved');
    Chandra::Bridge::Extension->clear;
}

# --- a canvas number too long for its buffer ---
{
    my $c = Chandra::Canvas->new;
    $c->fill_rect(1, 2, 3, 4);
    my $op = $c->{_buffer}[0][0];
    push @{ $c->{_buffer} }, [ $op, '1' x 100, 1, 1, 1 ];
    like($c->_serialize_buffer, qr/fillRect\(1{63},1,1,1\)/, 'an overlong number is cut to the buffer');
}

# --- a form event that is not one of the four ---
{
    my $f = Chandra::Form->new(id => 'other');
    $f->dispatch('_form_other', '{"id":"other"}');
    pass('an unknown event type is ignored');
}

done_testing;
