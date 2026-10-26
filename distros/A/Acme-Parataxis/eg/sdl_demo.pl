use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use SDL3            qw[:all];

# A tiny SDL3 animation where every frame tick is a Parataxis park rather
# than a raw SDL_Delay: each bouncing square is its own fiber that steps its
# own physics and then await_sleep(16) lets the render fiber (the run() body)
# composite the shared state. Close the window or press Esc to quit early,
# otherwise the demo self-limits to FRAMES ticks and exits 0.
#
# SDL_PollEvent cannot hand the SDL3 event union back to Perl reliably, so we
# use the event-watch callback path (the same one the :main harness uses) and
# only read event fields inside the callback. PumpEvents is called once per
# rendered frame to let queued events reach the watch.
my $W       = 640;
my $H       = 480;
my $BLOBS   = 8;
my $TICK    = 16;    # ms between scheduler ticks (one "frame")
my $FRAMES  = 90;    # ~1.5-3s of animation, then the demo ends itself
my $quit    = 0;
my @palette = (
    [ 255, 90,  90 ],
    [ 255, 200, 60 ],
    [ 120, 255, 120 ],
    [ 90,  210, 255 ],
    [ 220, 130, 255 ],
    [ 255, 140, 200 ],
    [ 140, 255, 220 ],
    [ 255, 255, 170 ]
);

sub on_event ( $userdata, $event ) {
    my $type = $event->{type};
    $quit = 1
        if $type == SDL_EVENT_QUIT or
        $type == SDL_EVENT_WINDOW_CLOSE_REQUESTED or
        ( $type == SDL_EVENT_KEY_DOWN && $event->{key}{key} == SDLK_ESCAPE );
    return 1;    # keep every event flowing
}
my $rc = SDL_Init(SDL_INIT_VIDEO);
if ( !$rc ) {
    say "SDL unavailable (SDL_Init: ", SDL_GetError(), "); skipping the SDL demo.";
    exit 0;
}
my ( $win, $ren );
$rc = SDL_CreateWindowAndRenderer( 'parataxis splat', $W, $H, 0, \$win, \$ren );
if ( !$rc ) {
    say "SDL unavailable (SDL_CreateWindowAndRenderer: ", SDL_GetError(), "); skipping the SDL demo.";
    SDL_Quit();
    exit 0;
}
SDL_SetRenderVSync( $ren, 1 );
SDL_AddEventWatch( \&on_event, undef );    # non-fatal: the frame budget still ends us
my @blobs = map {
    my ( $r, $g, $b ) = @{ $palette[ $_ - 1 ] };
    {   x  => int( rand $W ),
        y  => int( rand $H ),
        dx => ( rand() < 0.5 ? -1 : 1 ) * ( 1 + int( rand 3 ) ),
        dy => ( rand() < 0.5 ? -1 : 1 ) * ( 1 + int( rand 3 ) ),
        w  => 16 + int( rand 20 ),
        h  => 16 + int( rand 20 ),
        r  => $r,
        g  => $g,
        b  => $b
    };
} 1 .. $BLOBS;

sub blob_actor ($b) {
    while ( !$quit ) {
        $b->{x} += $b->{dx};
        $b->{y} += $b->{dy};
        if    ( $b->{x} < 0 )            { $b->{x} = 0;            $b->{dx} = -$b->{dx} }
        elsif ( $b->{x} > $W - $b->{w} ) { $b->{x} = $W - $b->{w}; $b->{dx} = -$b->{dx} }
        if    ( $b->{y} < 0 )            { $b->{y} = 0;            $b->{dy} = -$b->{dy} }
        elsif ( $b->{y} > $H - $b->{h} ) { $b->{y} = $H - $b->{h}; $b->{dy} = -$b->{dy} }
        await_sleep($TICK);
    }
}
my $frame     = 0;
my $presented = 0;
Acme::Parataxis::run(
    sub {
        say "parataxis drives $BLOBS actor fibers + one render fiber at ~${TICK}ms ticks";
        say "animate for ~", $FRAMES * $TICK / 1000, "s, or close the window / press Esc to quit early";
        my @actors = map {
            spawn( sub { blob_actor($_) } )
        } @blobs;
        while ( !$quit && $frame < $FRAMES ) {
            SDL_PumpEvents();
            SDL_SetRenderDrawColor( $ren, 18, 22, 32, 255 );
            SDL_RenderClear($ren);
            for my $b (@blobs) {
                SDL_SetRenderDrawColor( $ren, $b->{r}, $b->{g}, $b->{b}, 255 );
                SDL_RenderFillRect( $ren, { x => $b->{x}, y => $b->{y}, w => $b->{w}, h => $b->{h} } );
            }
            SDL_RenderPresent($ren);
            $presented++;
            $frame++;
            if ( $frame % 30 == 0 ) {
                say sprintf '  [fiber %-2d] frame %3d  blob 1 @ (%3d,%3d)  blob 5 @ (%3d,%3d)', current_fid(), $frame, $blobs[0]{x}, $blobs[0]{y},
                    $blobs[4]{x}, $blobs[4]{y};
            }
            await_sleep($TICK);
        }
        $quit = 1;
        say "rendered $presented frames" . ( $presented < $FRAMES ? ' (quit early via event)' : '' );
        die "self-test failed: no frame ever rendered\n" if !$presented;
        stop();
    }
);
SDL_DestroyRenderer($ren);
SDL_DestroyWindow($win);
SDL_Quit();
say 'exit 0';
