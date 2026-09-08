use v5.40;
use blib;
use feature 'class';
no warnings 'experimental::class';

# A modern, object-oriented WebUI example.
#
# Shows how to:
#   * resolve the webui C library through Alien::Xrepo / xrepo
#   * declare typed, named Affix signatures (enums, structs, callbacks)
#   * register synchronous element callbacks  via webui_bind()
#   * register async, response-capable calls  via webui_interface_bind()
#     (these show up on the JS side as Promise-returning functions)
#   * push state from Perl back into the page via webui_run()
#   * observe window events: connected, disconnected, click, navigation
#
# TODO: https://webui.me/docs.html#/
#
use Alien::Xrepo;
my $repo = Alien::Xrepo->new( verbose => 0 );

#~ $repo->update_repo;
my $webui = $repo->install(
    'webui', undef,
    #
    kind => 'shared'

    #~ configs => { shared => true } # This would also work
);

# A tiny OO wrapper around the WebUI C API used here.
# The affix declarations mirror include/webui.h from the installed package.
class WebUI {
    use Affix    qw[:all];
    use JSON::PP qw[encode_json];
    #
    my $lib = $webui->libpath;
    typedef webui_events =>
        Enum [ 'WEBUI_EVENT_DISCONNECTED', 'WEBUI_EVENT_CONNECTED', 'WEBUI_EVENT_MOUSE_CLICK', 'WEBUI_EVENT_NAVIGATION', 'WEBUI_EVENT_CALLBACK' ];
    typedef webui_event_t => Struct [ window => Size_t, event_type => Size_t, element => String, event_number => Size_t, bind_id => Size_t ];
    affix $lib, webui_new_window => [], Size_t;
    affix $lib, webui_show       => [ Size_t, String ], Bool;
    affix $lib, webui_wait       => [], Void;
    affix $lib, webui_close      => [Size_t], Void;
    affix $lib, webui_clean      => [], Void;
    affix $lib, webui_run        => [ Size_t, String ], Void;
    affix $lib, webui_navigate   => [ Size_t, String ], Void;
    affix $lib, webui_get_url    => [Size_t], String;
    affix $lib, webui_set_size   => [ Size_t, UInt, UInt ], Void;

    # Synchronous window event / element callbacks: void, event struct pointer
    affix $lib,
        webui_bind => [ Size_t, String, Callback [ [ Pointer [ webui_event_t() ] ] => Void ] ],
        Size_t;

    # Async, response-capable callbacks: window, type, element, event#, bind#
    affix $lib,
        webui_interface_bind => [ Size_t, String, Callback [ [ Size_t, Size_t, String, Size_t, Size_t ] => Void ] ],
        Size_t;
    affix $lib, webui_interface_set_response  => [ Size_t, Size_t, String ], Void;
    affix $lib, webui_interface_get_int_at    => [ Size_t, Size_t, Size_t ], LongLong;
    affix $lib, webui_interface_get_string_at => [ Size_t, Size_t, Size_t ], String;
    affix $lib, webui_interface_get_size_at   => [ Size_t, Size_t, Size_t ], Size_t;
    #
    field $win : param //= webui_new_window();
    #
    # Synchronous event / element callback
    method on ( $element, $callback ) {
        webui_bind( $win, $element, $callback );
        $self;
    }

    # Async callback callable from JS as a Promise
    method on_call ( $element, $callback ) {
        webui_interface_bind( $win, $element, $callback );
        $self;
    }

    # Argument access for async callbacks
    method arg_size ( $event_number, $i )     { webui_interface_get_size_at( $win, $event_number, $i ) }
    method arg_i    ( $event_number, $i )     { webui_interface_get_int_at( $win, $event_number, $i ) }
    method arg_s    ( $event_number, $i )     { webui_interface_get_string_at( $win, $event_number, $i ) }
    method respond  ( $event_number, $value ) { webui_interface_set_response( $win, $event_number, '' . $value ) }

    # Run JavaScript in the page
    method run ($script)  { webui_run( $win, $script );                              return $self }
    method log ($message) { $self->run( 'log(' . encode_json( [$message] ) . ');' ); return $self }
    method url ( )                     { webui_get_url($win) }
    method navigate ($url)             { webui_navigate( $win, $url );            return $self }
    method set_size( $width, $height ) { webui_set_size( $win, $width, $height ); $self }
    method show ($html)                { webui_show( $win, $html );               $self }
    method wait ( )                    { webui_wait() }
    method clean ( )                   { webui_clean() }
}
#
my $app = WebUI->new;
my $home;    # our own URL, captured on connect
my $count = 0;

# Window events
$app->on(
    '' => sub ($e) {
        my $type = $e->{event_type};
        if ( $type == WebUI::WEBUI_EVENT_CONNECTED() ) {
            $home = $app->url;
            $app->log( 'Window connected - ' . $home );
            $app->run( 'updateCount(' . $count . ');' );
        }
        elsif ( $type == WebUI::WEBUI_EVENT_DISCONNECTED() ) { $app->log('Window disconnected'); }
        elsif ( $type == WebUI::WEBUI_EVENT_MOUSE_CLICK() )  { $app->log( 'Mouse click on "' . ( $e->{element} // '' ) . '"' ); }
        elsif ( $type == WebUI::WEBUI_EVENT_NAVIGATION() ) {
            $app->log( 'Navigation to ' . ( $app->url // '?' ) . ' - coming right back' );
            $app->navigate($home) if $home;
        }
    }
);

# Synchronous element callbacks (void)
$app->on( count_inc   => sub ($e) { $count++;   $app->log( 'count_inc() -> ' . $count ); $app->run( 'updateCount(' . $count . ');' ) } );
$app->on( count_dec   => sub ($e) { $count--;   $app->log( 'count_dec() -> ' . $count ); $app->run( 'updateCount(' . $count . ');' ) } );
$app->on( count_reset => sub ($e) { $count = 0; $app->log('count_reset() -> 0');         $app->run('updateCount(0);'); } );

# Async, response-capable callbacks (Promise on the JS side)
$app->on_call(
    double_async => sub ( $win, $event_type, $element, $event_number, $bind_id ) {
        my $n = $app->arg_i( $event_number, 0 );
        $app->log( 'double_async( ' . $n . ' ) - arg0 is ' . $app->arg_size( $event_number, 0 ) . ' byte(s)' );
        $app->respond( $event_number, $n * 2 );
    }
);
$app->on_call(
    shout_async => sub ( $win, $event_type, $element, $event_number, $bind_id ) {
        my $text = $app->arg_s( $event_number, 0 ) // '';
        $app->log( 'shout_async( "' . $text . '" )' );
        $app->respond( $event_number, uc $text );
    }
);
#
my $html = <<~'HTML';
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>WebUI - Modern Perl Demo</title>
    <script src="webui.js"></script>
    <style>
      :root {
        --bg: #0f1220;
        --panel: #1a1f33;
        --border: #2a3050;
        --text: #e6e9f5;
        --muted: #8b93b8;
        --accent: #6c8cff;
        --accent2: #ff9f6c;
        --ok: #3ddc97;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0; min-height: 100vh;
        font-family: "Segoe UI", system-ui, sans-serif;
        color: var(--text);
        background: radial-gradient(1200px 600px at 20% -10%, #233056 0%, var(--bg) 55%);
        display: grid; place-items: center; padding: 24px;
      }
      main { width: min(880px, 100%); }
      h1 { font-size: 1.6rem; margin: 0 0 4px; letter-spacing: .5px; }
      h1 span { color: var(--accent); }
      p.sub { color: var(--muted); margin: 0 0 20px; }
      .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
      .card {
        background: linear-gradient(180deg, rgba(255,255,255,.04), rgba(255,255,255,0)), var(--panel);
        border: 1px solid var(--border);
        border-radius: 14px; padding: 18px;
      }
      .card h2 { margin: 0 0 12px; font-size: .9rem; text-transform: uppercase; letter-spacing: 1.5px; color: var(--muted); }
      button, input {
        font: inherit; color: var(--text);
        border: 1px solid var(--border); border-radius: 8px;
        background: #222846; padding: 8px 14px; cursor: pointer;
        transition: filter .15s, transform .05s;
      }
      button:hover { filter: brightness(1.25); }
      button:active { transform: translateY(1px); }
      button.primary { background: var(--accent); border-color: transparent; }
      input { width: 110px; }
      .row { display: flex; gap: 8px; align-items: center; margin: 8px 0; flex-wrap: wrap; }
      #count { font-size: 2.4rem; font-weight: 700; color: var(--accent2); }
      .result { color: var(--ok); min-height: 1.4em; font-family: Consolas, monospace; font-size: .95rem; }
      code { color: var(--accent); }
      #log {
        list-style: none; margin: 0; padding: 8px; height: 240px; overflow: auto;
        font-family: Consolas, "Cascadia Code", monospace; font-size: .82rem;
        background: #0b0e1c; border: 1px solid var(--border); border-radius: 8px;
      }
      #log li { padding: 2px 0; border-bottom: 1px dashed #1e2439; }
      #log .ev { color: var(--accent); }
      #log .err { color: #ff6b6b; }
      footer { margin-top: 14px; color: var(--muted); font-size: .8rem; }
      a { color: var(--accent); }
    </style>
  </head>
  <body>
    <main>
      <h1>WebUI <span>·</span> Modern Perl</h1>
      <p class="sub">Synchronous callbacks, async Promises, and Perl with page events via Alien::Xrepo and Affix</p>

      <div class="grid">
        <section class="card">
          <h2>Counter · synchronous</h2>
          <div class="row">
            <button onclick="count_inc()">+1</button>
            <button onclick="count_dec()">-1</button>
            <button class="primary" onclick="count_reset()">reset</button>
            <div id="count">0</div>
          </div>
          <p style="color:var(--muted);font-size:.85rem;margin:0">Each click calls C bound with <code>webui_bind()</code>; Perl writes the result back with <code>webui_run()</code>.</p>
        </section>

        <section class="card">
          <h2>Async · Promises</h2>
          <div class="row">
            <input id="n" type="number" value="21">
            <button onclick="callDouble()">double it</button>
          </div>
          <div class="result" id="double-out"></div>
          <div class="row">
            <input id="t" type="text" value="hello, webui">
            <button onclick="callShout()">shout it</button>
          </div>
          <div class="result" id="shout-out"></div>
          <p style="color:var(--muted);font-size:.85rem;margin:0">Resolved by C via <code>webui_interface_bind()</code> + <code>webui_interface_set_response()</code>.</p>
        </section>
      </div>

      <section class="card" style="margin-top:16px">
        <h2>Event log</h2>
        <ul id="log"></ul>
        <footer>Open an <a id="ext" href="https://example.com">external link</a> to trigger a navigation event - Perl sends you right back.</footer>
      </section>
    </main>

    <script>
      const logEl = document.getElementById('log');
      function log(message, kind = '') {
        const li = document.createElement('li');
        if (kind) li.className = kind;
        const t = new Date().toLocaleTimeString([], { hour12: false });
        li.textContent = `${t}  ${message}`;
        logEl.appendChild(li);
        logEl.scrollTop = logEl.scrollHeight;
      }
      function updateCount(n) { document.getElementById('count').textContent = n; }

      function callDouble() {
        const n = Number(document.getElementById('n').value);
        if (Number.isNaN(n)) return log('double: invalid number', 'err');
        double_async(n)
          .then(r => { document.getElementById('double-out').textContent = `${n} × 2 = ${r}`; })
          .catch(e => log(`double_async() rejected: ${e}`, 'err'));
      }
      function callShout() {
        const t = document.getElementById('t').value;
        shout_async(t)
          .then(r => { document.getElementById('shout-out').textContent = `"${t}" → "${r}"`; })
          .catch(e => log(`shout_async() rejected: ${e}`, 'err'));
      }

      log('page ready - waiting for the C side to talk back', 'ev');
    </script>
  </body>
  </html>
HTML
$app->set_size( 920, 800 );
$app->show($html);
$app->wait;
$app->clean;
