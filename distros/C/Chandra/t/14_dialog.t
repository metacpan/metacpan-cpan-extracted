#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::Dialog');

# --- Constants ---
{
    is(Chandra::Dialog::TYPE_OPEN(),  0, 'TYPE_OPEN is 0');
    is(Chandra::Dialog::TYPE_SAVE(),  1, 'TYPE_SAVE is 1');
    is(Chandra::Dialog::TYPE_ALERT(), 2, 'TYPE_ALERT is 2');

    is(Chandra::Dialog::FLAG_FILE(),      0, 'FLAG_FILE is 0');
    is(Chandra::Dialog::FLAG_DIRECTORY(),  1, 'FLAG_DIRECTORY is 1');
    is(Chandra::Dialog::FLAG_INFO(),       2, 'FLAG_INFO is 2');
    is(Chandra::Dialog::FLAG_WARNING(),    4, 'FLAG_WARNING is 4');
    is(Chandra::Dialog::FLAG_ERROR(),      6, 'FLAG_ERROR is 6');
}

# --- Constructor ---
{
    my $dlg = Chandra::Dialog->new;
    ok($dlg, 'Dialog created');
    isa_ok($dlg, 'Chandra::Dialog');
}

# --- Constructor with app ---
{
    my $mock = bless {}, 'MockDialogApp';
    my $dlg = Chandra::Dialog->new(app => $mock);
    is($dlg->{app}, $mock, 'app stored');
}

# --- Methods exist ---
{
    my $dlg = Chandra::Dialog->new;
    can_ok($dlg, 'open_file');
    can_ok($dlg, 'open_directory');
    can_ok($dlg, 'save_file');
    can_ok($dlg, 'info');
    can_ok($dlg, 'warning');
    can_ok($dlg, 'error');
}

# --- open_file calls dialog with correct args ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV1';
    no strict 'refs';
    *MockWV1::dialog = sub { shift; push @calls, [@_]; return '/tmp/test.txt' };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp1';
    no strict 'refs';
    *MockDApp1::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $result = $dlg->open_file(title => 'Pick a file');

    is(scalar @calls, 1, 'dialog called once');
    is($calls[0][0], Chandra::Dialog::TYPE_OPEN(), 'type is OPEN');
    is($calls[0][1], Chandra::Dialog::FLAG_FILE(), 'flag is FILE');
    is($calls[0][2], 'Pick a file', 'title passed');
    is($result, '/tmp/test.txt', 'result returned');
}

# --- open_file defaults ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV2';
    no strict 'refs';
    *MockWV2::dialog = sub { shift; push @calls, [@_]; return undef };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp2';
    no strict 'refs';
    *MockDApp2::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    $dlg->open_file;

    is($calls[0][2], 'Open File', 'default title for open_file');
    is($calls[0][3], '', 'default filter is empty');
}

# --- open_directory ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV3';
    no strict 'refs';
    *MockWV3::dialog = sub { shift; push @calls, [@_]; return '/tmp/dir' };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp3';
    no strict 'refs';
    *MockDApp3::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $result = $dlg->open_directory(title => 'Pick Dir');

    is($calls[0][0], Chandra::Dialog::TYPE_OPEN(), 'type is OPEN');
    is($calls[0][1], Chandra::Dialog::FLAG_DIRECTORY(), 'flag is DIRECTORY');
    is($calls[0][2], 'Pick Dir', 'title passed');
    is($result, '/tmp/dir', 'directory result returned');
}

# --- save_file ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV4';
    no strict 'refs';
    *MockWV4::dialog = sub { shift; push @calls, [@_]; return '/tmp/save.txt' };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp4';
    no strict 'refs';
    *MockDApp4::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $result = $dlg->save_file(title => 'Save As', default => 'output.txt');

    is($calls[0][0], Chandra::Dialog::TYPE_SAVE(), 'type is SAVE');
    is($calls[0][1], Chandra::Dialog::FLAG_FILE(), 'flag is FILE');
    is($calls[0][2], 'Save As', 'title passed');
    is($calls[0][3], 'output.txt', 'default filename passed');
    is($result, '/tmp/save.txt', 'save result returned');
}

# --- info ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV5';
    no strict 'refs';
    *MockWV5::dialog = sub { shift; push @calls, [@_]; return undef };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp5';
    no strict 'refs';
    *MockDApp5::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $ret = $dlg->info(title => 'Info', message => 'Hello');

    is($calls[0][0], Chandra::Dialog::TYPE_ALERT(), 'type is ALERT');
    is($calls[0][1], Chandra::Dialog::FLAG_INFO(), 'flag is INFO');
    is($calls[0][2], 'Info', 'title passed');
    is($calls[0][3], 'Hello', 'message passed');
    is($ret, $dlg, 'info returns self');
}

# --- warning ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV6';
    no strict 'refs';
    *MockWV6::dialog = sub { shift; push @calls, [@_] };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp6';
    no strict 'refs';
    *MockDApp6::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    $dlg->warning(message => 'Watch out');

    is($calls[0][1], Chandra::Dialog::FLAG_WARNING(), 'flag is WARNING');
    is($calls[0][3], 'Watch out', 'warning message');
}

# --- error ---
{
    my @calls;
    my $mock_wv = bless {}, 'MockWV7';
    no strict 'refs';
    *MockWV7::dialog = sub { shift; push @calls, [@_] };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDApp7';
    no strict 'refs';
    *MockDApp7::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    $dlg->error(message => 'Broken!');

    is($calls[0][1], Chandra::Dialog::FLAG_ERROR(), 'flag is ERROR');
    is($calls[0][3], 'Broken!', 'error message');
}

done_testing;
