use v5.40;
use experimental qw[declared_refs];
use blib;
$|++;
use Acme::Parataxis qw[:all];
use Acme::Parataxis::Channel;
use Acme::Parataxis::Signal;

# Platform setup: POSIX termios or Win32 kernel32 via Affix FFI
BEGIN {
    if ( $^O ne 'MSWin32' ) {
        require POSIX;
        POSIX->import(qw[:termios_h]);
    }
    else {
        use Affix qw[:all];
        affix 'kernel32', 'GetConsoleMode',                [ LongLong, Pointer [Void] ], Int;
        affix 'kernel32', 'SetConsoleMode',                [ LongLong, ULong ],          Int;
        affix 'kernel32', 'GetConsoleScreenBufferInfo',    [ LongLong, Pointer [Void] ], Int;
        affix 'kernel32', 'GetNumberOfConsoleInputEvents', [ LongLong, Pointer [Void] ], Int;
        affix 'kernel32', 'ReadConsoleInputA',             [ LongLong, Pointer [Void], ULong, Pointer [Void] ], Int;
    }
}
#
# A bubbletea-inspired TUI using Acme::Parataxis fibers.
#
# Architecture (Elm-like / bubbletea-style):
#   - input fiber:   reads keyboard -> MsgKey
#   - resize fiber:  $SIG{WINCH} or Win32 polling -> MsgResize
#   - tick fiber:    await_sleep(1000) -> MsgTick
#   - main loop:     Channel.get() -> Update(model, msg) -> render via View()
#
# Windows notes:
#   - Raw mode, VT processing, and input are handled via kernel32 FFI
#   - select() only works on sockets on Windows, so await_read/await_write
#     (which use select in the thread pool) don't work on console handles.
#     The input fiber uses GetNumberOfConsoleInputEvents + ReadConsoleInputA
#     polling instead.  await_write(STDOUT) is skipped since stdout is always
#     writable for a console.
#
# Terminal raw mode
my $ORIG_TERMIOS;
my $ORIG_WIN32_IN_MODE;

sub save_termios {
    if ( $^O eq 'MSWin32' ) {
        my $handle = Acme::Parataxis::win32_get_osfhandle( fileno(STDIN) );
        my $buf    = pack( "L", 0 );
        GetConsoleMode( $handle, $buf );
        $ORIG_WIN32_IN_MODE = unpack( "L", $buf );

        # Enable VT processing on the output handle so ANSI escapes render.
        my $out_handle = Acme::Parataxis::win32_get_osfhandle( fileno(STDOUT) );
        my $out_buf    = pack( "L", 0 );
        GetConsoleMode( $out_handle, $out_buf );
        my $out_mode                           = unpack( "L", $out_buf );
        my $ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
        SetConsoleMode( $out_handle, $out_mode | $ENABLE_VIRTUAL_TERMINAL_PROCESSING );
    }
    else {
        my $t = POSIX::Termios->new();
        $t->getattr(0);    # STDIN
        $ORIG_TERMIOS = $t;
    }
}

sub enable_raw_mode {
    save_termios() unless defined $ORIG_TERMIOS || defined $ORIG_WIN32_IN_MODE;
    if ( $^O eq 'MSWin32' ) {
        my $handle              = Acme::Parataxis::win32_get_osfhandle( fileno(STDIN) );
        my $ENABLE_LINE_INPUT   = 0x0002;
        my $ENABLE_ECHO_INPUT   = 0x0004;
        my $ENABLE_PROCESSED_IN = 0x0001;
        my $raw                 = $ORIG_WIN32_IN_MODE & ~( $ENABLE_LINE_INPUT | $ENABLE_ECHO_INPUT | $ENABLE_PROCESSED_IN );
        SetConsoleMode( $handle, $raw );
    }
    else {
        no strict 'subs';
        my $t = POSIX::Termios->new();
        $t->getattr(0);
        my $lflag = $t->getlflag();
        my $iflag = $t->getiflag();
        my $oflag = $t->getoflag();

        # Turn off: echo, canonical (line-buffered) mode, signal chars (ISIG
        # catches Ctrl+C/SUSP before we see the raw byte), newline echo.
        $lflag &= ~( ECHO | ICANON | ISIG | ECHONL );

        # Turn off: CR->NL translation, XON/XOFF flow control, break interrupt.
        $iflag &= ~( ICRNL | IXON | BRKINT );

        # Turn off: output processing (NL -> CRNL).
        $oflag &= ~(OPOST);
        $t->setlflag($lflag);
        $t->setiflag($iflag);
        $t->setoflag($oflag);

        # Minimum 1 byte, no timeout for reads
        $t->setcc( VMIN,  1 );
        $t->setcc( VTIME, 0 );
        $t->setattr(0);
    }
}

sub disable_raw_mode {
    if ( $^O eq 'MSWin32' ) {
        if ( defined $ORIG_WIN32_IN_MODE ) {
            my $handle = Acme::Parataxis::win32_get_osfhandle( fileno(STDIN) );
            SetConsoleMode( $handle, $ORIG_WIN32_IN_MODE );
            undef $ORIG_WIN32_IN_MODE;
        }
    }
    elsif ( defined $ORIG_TERMIOS ) {
        $ORIG_TERMIOS->setattr(0);
        undef $ORIG_TERMIOS;
    }
}

# Terminal size -- platform-aware
sub get_terminal_size {
    if ( $^O eq 'MSWin32' ) {
        return _win32_terminal_size();
    }
    else {
        return _posix_terminal_size();
    }
}

sub _posix_terminal_size {

    # ioctl(fd, TIOCGWINSZ, &winsize)  --  TIOCGWINSZ = 0x5413 on Linux
    my $TIOCGWINSZ = 0x5413;

    # struct winsize { unsigned short ws_row; ws_col; ws_xpixel; ws_ypixel; }
    my $buf = "\0" x 8;
    if ( ioctl( \*STDOUT, $TIOCGWINSZ, $buf ) ) {
        my ( $rows, $cols, $xpix, $ypix ) = unpack( 'S4', $buf );
        return ( $rows, $cols ) if $rows > 0 && $cols > 0;
    }

    # Fallback: environment (often set by screen/tmux)
    my $h = $ENV{LINES}   // $ENV{COLUMNS};
    my $w = $ENV{COLUMNS} // $ENV{LINES};
    return ( $h // 24, $w // 80 );
}

sub _win32_terminal_size {

    # CONSOLE_SCREEN_BUFFER_INFO (22 bytes):
    #   COORD dwSize           (0:  4 bytes)
    #   COORD dwCursorPosition (4:  4 bytes)
    #   WORD  wAttributes      (8:  2 bytes)
    #   SMALL_RECT srWindow   (10: 8 bytes -- Left,Top,Right,Bottom as SHORTs)
    #   COORD dwMaximumSize    (18: 4 bytes)
    my $handle = Acme::Parataxis::win32_get_osfhandle( fileno(STDOUT) );
    my $csbi   = "\0" x 22;
    if ( GetConsoleScreenBufferInfo( $handle, $csbi ) ) {
        my ( $wl, $wt, $wr, $wb ) = unpack( 'ssss', substr( $csbi, 10, 8 ) );
        my $cols = $wr - $wl + 1;
        my $rows = $wb - $wt + 1;
        return ( $rows, $cols ) if $rows > 0 && $cols > 0;
    }

    # Fallback: environment or sensible defaults
    my $rows = $ENV{LINES}   // 24;
    my $cols = $ENV{COLUMNS} // 80;
    return ( $rows, $cols );
}

# ANSI helpers
sub hide_cursor  { print "\e[?25l" }
sub show_cursor  { print "\e[?25h" }
sub clear_screen { print "\e[H\e[2J" }
sub move_to      { my ( $r, $c ) = @_; print "\e[${r};${c}H" }

# Message types (plain hashrefs -- bubbletea-style)
sub MsgKey    { { type => 'key',    key   => $_[0] } }
sub MsgTick   { { type => 'tick',   count => $_[0] } }
sub MsgResize { { type => 'resize', width => $_[0], height => $_[1] } }
sub MsgQuit   { { type => 'quit' } }

# Update / View  (pure functions over model)
sub Update ( $model, $msg ) {
    my %m = %$model;
    if ( $msg->{type} eq 'key' ) {
        my $key = $msg->{key};
        if ( !defined $key || $key eq "\cC" || $key eq 'q' ) {
            return \%m, MsgQuit();
        }
        elsif ( $key eq 'j' || $key eq "\e[B" ) {
            $m{cursor} = $m{cursor} < $#{ $m{items} } ? $m{cursor} + 1 : $m{cursor};
        }
        elsif ( $key eq 'k' || $key eq "\e[A" ) {
            $m{cursor} = $m{cursor} > 0 ? $m{cursor} - 1 : 0;
        }
        elsif ( $key eq ' ' || $key eq "\r" || $key eq "\n" ) {
            my $i = $m{cursor};
            $m{toggled}{$i} = !$m{toggled}{$i};
        }
    }
    elsif ( $msg->{type} eq 'resize' ) {
        $m{width}  = $msg->{width};
        $m{height} = $msg->{height};
    }
    elsif ( $msg->{type} eq 'tick' ) {
        $m{ticks} = $msg->{count};
    }
    return \%m, undef;
}

sub View ($model) {
    my $w    = $model->{width};
    my $h    = $model->{height};
    my $buf  = '';
    my $list = '';

    # -- title bar --
    my $title = 'Parataxis TUI Demo (bubbletea-style)';
    $buf .= "\e[1;36m$title\e[0m\r\n";
    $buf .= "\e[2m${w}x${h}\e[0m\r\n";
    $buf .= "\r\n";

    # -- list items --
    for my $i ( 0 .. $#{ $model->{items} } ) {
        my $item   = $model->{items}[$i];
        my $mark   = $model->{toggled}{$i}  ? "\e[32m[x]\e[0m" : "[ ]";
        my $cursor = $i == $model->{cursor} ? "\e[1;33m>\e[0m" : ' ';
        $list .= "$cursor $mark $item\r\n";
    }
    $buf .= $list;

    # -- status bar (pad to fill width) --
    $buf .= "\r\n";
    my $status = sprintf 'ticks: %-5d | j/k move  space toggle  q quit', $model->{ticks};
    my $pad    = $w - length($status) - 2;
    $pad = 0 if $pad < 0;
    $buf .= "\e[7m ${status}\e[0m" . ( ' ' x $pad ) . "\r\n";

    # -- center a box to prove we see the real terminal size --
    my $box_w = 32;
    my $box_h = 5;
    my $bx    = int( ( $w - $box_w ) / 2 );
    my $by    = int( ( $h - $box_h ) / 2 );
    $bx = 1 if $bx < 1;
    $by = 4 if $by < 4;    # below the list
    $buf .= "\e[${by};${bx}H\e[1;35m+\e[0m" . ( '-' x ( $box_w - 2 ) ) . "\e[1;35m+\e[0m\r\n";

    for my $row ( 1 .. $box_h - 2 ) {
        my $inner = $row == 2 ? ' Resize the terminal! ' : '';
        my $pad2  = $box_w - 2 - length($inner);
        $pad2 = 1 if $pad2 < 1;
        $buf .= "\e[" . ( $by + $row ) . ";${bx}H\e[1;35m|\e[0m${inner}" . ( ' ' x $pad2 ) . "\e[1;35m|\e[0m\r\n";
    }
    $buf .= "\e[" . ( $by + $box_h - 1 ) . ";${bx}H\e[1;35m+\e[0m" . ( '-' x ( $box_w - 2 ) ) . "\e[1;35m+\e[0m\r\n";
    return $buf;
}

# Fiber: raw keyboard input
# Windows INPUT_RECORD layout (20 bytes):
#   WORD  EventType        (offset  0, 2 bytes)
#   [2 bytes padding]
#   KEY_EVENT_RECORD union (offset  4, 16 bytes):
#     BOOL  bKeyDown       (offset  4, 4 bytes)
#     WORD  wRepeatCount   (offset  8, 2 bytes)
#     WORD  wVirtualKeyCode (offset 10, 2 bytes)
#     WORD  wVirtualScanCode(offset 12, 2 bytes)
#     CHAR  AsciiChar      (offset 14, 1 byte)
#     [1 byte padding]
#     DWORD dwControlKeyState (offset 16, 4 bytes)
sub input_fiber ( $ch, $quit ) {
    if ( $^O eq 'MSWin32' ) {

        # Windows: select() doesn't work on console handles, so we poll
        # with GetNumberOfConsoleInputEvents + ReadConsoleInputA via
        # kernel32 FFI.  WaitForSingleObject would be ideal but would block
        # the whole scheduler thread, so we use a tight await_sleep loop
        # and drain every pending event each cycle.
        my $handle = Acme::Parataxis::win32_get_osfhandle( fileno(STDIN) );
        while ( !$quit->count ) {
            Acme::Parataxis->await_sleep(10);    # 100 Hz polling

            # Check how many events are queued and drain them all.
            my $num_buf = pack( "L", 0 );
            GetNumberOfConsoleInputEvents( $handle, $num_buf );
            my $num = unpack( "L", $num_buf );
            next unless $num > 0;
            my $record    = "\0" x 20;
            my $count_buf = pack( "L", 0 );
            for ( 1 .. $num ) {
                ReadConsoleInputA( $handle, $record, 1, $count_buf );
                last unless unpack( "L", $count_buf ) > 0;
                my $event_type = unpack( "v", substr( $record, 0, 2 ) );
                next unless $event_type == 1;    # KEY_EVENT
                my $bkeydown = unpack( "V", substr( $record, 4, 4 ) );
                next unless $bkeydown;           # ignore key-up
                my $vk    = unpack( "v", substr( $record, 10, 2 ) );
                my $ascii = ord( substr( $record, 14, 1 ) );

                # Map virtual-key codes to the same strings the POSIX path
                # uses, so Update() doesn't need platform-specific branches.
                my $key;
                if    ( $vk == 0x26 )    { $key = "\e[A" }                  # Up
                elsif ( $vk == 0x28 )    { $key = "\e[B" }                  # Down
                elsif ( $vk == 0x27 )    { $key = "\e[C" }                  # Right
                elsif ( $vk == 0x25 )    { $key = "\e[D" }                  # Left
                elsif ( $vk == 0x24 )    { $key = "home" }                  # Home
                elsif ( $vk == 0x23 )    { $key = "end" }                   # End
                elsif ( $vk == 0x21 )    { $key = "pgup" }                  # Page Up
                elsif ( $vk == 0x22 )    { $key = "pgdn" }                  # Page Down
                elsif ( $ascii == 0x04 ) { $ch->put( MsgQuit() ); last }    # Ctrl+D
                elsif ( $ascii == 0x03 ) { $key = "\cC" }                   # Ctrl+C
                elsif ( $ascii >= 0x20 ) { $key = chr($ascii) }             # printable
                $ch->put( MsgKey($key) ) if defined $key;
            }
        }
    }
    else {
        # POSIX: await_read uses select() on a background thread -- fiber
        # suspends until data is ready or the timeout fires.
        my $STDIN = \*STDIN;
        while ( !$quit->count ) {
            my $ready = Acme::Parataxis->await_read( $STDIN, 200 );
            next unless $ready > 0;
            my $bytes = '';
            my $n     = sysread( $STDIN, $bytes, 32 );
            if ( !defined $n || $n == 0 ) {
                $ch->put( MsgQuit() );
                last;
            }
            my $i = 0;
            while ( $i < length $bytes ) {
                my $ch1 = substr( $bytes, $i, 1 );
                $i++;
                if ( $ch1 eq "\e" ) {
                    my $seq = $ch1;
                    if ( $i < length $bytes ) {
                        while ( $i < length $bytes ) {
                            my $c = substr( $bytes, $i, 1 );
                            $i++;
                            $seq .= $c;
                            last if $c =~ /[A-HJKLZcffhlm]/;
                        }
                    }
                    else {
                        Acme::Parataxis->await_read( $STDIN, 20 );
                        my $extra = '';
                        sysread( $STDIN, $extra, 8 );
                        $seq .= $extra;
                        while (1) {
                            Acme::Parataxis->await_read( $STDIN, 5 );
                            my $more = '';
                            my $n    = sysread( $STDIN, $more, 8 );
                            last unless $n && $n > 0;
                            $seq .= $more;
                        }
                    }
                    if    ( $seq eq "\e[A" )     { $ch->put( MsgKey("\e[A") ) }
                    elsif ( $seq eq "\e[B" )     { $ch->put( MsgKey("\e[B") ) }
                    elsif ( $seq eq "\e[C" )     { $ch->put( MsgKey("\e[C") ) }
                    elsif ( $seq eq "\e[D" )     { $ch->put( MsgKey("\e[D") ) }
                    elsif ( $seq eq "\e[H" )     { $ch->put( MsgKey("home") ) }
                    elsif ( $seq eq "\e[F" )     { $ch->put( MsgKey("end") ) }
                    elsif ( $seq =~ /^\e\[5~$/ ) { $ch->put( MsgKey("pgup") ) }
                    elsif ( $seq =~ /^\e\[6~$/ ) { $ch->put( MsgKey("pgdn") ) }
                    else                         { $ch->put( MsgKey($seq) ) }
                }
                elsif ( $ch1 eq "\cC" ) {
                    $ch->put( MsgKey("\cC") );
                }
                elsif ( $ch1 eq "\cD" ) {
                    $ch->put( MsgQuit() );
                    last;
                }
                else {
                    $ch->put( MsgKey($ch1) );
                }
            }
        }
    }
}

# Fiber: terminal resize detection
my $RESIZE_FLAG = 0;

sub resize_fiber ( $ch, $quit, $init_w, $init_h ) {
    my $prev_w = $init_w;
    my $prev_h = $init_h;
    if ( $^O eq 'MSWin32' ) {
        while ( !$quit->count ) {
            Acme::Parataxis->await_sleep(100);    # 10 Hz polling
            my ( $w, $h ) = get_terminal_size();
            if ( $w != $prev_w || $h != $prev_h ) {
                ( $prev_w, $prev_h ) = ( $w, $h );
                $ch->put( MsgResize( $w, $h ) );
            }
        }
    }
    else {
        $SIG{WINCH} = sub { $RESIZE_FLAG = 1 };
        while ( !$quit->count ) {
            Acme::Parataxis->await_sleep(250);    # 4 Hz polling
            if ($RESIZE_FLAG) {
                $RESIZE_FLAG = 0;
                my ( $w, $h ) = get_terminal_size();
                if ( $w != $prev_w || $h != $prev_h ) {
                    ( $prev_w, $prev_h ) = ( $w, $h );
                    $ch->put( MsgResize( $w, $h ) );
                }
            }
        }
    }
}

# Fiber: periodic tick (1 Hz)
sub tick_fiber ( $ch, $quit ) {
    my $count = 0;
    while ( !$quit->count ) {
        Acme::Parataxis->await_sleep(1000);
        $count++;
        $ch->put( MsgTick($count) );
    }
}

# Main runtime
async {
    enable_raw_mode();
    hide_cursor();
    my $messages = Acme::Parataxis::Channel->new( capacity => 64 );

    # Shared quit signal -- broadcast() wakes all fibers checking it
    my $quit = Acme::Parataxis::Signal->new( count => 0 );

    # Query initial terminal size
    my ( $init_w, $init_h ) = get_terminal_size();

    # Initial model
    my $model = {
        cursor  => 0,
        ticks   => 0,
        toggled => {},
        width   => $init_w,
        height  => $init_h,
        items   => [
            'Async I/O via thread pool',
            'Fibers with cooperative scheduling',
            'Nonblocking reads on STDIN',
            'Concurrent tick timers',
            'Channel-based message passing',
            'SIGWINCH resize support',
            'No Term::ReadKey dependency'
        ],
    };

    # Spawn concurrent fibers (use `fiber` -- it has the & prototype)
    fiber { input_fiber( $messages, $quit ) };
    fiber { tick_fiber( $messages, $quit ) };
    fiber { resize_fiber( $messages, $quit, $init_w, $init_h ) };

    # Event loop
    clear_screen();
    while (1) {
        my $msg = $messages->get();
        my $cmd;
        ( $model, $cmd ) = Update( $model, $msg );
        if ( $cmd && $cmd->{type} eq 'quit' ) {
            last;
        }

        # Render.
        # await_write(STDOUT) uses select() which doesn't work on Windows
        # console handles -- skip it there.  stdout is always writable for
        # a console anyway.
        my $view = View($model);
        Acme::Parataxis->await_write( \*STDOUT, 50 ) if $^O ne 'MSWin32';
        clear_screen();
        print $view;
    }

    # Cleanup: signal all fibers to exit, then restore terminal
    $quit->send();    # sets $count = true so all fiber loops see it
    $messages->shutdown();
    show_cursor();
    clear_screen();
    move_to( 1, 1 );
    disable_raw_mode();
    say 'Goodbye!';
    Acme::Parataxis::stop();
};
