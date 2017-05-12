package Catalyst::Blinker;

use strict;
use warnings;

=head1 NAME

Catalyst::Blinker - show a little X11 blinker while Catalyst is reloading

=head1 DESCRIPTION

I'm developing under Catalyst and am using the Catalyst test server that
is running on my local machine and is relaoding every time I'm saving changes
to the source tree. This is a cool feature, but I have to wait in front of the
browser until the application is loaded full and can answer http requests; if I hit
F5 in the browser before it is up and running I get a failure and have to hit it
again. I got tired of this and made this little module, that notifies me if it's
safe or not to operate the app.

The thing is very primitive. While Catalyst app is loading, it blinks yellow. If
it has loaded ok, it shows green light for a couple of seconds and disappears.
If there was a failure (syntax failure in my case most of the time), it shows red
light which doesn't go away until the problem is fixed.

Wasn't tested on anything other than ubuntu. Most probably wouldn't run on win32
out of box, because the module expects pipes and forks to be working.

=head1 SYNOPSIS

In your script/myapp.pl, add this, if you want blinker on by default:

    use Catalyst::Blinker;
    Catalyst::Blinker->start;

if you want it off by default, do this instead:

    if ( $ENV{BLINKER} ) {
       require Catalyst::Blinker;
       Catalyst::Blinker->start;
    }

before

    Catalyst::ScriptRunner->run('MyApp', 'Server');

In both cases, the module recognizes $ENV{BLINKER} and parses the passed options (see below),
f.ex.

    $ export BLINKER=x=1600,y=-150

=head1 API

=head2 start(@options)

Does the necessary hacks for a fork-based test catalyst server running on a X11 desktop.
Dies if there's no X11.

The modules does not do anything unless start() is called. It is safe to
use it everywhere.

=head2 options

=over

=item size INT

size of the blinker

=item x INT

Horizontal position of the blinker. If less than zero, the right desktop border is used.

=item y INT

Vertical position of the blinker. If less than zero, the bottom desktop border is used.

=back

=cut

our $VERSION = '1.0';

my %blinkopt = (
    size => 20,
    x => 0,
    y => 0,
);

sub start
{
    if ( $ENV{BLINKER} ) {
        # use as this:
        # env BLINKER=size=200,y=-20,x=1024
        my @opt = ( $ENV{BLINKER} =~ /^(1|yes|default)$/ ) ? ()
            : (split /[,=]/, $ENV{BLINKER});
        die "bad options to env BLINKER, (@opt), has to be a hash\n" if @opt % 2;
        my %opt = @opt;
        for ( keys %opt ) {
    	    $blinkopt{$_} = $opt{$_}, next if exists $blinkopt{$_};
            die "unknown blinker option '$_'\n";
        }
    }

    # options
    shift;
    my %opt = ( %blinkopt, @_ );

    # use this if you're tired to hit F5 until it loads
    require IO::Handle;
    pipe(my $r, my $w);
    autoflush $w, 1;

    {
        no warnings 'redefine';

        my $failed;

        require Catalyst::Script::Server;
        my $css_run = \&Catalyst::Script::Server::_run_application;
        *Catalyst::Script::Server::_run_application = sub {
            my $ret;
            eval { $ret = $css_run->(@_); };
            if ( $@ ) {
                $failed = 1;
                print $w "fail\n"; 
                die $@;
            } else {
                return $ret;
            }
        };
        
        my $css_pla = \&Catalyst::Script::Server::_plack_loader_args;
        *Catalyst::Script::Server::_plack_loader_args = sub {
            my %args = $css_pla->(@_);
            my $sr = delete $args{server_ready};
            $args{server_ready} = sub {
                $failed = 0;
                print $w "start\n"; 
                $sr ? $sr->(@_) : ();
            };
            return %args;
        };

        my $child = 0;
        require Catalyst::Restarter::Forking;
        my $crf_kc = \&Catalyst::Restarter::Forking::_kill_child;
        *Catalyst::Restarter::Forking::_kill_child = sub {
            print $w "stop\n" if not($failed) and $$ == $child;
            $crf_kc->(@_)
        };
        
        my $crf_fork = \&Catalyst::Restarter::Forking::_fork_and_start;
        *Catalyst::Restarter::Forking::_fork_and_start = sub {
            $child = $$;
            $crf_fork->(@_);
        };
    }

    my $pid = fork;
    die "fork error:$!" unless defined $pid;
    if ( $pid ) {
        close $r;
        return;
    }

    # child here
    eval "use Prima qw(Application);";
    die $@ if $@;

    close $w;
    my $size = $opt{size};
    my $center = $size / 2;
    my $countdown_to_hide = 0;
    my $circle  = Prima::Image->new(
        width     => $size,
        height    => $size,
        type      => 1,
        color     => 0xffffff,
        backColor => 0,
    );
    $circle->begin_paint;
    $circle->clear;
    $circle->fill_ellipse($center,$center,$size-2,$size-2);
    $circle->end_paint;
    my $dx = ( $opt{x} <= 0 ) ? $::application->width-$size-2+$opt{x} : $opt{x};
    my $dy = ( $opt{y} <= 0 ) ? $::application->height-$size-2+$opt{y} : $opt{y};
    my $blinker = Prima::Widget->new(
        origin      => [ $dx, $dy ],
        size        => [ $size, $size ],
        visible     => 1,
        syncPaint   => 1, 
        backColor   => cl::LightRed(),
        selectable  => 0,
        shape       => $circle,
        buffered    => 1,
        onPaint     => sub {
            my ( $self, $canvas ) = @_;
            $canvas->clear;
            $canvas->lineWidth(4);
            my ( $c, $x ) = ( 8, $size-2 );
            while ( $c < 16 ) {
                $canvas->color($canvas->backColor & ( $c * 0x101010) );
                $canvas->ellipse($center,$center,$x,$x);
                $canvas->lineWidth(2);
                $x--;
                $c++;
            }
        },
    );
    $blinker->bring_to_front;
    my $blinkstate = 0;
    my $blinkcolor = 16;
    my $timer = Prima::Timer->new(
        timeout   => 100,
        onTick    => sub {
            my $self = shift;
            if ( $blinkcolor == 8 && $countdown_to_hide > 0 ) {
                # green waits and hides the blinker
                unless (--$countdown_to_hide) {
                    $self->stop;
                    $blinker->hide;
                }
            }

            my $c;
            if ( $countdown_to_hide < 8 ) {
                # normal up-down blinking
                $blinkstate = 0 if ++$blinkstate > 15;
            } else {
                # green glows steadily, then nicely fades out
                $blinkstate = 7;
            }

            $c = ( $blinkstate > 7 ) ? ( 15 - $blinkstate ) : $blinkstate;
            $c = (( $c << 4 ) | 0x80) << $blinkcolor;
            $c |= ( $c >> 8 ) if $c > 0x10000; # makes it yellow, as red doesn't blink at all
            $blinker->backColor($c);
        },
    );
    $timer->start;
    my $reader = Prima::File->new(
        file   => $r,
        mask   => fe::Read(),
        onRead => sub {
            my $cmd = <$r>;
            chomp $cmd;
            if ( $cmd eq 'start' ) {
                $blinkstate = 0;
                $countdown_to_hide = 32;
                $blinkcolor = 8;
            } elsif ( $cmd eq 'stop') {
                $timer->start;
                $blinkstate = 0;
                $blinkcolor = 16;
                $blinker->backColor(0x808000);
                $blinker->show;
                $blinker->bring_to_front;
            } elsif ( $cmd eq 'fail') {
                $blinker->backColor(cl::LightRed());
                $blinker->show;
                $blinker->bring_to_front;
                $timer->stop;
            }
        },
    );
    run Prima;
    exit;
}

1;

=head1 AUTHOR

Dmitry Karasik <dmitry@karasik.eu.org>

=head1 LICENSE

Copyright (C) 2013, Novozymes.

=cut
