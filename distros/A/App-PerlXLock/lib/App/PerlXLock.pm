package App::PerlXLock;
$App::PerlXLock::VERSION = '0.08';
use strict;
use warnings;
use base 'Exporter';
our @EXPORT  = qw(main_loop);

BEGIN {
   use constant PLOCK_PASSWORD => $ENV{PLOCK_PASSWORD};
}

sub detect_x11 {
   my $pkg = `pkg-config --cflags --libs x11`;
   if($? != 0){
      die "Could not detect x11 using pkg-config (perhaps you are missing libx11)";
   }
   return $pkg;
}

use App::PerlXLock::Inline C => Config => LIBS => detect_x11();
use App::PerlXLock::Inline C => "DATA";

my @buffer;
my @windows;
my @screens;


sub lock_all {
    my $d = shift();
    for ( 0 .. screen_count($d) - 1 ) {
        push( @screens, $_ );
        push( @windows, open_lock( $d, $_ ) );
    }
}

sub has_shadow {
    -e "/etc/shadow";
}

sub shadow_readable {
    -r "/etc/shadow";
}

sub password_accessible {
    PLOCK_PASSWORD || ( has_shadow() && shadow_readable() );
}

sub check_event {
    my $ev = read_event( $_[0] );
    $ev > 0 ? push( @buffer, chr($ev) ) : undef;
}

sub check_password {
    my $pw = shift;
    defined( PLOCK_PASSWORD ) && return(PLOCK_PASSWORD eq $pw);
    check_unix_password($pw) == 0;
}

sub main_loop {
    my $d = open_connection();
    lock_all($d);
    grab_keyboard( $d, 0 );
    my $locked = 1;
    while ($locked) {
        check_event($d);
        if ( $buffer[-1] && $buffer[-1] eq "\n" ) {
            pop(@buffer);
            if ( password_accessible() ) {
                for my $n ( 0 .. $#buffer ) {
                    if ( check_password( join( "", @buffer[ $n .. $#buffer ] ) ) ) {
                        $locked = 0;
                    }
                }
            }
            else {
                $locked = 0;
            }
            @buffer = ();
        }
    }
    unlock_all($d);
    ungrab_keyboard($d);
    close_connection($d);
}

sub unlock_all {
    my $d = shift;
    destroy_window( $d, $_ ) for (@windows);
}

unless ( PLOCK_PASSWORD ) {
    has_shadow()
      || print "/etc/shadow does not exist. Xlock is not password protected.\n";
    shadow_readable
      || print "No permissions to read /etc/shadow. Xlock is not password protected.\n";
}

1;

__DATA__
__C__

#include <X11/Xlib.h>
#include <X11/X.h>
#include <X11/keysym.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <shadow.h>
#include <crypt.h>

SV *open_connection(){
    Display *display;
    SV *d_sv;
    SV *d_sv_ref;
    display = XOpenDisplay(NULL);
    if (display == NULL){
        croak("Could not open X display connection.");
    }
    d_sv = newSViv((IV)display);
    d_sv_ref = newRV_noinc(d_sv);
    return d_sv_ref;
}

void close_connection(SV* display){
    XCloseDisplay((Display *)SvIV(SvRV(display)));
}

void destroy_window(SV *display, int window){
    XDestroyWindow((Display *)SvIV(SvRV(display)), window);
}

int screen_count(SV *display){
    return XScreenCount((Display *)SvIV(SvRV(display)));
}

int close_window(SV *display, int window){
    XDestroyWindow((Display *)SvIV(SvRV(display)), window);
}

int open_lock(SV *disp_ref, int screen){
    Display *display;
    int window;
    int root;
    int status;
    XColor black, d;
    XSetWindowAttributes attr;
    XEvent event;

    display = (Display *)SvIV(SvRV(disp_ref));
    screen = XDefaultScreen(display);
    root = XRootWindow(display,screen);
    window = XCreateSimpleWindow(display, root, 0, 0, DisplayWidth(display,screen), DisplayHeight(display,screen), 1, BlackPixel(display, screen), BlackPixel(display, screen));
    attr.override_redirect = 1;
    XChangeWindowAttributes(display, window, CWOverrideRedirect, &attr);

    status = XMapRaised(display, window);
    XRaiseWindow(display, window);

    XSync(display,0);

    XSelectInput(display, root, SubstructureNotifyMask);
    return window;
} 

int grab_keyboard(SV *disp_ref, int screen){
    Display *display;
    int root;
    int kgrab;
    int mgrab; 

    display = (Display *)SvIV(SvRV(disp_ref));
    root = XRootWindow(display, screen);
    kgrab = XGrabKeyboard(display, root, True, GrabModeAsync, GrabModeAsync, CurrentTime);
    mgrab = XGrabPointer(display, root, False, ButtonPress | PointerMotionMask, GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
    return (kgrab > 0 && mgrab > 0);
}

void ungrab_keyboard(SV* disp_ref){
    Display *display;
    display = (Display *)SvIV(SvRV(disp_ref));
    XUngrabKeyboard(display, CurrentTime);
    XUngrabPointer(display, CurrentTime);
}

int read_event(SV *d){
    Display *display;
    char buffer[64];
    XEvent event;
    display = (Display *)SvIV(SvRV(d));
    KeySym sym;
    XNextEvent(display, &event);
    int num;

    if (event.type == KeyPress){
         num = XLookupString(&event.xkey, buffer, sizeof buffer, &sym, 0);
     if (num == 1) {
        if (sym == XK_Return){
            return 10;
        }else {
            return buffer[0];
        }
     }

    }
    return -1;
}


int check_unix_password(char *checkpw){
    struct spwd *entry;
    char *pw;
    entry = getspnam(getenv("USER"));
    pw = entry->sp_pwdp;
    return strcmp(pw, crypt(checkpw, pw));
}

=head1 NAME

App::PerlXLock - A simple X locking utility.

=head1 SYNOPSIS

    #lock without password
    plock 

    #When using perlbrew, the following zsh command runs lock with password read from /etc/shadow.
    #Add NOPASSWD to sudoers accordingly. 
    sudo $(which perl) $(which plock)

    #lock with password given in an environmental variable
    PLOCK_PASSWORD="password" plock

=head1 DESCRIPTION

A X11 locking utility. plock turns the screen black and waits for a key press. If /etc/shadow
is not accessible and PLOCK_PASSWORD is not set, plock terminates after pressing return. If /etc/shadow
is found to be readable, then it waits until the user has typed his password and pressed return. 

In case of mistyping the password, simply retype as plock detects once the correct password
appears in the buffer.

The module uses libX11, which must be installed prior to installing this module. 

=head1 CAVEATS

At the moment, recognizes only a shadow password file or the environmental variable.

=head1 LICENSE

This software is licensed under the same terms as Perl itself.

=cut
