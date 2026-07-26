package Chandra::Same::Boy;

use 5.008003;
use strict;
use warnings;
use Object::Proto::Sugar qw(is_ro is_rw);
use Carp ();
use Same::Boy ();
use MIME::Base64 ();
use Time::HiRes ();

our $VERSION = '0.02';

# ---------------------------------------------------------------------------
# Attributes
# ---------------------------------------------------------------------------

# ---- configuration (constructor args) ----
has app        => (is_ro);                        # required (checked in BUILD)
has model      => (is_rw, default => 'cgb');      # normalised (lc) in BUILD
has id         => (is_ro, default => 'gbScreen');
has scale      => (is_ro, default => 3);
has draw_every => (is_rw, default => 1);          # coerced to >= 1 in BUILD
has sample_rate => (is_ro, default => 44100);
has volume     => (is_rw, default => 1);
has autosave   => (is_ro, default => 10);
has sav        => (is_rw);                        # <rom>.sav (defaulted in load_rom)
has state_path => (is_rw, init_arg => 'state');   # <rom>.state

# transient constructor args, consumed by BUILD
has rom        => (is_rw);
has _on_arg    => (is_rw, init_arg => 'on');      # on => { event => cb, ... }

# ---- runtime state ----
has boy        => (is_rw);
has muted      => (is_rw, default => 0);
has paused     => (is_rw, default => 0);
has frame      => (is_rw, default => 0);
has rom_path   => (is_rw);
has _events    => (is_ro, default => sub { +{} });  # event => [ coderef, ... ]

# ---- game-loop pacing (initialised in mount) ----
has _period    => (is_rw, default => 0);
has _next      => (is_rw, default => 0);
has _fps_t     => (is_rw, default => 0);
has _fps_n     => (is_rw, default => 0);
has _sav_next  => (is_rw, default => 0);
has _ff        => (is_rw, default => 0);

# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;
    Carp::croak("Chandra::Same::Boy: 'app' is required") unless $self->app;

    $self->model(lc($self->model || 'cgb'));
    $self->draw_every($self->draw_every || 1);

    # allow on => { rom => sub {...}, save => sub {...} } at construction
    if (ref $self->_on_arg eq 'HASH') {
        $self->on($_, $self->_on_arg->{$_}) for keys %{ $self->_on_arg };
    }

    $self->load_rom($self->rom) if defined $self->rom;
    return;
}

# ---------------------------------------------------------------------------
# Events (embedder callbacks): frame, fps, rom, save
# ---------------------------------------------------------------------------

sub on {
    my ($self, $event, $cb) = @_;
    Carp::croak("on: a coderef is required") unless ref $cb eq 'CODE';
    push @{ $self->_events->{$event} }, $cb;
    return $self;
}

sub _emit {
    my ($self, $event, @args) = @_;
    my $list = $self->_events->{$event} or return;
    $_->($self, @args) for @$list;
    return;
}

# ---------------------------------------------------------------------------
# Accessors (derived)
# ---------------------------------------------------------------------------

sub is_paused { $_[0]->paused ? 1 : 0 }

sub rom_title  { $_[0]->boy ? $_[0]->boy->rom_title  : undef }
sub rom_crc32  { $_[0]->boy ? $_[0]->boy->rom_crc32  : undef }
sub dimensions { $_[0]->boy ? $_[0]->boy->dimensions : (160, 144) }

# ---------------------------------------------------------------------------
# ROM / cartridge
# ---------------------------------------------------------------------------

sub load_rom {
    my ($self, $src) = @_;
    Carp::croak("load_rom: no ROM given") unless defined $src;

    # Flush the outgoing cartridge's battery before swapping.
    $self->save_battery if $self->boy;

    unless (ref $src) {                 # a filesystem path
        $self->rom_path($src);
        $self->sav($self->sav || "$src.sav");
        $self->state_path($self->state_path || "$src.state");
    }

    $self->boy(Same::Boy->new(
        model => $self->model,
        rom   => $src,
        ($self->sample_rate ? (sample_rate => $self->sample_rate) : ()),
    ));
    $self->boy->load_battery_from_file($self->sav)
        if $self->sav && -f $self->sav;

    $self->_emit('rom', $self->rom_title, $self->rom_crc32);
    return $self;
}

# ---------------------------------------------------------------------------
# Webview integration
# ---------------------------------------------------------------------------

sub mount {
    my ($self) = @_;
    Carp::croak("Chandra::Same::Boy->mount: load a ROM first") unless $self->boy;
    my $app = $self->app;

    # Page: a scaled, pixelated canvas plus the JS blit helper and input
    # listeners (keydown/keyup -> window.chandra.invoke('__sb_key', ...)).
    $app->set_content($self->_page_html);

    # JS -> Perl input bridge.
    $app->bind('__sb_key', sub {
        my ($btn, $down) = @_;
        return unless defined $btn;
        $down ? $self->press($btn) : $self->release($btn);
    });

    # JS -> Perl action bridge (save/load state, pause, reset, fast-forward).
    $app->bind('__sb_action', sub {
        my ($action, $down) = @_;
        return unless defined $action;
        $self->_action($action, $down);
    });

    # Toolbar buttons and HUD share the __sb_action bridge (mute/open too).

    # Flush the cartridge battery when the window closes (in-game saves).
    $app->on_close(sub { $self->shutdown }) if $app->can('on_close');

    # Game loop pacing (on_tick fires every event-loop iteration).
    my $now = Time::HiRes::time();
    $self->_period(1 / 60);
    $self->_next($now);
    $self->_fps_t($now);
    $self->_fps_n(0);
    $self->_sav_next($now + $self->autosave);

    $app->on_tick(sub { $self->_tick });

    # Seed the HUD (title/speed) once the page is up.
    $self->_hud('title', $self->rom_title // '');
    $self->_hud('speed', '1x');
    return $self;
}

# Flush battery-backed save RAM; safe to call repeatedly (idempotent).
sub shutdown {
    my ($self) = @_;
    $self->save_battery if $self->boy;
    return $self;
}

# Update a HUD field (title/fps/speed) via a tiny JS helper.
sub _hud {
    my ($self, $field, $text) = @_;
    $text =~ s/'/\\'/g;
    $self->app->dispatch_eval("window.SB_hud&&SB_hud('$field','$text')");
    return;
}

# Show a toast if the app supports it (real Chandra::App does; stubs may not).
sub _toast {
    my ($self, $msg, $type) = @_;
    return unless $self->app->can('toast');
    $self->app->toast($msg, type => ($type || 'info'));
    return;
}

# Open a ROM via the native file dialog and hot-swap it.
sub _open_rom {
    my ($self) = @_;
    my $path = eval {
        require Chandra::Dialog;
        Chandra::Dialog->new(app => $self->app)->open_file(title => 'Open ROM');
    };
    return $self unless defined $path && length $path;
    $self->load_rom($path);
    $self->_hud('title', $self->rom_title // '');
    $self->_emit('action', 'open_rom');
    $self->_toast('Loaded ' . ($self->rom_title // 'ROM'), 'success');
    return $self;
}

# One iteration of the loop: run a frame if it is time, blit, emit events.
sub _tick {
    my ($self) = @_;
    return if $self->paused;

    my $now = Time::HiRes::time();
    return if $now < $self->_next;              # paced to ~60fps
    $self->_next($self->_next + $self->_period);
    $self->_next($now) if $now - $self->_next > 0.25;   # resync if behind

    $self->boy->run_frame;
    my $f = $self->frame + 1;
    $self->frame($f);

    if ($f % $self->draw_every == 0) {
        my $b64 = MIME::Base64::encode_base64($self->boy->pixels_rgba, '');
        $self->app->dispatch_eval("window.SB&&SB.blit('$b64')");
    }
    $self->_pump_audio if $self->sample_rate;
    $self->_emit('frame', $f);

    # measured fps, once per second (also drives the HUD)
    $self->_fps_n($self->_fps_n + 1);
    my $dt = $now - $self->_fps_t;
    if ($dt >= 1.0) {
        my $fps = $self->_fps_n / $dt;
        $self->_emit('fps', $fps);
        $self->_hud('fps', sprintf('%d fps', $fps + 0.5));
        $self->_fps_t($now);
        $self->_fps_n(0);
    }

    # periodic battery autosave (bounds loss if the process is killed)
    if ($self->autosave && $now >= $self->_sav_next) {
        $self->save_battery;
        $self->_sav_next($now + $self->autosave);
    }
    return;
}

# Drain the emulator's captured audio and hand it to the Web Audio sink.
# The buffer is always drained (to bound its growth); dispatch is skipped
# while fast-forwarding, which would otherwise overrun the audio clock.
sub _pump_audio {
    my ($self) = @_;
    my $pcm = $self->boy->samples;
    return if $self->_ff || !length $pcm;
    my $b64  = MIME::Base64::encode_base64($pcm, '');
    my $rate = $self->sample_rate;
    $self->app->dispatch_eval("window.SBA&&SBA.push('$b64',$rate)");
    return;
}

# Dispatch a UI action (key or toolbar). Emits an 'action' event with a
# result token so embedders (or the phase-6 toast/HUD) can react.
sub _action {
    my ($self, $action, $down) = @_;

    if ($action eq 'save_state') {
        if ($self->state_path) {
            $self->save_state;
            $self->_emit('action', 'save_state');
            $self->_toast('State saved', 'success');
        }
        else {
            $self->_emit('action', 'save_state_no_path');
            $self->_toast('No save path', 'warning');
        }
    }
    elsif ($action eq 'load_state') {
        if ($self->state_path && -f $self->state_path) {
            $self->load_state;
            $self->_emit('action', 'load_state');
            $self->_toast('State loaded', 'success');
        }
        else {
            $self->_emit('action', 'load_state_missing');
            $self->_toast('No save state', 'warning');
        }
    }
    elsif ($action eq 'pause') {
        $self->toggle_pause;
        my $p = $self->is_paused;
        $self->_emit('action', $p ? 'paused' : 'resumed');
        $self->_toast($p ? 'Paused' : 'Resumed', 'info');
    }
    elsif ($action eq 'reset') {
        $self->reset;
        $self->_emit('action', 'reset');
        $self->_toast('Reset', 'info');
    }
    elsif ($action eq 'ff') {
        $self->_ff($down ? 1 : 0);      # mutes audio while held
        $self->set_speed($down ? 4 : 1);
        $self->_hud('speed', $down ? '4x' : '1x');
        $self->_emit('action', $down ? 'fast_forward_on' : 'fast_forward_off');
    }
    elsif ($action eq 'mute') {
        $self->mute;
        my $m = $self->is_muted;
        $self->_emit('action', $m ? 'muted' : 'unmuted');
        $self->_toast($m ? 'Muted' : 'Unmuted', 'info');
    }
    elsif ($action eq 'open') {
        $self->_open_rom;
    }
    else {
        $self->_emit('action', "unknown:$action");
    }
    return $self;
}

# ---------------------------------------------------------------------------
# Controls (functional now; independent of the webview)
# ---------------------------------------------------------------------------

sub pause        { $_[0]->paused(1); $_[0] }
sub resume       { $_[0]->paused(0); $_[0] }
sub toggle_pause { $_[0]->paused($_[0]->paused ? 0 : 1); $_[0] }

sub reset     { $_[0]->boy->reset                       if $_[0]->boy; $_[0] }
sub set_speed { $_[0]->boy->set_clock_multiplier($_[1]) if $_[0]->boy; $_[0] }

sub set_volume {
    my ($self, $v) = @_;
    $v = 0 if $v < 0;
    $v = 1 if $v > 1;
    $self->volume($v);
    $self->muted(0);
    $self->app->dispatch_eval("window.SBA&&SBA.setVolume($v)");
    return $self;
}

sub mute {
    my ($self, $on) = @_;
    $on = $self->muted ? 0 : 1 unless defined $on;   # toggle with no arg
    $self->muted($on ? 1 : 0);
    my $v = $on ? 0 : ($self->volume // 1);
    $self->app->dispatch_eval("window.SBA&&SBA.setVolume($v)");
    return $self;
}

sub is_muted { $_[0]->muted ? 1 : 0 }
sub press    { $_[0]->boy->press($_[1])   if $_[0]->boy; $_[0] }
sub release  { $_[0]->boy->release($_[1]) if $_[0]->boy; $_[0] }

sub press_for_player {
    $_[0]->boy->press_for_player($_[1], $_[2]) if $_[0]->boy; $_[0];
}
sub release_for_player {
    $_[0]->boy->release_for_player($_[1], $_[2]) if $_[0]->boy; $_[0];
}

sub save_state {
    my ($self, $path) = @_;
    $path ||= $self->state_path;
    Carp::croak("save_state: no path") unless $path;
    $self->boy->save_state_to_file($path);
    $self->_emit('save', 'state', $path);
    return $self;
}

sub load_state {
    my ($self, $path) = @_;
    $path ||= $self->state_path;
    Carp::croak("load_state: no state file") unless $path && -f $path;
    $self->boy->load_state_from_file($path);
    return $self;
}

sub save_battery {
    my ($self, $path) = @_;
    return $self unless $self->boy;
    $path ||= $self->sav;
    return $self unless $path;
    if (defined $self->boy->save_battery) {
        $self->boy->save_battery_to_file($path);
        $self->_emit('save', 'battery', $path);
    }
    return $self;
}

# The HTML page: canvas + blit helper + keydown/keyup bridge.
sub _page_html {
    my ($self) = @_;
    my ($w, $h) = $self->boy->dimensions;
    my $sw = $w * $self->scale;
    my $sh = $h * $self->scale;
    my $id = $self->id;

    return <<"HTML";
<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{margin:0;height:100%;background:#111;overflow:hidden;
    font:12px system-ui,sans-serif;color:#ccc}
  #sb-wrap{height:100%;display:flex;flex-direction:column}
  #sb-bar{display:flex;align-items:center;gap:6px;padding:4px 8px;
    background:#1c1c1c;border-bottom:1px solid #000}
  #sb-bar button{background:#333;color:#eee;border:0;border-radius:4px;
    padding:3px 8px;cursor:pointer;font:inherit}
  #sb-bar button:hover{background:#444}
  #sb-title{margin-left:8px;font-weight:600;color:#fff}
  #sb-speed{margin-left:auto;opacity:.7}
  #sb-fps{margin-left:12px;min-width:52px;text-align:right;opacity:.7}
  #sb-screen-wrap{flex:1;display:flex;align-items:center;
    justify-content:center;background:#000}
  #$id\{image-rendering:pixelated;image-rendering:crisp-edges;
    width:${sw}px;height:${sh}px;background:#000}
</style></head><body>
<div id="sb-wrap">
  <div id="sb-bar">
    <button data-act="pause">Pause</button>
    <button data-act="reset">Reset</button>
    <button data-act="save_state">Save</button>
    <button data-act="load_state">Load</button>
    <button data-act="mute">Mute</button>
    <button data-act="open">Open</button>
    <span id="sb-title"></span>
    <span id="sb-speed">1x</span>
    <span id="sb-fps"></span>
  </div>
  <div id="sb-screen-wrap">
    <canvas id="$id" width="$sw" height="$sh"></canvas>
  </div>
</div>
<script>
(function(){
  var NW=$w, NH=$h;
  var off=document.createElement('canvas'); off.width=NW; off.height=NH;
  var octx=off.getContext('2d');
  var img=octx.createImageData(NW,NH);
  var cv=document.getElementById('$id');
  var vis=cv.getContext('2d'); vis.imageSmoothingEnabled=false;
  window.SB={blit:function(b64){
    var raw=atob(b64), d=img.data, n=d.length, i=0;
    for(;i<n;i++) d[i]=raw.charCodeAt(i);
    octx.putImageData(img,0,0);
    vis.drawImage(off,0,0,cv.width,cv.height);
  }};
  window.SBA=(function(){
    var AC=window.AudioContext||window.webkitAudioContext;
    if(!AC) return {push:function(){},setVolume:function(){},resume:function(){}};
    var ac=new AC(), gain=ac.createGain(); gain.connect(ac.destination);
    var t=0;
    return {
      resume:function(){ if(ac.state==='suspended') ac.resume(); },
      setVolume:function(v){ gain.gain.value=v; },
      push:function(b64,rate){
        var raw=atob(b64), n=raw.length>>2;   // 4 bytes per stereo frame
        if(!n) return;
        var buf=ac.createBuffer(2,n,rate);
        var L=buf.getChannelData(0), R=buf.getChannelData(1), i;
        for(i=0;i<n;i++){
          var l=raw.charCodeAt(i*4)|(raw.charCodeAt(i*4+1)<<8); if(l>=32768)l-=65536;
          var r=raw.charCodeAt(i*4+2)|(raw.charCodeAt(i*4+3)<<8); if(r>=32768)r-=65536;
          L[i]=l/32768; R[i]=r/32768;
        }
        var src=ac.createBufferSource(); src.buffer=buf; src.connect(gain);
        var now=ac.currentTime;
        if(t<now+0.02) t=now+0.02;   // small lead; resync if we fell behind
        src.start(t); t+=buf.duration;
      }
    };
  })();
  var MAP={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right',
    KeyW:'up',KeyS:'down',KeyA:'left',KeyD:'right',
    KeyZ:'b',KeyX:'a',Space:'a',Enter:'start',Backslash:'select'};
  var ACT={F2:'save_state',F4:'load_state',KeyP:'pause',KeyR:'reset'};
  var down={}, ffdown=0;
  function send(b,d){ if(window.chandra&&window.chandra.invoke)
    window.chandra.invoke('__sb_key',[b,d]); }
  function act(a,d){ if(window.chandra&&window.chandra.invoke)
    window.chandra.invoke('__sb_action',[a,d]); }
  document.addEventListener('keydown',function(e){
    if(window.SBA) SBA.resume();   // browsers require a gesture to start audio
    if(e.code==='Tab'){ e.preventDefault(); if(!ffdown){ffdown=1; act('ff',1);} return; }
    var a=ACT[e.code]; if(a){ e.preventDefault(); act(a,1); return; }
    var b=MAP[e.code]; if(!b) return; e.preventDefault();
    if(!down[b]){down[b]=1; send(b,1);} },true);
  document.addEventListener('keyup',function(e){
    if(e.code==='Tab'){ e.preventDefault(); ffdown=0; act('ff',0); return; }
    var b=MAP[e.code]; if(!b) return; e.preventDefault();
    down[b]=0; send(b,0); },true);
  window.SB_hud=function(field,text){
    var e=document.getElementById('sb-'+field); if(e)e.textContent=text; };
  var bar=document.getElementById('sb-bar');
  if(bar) bar.querySelectorAll('button').forEach(function(btn){
    btn.addEventListener('click',function(){ act(btn.getAttribute('data-act'),1); }); });
})();
</script>
</body></html>
HTML
}

1;

__END__

=head1 NAME

Chandra::Same::Boy - play Game Boy / Game Boy Color games in a Chandra window

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Chandra::App;
    use Chandra::Same::Boy;

    my $app = Chandra::App->new(title => 'Game Boy');
    my $gb  = Chandra::Same::Boy->new(
        app   => $app,
        rom   => 'game.gbc',
        scale => 3,
    );
    $gb->mount;      # canvas + input + game loop (phase 3+)
    $app->run;

=head1 DESCRIPTION

Chandra::Same::Boy is a Chandra widget that renders a L<Same::Boy> emulator to
a canvas in a native webview window, with real keyboard input, save states and
battery-backed saves.

=head1 CONSTRUCTOR

=head2 new(%args)

Requires C<app> (a L<Chandra::App>). Optional: C<rom> (path or scalar ref),
C<model> (C<dmg|mgb|sgb|sgb2|cgb>, default C<cgb>), C<id>, C<scale> (default 3),
C<sample_rate> (default 44100; 0 disables audio), C<volume> (C<0>..C<1>,
default 1), C<autosave> (battery autosave interval in seconds, default 10; 0
disables), C<sav> and C<state> paths.

=head1 METHODS

=head2 mount

Set the app's page content to a scaled, pixelated canvas, register the
keyboard input bridge, and start the C<on_tick> game loop that runs the
emulator at ~60fps and blits each frame. Returns C<$self>. Call before
C<< $app->run >>.

=head2 load_rom($path_or_ref)

Load (or hot-swap) a cartridge ROM, flushing the previous cartridge's battery
first and loading any C<< <rom>.sav >>.

=head2 pause / resume / toggle_pause / is_paused

=head2 reset / set_speed($multiplier) / press($btn) / release($btn)

=head2 set_volume($v) / mute([$bool]) / is_muted

Audio output level. C<set_volume> takes C<0>..C<1>. C<mute> with no argument
toggles; audio is captured only when C<sample_rate> is non-zero, and is
automatically silenced while fast-forwarding.

=head2 save_state([$path]) / load_state([$path])

Snapshot to / restore from C<< <rom>.state >> (or an explicit path).

=head2 save_battery([$path])

Write cartridge save RAM to C<< <rom>.sav >> (or an explicit path). The
battery is also autosaved periodically during play and flushed by C<shutdown>.

=head2 shutdown

Flush the cartridge battery. Registered as the app's C<on_close> handler and
called by L<Chandra::Same::Boy::App> after the window closes, so in-game saves
survive every exit path.

=head2 press_for_player($btn, $player) / release_for_player($btn, $player)

Input for SGB multiplayer (C<$player> from 0).

=head2 app / boy / id / scale / frame / rom_title / rom_crc32 / dimensions

Accessors. C<boy> is the underlying L<Same::Boy> instance.

=head1 EVENTS

Register embedder callbacks with C<on($event, $coderef)> (or pass
C<< on => { $event => $cb, ... } >> to C<new>). Each callback is invoked as
C<< $cb->($widget, @args) >>. Multiple callbacks per event are allowed.

=over 4

=item rom  => ($title, $crc32)

Emitted after a ROM is loaded or hot-swapped.

=item save => ($kind, $path)

Emitted after a save is written; C<$kind> is C<'state'> or C<'battery'>.

=item frame => ($frame_number)

Emitted per rendered frame from the game loop (from phase 3).

=item fps => ($measured_fps)

Emitted periodically with the measured frame rate (from phase 3).

=item action => ($result)

Emitted when a UI action key fires. C<$result> is one of C<save_state>,
C<load_state>, C<load_state_missing>, C<save_state_no_path>, C<paused>,
C<resumed>, C<reset>, C<fast_forward_on>, C<fast_forward_off>.

=back

=head1 CONTROLS

After C<mount>, the window handles these keys:

    Arrows / WASD    D-pad          Z / X (or Space)   B / A
    Enter            Start          \                  Select
    F2 / F4          save / load state
    P                pause / resume
    R                reset
    Tab (hold)       fast-forward (4x while held)

D-pad and buttons are true press/hold/release (webview key-up events);
action keys fire on press (Tab also on release).

A toolbar (Pause, Reset, Save, Load, Mute, Open) sits above the screen, with a
HUD showing the ROM title, current speed and measured FPS. The Open button
uses the native file dialog (L<Chandra::Dialog>) to hot-swap ROMs. Actions
also raise a toast (L<Chandra::Toast>) for feedback.

=head1 SEE ALSO

L<Same::Boy>, L<Chandra::App>, L<Chandra::Same::Boy::App>.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
