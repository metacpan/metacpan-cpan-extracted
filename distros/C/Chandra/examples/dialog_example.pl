#!/usr/bin/env perl
#
# Example: Native Dialogs using Chandra::Dialog
#
# Demonstrates file open, save, directory picker, and alert dialogs.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;

my $app = Chandra::App->new(
    title  => 'Dialog Example',
    width  => 500,
    height => 400,
    debug  => 1,
);

# Bind dialog actions to Perl
$app->bind('open_file_dialog', sub {
    my $path = $app->dialog->open_file(title => 'Select a File');
    if (defined $path) {
        print "[Perl] File selected: $path\n";
        return { success => 1, path => $path };
    }
    return { success => 0, message => 'Cancelled' };
});

$app->bind('open_directory_dialog', sub {
    my $dir = $app->dialog->open_directory(title => 'Select a Directory');
    if (defined $dir) {
        print "[Perl] Directory selected: $dir\n";
        return { success => 1, path => $dir };
    }
    return { success => 0, message => 'Cancelled' };
});

$app->bind('save_file_dialog', sub {
    my $path = $app->dialog->save_file(
        title   => 'Save File As',
        default => 'document.txt',
    );
    if (defined $path) {
        print "[Perl] Save path: $path\n";
        return { success => 1, path => $path };
    }
    return { success => 0, message => 'Cancelled' };
});

$app->bind('show_info', sub {
    $app->dialog->info(
        title   => 'Information',
        message => 'This is an informational message.',
    );
    return { shown => 'info' };
});

$app->bind('show_warning', sub {
    $app->dialog->warning(
        title   => 'Warning',
        message => 'This is a warning message!',
    );
    return { shown => 'warning' };
});

$app->bind('show_error', sub {
    $app->dialog->error(
        title   => 'Error',
        message => 'Something went wrong!',
    );
    return { shown => 'error' };
});

$app->set_content(<<'HTML');
<!DOCTYPE html>
<html>
<head>
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        padding: 24px;
        background: #f5f5f5;
    }
    h1 {
        color: #2c3e50;
        margin-bottom: 20px;
    }
    .section {
        background: #fff;
        border-radius: 8px;
        padding: 16px;
        margin-bottom: 16px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .section h2 {
        font-size: 14px;
        color: #666;
        margin-bottom: 12px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    button {
        background: #3498db;
        color: #fff;
        border: none;
        padding: 10px 16px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 14px;
        margin-right: 8px;
        margin-bottom: 8px;
    }
    button:hover {
        background: #2980b9;
    }
    button.warning {
        background: #f39c12;
    }
    button.warning:hover {
        background: #d68910;
    }
    button.error {
        background: #e74c3c;
    }
    button.error:hover {
        background: #c0392b;
    }
    button.success {
        background: #27ae60;
    }
    button.success:hover {
        background: #1e8449;
    }
    #result {
        margin-top: 16px;
        padding: 12px;
        background: #ecf0f1;
        border-radius: 4px;
        font-family: monospace;
        font-size: 13px;
        white-space: pre-wrap;
        min-height: 60px;
    }
</style>
</head>
<body>
    <h1>Dialog Examples</h1>

    <div class="section">
        <h2>File Dialogs</h2>
        <button class="success" onclick="openFile()">Open File</button>
        <button class="success" onclick="openDir()">Open Directory</button>
        <button onclick="saveFile()">Save File</button>
    </div>

    <div class="section">
        <h2>Alert Dialogs</h2>
        <button onclick="showInfo()">Info</button>
        <button class="warning" onclick="showWarning()">Warning</button>
        <button class="error" onclick="showError()">Error</button>
    </div>

    <div id="result">Click a button to test dialogs...</div>

    <script>
        function updateResult(text) {
            document.getElementById('result').textContent = text;
        }

        async function openFile() {
            updateResult('Opening file dialog...');
            const result = await window.chandra.invoke('open_file_dialog');
            if (result.success) {
                updateResult('Selected file:\n' + result.path);
            } else {
                updateResult('File dialog cancelled');
            }
        }

        async function openDir() {
            updateResult('Opening directory dialog...');
            const result = await window.chandra.invoke('open_directory_dialog');
            if (result.success) {
                updateResult('Selected directory:\n' + result.path);
            } else {
                updateResult('Directory dialog cancelled');
            }
        }

        async function saveFile() {
            updateResult('Opening save dialog...');
            const result = await window.chandra.invoke('save_file_dialog');
            if (result.success) {
                updateResult('Save path:\n' + result.path);
            } else {
                updateResult('Save dialog cancelled');
            }
        }

        async function showInfo() {
            updateResult('Showing info dialog...');
            await window.chandra.invoke('show_info');
            updateResult('Info dialog closed');
        }

        async function showWarning() {
            updateResult('Showing warning dialog...');
            await window.chandra.invoke('show_warning');
            updateResult('Warning dialog closed');
        }

        async function showError() {
            updateResult('Showing error dialog...');
            await window.chandra.invoke('show_error');
            updateResult('Error dialog closed');
        }
    </script>
</body>
</html>
HTML

print "Starting Dialog Example...\n";
print "Click the buttons to test native dialogs.\n";

$app->run;
