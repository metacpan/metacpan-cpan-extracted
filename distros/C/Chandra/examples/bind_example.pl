#!/usr/bin/env perl
#
# Example: Binding Perl functions to JavaScript
#
# This demonstrates how to make Perl functions callable from JavaScript
# using the bind() method and the window.chandra.invoke() API.
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Chandra;

print "Starting Chandra bind example...\n";

# HTML content with JavaScript that calls our Perl functions
my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            padding: 20px;
            background: #f5f5f5;
        }
        h1 { color: #333; }
        .card {
            background: white;
            border-radius: 8px;
            padding: 15px;
            margin: 10px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        button {
            background: rgb(76, 175, 80);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        button:hover { background: rgb(69, 160, 73); }
        input {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            margin: 5px;
        }
        #result {
            margin-top: 10px;
            padding: 10px;
            background: #e8f5e9;
            border-radius: 4px;
            min-height: 20px;
        }
    </style>
</head>
<body>
    <h1>Chandra Bind Example</h1>
    
    <div class="card">
        <h3>Greet</h3>
        <input type="text" id="name" placeholder="Enter your name" value="World">
        <button onclick="callGreet()">Call greet()</button>
    </div>
    
    <div class="card">
        <h3>Add Numbers</h3>
        <input type="number" id="num1" value="10" style="width:60px">
        +
        <input type="number" id="num2" value="20" style="width:60px">
        <button onclick="callAdd()">Call add()</button>
    </div>
    
    <div class="card">
        <h3>Get Time</h3>
        <button onclick="callGetTime()">Call get_time()</button>
    </div>
    
    <div class="card">
        <h3>Reverse String</h3>
        <input type="text" id="str" placeholder="Enter text" value="Hello Perl!">
        <button onclick="callReverse()">Call reverse()</button>
    </div>
    
    <div class="card">
        <h3>Result</h3>
        <div id="result">Click a button above to call a Perl function...</div>
    </div>

    <script>
    BRIDGE_JS
    </script>
    <script>
        function showResult(text) {
            document.getElementById('result').textContent = text;
        }
        
        async function callGreet() {
            const name = document.getElementById('name').value;
            try {
                const result = await window.chandra.invoke('greet', [name]);
                showResult('greet() returned: ' + result);
            } catch (e) {
                showResult('Error: ' + e.message);
            }
        }
        
        async function callAdd() {
            const a = parseInt(document.getElementById('num1').value);
            const b = parseInt(document.getElementById('num2').value);
            try {
                const result = await window.chandra.invoke('add', [a, b]);
                showResult('add(' + a + ', ' + b + ') returned: ' + result);
            } catch (e) {
                showResult('Error: ' + e.message);
            }
        }
        
        async function callGetTime() {
            try {
                const result = await window.chandra.invoke('get_time', []);
                showResult('get_time() returned: ' + result);
            } catch (e) {
                showResult('Error: ' + e.message);
            }
        }
        
        async function callReverse() {
            const str = document.getElementById('str').value;
            try {
                const result = await window.chandra.invoke('reverse', [str]);
                showResult('reverse() returned: ' + result);
            } catch (e) {
                showResult('Error: ' + e.message);
            }
        }
    </script>
</body>
</html>
HTML

# Inject the Chandra bridge JS directly into the HTML
my $bridge = Chandra::Bridge->js_code;
$html =~ s/BRIDGE_JS/$bridge/;

# Minimal URL encoding - only escape essential characters
# Order matters: escape % first, then #
$html =~ s/%/%25/g;
$html =~ s/#/%23/g;
$html =~ s/\n//g;  # Remove newlines for data URL

# Create app with HTML data URL
my $app = Chandra->new(
    title  => 'Chandra Bind Example',
    url    => "data:text/html,$html",
    width  => 600,
    height => 500,
    debug  => 1,
);

# Bind Perl functions that JavaScript can call
$app->bind('greet', sub {
    my ($name) = @_;
    print "[Perl] greet('$name') called\n";
    return "Hello, $name! Greetings from Perl.";
});

$app->bind('add', sub {
    my ($a, $b) = @_;
    print "[Perl] add($a, $b) called\n";
    return $a + $b;
});

$app->bind('get_time', sub {
    print "[Perl] get_time() called\n";
    return scalar localtime();
});

$app->bind('reverse', sub {
    my ($str) = @_;
    print "[Perl] reverse('$str') called\n";
    return scalar reverse($str);
});

# Initialize and run
$app->init;

print "Window opened. Try clicking the buttons!\n";
print "Check this terminal for Perl output.\n";

# Event loop
while ($app->loop(1) == 0) {
    # Could do background work here
}

$app->exit;
print "Done.\n";

=head1 NAME

Chandra Bind Example - Demonstrates binding Perl functions to JavaScript in a Chandra app

=head1 DESCRIPTION

This example shows how to use the C<bind()> method of C<Chandra::App> to make Perl functions callable from JavaScript. The HTML content includes buttons that, when clicked, invoke Perl functions via the C<window.chandra.invoke()> API. The Perl functions perform simple tasks like greeting, adding numbers, getting the current time, and reversing a string, and return results back to JavaScript for display in the UI.

=cut