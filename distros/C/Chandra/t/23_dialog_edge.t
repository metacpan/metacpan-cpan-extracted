#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::Dialog');

# Reusable mock helpers
sub _mock_dialog_app {
    my ($calls_ref) = @_;
    my $mock_wv = bless {}, 'MockDlgWV';
    no strict 'refs';
    no warnings 'redefine';
    *MockDlgWV::dialog = sub { shift; push @$calls_ref, [@_]; return undef };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDlgApp';
    no strict 'refs';
    *MockDlgApp::webview = sub { shift->{_wv} };
    use strict 'refs';

    return $mock_app;
}

# === open_directory default title ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->open_directory;
    is($calls[0][2], 'Open Directory', 'default title for open_directory');
}

# === save_file defaults ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->save_file;
    is($calls[0][2], 'Save File', 'default title for save_file');
    is($calls[0][3], '', 'default filename is empty');
}

# === info default title ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->info;
    is($calls[0][2], 'Information', 'default title for info');
    is($calls[0][3], '', 'default message is empty');
}

# === warning default title ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->warning;
    is($calls[0][2], 'Warning', 'default title for warning');
    is($calls[0][3], '', 'default message is empty');
}

# === error default title ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->error;
    is($calls[0][2], 'Error', 'default title for error');
    is($calls[0][3], '', 'default message is empty');
}

# === open_file with filter ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->open_file(filter => '*.txt');
    is($calls[0][3], '*.txt', 'filter passed to open_file');
}

# === open_file with empty filter ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->open_file(filter => '');
    is($calls[0][3], '', 'empty filter passed through');
}

# === warning returns self for chaining ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    my $ret = $dlg->warning(message => 'test');
    is($ret, $dlg, 'warning returns self');
}

# === error returns self for chaining ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    my $ret = $dlg->error(message => 'test');
    is($ret, $dlg, 'error returns self');
}

# === chaining alert dialogs ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->info(message => 'first')
        ->warning(message => 'second')
        ->error(message => 'third');
    is(scalar @calls, 3, 'three chained dialogs called');
    is($calls[0][3], 'first', 'first dialog message');
    is($calls[1][3], 'second', 'second dialog message');
    is($calls[2][3], 'third', 'third dialog message');
}

# === open_file returns undef on cancel ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    my $result = $dlg->open_file;
    ok(!defined $result, 'open_file returns undef when dialog returns undef');
}

# === open_file returns path ===
{
    my $mock_wv = bless {}, 'MockDlgWVPath';
    no strict 'refs';
    *MockDlgWVPath::dialog = sub { return '/home/user/file.txt' };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDlgAppPath';
    no strict 'refs';
    *MockDlgAppPath::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $result = $dlg->open_file;
    is($result, '/home/user/file.txt', 'open_file returns path from dialog');
}

# === save_file returns path ===
{
    my $mock_wv = bless {}, 'MockDlgWVSave';
    no strict 'refs';
    *MockDlgWVSave::dialog = sub { return '/tmp/output.txt' };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDlgAppSave';
    no strict 'refs';
    *MockDlgAppSave::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $result = $dlg->save_file;
    is($result, '/tmp/output.txt', 'save_file returns path from dialog');
}

# === open_directory returns path ===
{
    my $mock_wv = bless {}, 'MockDlgWVDir';
    no strict 'refs';
    *MockDlgWVDir::dialog = sub { return '/home/user/docs' };
    use strict 'refs';

    my $mock_app = bless { _wv => $mock_wv }, 'MockDlgAppDir';
    no strict 'refs';
    *MockDlgAppDir::webview = sub { shift->{_wv} };
    use strict 'refs';

    my $dlg = Chandra::Dialog->new(app => $mock_app);
    my $result = $dlg->open_directory;
    is($result, '/home/user/docs', 'open_directory returns path from dialog');
}

# === Unicode in title and message ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->info(title => 'Información', message => '日本語メッセージ');
    is($calls[0][2], 'Información', 'Unicode title');
    is($calls[0][3], '日本語メッセージ', 'Unicode message');
}

# === Special characters in file filter ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->open_file(filter => '*.{txt,md,rst}');
    is($calls[0][3], '*.{txt,md,rst}', 'brace expansion filter');
}

# === open_directory always passes empty filter ===
{
    my @calls;
    my $dlg = Chandra::Dialog->new(app => _mock_dialog_app(\@calls));
    $dlg->open_directory(title => 'Pick');
    is($calls[0][3], '', 'open_directory filter is always empty');
}

# === constructor without app ===
{
    my $dlg = Chandra::Dialog->new;
    ok($dlg, 'Dialog created without app');
    ok(!$dlg->{app}, 'no app stored');
}

done_testing;
