# Chandra - Comprehensive Plan

## Overview

A Perl module for building cross-platform GUI applications using web technologies (HTML/CSS/JS) with native chandra rendering. Supports bidirectional Perl ↔ JavaScript communication.

**Backend**: [webview-c](https://github.com/javalikescript/webview-c) (Cocoa/WebKit on macOS, GTK/WebKit2 on Linux, MSHTML/Edge on Windows)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Perl Application                         │
├─────────────────────────────────────────────────────────────────┤
│  Chandra::App                                                   │
│  ├── Window management, lifecycle                               │
│  ├── Event dispatch                                             │
│  └── State management                                           │
├─────────────────────────────────────────────────────────────────┤
│  Chandra::Element (Moonshine::Element-compatible API)           │
│  ├── DOM-like element construction                              │
│  ├── Event handlers (onclick -> Perl subs)                      │
│  └── render() -> HTML                                           │
├─────────────────────────────────────────────────────────────────┤
│  Chandra::Bind                                                  │
│  ├── Perl sub registry                                          │
│  ├── JSON serialization                                         │
│  └── JS->Perl dispatch                                          │
├─────────────────────────────────────────────────────────────────┤
│  Chandra::XS (C layer)                                          │
│  ├── webview_init/loop/exit                                     │
│  ├── webview_eval (Perl -> JS)                                  │
│  └── external.invoke handler (JS -> Perl)                       │
├─────────────────────────────────────────────────────────────────┤
│  webview-c (native layer)                                       │
│  └── Platform-specific chandra implementation                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Structure

```
Chandra/
├── lib/
│   └── Chandra.pm              # Main entry point
│   └── Chandra/
│       ├── App.pm              # Application lifecycle
│       ├── Window.pm           # Window wrapper
│       ├── Element.pm          # DOM builder (Moonshine-compatible)
│       ├── Bind.pm             # JS<->Perl bridge
│       ├── Event.pm            # Event object
│       └── Types.pm            # Type constraints (optional)
├── Chandra.xs                  # XS bindings
├── include/
│   └── webview.h + platform .c files
├── t/
├── examples/
└── Makefile.PL
```

---

## API Design

### 1. Simple One-Liner

```perl
use Chandra;

Chandra->run(
    title => 'My App',
    url   => 'https://example.com',
);
```

### 2. Standard Application

```perl
use Chandra;

my $app = Chandra->new(
    title   => 'My App',
    width   => 800,
    height  => 600,
    debug   => 1,
);

# Build UI with Element API
my $ui = Chandra::Element->new(
    tag   => 'div',
    class => 'container',
    children => [
        { tag => 'h1', data => 'Hello World' },
        { 
            tag     => 'button', 
            data    => 'Click Me',
            onclick => sub {
                my ($event) = @_;
                $app->alert('Button clicked!');
            },
        },
    ],
);

$app->set_content($ui);
$app->run;
```

### 3. Binding Perl Functions to JS

```perl
# Register Perl subs callable from JavaScript
$app->bind('greet', sub {
    my ($name) = @_;
    return "Hello, $name!";
});

$app->bind('save_file', sub {
    my ($path, $content) = @_;
    write_file($path, $content);
    return { success => 1 };
});

# In JavaScript:
# const result = await window.chandra.greet('World');
# const status = await window.chandra.save_file('/tmp/foo', 'bar');
```

### 4. Eval JS from Perl

```perl
# Fire-and-forget
$app->eval('document.body.style.background = "red"');

# With callback (async)
$app->eval('document.title', sub {
    my ($result) = @_;
    print "Title is: $result\n";
});

# Synchronous-ish via event loop
my $title = $app->eval_sync('document.title');
```

---

## Chandra::Element API (Moonshine-Compatible)

The Element API should be familiar to users of Moonshine::Element:

```perl
use Chandra::Element;

my $div = Chandra::Element->new({
    tag   => 'div',
    id    => 'app',
    class => 'container',
    style => { padding => '20px', background => '#fff' },
});

# Add children
my $header = $div->add_child({
    tag  => 'h1',
    data => 'Welcome',
});

# Event handlers are Perl subs
my $btn = $div->add_child({
    tag     => 'button',
    class   => 'btn btn-primary',
    data    => 'Submit',
    onclick => sub {
        my ($event, $app) = @_;
        $app->eval('console.log("Clicked!")');
    },
});

# Query elements
my $h1 = $div->get_element_by_tag('h1');
$h1->data(['Updated Title']);

# Render to HTML
my $html = $div->render;
```

### Event Handler Signature

```perl
onclick => sub {
    my ($event, $app) = @_;
    # $event - Chandra::Event object with:
    #   ->type        # 'click', 'change', etc.
    #   ->target_id   # Element ID that fired
    #   ->target_name # Element name attribute
    #   ->value       # For inputs: current value
    #   ->data        # Custom data-* attributes as hashref
    # $app - Chandra::App instance for calling back
}
```

### Supported Event Attributes

| Attribute | Trigger |
|-----------|---------|
| onclick | Click |
| onchange | Value change (inputs/selects) |
| onsubmit | Form submission |
| onkeyup/onkeydown | Keyboard |
| oninput | Real-time input |
| onfocus/onblur | Focus changes |
| onmouseover/onmouseout | Hover |

---

## JS ↔ Perl Bridge Protocol

### JS → Perl (via external.invoke)

```javascript
// Injected into every page:
window.chandra = {
    _callbacks: {},
    _id: 0,
    
    invoke: function(method, args) {
        return new Promise((resolve, reject) => {
            const id = ++this._id;
            this._callbacks[id] = { resolve, reject };
            window.external.invoke(JSON.stringify({
                type: 'call',
                id: id,
                method: method,
                args: args
            }));
        });
    },
    
    _resolve: function(id, result, error) {
        const cb = this._callbacks[id];
        delete this._callbacks[id];
        if (error) cb.reject(error);
        else cb.resolve(result);
    },
    
    // Event bridge
    _event: function(handlerId, eventData) {
        window.external.invoke(JSON.stringify({
            type: 'event',
            handler: handlerId,
            event: eventData
        }));
    }
};
```

### Perl → JS (via webview_eval)

```perl
# To return results to JS promises:
$app->eval(sprintf(
    'window.chandra._resolve(%d, %s, null)',
    $call_id,
    encode_json($result)
));
```

---

## Implementation Phases

### Phase 1: Core XS Layer ✓ (Prototype done)
- [x] webview_run (blocking one-liner)
- [x] webview_init/loop/exit (event loop control)
- [x] webview_eval (Perl → JS)
- [x] external.invoke callback (JS → Perl)
- [x] Platform detection in Makefile.PL

### Phase 2: Perl API Layer ✓
- [x] Chandra::App - clean OO wrapper
- [x] Chandra::Bind - function registry + JSON dispatch
- [x] Inject JS bridge code automatically
- [x] Promise-based return values

### Phase 3: Element API ✓
- [x] Chandra::Element (port/adapt Moonshine::Element)
- [x] Event handler compilation (sub → JS onclick)
- [x] Handler registry with unique IDs
- [x] render() with injected event wiring

### Phase 4: Developer Experience
- [ ] Chandra::DevTools - inspector, reload
- [ ] Hot reload (watch files, re-render)
- [ ] Error handling and stack traces
- [ ] Documentation and examples

### Phase 5: Advanced Features
- [ ] Dialogs (open/save file, alert)
- [ ] System tray (where supported)
- [ ] Multiple windows (if webview-c supports)
- [ ] Custom protocols (app:// URLs)
- [ ] Bundling/packaging guidance

---

## Event Handler Compilation

When rendering, event handlers are compiled:

```perl
# Perl:
$div->add_child({
    tag     => 'button',
    onclick => sub { $app->alert('Hi!') },
    data    => 'Click',
});

# Compiles to HTML:
<button onclick="chandra._event('_h_42', {type:'click', targetId:'_e_17'})">
    Click
</button>

# Handler registry:
$app->{_handlers}{'_h_42'} = sub { $app->alert('Hi!') };
```

When `chandra._event` fires, the JSON payload goes to Perl, which looks up and invokes the handler.

---

## Example: Todo App

```perl
use Chandra;
use Chandra::Element;

my @todos;

my $app = Chandra->new(title => 'Todo App', width => 400, height => 500);

sub render_todos {
    Chandra::Element->new({
        tag => 'ul',
        class => 'todo-list',
        children => [
            map { 
                my $t = $_;
                {
                    tag  => 'li',
                    data => $t->{text},
                    class => $t->{done} ? 'done' : '',
                    onclick => sub { toggle_todo($t->{id}) },
                }
            } @todos
        ],
    });
}

sub toggle_todo {
    my ($id) = @_;
    my ($t) = grep { $_->{id} eq $id } @todos;
    $t->{done} = !$t->{done};
    $app->update('#todo-list', render_todos());
}

$app->bind('add_todo', sub {
    my ($text) = @_;
    push @todos, { id => scalar(@todos), text => $text, done => 0 };
    $app->update('#todo-list', render_todos());
});

$app->set_content(Chandra::Element->new({
    tag => 'div',
    children => [
        { tag => 'h1', data => 'My Todos' },
        { 
            tag => 'input', 
            id => 'new-todo',
            placeholder => 'What needs doing?',
            onkeyup => sub {
                my ($e) = @_;
                if ($e->key eq 'Enter') {
                    $app->call('add_todo', $e->value);
                }
            },
        },
        { tag => 'div', id => 'todo-list' },
    ],
}));

$app->run;
```

---

## Dependencies

**Required:**
- Perl 5.10+
- JSON (or JSON::XS)
- XSLoader

**Build-time:**
- C compiler
- macOS: Xcode CLT (WebKit framework)
- Linux: libgtk-3-dev libwebkit2gtk-4.0-dev
- Windows: MinGW + Chandra2 SDK

**Optional:**
- UNIVERSAL::Object (for Moonshine compatibility)
- AnyEvent (for async patterns)

---

## Open Questions

1. **Sync vs Async eval**: Should `eval` block until JS completes? Probably not (event loop), but offer `eval_sync` that pumps events until callback fires?

2. **State management**: Just let users manage state, or provide reactive primitives?

3. **CSS injection**: Auto-inject a base stylesheet? Let users BYO?

4. **Moonshine compatibility**: Should Chandra::Element be a drop-in replacement, or "inspired-by"?

5. **Multiple windows**: webview-c says "not supported" - confirm limitation or work around?

---

## File-by-File Implementation Order

1. `lib/Chandra.pm` - Entry point, exports, simple `run()` 
2. `lib/Chandra/Bind.pm` - Handler registry, JSON protocol
3. `lib/Chandra/App.pm` - Full OO wrapper
4. `lib/Chandra/Event.pm` - Event object
5. `lib/Chandra/Element.pm` - DOM builder
6. Update `Chandra.xs` - Inject JS bridge
7. `examples/` - Counter, Todo, Form
8. Tests and docs

---

## Next Steps

1. Review this plan - any changes to API design?
2. Decide on Moonshine::Element compatibility level
3. Begin Phase 2: Chandra::Bind + Chandra::App
