package Acme::MUDLike;

use 5.008000;
use strict;
use warnings;

use Continuity;
use Carp;
use Devel::Pointer;

our $VERSION = '0.04';

# Todo:
# 
# *  what would be *really* cool is doing on the fly image generation to draw an overhead map of the program based on a 
#    graph of which objects reference which other objects and let people go walk around inside of their program
#    and then they could fight methods and use global variables as weapons!
#
# * http://zvtm.sourceforge.net/zgrviewer.html or something similar for showing the user the "map" of
#   nodes/rooms/whatever made of has-a references or something.
# 
# * /goto should put you inside an arbitrary object, /look should list as exits and/or items the object references contained by that object
#   in other words, break away from our rigid API for inventory/room/etc.
# 
# * need a black list black list, so we can re-add ourself to things that get serialized by Acme::State even though we're in %INC
# 
# * need an error log viewabe by all.
# 
# * eval and its output should be sent to the whole room.
# 
# * Better account management.
# 
# * There's code around to parse LPC and convert it to Perl.  It would be neat to offer a full blown 2.4.5
#   lib for people to play around in.
# 
# * Acme::IRCLike would probably be more popular -- bolt an IRC server onto your app.
# 
# * Also, a telnet interface beyond just an HTTP interface would be nice.  Should be easy to do.
# 
# * Let "players" wander between apps.  Offer RPC to support this.
# 
# * Optionally take an existing Continuity instance with path_session set and optionally parameters
#   for the paths to use for chat pull and commands.
#   Not sure how to work this; each path gets its own coroutine, but there is still only one main().
#   Continuity doesn't have a registry of which paths go to which callbacks.
# 
# Done:
# 
# * mark/call commands should have a current object register, so you can do /call thingie whatever /next and then be calling 
#   into the object returned by thingie->whatever
# 
# * /list (like look, but with stringified object references)
# 
# * /mark <n>  ... or... /mark <stringified obj ref>
# 
# * messages still in duplicate when the same player logs in twice; make room's tell_object operate uniquely.
# 
# * messages in triplicate because each player has three routines and is inserted into the floor three times.  oops.
# 
# * build the ajax.chat.js into source. -- okay, test.
# 
# * eval, call
# 
# * inventory's insert() method should set the insertee's environment to itself.  that way, all objects have an environment.
# 
# * Commands need to do $floor->tell_object or $self->tell_object rather than output directly.
# 
# * Put @messages into the room ($floor).  Get the chat action out of the main loop.  Dispatch all
#   actions.  Maybe.
# 

our $password; # Acme::State friendly
our $floor;    # holds all other objects
our $players;  # holds all players; kind of like $floor except in the future, inactive players might get removed from the floor, or there might be multiple rooms

my $continuity;
my $got_message;   # diddled to wake the chat event watchers

$SIG{PIPE} = 'IGNORE';

sub new {
    my $package = shift;
    my %args = @_;

    die "We've already got one" if $continuity;

    $password = delete $args{password} if exists $args{password};
    $password ||= join('', map { $_->[int rand scalar @$_] } (['a'..'z', 'A'..'Z', '0'..'9']) x 8),

    my $staticp = sub { 
        # warn "staticp: url->path: ``@{[ $_[0]->url->path ]}''"; 
        return 0 if $_[0]->url->path =~  m/\.js$/; 
        # warn "staticp: dynamic js handling override not engaged";
        return $_[0]->url->path =~ m/\.(jpg|jpeg|gif|png|css|ico|js)$/ 
    };

    $continuity = $args{continuity} || Continuity->new(
        staticp => sub { $staticp->(@_); },
        callback => sub { login(@_) },
        path_session => 1,
        port => 2000,
        %args,
    );

    print "Admin:\n", $continuity->adapter->daemon->url, '?admin=', $password, '&nick=', (getpwuid $<)[0], "\n";

    $floor ||= Acme::MUDLike::room->new();
    $players ||= Acme::MUDLike::inventory->new();

    bless { }, $package;
}

sub loop { my $self = shift; $continuity->loop(@_); }

sub header {
    qq{
        <html><head>
            <script src="/jquery.js" type="text/javascript"></script>
            <script src="/chat.js" type="text/javascript"></script>
        </head><body>
    }; 
}

sub footer { qq{</body></html>\n}; }

sub login {

    my $request = shift;

    #
    # per-user variables
    #

    my $player;

    # STDERR->print("debug: " . $request->request->url->path . "\n"); # XXX
    # STDERR->print("debug: " . $request->request->as_string . "\n"); # XXX
    $SIG{PIPE} = 'IGNORE'; # XXX not helping at all.  grr.

    #
    # static files
    #

    if($request->request->url->path eq '/chat.js') {
        # warn "handling chat.js XXX: ". $request->request->url->path;
        $request->print(Acme::MUDLike::data->chat_js());
        return;
    } elsif($request->request->url->path eq '/jquery.js') {
        # warn "handling jquery.js XXX: ". $request->request->url->path;
        $request->print(Acme::MUDLike::data->jquery());
        return;
    }

    #
    # login
    #

    while(1) {
        my $nick_tmp = $request->param('nick');
        my $admin_tmp = $request->param('admin');
        if(defined($nick_tmp) and defined($admin_tmp) and $nick_tmp =~ m/^[a-z]{2,20}$/i and $admin_tmp eq $password) {
            my $nick = $nick_tmp;
            $player = $players->named($nick) || $players->insert(Acme::MUDLike::player->new(name => $nick), );
            $player->request = $request;
            # @_ = ($player, $request,); goto &{Acme::MUDLike::player->can('command')};
            $player->command($request); # doesn't return
        }
        # warn "trying login again XXX";
        $nick_tmp ||= ''; $admin_tmp ||= '';
        $nick_tmp =~ s/[^a-z]//gi; $admin_tmp =~ s/[^a-z0-9]//gi;
        $request->print(
            header, # $msg, 
            qq{
                <form method="post" action="/">
                    <input type="text" name="nick" value="$nick_tmp"> &lt;-- nickname<br>
                    <input type="password" name="admin" value="$admin_tmp"> &lt;-- admin password<br>
                    <input type="submit" value="Enter"><br>
                </form>
            },
            footer,
        );
        $request->next();
    }

}

#
# object
#

package Acme::MUDLike::object;

sub new { my $package = shift; bless { @_ }, $package; }
sub name :lvalue { $_[0]->{name} }
sub environment :lvalue { $_[0]->{environment} }
sub use { }
sub player { 0 }
sub desc { }
sub tell_object { }
sub get { 1 } # may be picked up
sub id { 0 }

#
# inventory
#

package Acme::MUDLike::inventory;

sub new { 
    # subclass this to build little container classes or create instances of it directly
    my $package = shift; bless [ ], $package; 
}

sub delete {
    my $self = shift;
    my $name = shift;
    for my $i (0..$#$self) {
        return splice @$self, $i, 1, () if $self->[$i]->id($name);
    }
}
sub insert {
    my $self = shift;
    my $ob = shift;
    UNIVERSAL::isa($ob, 'Acme::MUDLike::object') or Carp::confess('lit: ' . $ob . ' ref: ' . ref($ob));
    push @$self, $ob;
    $ob->environment = $self;
    $ob;
}
sub named {
    my $self = shift;
    my $name = shift;
    for my $i (@$self) {
        return $i if $i->id($name);
    }
}
sub apply {
    my $self = shift;
    my $func = shift;
    my @args = @_;
    my @ret;
    for my $i (@$self) {
        if(ref($func) eq 'CODE') { 
            push @ret, $func->($i, @args);
        } else {
            push @ret, $i->can($func)->($i, @args);
        }
    }
    return @ret;
}

sub contents {
    my $self = shift;
    return @$self;
}

#
# room
#

package Acme::MUDLike::room;
push our @ISA, 'Acme::MUDLike::inventory';

sub tell_object {
    my $self = shift;
    my $message = shift;
    # rather than buffering messages, room objects recurse and distribute the message to everyone and everything in it
    # $self->apply('tell_object', $message);
    my %already_told;
    $self->apply(sub { return if $already_told{$_[0]}++; $_[0]->tell_object($message); }, );
}

#
# players
#

package Acme::MUDLike::players;
push our @ISA, 'Acme::MUDLike::inventory'; # use base 'Acme::MUDLike::inventory';

#
# player
#

package Acme::MUDLike::player;
push our @ISA, 'Acme::MUDLike::object';

sub player { 1 }
sub new {
    my $pack = shift;
    bless {
        inventory => Acme::MUDLike::inventory->new,
        messages => [ ],
        @_,
    }, $pack;
}
sub request :lvalue { $_[0]->{request} }
sub id { $_[0]->{name} eq $_[1] or $_[0] eq $_[1] }
sub name { $_[0]->{name} }
sub password { $_[0]->{password} }
sub x :lvalue { $_[0]->{x} }
sub y :lvalue { $_[0]->{y} }
sub xy { $_[0]->{x}, $_[0]->{y} }
sub get { 0; } # can't be picked up
sub inventory { $_[0]->{inventory} }
sub evalcode :lvalue { $_[0]->{evalcode } }
sub current_item :lvalue { $_[0]->{current_item} }

sub tell_object {
    my $self = shift;
    my $msg = shift;
    push @{$self->{messages}}, $msg;
    shift @{$self->{messages}} if @{$self->{messages}} > 100;
    $got_message = 1; # XXX wish this didn't happen for each player but only once after all players got their message
}

sub get_html_messages {
    my $self = shift;
    return join "<br>\n", map { s{<}{\&lt;}gs; s{\n}{<br>\n}g; $_ } $self->get_messages;
}

sub get_messages {
    my $self = shift;
    my @ret;
    # this is written out long because I keep changing it around
    for my $i (1..20) {
        exists $self->{messages}->[-$i] or last;
        my $msg = $self->{messages}->[-$i];
        push @ret, $msg;
    }
    return reverse @ret;
}

sub header () { Acme::MUDLike::header() }
sub footer () { Acme::MUDLike::footer() }

sub command {

    my $self = shift;
    my $request = shift;

    # this is called by login() immediately after verifying credientials

    if($request->request->url->path =~ m/pushstream/) {
        # warn "pushstream path_session handling XXX";
        my $w = Coro::Event->var(var => \$got_message, poll => 'w');
        while(1) {
            $w->next;
            # warn "got_message diddled XXX";
            # on submitting the form without a JS background post, the poll HTTP connection gets broken
            $SIG{PIPE} = 'IGNORE';
            $request->print( join "<br>\n", map { s{<}{\&lt;}gs; s{\n}{<br>\n}g; $_ } $self->get_messages );
            $request->next;
        }
    }

    if($request->request->url->path =~ m/sendmessage/) {
        while(1) {
            # warn "sendmessage path_session handling XXX";
            my $msg = $request->param('message');  
            $self->parse_command($msg);
            # $request->print("Got message.\n");
            $request->print($self->get_html_messages());
            $request->next;
        }
    }

    #
    # players get three execution contexts:
    # * one for AJAX message posts without header/footer in the reply
    # * one for COMET message pulls
    # * the main HTML one below (which might only run once); arbitrarily selected as being the main one cuz its longest
    #

    $floor->insert($self);

    while(1) {

        $request->print(header);
    
        #
        # chat/commands
        #
 
        if($request->param('action') and $request->param('action') eq 'chat') {
            # chat messages first so they appear in the log below
            # there's only one action defined right now -- chat.  everything else hangs off of that. 
            my $msg = $request->param('message');  
            $self->parse_command($msg);
        };

        do {

            $request->print(qq{
                <b>Chat/Command:</b>
                <form method="post" id="f" action="/">
                    <input type="hidden" name="action" value="chat">
                    <input type="hidden" id="nick" name="nick" value="@{[ $self->name ]}"> 
                    <input type="hidden" id="admin" name="admin" value="$password">
                    <input type="text" id="message" name="message" size="50">
                    <!-- <input type="submit" name="sendbutton" value="Send" id="sendbutton"> -->
                    <input type="submit" name="sendbutton" value="Send" id="sendbutton">
                    <span id="status"></span>
                </form>
                <br>
                <div id="log">@{[ $self->get_html_messages ]}</div>
            });
        };

    } continue {
        $request->print(footer);
        $request->next();
    }  # end while
}

sub parse_command {
    my $self = shift;
    my $msg = shift;
warn "parse_command: msg: ``$msg''";
    $self->tell_object("> $msg");
    if($msg and $msg =~ m{^/}) {
        my @args = split / /, $msg;
        (my $cmd) = shift(@args) =~ m{/(\w+)};
        # XXX I'd like to see template matching, like V N A N, then preact/act/postact
        if( $self->can("_$cmd") ) {
            eval { $self->can("_$cmd")->($self, @args); 1; } or $self->tell_object("Error in command: ``$@''.");
        } else {
            $self->tell_object("No such command:  $cmd.");
        }
    } elsif($msg) {
        $floor->tell_object($self->name . ': ' . $msg); # XXX should be $self->environment->tell_object
        # $request->print("Got it!\n");
    }
}

sub item_by_arg {
    my $self = shift;
    my $item = shift;
    my $ob;
    return $self->current_item if $item eq 'current';
    if($item =~ m/^\d+$/) {
        my @stuff = $self->environment->contents;
        $ob = $stuff[$item] if $item < @stuff;
    }
    $ob or $ob = $self->inventory->named($item);      # thing in our inventory with that name
    $ob or $ob = $self->environment->named($item);     # thing in our environment with that name
    $ob or $ob = $item if exists &{$item.'::new'}; # raw package name
    $ob or do {
      # Foo::Bar=HASH(0x812ea54)
      my $hex;
      ($hex) = $item =~ m{^[a-z][a-z_:]+\((0x[0-9a-z]+)\)}i;
      $hex or ($hex) = $item =~ m{^0x([0-9a-z]+)}i;
      if($hex) {
          $ob = Devel::Pointer::deref(hex($hex));
      }
    };
    return $ob;
}

# actions

sub _call {
    my $self = shift;
    # XXX call a method an in object
    # XXX call sword name 
    my $item = shift;
    my $func = shift;
    my @args = @_; # XXX for each arg, go through the item finding code below, except keep identify if not found
    my $ob = $self->item_by_arg($item) or do {
        $self->tell_object("call: no item by that name/number/package name here");
        return;
    };
    for my $i (0..$#args) {
        my $x = $self->item_by_arg($args[$i]);
        $args[$i] = $x if $x;
    }
    $ob->can($func) or do {
        $self->tell_object("call:  item ``$item'' has no ``$func'' method");
        return;
    };
    $self->tell_object(join '', "Call: ", eval { $ob->can($func)->($ob, @args); } || "Error: ``$@''.");
    1;
}

sub _list {
    my $self = shift;
    my $i = 0;
    $self->tell_object(join '', 
        "Here, you see:\n", 
        map qq{$_\n}, 
        map { $i . ': ' . $_ }
        $self->environment->contents, $self->inventory->contents,
    ); 
}

sub _mark {
    my $self = shift;
    my $item = shift;
    my $ob = $self->item_by_arg($item) or do {
        $self->tell_object("mark: no item by that name/number/package name here");
        return;
    };
    $self->current_item = $ob;
}

sub _eval {
    my $self = shift;
    my $cmd = join ' ', @_;
    no warnings 'redefine';
    # *print = sub { $self->tell_object(@_); };  # this doesn't work reliablely due to possible context changes but worth a shot
    # *say = sub { $self->tell_object("@_\n"); }; # ack... doesn't work at all.
    select $self->request->{request}->{conn};  # would rather it went into their message buffer but comprimising for now
    my $res = eval($cmd) || "Error: ``$@''.";
    $self->tell_object("eval:\n$res");
}

sub _who {
    my $self = shift;
    $self->_look(@_); # for now
}

sub _look {
    my $self = shift;
    my @args = @_;
    # $self->tell_object(join '', "Here, you see:\n", map qq{$_\n}, map $_->name, $floor->contents); 
    $self->tell_object(join '', 
        "Here, you see:\n", 
        map qq{$_\n}, 
        map { $_->can('name') ? $_->name : ref($_) }
        $self->environment->contents
    ); 
}

sub _inv {
    my $self = shift;
    $self->_inventory(@_);
}

sub _i {
    my $self = shift;
    $self->_inventory(@_);
}

sub _inventory {
    my $self = shift;
    my @args = @_;
    $self->tell_object(join '', 
        "You are holding:\n", 
        map qq{$_\n}, 
        map { $_->can('name') ? $_->name : ''.$_ } 
        $self->inventory->contents
    ); 
}

sub _take {
    my $self = shift;
    my @args = @_;
    if(@args == 1) {
        # take thingie
        my $item = $floor->delete($args[0]) or do { $self->tell_object("No ``$args[0]'' here."); return; };
        $self->inventory->insert($item);
        $self->tell_object(qq{Taken.});
    } elsif(@args == 2) {
        $self->tell_object("I don't understand ``$args[0] $args[1]''.");
    } elsif(@args == 3) {
        if($args[1] ne 'from') {
            $self->tell_object("I don't understand ``$args[1] $args[2]''.");
            return;
        }
        my $container = $floor->named($args[2]) or do { $self->tell_object("No ``$args[2]'' here."); return; };
        my $item = $container->inventory->delete($args[0]) or do { $self->tell_object("No ``$args[0]'' here."); return; };
        $self->inventory->insert($item);
        $self->tell_object(qq{Taken.});
    } elsif(! @args or @args > 3) {
        $self->tell_object("Take what?");
    }
}

sub _drop {
    my $self = shift;
    my @args = @_;
    if(@args != 1) {
        $self->tell_object("Drop what?");
        return;
    }
    my $item = $self->delete($args[0]) or do { $self->tell_object("You have no ``$args[0]''."); return; }; 
    $floor->insert($item);
    $self->tell_object(qq{Dropped.});
}

sub _give {
    my $self = shift;
    my @args = @_;
    if(@args != 3 or $args[1] ne 'to') {
        $self->tell_object(qq{Give what to whom?});
        return;
    }
    my $item = $self->inventory->named($args[0]) or do { $self->tell_object("You have no ``$args[0]''."); return; };
    my $container = $floor->named($args[2]) or do { $self->tell_object("There is no ``$args[2]'' here."); return; };
    $self->inventory->delete($args[0]);
    $container->inventory->insert($item);
    $self->tell_object("Ok.");
}

sub _clone {
    my $self = shift;
    my $ob = shift;
    if(! $ob) {
        $self->tell_object(qq{Clone what?});
        return;
    }
    my $item = eval { $ob->new() };
    if(! $item ) {
        $self->tell_object("Failed to load object: ``$@''.");
        return;
    }
    # XXX force an inheritance of object onto it if it doesn't already have one?
    $self->inventory->insert($item);
    $self->tell_object("Ok.");
}

sub _dest {
    my $self = shift;
    my @args = @_;
    if(@args != 1) {
        $self->tell_object(qq{Dest what?});
        return;
    }
    $self->inventory->delete($args[0]) or do { $self->tell_object("You don't have a ``$args[0]''."); return; };
    $self->tell_object("Dest: Ok.");
}


=head1 NAME

Acme::MUDLike - Hang out inside of your application

=head1 SYNOPSIS

    use Acme::MUDLike; 
    my $server = Acme::MUDLike->new;

    # ... your code here

    $server->loop;  # or call the Event or AnyEvent event loop

Connect to the URL provided and cut and paste into the text box:

    /eval package sword; our @ISA = qw/Acme::MUDLike::object/; sub new { my $pack = shift; $pack->SUPER::new(name=>"sword", @_); }
    /clone sword
    /i
    /call sword name
    wee, fun!  oh, hai everyone!
    /eval no strict "refs"; join '', map "$_\n", keys %{"main::"};
    /call Acme::MUDLike::player=HASH(0x8985e10) name

=head1 DESCRIPTION

Multi user chat, general purpose object tracer, eval, and give/drop/take/clone/dest/look.

Adds a social element to software development and develop it from within.
Chat within the application, eval code inside of it (sort of like a simple Read-Eval-Parse Loop).
Call methods in objects from the command line.
Create instances of objects, give them to people, drop them on the floor.

The idea is take the simple command line interface and extend it with more commands,
and to create tools and helper objects that inspect and modify the running program from within.

It fires up a Continuity/HTTP::Daemon based Web server on port 2000 and prints out a login
URL on the command line.
Paste the URL into your browser.
Chat with other users logged into the app.
Messages beginning with a slash, C</>, are interpreted as commands:

=over 2

=item C<< /look >> 

See who else and what else is in the room.

=item C<< /mark >>

  /mark 1

  /mark torch

  /mark foo::bar

  /mark 0x812ea54

Select an object as the logical current object by name, package name, number (as a position in your
inventory list, which is useful for when you've cloned an object that does not define an C<id> or C<name> function),
or by memory address (as in C<< Foo::Bar=HASH(0x812ea54) >>).

=item C<< /call >> 

Call a function in an object; eg, if you're holding a C<toaster>, you can write:

  /call toaster add_bread 1

The special name "current" refers to the current object, as marked with mark.

=item C<< /eval >>

Executes Perl.
C<< $self >> is your own player object.
C<< $self->inventory >> is an C<< Acme::MUDLike::inventory >> object with C<delete>, C<insert>, C<named>,
C<apply>, and C<contents> methods.
C<< $self->environment >> is also an C<< Acme::MUDLike::inventory >> object holding you and other players 
and objects in the room.
The environment and players in it all have C<tell_object> methods that takes a string to add to their
message buffer.
Calling C<tell_object> in the environment sends the message to all players.
Objects define various other methods.

=item C<< /who >>

List of who is logged in.  Currently the same C</look>.

=item C<< /inventory >>

Or C</i> or C</inv>.  Lists the items you are carrying.

=item C<< /clone >>

Creates an instance of an object given a package name.  Eg:

  /clone sword

=item C<< /take >>

Pick up an item from the floor (the room) and place it in your inventory.
Or alternatively C<< /take item from player >> to take something from someone.

=item C<< /drop >>

Drop an item on the floor.

=item C<< /give >>

Eg:

  /give sword to scrottie

Transfers an object to another player.

=item C<< /dest >>

Destroys an object instance.

=back

=head2 new()

Each running program may only have one L<Acme::MUDLike> instance running.
It would be dumb to have two coexisting parallel universes tucked away inside the same program.
Hell, if anything, it would be nice to do some peer discovery, RPC, object serialization, etc,
and share objects between multiple running programs.

=item C<continuity>

Optional.  Pass in an existing L<Continuity> instance.
Must have been created with the parameter  C<< path_session => 1 >>.

=item C<port>

Optional.  Defaults to C<2000>.
This and other parameters, such as those documented in L<Continuity>, are passed through
to C<< Continuity->new() >>.

=item C<password>

Optional.  Password to use.
Everyone gets the same password, and anyone with the password can log in with any name.
Otherwise one is pseudo-randomly generated and printed to C<stdout>.

=cut

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.23 with options

  -A -C -X -b 5.8.0 -c -n Acme::MUDLike

=back

=head1 TODO

(Major items... additional in the source.)

=item Test.  Very, very green right now.

=item Telnet in as well as HTTP.

=item JavaScript vi/L<Acme::SubstituteSubs> integration.

=item Multiple rooms.  Right now, there's just one.

The JavaScript based vi and file browser I've been using with L<Acme::SubstituteSubs> isn't in any of my modules 
yet so development from within isn't really practical using just these modules. 
There's some glue missing.

=head1 SEE ALSO

=item L<Continuity>

=item L<Continuity::Monitor>

=item L<Acme::State>

=item  L<Acme::SubstituteSubs>

L<Acme::State> preserves state across runs and L<Acme::SubstituteSubs>.
These three modules work on their own but are complimentary to each other.
Using L<Acme::SubstituteSubs>, the program can be modified in-place without being restarted,
so you don't have to log back in again after each change batch of changes to the code.
Code changes take effect immediately.
L<Acme::State> persists variable values when the program is finally stopped and restarted.
L<Acme::State> will also optionally serialize code references to disc, so you can
C<eval> subs into existance and let it save them to disc for you and then later
use L<B::Deparse> to retrieve a version of the source.

The C<Todo> comments near the top of the source.

=head1 AUTHOR

Scott Walters, E<lt>scott@slowass.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Scott Walters

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.
By using this software, you signify that you like llamas.

Includes code by John Resig:

 jQuery 1.1.2 - New Wave Javascript

 Copyright (c) 2007 John Resig (jquery.com) 
 Dual licensed under the MIT (MIT-LICENSE.txt)
 and GPL (GPL-LICENSE.txt) licenses.

 $Date: 2007-02-28 12:03:00 -0500 (Wed, 28 Feb 2007) $
 $Rev: 1465 $

Includes code by Awwaiid (Brock Wilcox)

=cut

package Acme::MUDLike::data;

sub chat_js {

return <<'EOF';

var poll_count = 0;

function new_request() {
  var req;
  if (window.XMLHttpRequest) {
    req = new XMLHttpRequest();
  } else if (window.ActiveXObject) {
    req = new ActiveXObject("Microsoft.XMLHTTP");
  } 
  return req;
}

function do_request(url, callback) {
  var req = new_request();
  if(req != undefined) {
    req.onreadystatechange = function() {
      if (req.readyState == 4) { // only if req is "loaded"
        if (req.status == 200) { // only if "OK"
          if(callback) callback(req.responseText);
        } else {
          alert("AJAX Error:\r\n" + req.statusText);
        }
      }
    }
    req.open("GET", url, true);
    req.send("");
  }
}

function setup_poll() {
   setTimeout('poll_server()', 1000);
}

function poll_server() {
  var nick = document.getElementById("nick").value;
  var admin = document.getElementById("admin").value;
  document.getElementById('status').innerHTML = 'Polling ('+(poll_count++)+')...';
  do_request('/pushstream/?nick=' + nick + '&admin=' + admin, got_update);
}

function got_update(txt) {
  document.getElementById('status').innerHTML = 'Got update.'
  if(document.getElementById("log").innerHTML != txt)
    document.getElementById("log").innerHTML = txt;
  setup_poll();
}

// This stuff gets executed once the document is loaded
$(function(){
  // Start up the long-pull cycle
  setup_poll();
  // Unobtrusively make submitting a message use send_message()
  $('#f').submit(send_message);
});

// We also send messages using AJAX
function send_message() {
  var nick = $('#nick').val();
  var admin = $('#admin').val();
  var message = $('#message').val();
  $('#log').load('/sendmessage', {
    nick:     nick,
    admin:    admin,
    action:   'ajaxchat',
    message:  message
  }, function() {
    $('#message').val('');
    $('#message').focus();
  });
  return false;
}

EOF

}

sub jquery {

return <<'EOF';

/* prevent execution of jQuery if included more than once */
if(typeof window.jQuery == "undefined") {
/*
 * jQuery 1.1.2 - New Wave Javascript
 *
 * Copyright (c) 2007 John Resig (jquery.com)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * $Date: 2007-02-28 12:03:00 -0500 (Wed, 28 Feb 2007) $
 * $Rev: 1465 $
 */

// Global undefined variable
window.undefined = window.undefined;
var jQuery = function(a,c) {
	// If the context is global, return a new object
	if ( window == this )
		return new jQuery(a,c);

	// Make sure that a selection was provided
	a = a || document;
	
	// HANDLE: $(function)
	// Shortcut for document ready
	if ( jQuery.isFunction(a) )
		return new jQuery(document)[ jQuery.fn.ready ? "ready" : "load" ]( a );
	
	// Handle HTML strings
	if ( typeof a  == "string" ) {
		// HANDLE: $(html) -> $(array)
		var m = /^[^<]*(<(.|\s)+>)[^>]*$/.exec(a);
		if ( m )
			a = jQuery.clean( [ m[1] ] );
		
		// HANDLE: $(expr)
		else
			return new jQuery( c ).find( a );
	}
	
	return this.setArray(
		// HANDLE: $(array)
		a.constructor == Array && a ||

		// HANDLE: $(arraylike)
		// Watch for when an array-like object is passed as the selector
		(a.jquery || a.length && a != window && !a.nodeType && a[0] != undefined && a[0].nodeType) && jQuery.makeArray( a ) ||

		// HANDLE: $(*)
		[ a ] );
};

// Map over the $ in case of overwrite
if ( typeof $ != "undefined" )
	jQuery._$ = $;
	
// Map the jQuery namespace to the '$' one
var $ = jQuery;

jQuery.fn = jQuery.prototype = {
	jquery: "1.1.2",

	size: function() {
		return this.length;
	},
	
	length: 0,

	get: function( num ) {
		return num == undefined ?

			// Return a 'clean' array
			jQuery.makeArray( this ) :

			// Return just the object
			this[num];
	},
	pushStack: function( a ) {
		var ret = jQuery(a);
		ret.prevObject = this;
		return ret;
	},
	setArray: function( a ) {
		this.length = 0;
		[].push.apply( this, a );
		return this;
	},
	each: function( fn, args ) {
		return jQuery.each( this, fn, args );
	},
	index: function( obj ) {
		var pos = -1;
		this.each(function(i){
			if ( this == obj ) pos = i;
		});
		return pos;
	},

	attr: function( key, value, type ) {
		var obj = key;
		
		// Look for the case where we're accessing a style value
		if ( key.constructor == String )
			if ( value == undefined )
				return this.length && jQuery[ type || "attr" ]( this[0], key ) || undefined;
			else {
				obj = {};
				obj[ key ] = value;
			}
		
		// Check to see if we're setting style values
		return this.each(function(index){
			// Set all the styles
			for ( var prop in obj )
				jQuery.attr(
					type ? this.style : this,
					prop, jQuery.prop(this, obj[prop], type, index, prop)
				);
		});
	},

	css: function( key, value ) {
		return this.attr( key, value, "curCSS" );
	},

	text: function(e) {
		if ( typeof e == "string" )
			return this.empty().append( document.createTextNode( e ) );

		var t = "";
		jQuery.each( e || this, function(){
			jQuery.each( this.childNodes, function(){
				if ( this.nodeType != 8 )
					t += this.nodeType != 1 ?
						this.nodeValue : jQuery.fn.text([ this ]);
			});
		});
		return t;
	},

	wrap: function() {
		// The elements to wrap the target around
		var a = jQuery.clean(arguments);

		// Wrap each of the matched elements individually
		return this.each(function(){
			// Clone the structure that we're using to wrap
			var b = a[0].cloneNode(true);

			// Insert it before the element to be wrapped
			this.parentNode.insertBefore( b, this );

			// Find the deepest point in the wrap structure
			while ( b.firstChild )
				b = b.firstChild;

			// Move the matched element to within the wrap structure
			b.appendChild( this );
		});
	},
	append: function() {
		return this.domManip(arguments, true, 1, function(a){
			this.appendChild( a );
		});
	},
	prepend: function() {
		return this.domManip(arguments, true, -1, function(a){
			this.insertBefore( a, this.firstChild );
		});
	},
	before: function() {
		return this.domManip(arguments, false, 1, function(a){
			this.parentNode.insertBefore( a, this );
		});
	},
	after: function() {
		return this.domManip(arguments, false, -1, function(a){
			this.parentNode.insertBefore( a, this.nextSibling );
		});
	},
	end: function() {
		return this.prevObject || jQuery([]);
	},
	find: function(t) {
		return this.pushStack( jQuery.map( this, function(a){
			return jQuery.find(t,a);
		}), t );
	},
	clone: function(deep) {
		return this.pushStack( jQuery.map( this, function(a){
			var a = a.cloneNode( deep != undefined ? deep : true );
			a.$events = null; // drop $events expando to avoid firing incorrect events
			return a;
		}) );
	},

	filter: function(t) {
		return this.pushStack(
			jQuery.isFunction( t ) &&
			jQuery.grep(this, function(el, index){
				return t.apply(el, [index])
			}) ||

			jQuery.multiFilter(t,this) );
	},

	not: function(t) {
		return this.pushStack(
			t.constructor == String &&
			jQuery.multiFilter(t, this, true) ||

			jQuery.grep(this, function(a) {
				return ( t.constructor == Array || t.jquery )
					? jQuery.inArray( a, t ) < 0
					: a != t;
			})
		);
	},

	add: function(t) {
		return this.pushStack( jQuery.merge(
			this.get(),
			t.constructor == String ?
				jQuery(t).get() :
				t.length != undefined && (!t.nodeName || t.nodeName == "FORM") ?
					t : [t] )
		);
	},
	is: function(expr) {
		return expr ? jQuery.filter(expr,this).r.length > 0 : false;
	},

	val: function( val ) {
		return val == undefined ?
			( this.length ? this[0].value : null ) :
			this.attr( "value", val );
	},

	html: function( val ) {
		return val == undefined ?
			( this.length ? this[0].innerHTML : null ) :
			this.empty().append( val );
	},
	domManip: function(args, table, dir, fn){
		var clone = this.length > 1; 
		var a = jQuery.clean(args);
		if ( dir < 0 )
			a.reverse();

		return this.each(function(){
			var obj = this;

			if ( table && jQuery.nodeName(this, "table") && jQuery.nodeName(a[0], "tr") )
				obj = this.getElementsByTagName("tbody")[0] || this.appendChild(document.createElement("tbody"));

			jQuery.each( a, function(){
				fn.apply( obj, [ clone ? this.cloneNode(true) : this ] );
			});

		});
	}
};

jQuery.extend = jQuery.fn.extend = function() {
	// copy reference to target object
	var target = arguments[0],
		a = 1;

	// extend jQuery itself if only one argument is passed
	if ( arguments.length == 1 ) {
		target = this;
		a = 0;
	}
	var prop;
	while (prop = arguments[a++])
		// Extend the base object
		for ( var i in prop ) target[i] = prop[i];

	// Return the modified object
	return target;
};

jQuery.extend({
	noConflict: function() {
		if ( jQuery._$ )
			$ = jQuery._$;
		return jQuery;
	},

	// This may seem like some crazy code, but trust me when I say that this
	// is the only cross-browser way to do this. --John
	isFunction: function( fn ) {
		return !!fn && typeof fn != "string" && !fn.nodeName && 
			typeof fn[0] == "undefined" && /function/i.test( fn + "" );
	},
	
	// check if an element is in a XML document
	isXMLDoc: function(elem) {
		return elem.tagName && elem.ownerDocument && !elem.ownerDocument.body;
	},

	nodeName: function( elem, name ) {
		return elem.nodeName && elem.nodeName.toUpperCase() == name.toUpperCase();
	},
	// args is for internal usage only
	each: function( obj, fn, args ) {
		if ( obj.length == undefined )
			for ( var i in obj )
				fn.apply( obj[i], args || [i, obj[i]] );
		else
			for ( var i = 0, ol = obj.length; i < ol; i++ )
				if ( fn.apply( obj[i], args || [i, obj[i]] ) === false ) break;
		return obj;
	},
	
	prop: function(elem, value, type, index, prop){
			// Handle executable functions
			if ( jQuery.isFunction( value ) )
				value = value.call( elem, [index] );
				
			// exclude the following css properties to add px
			var exclude = /z-?index|font-?weight|opacity|zoom|line-?height/i;

			// Handle passing in a number to a CSS property
			return value && value.constructor == Number && type == "curCSS" && !exclude.test(prop) ?
				value + "px" :
				value;
	},

	className: {
		// internal only, use addClass("class")
		add: function( elem, c ){
			jQuery.each( c.split(/\s+/), function(i, cur){
				if ( !jQuery.className.has( elem.className, cur ) )
					elem.className += ( elem.className ? " " : "" ) + cur;
			});
		},

		// internal only, use removeClass("class")
		remove: function( elem, c ){
			elem.className = c ?
				jQuery.grep( elem.className.split(/\s+/), function(cur){
					return !jQuery.className.has( c, cur );	
				}).join(" ") : "";
		},

		// internal only, use is(".class")
		has: function( t, c ) {
			t = t.className || t;
			// escape regex characters
			c = c.replace(/([\.\\\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
			return t && new RegExp("(^|\\s)" + c + "(\\s|$)").test( t );
		}
	},
	swap: function(e,o,f) {
		for ( var i in o ) {
			e.style["old"+i] = e.style[i];
			e.style[i] = o[i];
		}
		f.apply( e, [] );
		for ( var i in o )
			e.style[i] = e.style["old"+i];
	},

	css: function(e,p) {
		if ( p == "height" || p == "width" ) {
			var old = {}, oHeight, oWidth, d = ["Top","Bottom","Right","Left"];

			jQuery.each( d, function(){
				old["padding" + this] = 0;
				old["border" + this + "Width"] = 0;
			});

			jQuery.swap( e, old, function() {
				if (jQuery.css(e,"display") != "none") {
					oHeight = e.offsetHeight;
					oWidth = e.offsetWidth;
				} else {
					e = jQuery(e.cloneNode(true))
						.find(":radio").removeAttr("checked").end()
						.css({
							visibility: "hidden", position: "absolute", display: "block", right: "0", left: "0"
						}).appendTo(e.parentNode)[0];

					var parPos = jQuery.css(e.parentNode,"position");
					if ( parPos == "" || parPos == "static" )
						e.parentNode.style.position = "relative";

					oHeight = e.clientHeight;
					oWidth = e.clientWidth;

					if ( parPos == "" || parPos == "static" )
						e.parentNode.style.position = "static";

					e.parentNode.removeChild(e);
				}
			});

			return p == "height" ? oHeight : oWidth;
		}

		return jQuery.curCSS( e, p );
	},

	curCSS: function(elem, prop, force) {
		var ret;
		
		if (prop == "opacity" && jQuery.browser.msie)
			return jQuery.attr(elem.style, "opacity");
			
		if (prop == "float" || prop == "cssFloat")
		    prop = jQuery.browser.msie ? "styleFloat" : "cssFloat";

		if (!force && elem.style[prop])
			ret = elem.style[prop];

		else if (document.defaultView && document.defaultView.getComputedStyle) {

			if (prop == "cssFloat" || prop == "styleFloat")
				prop = "float";

			prop = prop.replace(/([A-Z])/g,"-$1").toLowerCase();
			var cur = document.defaultView.getComputedStyle(elem, null);

			if ( cur )
				ret = cur.getPropertyValue(prop);
			else if ( prop == "display" )
				ret = "none";
			else
				jQuery.swap(elem, { display: "block" }, function() {
				    var c = document.defaultView.getComputedStyle(this, "");
				    ret = c && c.getPropertyValue(prop) || "";
				});

		} else if (elem.currentStyle) {

			var newProp = prop.replace(/\-(\w)/g,function(m,c){return c.toUpperCase();});
			ret = elem.currentStyle[prop] || elem.currentStyle[newProp];
			
		}

		return ret;
	},
	
	clean: function(a) {
		var r = [];

		jQuery.each( a, function(i,arg){
			if ( !arg ) return;

			if ( arg.constructor == Number )
				arg = arg.toString();
			
			 // Convert html string into DOM nodes
			if ( typeof arg == "string" ) {
				// Trim whitespace, otherwise indexOf won't work as expected
				var s = jQuery.trim(arg), div = document.createElement("div"), tb = [];

				var wrap =
					 // option or optgroup
					!s.indexOf("<opt") &&
					[1, "<select>", "</select>"] ||
					
					(!s.indexOf("<thead") || !s.indexOf("<tbody") || !s.indexOf("<tfoot")) &&
					[1, "<table>", "</table>"] ||
					
					!s.indexOf("<tr") &&
					[2, "<table><tbody>", "</tbody></table>"] ||
					
				 	// <thead> matched above
					(!s.indexOf("<td") || !s.indexOf("<th")) &&
					[3, "<table><tbody><tr>", "</tr></tbody></table>"] ||
					
					[0,"",""];

				// Go to html and back, then peel off extra wrappers
				div.innerHTML = wrap[1] + s + wrap[2];
				
				// Move to the right depth
				while ( wrap[0]-- )
					div = div.firstChild;
				
				// Remove IE's autoinserted <tbody> from table fragments
				if ( jQuery.browser.msie ) {
					
					// String was a <table>, *may* have spurious <tbody>
					if ( !s.indexOf("<table") && s.indexOf("<tbody") < 0 ) 
						tb = div.firstChild && div.firstChild.childNodes;
						
					// String was a bare <thead> or <tfoot>
					else if ( wrap[1] == "<table>" && s.indexOf("<tbody") < 0 )
						tb = div.childNodes;

					for ( var n = tb.length-1; n >= 0 ; --n )
						if ( jQuery.nodeName(tb[n], "tbody") && !tb[n].childNodes.length )
							tb[n].parentNode.removeChild(tb[n]);
					
				}
				
				arg = [];
				for (var i=0, l=div.childNodes.length; i<l; i++)
					arg.push(div.childNodes[i]);
			}

			if ( arg.length === 0 && !jQuery.nodeName(arg, "form") )
				return;
			
			if ( arg[0] == undefined || jQuery.nodeName(arg, "form") )
				r.push( arg );
			else
				r = jQuery.merge( r, arg );

		});

		return r;
	},
	
	attr: function(elem, name, value){
		var fix = jQuery.isXMLDoc(elem) ? {} : {
			"for": "htmlFor",
			"class": "className",
			"float": jQuery.browser.msie ? "styleFloat" : "cssFloat",
			cssFloat: jQuery.browser.msie ? "styleFloat" : "cssFloat",
			innerHTML: "innerHTML",
			className: "className",
			value: "value",
			disabled: "disabled",
			checked: "checked",
			readonly: "readOnly",
			selected: "selected"
		};
		
		// IE actually uses filters for opacity ... elem is actually elem.style
		if ( name == "opacity" && jQuery.browser.msie && value != undefined ) {
			// IE has trouble with opacity if it does not have layout
			// Force it by setting the zoom level
			elem.zoom = 1; 

			// Set the alpha filter to set the opacity
			return elem.filter = elem.filter.replace(/alpha\([^\)]*\)/gi,"") +
				( value == 1 ? "" : "alpha(opacity=" + value * 100 + ")" );

		} else if ( name == "opacity" && jQuery.browser.msie )
			return elem.filter ? 
				parseFloat( elem.filter.match(/alpha\(opacity=(.*)\)/)[1] ) / 100 : 1;
		
		// Mozilla doesn't play well with opacity 1
		if ( name == "opacity" && jQuery.browser.mozilla && value == 1 )
			value = 0.9999;
			

		// Certain attributes only work when accessed via the old DOM 0 way
		if ( fix[name] ) {
			if ( value != undefined ) elem[fix[name]] = value;
			return elem[fix[name]];

		} else if ( value == undefined && jQuery.browser.msie && jQuery.nodeName(elem, "form") && (name == "action" || name == "method") )
			return elem.getAttributeNode(name).nodeValue;

		// IE elem.getAttribute passes even for style
		else if ( elem.tagName ) {
			if ( value != undefined ) elem.setAttribute( name, value );
			if ( jQuery.browser.msie && /href|src/.test(name) && !jQuery.isXMLDoc(elem) ) 
				return elem.getAttribute( name, 2 );
			return elem.getAttribute( name );

		// elem is actually elem.style ... set the style
		} else {
			name = name.replace(/-([a-z])/ig,function(z,b){return b.toUpperCase();});
			if ( value != undefined ) elem[name] = value;
			return elem[name];
		}
	},
	trim: function(t){
		return t.replace(/^\s+|\s+$/g, "");
	},

	makeArray: function( a ) {
		var r = [];

		if ( a.constructor != Array )
			for ( var i = 0, al = a.length; i < al; i++ )
				r.push( a[i] );
		else
			r = a.slice( 0 );

		return r;
	},

	inArray: function( b, a ) {
		for ( var i = 0, al = a.length; i < al; i++ )
			if ( a[i] == b )
				return i;
		return -1;
	},
	merge: function(first, second) {
		var r = [].slice.call( first, 0 );

		// Now check for duplicates between the two arrays
		// and only add the unique items
		for ( var i = 0, sl = second.length; i < sl; i++ )
			// Check for duplicates
			if ( jQuery.inArray( second[i], r ) == -1 )
				// The item is unique, add it
				first.push( second[i] );

		return first;
	},
	grep: function(elems, fn, inv) {
		// If a string is passed in for the function, make a function
		// for it (a handy shortcut)
		if ( typeof fn == "string" )
			fn = new Function("a","i","return " + fn);

		var result = [];

		// Go through the array, only saving the items
		// that pass the validator function
		for ( var i = 0, el = elems.length; i < el; i++ )
			if ( !inv && fn(elems[i],i) || inv && !fn(elems[i],i) )
				result.push( elems[i] );

		return result;
	},
	map: function(elems, fn) {
		// If a string is passed in for the function, make a function
		// for it (a handy shortcut)
		if ( typeof fn == "string" )
			fn = new Function("a","return " + fn);

		var result = [], r = [];

		// Go through the array, translating each of the items to their
		// new value (or values).
		for ( var i = 0, el = elems.length; i < el; i++ ) {
			var val = fn(elems[i],i);

			if ( val !== null && val != undefined ) {
				if ( val.constructor != Array ) val = [val];
				result = result.concat( val );
			}
		}

		var r = result.length ? [ result[0] ] : [];

		check: for ( var i = 1, rl = result.length; i < rl; i++ ) {
			for ( var j = 0; j < i; j++ )
				if ( result[i] == r[j] )
					continue check;

			r.push( result[i] );
		}

		return r;
	}
});
 
/*
 * Whether the W3C compliant box model is being used.
 *
 * @property
 * @name $.boxModel
 * @type Boolean
 * @cat JavaScript
 */
new function() {
	var b = navigator.userAgent.toLowerCase();

	// Figure out what browser is being used
	jQuery.browser = {
		safari: /webkit/.test(b),
		opera: /opera/.test(b),
		msie: /msie/.test(b) && !/opera/.test(b),
		mozilla: /mozilla/.test(b) && !/(compatible|webkit)/.test(b)
	};

	// Check to see if the W3C box model is being used
	jQuery.boxModel = !jQuery.browser.msie || document.compatMode == "CSS1Compat";
};

jQuery.each({
	parent: "a.parentNode",
	parents: "jQuery.parents(a)",
	next: "jQuery.nth(a,2,'nextSibling')",
	prev: "jQuery.nth(a,2,'previousSibling')",
	siblings: "jQuery.sibling(a.parentNode.firstChild,a)",
	children: "jQuery.sibling(a.firstChild)"
}, function(i,n){
	jQuery.fn[ i ] = function(a) {
		var ret = jQuery.map(this,n);
		if ( a && typeof a == "string" )
			ret = jQuery.multiFilter(a,ret);
		return this.pushStack( ret );
	};
});

jQuery.each({
	appendTo: "append",
	prependTo: "prepend",
	insertBefore: "before",
	insertAfter: "after"
}, function(i,n){
	jQuery.fn[ i ] = function(){
		var a = arguments;
		return this.each(function(){
			for ( var j = 0, al = a.length; j < al; j++ )
				jQuery(a[j])[n]( this );
		});
	};
});

jQuery.each( {
	removeAttr: function( key ) {
		jQuery.attr( this, key, "" );
		this.removeAttribute( key );
	},
	addClass: function(c){
		jQuery.className.add(this,c);
	},
	removeClass: function(c){
		jQuery.className.remove(this,c);
	},
	toggleClass: function( c ){
		jQuery.className[ jQuery.className.has(this,c) ? "remove" : "add" ](this, c);
	},
	remove: function(a){
		if ( !a || jQuery.filter( a, [this] ).r.length )
			this.parentNode.removeChild( this );
	},
	empty: function() {
		while ( this.firstChild )
			this.removeChild( this.firstChild );
	}
}, function(i,n){
	jQuery.fn[ i ] = function() {
		return this.each( n, arguments );
	};
});

jQuery.each( [ "eq", "lt", "gt", "contains" ], function(i,n){
	jQuery.fn[ n ] = function(num,fn) {
		return this.filter( ":" + n + "(" + num + ")", fn );
	};
});

jQuery.each( [ "height", "width" ], function(i,n){
	jQuery.fn[ n ] = function(h) {
		return h == undefined ?
			( this.length ? jQuery.css( this[0], n ) : null ) :
			this.css( n, h.constructor == String ? h : h + "px" );
	};
});
jQuery.extend({
	expr: {
		"": "m[2]=='*'||jQuery.nodeName(a,m[2])",
		"#": "a.getAttribute('id')==m[2]",
		":": {
			// Position Checks
			lt: "i<m[3]-0",
			gt: "i>m[3]-0",
			nth: "m[3]-0==i",
			eq: "m[3]-0==i",
			first: "i==0",
			last: "i==r.length-1",
			even: "i%2==0",
			odd: "i%2",

			// Child Checks
			"nth-child": "jQuery.nth(a.parentNode.firstChild,m[3],'nextSibling',a)==a",
			"first-child": "jQuery.nth(a.parentNode.firstChild,1,'nextSibling')==a",
			"last-child": "jQuery.nth(a.parentNode.lastChild,1,'previousSibling')==a",
			"only-child": "jQuery.sibling(a.parentNode.firstChild).length==1",

			// Parent Checks
			parent: "a.firstChild",
			empty: "!a.firstChild",

			// Text Check
			contains: "jQuery.fn.text.apply([a]).indexOf(m[3])>=0",

			// Visibility
			visible: 'a.type!="hidden"&&jQuery.css(a,"display")!="none"&&jQuery.css(a,"visibility")!="hidden"',
			hidden: 'a.type=="hidden"||jQuery.css(a,"display")=="none"||jQuery.css(a,"visibility")=="hidden"',

			// Form attributes
			enabled: "!a.disabled",
			disabled: "a.disabled",
			checked: "a.checked",
			selected: "a.selected||jQuery.attr(a,'selected')",

			// Form elements
			text: "a.type=='text'",
			radio: "a.type=='radio'",
			checkbox: "a.type=='checkbox'",
			file: "a.type=='file'",
			password: "a.type=='password'",
			submit: "a.type=='submit'",
			image: "a.type=='image'",
			reset: "a.type=='reset'",
			button: 'a.type=="button"||jQuery.nodeName(a,"button")',
			input: "/input|select|textarea|button/i.test(a.nodeName)"
		},
		".": "jQuery.className.has(a,m[2])",
		"@": {
			"=": "z==m[4]",
			"!=": "z!=m[4]",
			"^=": "z&&!z.indexOf(m[4])",
			"$=": "z&&z.substr(z.length - m[4].length,m[4].length)==m[4]",
			"*=": "z&&z.indexOf(m[4])>=0",
			"": "z",
			_resort: function(m){
				return ["", m[1], m[3], m[2], m[5]];
			},
			_prefix: "z=a[m[3]];if(!z||/href|src/.test(m[3]))z=jQuery.attr(a,m[3]);"
		},
		"[": "jQuery.find(m[2],a).length"
	},
	
	// The regular expressions that power the parsing engine
	parse: [
		// Match: [@value='test'], [@foo]
		/^\[ *(@)([a-z0-9_-]*) *([!*$^=]*) *('?"?)(.*?)\4 *\]/i,

		// Match: [div], [div p]
		/^(\[)\s*(.*?(\[.*?\])?[^[]*?)\s*\]/,

		// Match: :contains('foo')
		/^(:)([a-z0-9_-]*)\("?'?(.*?(\(.*?\))?[^(]*?)"?'?\)/i,

		// Match: :even, :last-chlid
		/^([:.#]*)([a-z0-9_*-]*)/i
	],

	token: [
		/^(\/?\.\.)/, "a.parentNode",
		/^(>|\/)/, "jQuery.sibling(a.firstChild)",
		/^(\+)/, "jQuery.nth(a,2,'nextSibling')",
		/^(~)/, function(a){
			var s = jQuery.sibling(a.parentNode.firstChild);
			return s.slice(jQuery.inArray(a,s) + 1);
		}
	],

	multiFilter: function( expr, elems, not ) {
		var old, cur = [];

		while ( expr && expr != old ) {
			old = expr;
			var f = jQuery.filter( expr, elems, not );
			expr = f.t.replace(/^\s*,\s*/, "" );
			cur = not ? elems = f.r : jQuery.merge( cur, f.r );
		}

		return cur;
	},
	find: function( t, context ) {
		// Quickly handle non-string expressions
		if ( typeof t != "string" )
			return [ t ];

		// Make sure that the context is a DOM Element
		if ( context && !context.nodeType )
			context = null;

		// Set the correct context (if none is provided)
		context = context || document;

		// Handle the common XPath // expression
		if ( !t.indexOf("//") ) {
			context = context.documentElement;
			t = t.substr(2,t.length);

		// And the / root expression
		} else if ( !t.indexOf("/") ) {
			context = context.documentElement;
			t = t.substr(1,t.length);
			if ( t.indexOf("/") >= 1 )
				t = t.substr(t.indexOf("/"),t.length);
		}

		// Initialize the search
		var ret = [context], done = [], last = null;

		// Continue while a selector expression exists, and while
		// we're no longer looping upon ourselves
		while ( t && last != t ) {
			var r = [];
			last = t;

			t = jQuery.trim(t).replace( /^\/\//i, "" );

			var foundToken = false;

			// An attempt at speeding up child selectors that
			// point to a specific element tag
			var re = /^[\/>]\s*([a-z0-9*-]+)/i;
			var m = re.exec(t);

			if ( m ) {
				// Perform our own iteration and filter
				jQuery.each( ret, function(){
					for ( var c = this.firstChild; c; c = c.nextSibling )
						if ( c.nodeType == 1 && ( jQuery.nodeName(c, m[1]) || m[1] == "*" ) )
							r.push( c );
				});

				ret = r;
				t = t.replace( re, "" );
				if ( t.indexOf(" ") == 0 ) continue;
				foundToken = true;
			} else {
				// Look for pre-defined expression tokens
				for ( var i = 0; i < jQuery.token.length; i += 2 ) {
					// Attempt to match each, individual, token in
					// the specified order
					var re = jQuery.token[i];
					var m = re.exec(t);

					// If the token match was found
					if ( m ) {
						// Map it against the token's handler
						r = ret = jQuery.map( ret, jQuery.isFunction( jQuery.token[i+1] ) ?
							jQuery.token[i+1] :
							function(a){ return eval(jQuery.token[i+1]); });

						// And remove the token
						t = jQuery.trim( t.replace( re, "" ) );
						foundToken = true;
						break;
					}
				}
			}

			// See if there's still an expression, and that we haven't already
			// matched a token
			if ( t && !foundToken ) {
				// Handle multiple expressions
				if ( !t.indexOf(",") ) {
					// Clean the result set
					if ( ret[0] == context ) ret.shift();

					// Merge the result sets
					jQuery.merge( done, ret );

					// Reset the context
					r = ret = [context];

					// Touch up the selector string
					t = " " + t.substr(1,t.length);

				} else {
					// Optomize for the case nodeName#idName
					var re2 = /^([a-z0-9_-]+)(#)([a-z0-9\\*_-]*)/i;
					var m = re2.exec(t);
					
					// Re-organize the results, so that they're consistent
					if ( m ) {
					   m = [ 0, m[2], m[3], m[1] ];

					} else {
						// Otherwise, do a traditional filter check for
						// ID, class, and element selectors
						re2 = /^([#.]?)([a-z0-9\\*_-]*)/i;
						m = re2.exec(t);
					}

					// Try to do a global search by ID, where we can
					if ( m[1] == "#" && ret[ret.length-1].getElementById ) {
						// Optimization for HTML document case
						var oid = ret[ret.length-1].getElementById(m[2]);
						
						// Do a quick check for the existence of the actual ID attribute
						// to avoid selecting by the name attribute in IE
						if ( jQuery.browser.msie && oid && oid.id != m[2] )
							oid = jQuery('[@id="'+m[2]+'"]', ret[ret.length-1])[0];

						// Do a quick check for node name (where applicable) so
						// that div#foo searches will be really fast
						ret = r = oid && (!m[3] || jQuery.nodeName(oid, m[3])) ? [oid] : [];

					} else {
						// Pre-compile a regular expression to handle class searches
						if ( m[1] == "." )
							var rec = new RegExp("(^|\\s)" + m[2] + "(\\s|$)");

						// We need to find all descendant elements, it is more
						// efficient to use getAll() when we are already further down
						// the tree - we try to recognize that here
						jQuery.each( ret, function(){
							// Grab the tag name being searched for
							var tag = m[1] != "" || m[0] == "" ? "*" : m[2];

							// Handle IE7 being really dumb about <object>s
							if ( jQuery.nodeName(this, "object") && tag == "*" )
								tag = "param";

							jQuery.merge( r,
								m[1] != "" && ret.length != 1 ?
									jQuery.getAll( this, [], m[1], m[2], rec ) :
									this.getElementsByTagName( tag )
							);
						});

						// It's faster to filter by class and be done with it
						if ( m[1] == "." && ret.length == 1 )
							r = jQuery.grep( r, function(e) {
								return rec.test(e.className);
							});

						// Same with ID filtering
						if ( m[1] == "#" && ret.length == 1 ) {
							// Remember, then wipe out, the result set
							var tmp = r;
							r = [];

							// Then try to find the element with the ID
							jQuery.each( tmp, function(){
								if ( this.getAttribute("id") == m[2] ) {
									r = [ this ];
									return false;
								}
							});
						}

						ret = r;
					}

					t = t.replace( re2, "" );
				}

			}

			// If a selector string still exists
			if ( t ) {
				// Attempt to filter it
				var val = jQuery.filter(t,r);
				ret = r = val.r;
				t = jQuery.trim(val.t);
			}
		}

		// Remove the root context
		if ( ret && ret[0] == context ) ret.shift();

		// And combine the results
		jQuery.merge( done, ret );

		return done;
	},

	filter: function(t,r,not) {
		// Look for common filter expressions
		while ( t && /^[a-z[({<*:.#]/i.test(t) ) {

			var p = jQuery.parse, m;

			jQuery.each( p, function(i,re){
		
				// Look for, and replace, string-like sequences
				// and finally build a regexp out of it
				m = re.exec( t );

				if ( m ) {
					// Remove what we just matched
					t = t.substring( m[0].length );

					// Re-organize the first match
					if ( jQuery.expr[ m[1] ]._resort )
						m = jQuery.expr[ m[1] ]._resort( m );

					return false;
				}
			});

			// :not() is a special case that can be optimized by
			// keeping it out of the expression list
			if ( m[1] == ":" && m[2] == "not" )
				r = jQuery.filter(m[3], r, true).r;

			// Handle classes as a special case (this will help to
			// improve the speed, as the regexp will only be compiled once)
			else if ( m[1] == "." ) {

				var re = new RegExp("(^|\\s)" + m[2] + "(\\s|$)");
				r = jQuery.grep( r, function(e){
					return re.test(e.className || "");
				}, not);

			// Otherwise, find the expression to execute
			} else {
				var f = jQuery.expr[m[1]];
				if ( typeof f != "string" )
					f = jQuery.expr[m[1]][m[2]];

				// Build a custom macro to enclose it
				eval("f = function(a,i){" +
					( jQuery.expr[ m[1] ]._prefix || "" ) +
					"return " + f + "}");

				// Execute it against the current filter
				r = jQuery.grep( r, f, not );
			}
		}

		// Return an array of filtered elements (r)
		// and the modified expression string (t)
		return { r: r, t: t };
	},
	
	getAll: function( o, r, token, name, re ) {
		for ( var s = o.firstChild; s; s = s.nextSibling )
			if ( s.nodeType == 1 ) {
				var add = true;

				if ( token == "." )
					add = s.className && re.test(s.className);
				else if ( token == "#" )
					add = s.getAttribute("id") == name;
	
				if ( add )
					r.push( s );

				if ( token == "#" && r.length ) break;

				if ( s.firstChild )
					jQuery.getAll( s, r, token, name, re );
			}

		return r;
	},
	parents: function( elem ){
		var matched = [];
		var cur = elem.parentNode;
		while ( cur && cur != document ) {
			matched.push( cur );
			cur = cur.parentNode;
		}
		return matched;
	},
	nth: function(cur,result,dir,elem){
		result = result || 1;
		var num = 0;
		for ( ; cur; cur = cur[dir] ) {
			if ( cur.nodeType == 1 ) num++;
			if ( num == result || result == "even" && num % 2 == 0 && num > 1 && cur == elem ||
				result == "odd" && num % 2 == 1 && cur == elem ) return cur;
		}
	},
	sibling: function( n, elem ) {
		var r = [];

		for ( ; n; n = n.nextSibling ) {
			if ( n.nodeType == 1 && (!elem || n != elem) )
				r.push( n );
		}

		return r;
	}
});
/*
 * A number of helper functions used for managing events.
 * Many of the ideas behind this code orignated from 
 * Dean Edwards' addEvent library.
 */
jQuery.event = {

	// Bind an event to an element
	// Original by Dean Edwards
	add: function(element, type, handler, data) {
		// For whatever reason, IE has trouble passing the window object
		// around, causing it to be cloned in the process
		if ( jQuery.browser.msie && element.setInterval != undefined )
			element = window;

		// if data is passed, bind to handler
		if( data ) 
			handler.data = data;

		// Make sure that the function being executed has a unique ID
		if ( !handler.guid )
			handler.guid = this.guid++;

		// Init the element's event structure
		if (!element.$events)
			element.$events = {};

		// Get the current list of functions bound to this event
		var handlers = element.$events[type];

		// If it hasn't been initialized yet
		if (!handlers) {
			// Init the event handler queue
			handlers = element.$events[type] = {};

			// Remember an existing handler, if it's already there
			if (element["on" + type])
				handlers[0] = element["on" + type];
		}

		// Add the function to the element's handler list
		handlers[handler.guid] = handler;

		// And bind the global event handler to the element
		element["on" + type] = this.handle;

		// Remember the function in a global list (for triggering)
		if (!this.global[type])
			this.global[type] = [];
		this.global[type].push( element );
	},

	guid: 1,
	global: {},

	// Detach an event or set of events from an element
	remove: function(element, type, handler) {
		if (element.$events) {
			var i,j,k;
			if ( type && type.type ) { // type is actually an event object here
				handler = type.handler;
				type    = type.type;
			}
			
			if (type && element.$events[type])
				// remove the given handler for the given type
				if ( handler )
					delete element.$events[type][handler.guid];
					
				// remove all handlers for the given type
				else
					for ( i in element.$events[type] )
						delete element.$events[type][i];
						
			// remove all handlers		
			else
				for ( j in element.$events )
					this.remove( element, j );
			
			// remove event handler if no more handlers exist
			for ( k in element.$events[type] )
				if (k) {
					k = true;
					break;
				}
			if (!k) element["on" + type] = null;
		}
	},

	trigger: function(type, data, element) {
		// Clone the incoming data, if any
		data = jQuery.makeArray(data || []);

		// Handle a global trigger
		if ( !element )
			jQuery.each( this.global[type] || [], function(){
				jQuery.event.trigger( type, data, this );
			});

		// Handle triggering a single element
		else {
			var handler = element["on" + type ], val,
				fn = jQuery.isFunction( element[ type ] );

			if ( handler ) {
				// Pass along a fake event
				data.unshift( this.fix({ type: type, target: element }) );
	
				// Trigger the event
				if ( (val = handler.apply( element, data )) !== false )
					this.triggered = true;
			}

			if ( fn && val !== false )
				element[ type ]();

			this.triggered = false;
		}
	},

	handle: function(event) {
		// Handle the second event of a trigger and when
		// an event is called after a page has unloaded
		if ( typeof jQuery == "undefined" || jQuery.event.triggered ) return;

		// Empty object is for triggered events with no data
		event = jQuery.event.fix( event || window.event || {} ); 

		// returned undefined or false
		var returnValue;

		var c = this.$events[event.type];

		var args = [].slice.call( arguments, 1 );
		args.unshift( event );

		for ( var j in c ) {
			// Pass in a reference to the handler function itself
			// So that we can later remove it
			args[0].handler = c[j];
			args[0].data = c[j].data;

			if ( c[j].apply( this, args ) === false ) {
				event.preventDefault();
				event.stopPropagation();
				returnValue = false;
			}
		}

		// Clean up added properties in IE to prevent memory leak
		if (jQuery.browser.msie) event.target = event.preventDefault = event.stopPropagation = event.handler = event.data = null;

		return returnValue;
	},

	fix: function(event) {
		// Fix target property, if necessary
		if ( !event.target && event.srcElement )
			event.target = event.srcElement;

		// Calculate pageX/Y if missing and clientX/Y available
		if ( event.pageX == undefined && event.clientX != undefined ) {
			var e = document.documentElement, b = document.body;
			event.pageX = event.clientX + (e.scrollLeft || b.scrollLeft);
			event.pageY = event.clientY + (e.scrollTop || b.scrollTop);
		}
				
		// check if target is a textnode (safari)
		if (jQuery.browser.safari && event.target.nodeType == 3) {
			// store a copy of the original event object 
			// and clone because target is read only
			var originalEvent = event;
			event = jQuery.extend({}, originalEvent);
			
			// get parentnode from textnode
			event.target = originalEvent.target.parentNode;
			
			// add preventDefault and stopPropagation since 
			// they will not work on the clone
			event.preventDefault = function() {
				return originalEvent.preventDefault();
			};
			event.stopPropagation = function() {
				return originalEvent.stopPropagation();
			};
		}
		
		// fix preventDefault and stopPropagation
		if (!event.preventDefault)
			event.preventDefault = function() {
				this.returnValue = false;
			};
			
		if (!event.stopPropagation)
			event.stopPropagation = function() {
				this.cancelBubble = true;
			};
			
		return event;
	}
};

jQuery.fn.extend({
	bind: function( type, data, fn ) {
		return this.each(function(){
			jQuery.event.add( this, type, fn || data, data );
		});
	},
	one: function( type, data, fn ) {
		return this.each(function(){
			jQuery.event.add( this, type, function(event) {
				jQuery(this).unbind(event);
				return (fn || data).apply( this, arguments);
			}, data);
		});
	},
	unbind: function( type, fn ) {
		return this.each(function(){
			jQuery.event.remove( this, type, fn );
		});
	},
	trigger: function( type, data ) {
		return this.each(function(){
			jQuery.event.trigger( type, data, this );
		});
	},
	toggle: function() {
		// Save reference to arguments for access in closure
		var a = arguments;

		return this.click(function(e) {
			// Figure out which function to execute
			this.lastToggle = this.lastToggle == 0 ? 1 : 0;
			
			// Make sure that clicks stop
			e.preventDefault();
			
			// and execute the function
			return a[this.lastToggle].apply( this, [e] ) || false;
		});
	},
	hover: function(f,g) {
		
		// A private function for handling mouse 'hovering'
		function handleHover(e) {
			// Check if mouse(over|out) are still within the same parent element
			var p = (e.type == "mouseover" ? e.fromElement : e.toElement) || e.relatedTarget;
	
			// Traverse up the tree
			while ( p && p != this ) try { p = p.parentNode } catch(e) { p = this; };
			
			// If we actually just moused on to a sub-element, ignore it
			if ( p == this ) return false;
			
			// Execute the right function
			return (e.type == "mouseover" ? f : g).apply(this, [e]);
		}
		
		// Bind the function to the two event listeners
		return this.mouseover(handleHover).mouseout(handleHover);
	},
	ready: function(f) {
		// If the DOM is already ready
		if ( jQuery.isReady )
			// Execute the function immediately
			f.apply( document, [jQuery] );
			
		// Otherwise, remember the function for later
		else {
			// Add the function to the wait list
			jQuery.readyList.push( function() { return f.apply(this, [jQuery]) } );
		}
	
		return this;
	}
});

jQuery.extend({
	/*
	 * All the code that makes DOM Ready work nicely.
	 */
	isReady: false,
	readyList: [],
	
	// Handle when the DOM is ready
	ready: function() {
		// Make sure that the DOM is not already loaded
		if ( !jQuery.isReady ) {
			// Remember that the DOM is ready
			jQuery.isReady = true;
			
			// If there are functions bound, to execute
			if ( jQuery.readyList ) {
				// Execute all of them
				jQuery.each( jQuery.readyList, function(){
					this.apply( document );
				});
				
				// Reset the list of functions
				jQuery.readyList = null;
			}
			// Remove event lisenter to avoid memory leak
			if ( jQuery.browser.mozilla || jQuery.browser.opera )
				document.removeEventListener( "DOMContentLoaded", jQuery.ready, false );
		}
	}
});

new function(){

	jQuery.each( ("blur,focus,load,resize,scroll,unload,click,dblclick," +
		"mousedown,mouseup,mousemove,mouseover,mouseout,change,select," + 
		"submit,keydown,keypress,keyup,error").split(","), function(i,o){
		
		// Handle event binding
		jQuery.fn[o] = function(f){
			return f ? this.bind(o, f) : this.trigger(o);
		};
			
	});
	
	// If Mozilla is used
	if ( jQuery.browser.mozilla || jQuery.browser.opera )
		// Use the handy event callback
		document.addEventListener( "DOMContentLoaded", jQuery.ready, false );
	
	// If IE is used, use the excellent hack by Matthias Miller
	// http://www.outofhanwell.com/blog/index.php?title=the_window_onload_problem_revisited
	else if ( jQuery.browser.msie ) {
	
		// Only works if you document.write() it
		document.write("<scr" + "ipt id=__ie_init defer=true " + 
			"src=//:><\/script>");
	
		// Use the defer script hack
		var script = document.getElementById("__ie_init");
		
		// script does not exist if jQuery is loaded dynamically
		if ( script ) 
			script.onreadystatechange = function() {
				if ( this.readyState != "complete" ) return;
				this.parentNode.removeChild( this );
				jQuery.ready();
			};
	
		// Clear from memory
		script = null;
	
	// If Safari  is used
	} else if ( jQuery.browser.safari )
		// Continually check to see if the document.readyState is valid
		jQuery.safariTimer = setInterval(function(){
			// loaded and complete are both valid states
			if ( document.readyState == "loaded" || 
				document.readyState == "complete" ) {
	
				// If either one are found, remove the timer
				clearInterval( jQuery.safariTimer );
				jQuery.safariTimer = null;
	
				// and execute any waiting functions
				jQuery.ready();
			}
		}, 10); 

	// A fallback to window.onload, that will always work
	jQuery.event.add( window, "load", jQuery.ready );
	
};

// Clean up after IE to avoid memory leaks
if (jQuery.browser.msie)
	jQuery(window).one("unload", function() {
		var global = jQuery.event.global;
		for ( var type in global ) {
			var els = global[type], i = els.length;
			if ( i && type != 'unload' )
				do
					jQuery.event.remove(els[i-1], type);
				while (--i);
		}
	});
jQuery.fn.extend({
	loadIfModified: function( url, params, callback ) {
		this.load( url, params, callback, 1 );
	},
	load: function( url, params, callback, ifModified ) {
		if ( jQuery.isFunction( url ) )
			return this.bind("load", url);

		callback = callback || function(){};

		// Default to a GET request
		var type = "GET";

		// If the second parameter was provided
		if ( params )
			// If it's a function
			if ( jQuery.isFunction( params ) ) {
				// We assume that it's the callback
				callback = params;
				params = null;

			// Otherwise, build a param string
			} else {
				params = jQuery.param( params );
				type = "POST";
			}

		var self = this;

		// Request the remote document
		jQuery.ajax({
			url: url,
			type: type,
			data: params,
			ifModified: ifModified,
			complete: function(res, status){
				if ( status == "success" || !ifModified && status == "notmodified" )
					// Inject the HTML into all the matched elements
					self.attr("innerHTML", res.responseText)
					  // Execute all the scripts inside of the newly-injected HTML
					  .evalScripts()
					  // Execute callback
					  .each( callback, [res.responseText, status, res] );
				else
					callback.apply( self, [res.responseText, status, res] );
			}
		});
		return this;
	},
	serialize: function() {
		return jQuery.param( this );
	},
	evalScripts: function() {
		return this.find("script").each(function(){
			if ( this.src )
				jQuery.getScript( this.src );
			else
				jQuery.globalEval( this.text || this.textContent || this.innerHTML || "" );
		}).end();
	}

});

// If IE is used, create a wrapper for the XMLHttpRequest object
if ( !window.XMLHttpRequest )
	XMLHttpRequest = function(){
		return new ActiveXObject("Microsoft.XMLHTTP");
	};

// Attach a bunch of functions for handling common AJAX events

jQuery.each( "ajaxStart,ajaxStop,ajaxComplete,ajaxError,ajaxSuccess,ajaxSend".split(","), function(i,o){
	jQuery.fn[o] = function(f){
		return this.bind(o, f);
	};
});

jQuery.extend({
	get: function( url, data, callback, type, ifModified ) {
		// shift arguments if data argument was ommited
		if ( jQuery.isFunction( data ) ) {
			callback = data;
			data = null;
		}
		
		return jQuery.ajax({
			url: url,
			data: data,
			success: callback,
			dataType: type,
			ifModified: ifModified
		});
	},
	getIfModified: function( url, data, callback, type ) {
		return jQuery.get(url, data, callback, type, 1);
	},
	getScript: function( url, callback ) {
		return jQuery.get(url, null, callback, "script");
	},
	getJSON: function( url, data, callback ) {
		return jQuery.get(url, data, callback, "json");
	},
	post: function( url, data, callback, type ) {
		if ( jQuery.isFunction( data ) ) {
			callback = data;
			data = {};
		}

		return jQuery.ajax({
			type: "POST",
			url: url,
			data: data,
			success: callback,
			dataType: type
		});
	},

	// timeout (ms)
	//timeout: 0,
	ajaxTimeout: function( timeout ) {
		jQuery.ajaxSettings.timeout = timeout;
	},
	ajaxSetup: function( settings ) {
		jQuery.extend( jQuery.ajaxSettings, settings );
	},

	ajaxSettings: {
		global: true,
		type: "GET",
		timeout: 0,
		contentType: "application/x-www-form-urlencoded",
		processData: true,
		async: true,
		data: null
	},
	
	// Last-Modified header cache for next request
	lastModified: {},
	ajax: function( s ) {
		// TODO introduce global settings, allowing the client to modify them for all requests, not only timeout
		s = jQuery.extend({}, jQuery.ajaxSettings, s);

		// if data available
		if ( s.data ) {
			// convert data if not already a string
			if (s.processData && typeof s.data != "string")
    			s.data = jQuery.param(s.data);
			// append data to url for get requests
			if( s.type.toLowerCase() == "get" ) {
				// "?" + data or "&" + data (in case there are already params)
				s.url += ((s.url.indexOf("?") > -1) ? "&" : "?") + s.data;
				// IE likes to send both get and post data, prevent this
				s.data = null;
			}
		}

		// Watch for a new set of requests
		if ( s.global && ! jQuery.active++ )
			jQuery.event.trigger( "ajaxStart" );

		var requestDone = false;

		// Create the request object
		var xml = new XMLHttpRequest();

		// Open the socket
		xml.open(s.type, s.url, s.async);

		// Set the correct header, if data is being sent
		if ( s.data )
			xml.setRequestHeader("Content-Type", s.contentType);

		// Set the If-Modified-Since header, if ifModified mode.
		if ( s.ifModified )
			xml.setRequestHeader("If-Modified-Since",
				jQuery.lastModified[s.url] || "Thu, 01 Jan 1970 00:00:00 GMT" );

		// Set header so the called script knows that it's an XMLHttpRequest
		xml.setRequestHeader("X-Requested-With", "XMLHttpRequest");

		// Make sure the browser sends the right content length
		if ( xml.overrideMimeType )
			xml.setRequestHeader("Connection", "close");
			
		// Allow custom headers/mimetypes
		if( s.beforeSend )
			s.beforeSend(xml);
			
		if ( s.global )
		    jQuery.event.trigger("ajaxSend", [xml, s]);

		// Wait for a response to come back
		var onreadystatechange = function(isTimeout){
			// The transfer is complete and the data is available, or the request timed out
			if ( xml && (xml.readyState == 4 || isTimeout == "timeout") ) {
				requestDone = true;
				
				// clear poll interval
				if (ival) {
					clearInterval(ival);
					ival = null;
				}
				
				var status;
				try {
					status = jQuery.httpSuccess( xml ) && isTimeout != "timeout" ?
						s.ifModified && jQuery.httpNotModified( xml, s.url ) ? "notmodified" : "success" : "error";
					// Make sure that the request was successful or notmodified
					if ( status != "error" ) {
						// Cache Last-Modified header, if ifModified mode.
						var modRes;
						try {
							modRes = xml.getResponseHeader("Last-Modified");
						} catch(e) {} // swallow exception thrown by FF if header is not available
	
						if ( s.ifModified && modRes )
							jQuery.lastModified[s.url] = modRes;
	
						// process the data (runs the xml through httpData regardless of callback)
						var data = jQuery.httpData( xml, s.dataType );
	
						// If a local callback was specified, fire it and pass it the data
						if ( s.success )
							s.success( data, status );
	
						// Fire the global callback
						if( s.global )
							jQuery.event.trigger( "ajaxSuccess", [xml, s] );
					} else
						jQuery.handleError(s, xml, status);
				} catch(e) {
					status = "error";
					jQuery.handleError(s, xml, status, e);
				}

				// The request was completed
				if( s.global )
					jQuery.event.trigger( "ajaxComplete", [xml, s] );

				// Handle the global AJAX counter
				if ( s.global && ! --jQuery.active )
					jQuery.event.trigger( "ajaxStop" );

				// Process result
				if ( s.complete )
					s.complete(xml, status);

				// Stop memory leaks
				if(s.async)
					xml = null;
			}
		};
		
		// don't attach the handler to the request, just poll it instead
		var ival = setInterval(onreadystatechange, 13); 

		// Timeout checker
		if ( s.timeout > 0 )
			setTimeout(function(){
				// Check to see if the request is still happening
				if ( xml ) {
					// Cancel the request
					xml.abort();

					if( !requestDone )
						onreadystatechange( "timeout" );
				}
			}, s.timeout);
			
		// Send the data
		try {
			xml.send(s.data);
		} catch(e) {
			jQuery.handleError(s, xml, null, e);
		}
		
		// firefox 1.5 doesn't fire statechange for sync requests
		if ( !s.async )
			onreadystatechange();
		
		// return XMLHttpRequest to allow aborting the request etc.
		return xml;
	},

	handleError: function( s, xml, status, e ) {
		// If a local callback was specified, fire it
		if ( s.error ) s.error( xml, status, e );

		// Fire the global callback
		if ( s.global )
			jQuery.event.trigger( "ajaxError", [xml, s, e] );
	},

	// Counter for holding the number of active queries
	active: 0,

	// Determines if an XMLHttpRequest was successful or not
	httpSuccess: function( r ) {
		try {
			return !r.status && location.protocol == "file:" ||
				( r.status >= 200 && r.status < 300 ) || r.status == 304 ||
				jQuery.browser.safari && r.status == undefined;
		} catch(e){}
		return false;
	},

	// Determines if an XMLHttpRequest returns NotModified
	httpNotModified: function( xml, url ) {
		try {
			var xmlRes = xml.getResponseHeader("Last-Modified");

			// Firefox always returns 200. check Last-Modified date
			return xml.status == 304 || xmlRes == jQuery.lastModified[url] ||
				jQuery.browser.safari && xml.status == undefined;
		} catch(e){}
		return false;
	},

	/* Get the data out of an XMLHttpRequest.
	 * Return parsed XML if content-type header is "xml" and type is "xml" or omitted,
	 * otherwise return plain text.
	 * (String) data - The type of data that you're expecting back,
	 * (e.g. "xml", "html", "script")
	 */
	httpData: function( r, type ) {
		var ct = r.getResponseHeader("content-type");
		var data = !type && ct && ct.indexOf("xml") >= 0;
		data = type == "xml" || data ? r.responseXML : r.responseText;

		// If the type is "script", eval it in global context
		if ( type == "script" )
			jQuery.globalEval( data );

		// Get the JavaScript object, if JSON is used.
		if ( type == "json" )
			eval( "data = " + data );

		// evaluate scripts within html
		if ( type == "html" )
			jQuery("<div>").html(data).evalScripts();

		return data;
	},

	// Serialize an array of form elements or a set of
	// key/values into a query string
	param: function( a ) {
		var s = [];

		// If an array was passed in, assume that it is an array
		// of form elements
		if ( a.constructor == Array || a.jquery )
			// Serialize the form elements
			jQuery.each( a, function(){
				s.push( encodeURIComponent(this.name) + "=" + encodeURIComponent( this.value ) );
			});

		// Otherwise, assume that it's an object of key/value pairs
		else
			// Serialize the key/values
			for ( var j in a )
				// If the value is an array then the key names need to be repeated
				if ( a[j] && a[j].constructor == Array )
					jQuery.each( a[j], function(){
						s.push( encodeURIComponent(j) + "=" + encodeURIComponent( this ) );
					});
				else
					s.push( encodeURIComponent(j) + "=" + encodeURIComponent( a[j] ) );

		// Return the resulting serialization
		return s.join("&");
	},
	
	// evalulates a script in global context
	// not reliable for safari
	globalEval: function( data ) {
		if ( window.execScript )
			window.execScript( data );
		else if ( jQuery.browser.safari )
			// safari doesn't provide a synchronous global eval
			window.setTimeout( data, 0 );
		else
			eval.call( window, data );
	}

});
jQuery.fn.extend({

	show: function(speed,callback){
		var hidden = this.filter(":hidden");
		speed ?
			hidden.animate({
				height: "show", width: "show", opacity: "show"
			}, speed, callback) :
			
			hidden.each(function(){
				this.style.display = this.oldblock ? this.oldblock : "";
				if ( jQuery.css(this,"display") == "none" )
					this.style.display = "block";
			});
		return this;
	},

	hide: function(speed,callback){
		var visible = this.filter(":visible");
		speed ?
			visible.animate({
				height: "hide", width: "hide", opacity: "hide"
			}, speed, callback) :
			
			visible.each(function(){
				this.oldblock = this.oldblock || jQuery.css(this,"display");
				if ( this.oldblock == "none" )
					this.oldblock = "block";
				this.style.display = "none";
			});
		return this;
	},

	// Save the old toggle function
	_toggle: jQuery.fn.toggle,
	toggle: function( fn, fn2 ){
		var args = arguments;
		return jQuery.isFunction(fn) && jQuery.isFunction(fn2) ?
			this._toggle( fn, fn2 ) :
			this.each(function(){
				jQuery(this)[ jQuery(this).is(":hidden") ? "show" : "hide" ]
					.apply( jQuery(this), args );
			});
	},
	slideDown: function(speed,callback){
		return this.animate({height: "show"}, speed, callback);
	},
	slideUp: function(speed,callback){
		return this.animate({height: "hide"}, speed, callback);
	},
	slideToggle: function(speed, callback){
		return this.each(function(){
			var state = jQuery(this).is(":hidden") ? "show" : "hide";
			jQuery(this).animate({height: state}, speed, callback);
		});
	},
	fadeIn: function(speed, callback){
		return this.animate({opacity: "show"}, speed, callback);
	},
	fadeOut: function(speed, callback){
		return this.animate({opacity: "hide"}, speed, callback);
	},
	fadeTo: function(speed,to,callback){
		return this.animate({opacity: to}, speed, callback);
	},
	animate: function( prop, speed, easing, callback ) {
		return this.queue(function(){
		
			this.curAnim = jQuery.extend({}, prop);
			var opt = jQuery.speed(speed, easing, callback);
			
			for ( var p in prop ) {
				var e = new jQuery.fx( this, opt, p );
				if ( prop[p].constructor == Number )
					e.custom( e.cur(), prop[p] );
				else
					e[ prop[p] ]( prop );
			}
			
		});
	},
	queue: function(type,fn){
		if ( !fn ) {
			fn = type;
			type = "fx";
		}
	
		return this.each(function(){
			if ( !this.queue )
				this.queue = {};
	
			if ( !this.queue[type] )
				this.queue[type] = [];
	
			this.queue[type].push( fn );
		
			if ( this.queue[type].length == 1 )
				fn.apply(this);
		});
	}

});

jQuery.extend({
	
	speed: function(speed, easing, fn) {
		var opt = speed && speed.constructor == Object ? speed : {
			complete: fn || !fn && easing || 
				jQuery.isFunction( speed ) && speed,
			duration: speed,
			easing: fn && easing || easing && easing.constructor != Function && easing
		};

		opt.duration = (opt.duration && opt.duration.constructor == Number ? 
			opt.duration : 
			{ slow: 600, fast: 200 }[opt.duration]) || 400;
	
		// Queueing
		opt.old = opt.complete;
		opt.complete = function(){
			jQuery.dequeue(this, "fx");
			if ( jQuery.isFunction( opt.old ) )
				opt.old.apply( this );
		};
	
		return opt;
	},
	
	easing: {},
	
	queue: {},
	
	dequeue: function(elem,type){
		type = type || "fx";
	
		if ( elem.queue && elem.queue[type] ) {
			// Remove self
			elem.queue[type].shift();
	
			// Get next function
			var f = elem.queue[type][0];
		
			if ( f ) f.apply( elem );
		}
	},

	/*
	 * I originally wrote fx() as a clone of moo.fx and in the process
	 * of making it small in size the code became illegible to sane
	 * people. You've been warned.
	 */
	
	fx: function( elem, options, prop ){

		var z = this;

		// The styles
		var y = elem.style;
		
		// Store display property
		var oldDisplay = jQuery.css(elem, "display");

		// Make sure that nothing sneaks out
		y.overflow = "hidden";

		// Simple function for setting a style value
		z.a = function(){
			if ( options.step )
				options.step.apply( elem, [ z.now ] );

			if ( prop == "opacity" )
				jQuery.attr(y, "opacity", z.now); // Let attr handle opacity
			else if ( parseInt(z.now) ) // My hate for IE will never die
				y[prop] = parseInt(z.now) + "px";
			
			y.display = "block"; // Set display property to block for animation
		};

		// Figure out the maximum number to run to
		z.max = function(){
			return parseFloat( jQuery.css(elem,prop) );
		};

		// Get the current size
		z.cur = function(){
			var r = parseFloat( jQuery.curCSS(elem, prop) );
			return r && r > -10000 ? r : z.max();
		};

		// Start an animation from one number to another
		z.custom = function(from,to){
			z.startTime = (new Date()).getTime();
			z.now = from;
			z.a();

			z.timer = setInterval(function(){
				z.step(from, to);
			}, 13);
		};

		// Simple 'show' function
		z.show = function(){
			if ( !elem.orig ) elem.orig = {};

			// Remember where we started, so that we can go back to it later
			elem.orig[prop] = this.cur();

			options.show = true;

			// Begin the animation
			z.custom(0, elem.orig[prop]);

			// Stupid IE, look what you made me do
			if ( prop != "opacity" )
				y[prop] = "1px";
		};

		// Simple 'hide' function
		z.hide = function(){
			if ( !elem.orig ) elem.orig = {};

			// Remember where we started, so that we can go back to it later
			elem.orig[prop] = this.cur();

			options.hide = true;

			// Begin the animation
			z.custom(elem.orig[prop], 0);
		};
		
		//Simple 'toggle' function
		z.toggle = function() {
			if ( !elem.orig ) elem.orig = {};

			// Remember where we started, so that we can go back to it later
			elem.orig[prop] = this.cur();

			if(oldDisplay == "none")  {
				options.show = true;
				
				// Stupid IE, look what you made me do
				if ( prop != "opacity" )
					y[prop] = "1px";

				// Begin the animation
				z.custom(0, elem.orig[prop]);	
			} else {
				options.hide = true;

				// Begin the animation
				z.custom(elem.orig[prop], 0);
			}		
		};

		// Each step of an animation
		z.step = function(firstNum, lastNum){
			var t = (new Date()).getTime();

			if (t > options.duration + z.startTime) {
				// Stop the timer
				clearInterval(z.timer);
				z.timer = null;

				z.now = lastNum;
				z.a();

				if (elem.curAnim) elem.curAnim[ prop ] = true;

				var done = true;
				for ( var i in elem.curAnim )
					if ( elem.curAnim[i] !== true )
						done = false;

				if ( done ) {
					// Reset the overflow
					y.overflow = "";
					
					// Reset the display
					y.display = oldDisplay;
					if (jQuery.css(elem, "display") == "none")
						y.display = "block";

					// Hide the element if the "hide" operation was done
					if ( options.hide ) 
						y.display = "none";

					// Reset the properties, if the item has been hidden or shown
					if ( options.hide || options.show )
						for ( var p in elem.curAnim )
							if (p == "opacity")
								jQuery.attr(y, p, elem.orig[p]);
							else
								y[p] = "";
				}

				// If a callback was provided, execute it
				if ( done && jQuery.isFunction( options.complete ) )
					// Execute the complete function
					options.complete.apply( elem );
			} else {
				var n = t - this.startTime;
				// Figure out where in the animation we are and set the number
				var p = n / options.duration;
				
				// If the easing function exists, then use it 
				z.now = options.easing && jQuery.easing[options.easing] ?
					jQuery.easing[options.easing](p, n,  firstNum, (lastNum-firstNum), options.duration) :
					// else use default linear easing
					((-Math.cos(p*Math.PI)/2) + 0.5) * (lastNum-firstNum) + firstNum;

				// Perform the next step of the animation
				z.a();
			}
		};
	
	}
});
}

EOF

}

1;


