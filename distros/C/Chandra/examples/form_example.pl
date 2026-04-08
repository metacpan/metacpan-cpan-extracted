#!/usr/bin/env perl
#
# Example: Form API — build and render a settings form with two-way binding
#
# Demonstrates Chandra::Form with field types, groups, validation feedback,
# change handlers, and form submission via the webview bridge.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra::App;
use Chandra::Form;

my $app = Chandra::App->new(
    title  => 'Form Example',
    width  => 520,
    height => 700,
    debug  => 1,
);

# ---- Build the form ----

my $form = Chandra::Form->new(
    id     => 'settings',
    action => sub {
        my ($data) = @_;
        print "[Perl] Form submitted:\n";
        for my $key (sort keys %$data) {
            printf "  %-15s => %s\n", $key, $data->{$key} // '';
        }

        # Show a success message in the UI
        $app->dispatch_eval(qq{
            var msg = document.getElementById('result');
            msg.textContent = 'Settings saved!';
            msg.style.display = 'block';
            setTimeout(function(){ msg.style.display='none'; }, 3000);
        });
    },
);

$form->text('username', {
    label       => 'Username',
    placeholder => 'Enter your username',
    required    => 1,
    value       => 'alice',
    maxlength   => 50,
});

$form->email('email', {
    label => 'Email Address',
    value => 'alice@example.com',
});

$form->password('password', {
    label       => 'New Password',
    minlength   => 8,
    placeholder => 'Leave blank to keep current',
});

$form->group('Appearance' => sub {
    $form->select('theme', {
        label   => 'Theme',
        options => [
            { value => 'light', label => 'Light' },
            { value => 'dark',  label => 'Dark' },
            { value => 'auto',  label => 'System' },
        ],
        value => 'dark',
    });

    $form->number('font_size', {
        label => 'Font Size (px)',
        min   => 8,
        max   => 72,
        step  => 1,
        value => 14,
    });

    $form->range('opacity', {
        label => 'UI Opacity',
        min   => 20,
        max   => 100,
        value => 90,
    });
});

$form->group('Notifications' => sub {
    $form->checkbox('notify_email', {
        label   => 'Email notifications',
        checked => 1,
    });

    $form->checkbox('notify_desktop', {
        label => 'Desktop notifications',
    });

    $form->radio('frequency', {
        label   => 'Digest Frequency',
        options => [
            { value => 'instant', label => 'Instant' },
            { value => 'daily',   label => 'Daily' },
            { value => 'weekly',  label => 'Weekly' },
        ],
        value => 'daily',
    });
});

$form->textarea('bio', {
    label => 'Biography',
    rows  => 4,
    value => 'Hello, I am Alice.',
});

$form->hidden('csrf_token', { value => 'abc123def456' });

$form->submit('Save Settings');

# ---- Change handlers ----

$form->on_change(sub {
    my ($field, $value) = @_;
    print "[Perl] Changed: $field => $value\n";
});

$form->on_change('theme', sub {
    my ($value) = @_;
    print "[Perl] Theme switched to: $value\n";
    my $bg = $value eq 'dark' ? '#1e1e1e' : '#ffffff';
    my $fg = $value eq 'dark' ? '#d4d4d4' : '#333333';
    $app->dispatch_eval(qq{
        document.body.style.background = '$bg';
        document.body.style.color      = '$fg';
    });
});

# ---- CSS ----

my $css = <<'CSS';
<style>
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    margin: 0; padding: 24px;
    background: #1e1e1e; color: #d4d4d4;
    transition: background 0.3s, color 0.3s;
  }
  h1 { font-size: 20px; margin: 0 0 16px; }
  .chandra-form { max-width: 460px; }
  .chandra-field { margin-bottom: 14px; }
  .chandra-label {
    display: block; margin-bottom: 4px;
    font-size: 13px; font-weight: 600;
  }
  input[type="text"], input[type="email"], input[type="password"],
  input[type="number"], select, textarea {
    width: 100%; padding: 8px 10px;
    font-size: 14px; border: 1px solid #555;
    border-radius: 4px; background: #2d2d2d; color: #d4d4d4;
  }
  input[type="range"] { width: 100%; }
  .chandra-field-checkbox, .chandra-radio-option {
    display: flex; align-items: center; gap: 8px;
    font-size: 14px;
  }
  .chandra-radio-option { margin: 4px 0; }
  fieldset.chandra-group {
    border: 1px solid #444; border-radius: 6px;
    padding: 12px 14px; margin: 16px 0;
  }
  fieldset.chandra-group legend {
    font-size: 14px; font-weight: 600; padding: 0 6px;
  }
  .chandra-submit {
    padding: 10px 28px; font-size: 14px; font-weight: 600;
    background: #0078d4; color: #fff; border: none;
    border-radius: 4px; cursor: pointer; margin-top: 8px;
  }
  .chandra-submit:hover { background: #106ebe; }
  .chandra-error {
    display: block; font-size: 12px; color: #f44;
    min-height: 16px; margin-top: 2px;
  }
  #result {
    display: none; margin-top: 12px; padding: 10px;
    background: #1b5e20; border-radius: 4px;
    font-size: 14px; text-align: center;
  }
</style>
CSS

# ---- Render and launch ----

my $html = $css
    . "<h1>Settings</h1>"
    . $form->render
    . '<div id="result"></div>';

$app->set_content($html);

# Attach form to app — binds bridge events and injects two-way binding JS
$form->attach($app);

print "Starting form example...\n";
$app->run;
print "Done.\n";
