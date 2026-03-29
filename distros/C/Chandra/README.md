# Chandra - Perl bindings to webview-c

A Perl module for building cross-platform GUI applications using web technologies (HTML/CSS/JS) powered by [webview-c](https://github.com/javalikescript/webview-c).

## Synopsis

```perl
use Chandra;

# Simple usage - one liner
Chandra->new(
    title  => 'Hello World',
    url    => 'https://perl.org',
)->run;

# Using HTML directly
Chandra->new(
    title => 'My App',
    url   => 'data:text/html,<h1>Hello from Perl!</h1><button onclick="external.invoke(\'clicked\')">Click me</button>',
    callback => sub {
        my ($msg) = @_;
        print "JavaScript sent: $msg\n";
    },
)->run;

# Advanced: manual event loop
my $app = Chandra->new(
    title => 'Counter',
    url   => 'data:text/html,<div id="n">0</div>',
    debug => 1,
);

$app->init;

my $count = 0;
while ($app->loop(0) == 0) {
    # Non-blocking loop - could do other Perl work here
    $app->eval_js(sprintf('document.getElementById("n").textContent = %d', ++$count));
    select(undef, undef, undef, 0.1);  # Sleep 100ms
}

$app->exit;
```

## Building

### Prerequisites

**macOS:**
- Xcode Command Line Tools (provides WebKit framework)

**Linux:**
```bash
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

**Windows:**
- MinGW with WebView2 SDK (see webview-c docs)

### Build Steps

```bash
# Build
perl Makefile.PL
make
make test

# Try it
perl -Mblib -e 'use Chandra; Chandra->new(title => "Test", url => "https://perl.org")->run'
```

## API

### Chandra->new(%opts)

Create a new Chandra instance.

| Option | Default | Description |
|--------|---------|-------------|
| title | 'Chandra' | Window title |
| url | 'about:blank' | Initial URL or data: URI |
| width | 800 | Window width |
| height | 600 | Window height |
| resizable | 1 | Allow window resizing |
| debug | 0 | Enable dev tools (right-click inspect) |
| callback | undef | Perl sub for JS -> Perl calls |

### Methods

- `$app->run()` - Simple blocking run
- `$app->init()` - Initialize for manual loop control
- `$app->loop($blocking)` - Process events (returns non-zero to exit)
- `$app->eval_js($code)` - Execute JavaScript
- `$app->set_title($title)` - Change window title
- `$app->terminate()` - Signal loop to exit
- `$app->exit()` - Cleanup

### JS -> Perl Communication

Call `window.external.invoke("message")` from JavaScript. The callback receives the string.

```perl
Chandra->new(
    url => 'data:text/html,<button onclick="external.invoke(JSON.stringify({action:\'save\'}))">Save</button>',
    callback => sub {
        my $data = decode_json($_[0]);
        # Handle $data->{action}
    },
)->run;
```

## License

MIT
