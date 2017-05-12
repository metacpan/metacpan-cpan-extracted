package Audio::Moosic;

use strict;
use warnings;
use vars qw( $VERSION );
use RPC::XML;
use RPC::XML::Client;

$VERSION = '0.10';

=head1 NAME

Audio::Moosic - Moosic client library for Perl

=head1 SYNOPSIS

  use Audio::Moosic;

  $moo = Audio::Moosic::Unix->new();

  $moosic->append('/home/me/somewhat.ogg');
  $moosic->play;
  print $moosic->current, "\n";
  $moosic->pause;
  ...

=head1 DESCRIPTION

Audio::Moosic acts as a client for the musical jukebox programm Moosic
(http://nanoo.org/~daniel/moosic/) by Daniel Pearson <daniel@nanoo.org>.

Using Audio::Moosic you can connect to a moosic server either via an UNIX socket
or an INET socket.

=head1 METHODS

=head2 new

  $moo = Audio::Moosic::Unix->new();
  $moo = Audio::Moosic::Unix->new('/tmp/moosic/socket');
  $moo = Audio::Moosic::Inet->new('localhost', 8765);

Constructor. Initializes the class and invokes the connect method. If you're
creating a Audio::Moosic::Unix object you can give the location of your moosic
socket as parameter. If not ~/.moosic/socket is used. If you're creating a
Audio::Moosic::Inet instance you need to pass host and port as arguments.

You can't create an instance of Audio::Moosic itself. Use Unix or Inet subclass.

If the object was able to connect to the moosic server a reference to the object
instance is returned. If the connection failed $@ is set and undef returned.

=cut

sub new {
    my ($class, @args) = @_;
    $class = ref($class) || $class;

    my $self = { __errors => [ ] };
    bless $self, $class;

    unless( $self->connect(@args) ) {
        $@ = "Can't connect to moosic server: $!";
        return;
    }

    return $self;
}

=head2 connect

  $moo->connect('foobar.com', 9876);

Connect to the moosic server. You normally don't need to run this method in your
moosic client.

=cut

sub connect {
    require Carp;
    Carp::croak('This method should never be called. Please create an instance'.
                ' of Audio::Moosic::Inet or Audio::Moosic::Unix.');
}

=head2 disconnect

  $moo->disconnect;

Disconnect from the moosic daemon. No more calls will be sent to the server
after calling this method. You'll need to reconnect() first.

=cut

sub disconnect {
    my $self = shift;
    $self->{__connected} = 0;
    delete $self->{__rpc_xml_client};
}

=head2 reconnect

  $moo->reconnect;

Disconnects from the server if you're connected and tries to reconnect.

=cut

sub reconnect {
    my $self = shift;
    $self->disconnect if $self->connected;
    return $self->connect;
}

=head2 connected

  $moo->reconnect unless $moo->connected;

Check whether you're connected to the moosic server or not.

=cut

sub connected {
    my $self = shift;
    return $self->{__connected};
}

=head2 client_config

  print $moo->client_config('location');
  $conf = $moo->client_config();

Reads the moosic clients config. If a $key argument is given it returns only the
value associated with that key, if not the whole config hash.

Would it be a good idea to make the user able to edit the client_config here?
Suggestions or maybe patches are welcome.

=cut

sub client_config {
    my ($self, $key) = @_;
    if($key) {
        return $self->{__client_config}{$key};
    } else {
        return $self->{__client_config};
    }
}

=head2 ping

  die unless $moo->ping;

Checks if we're still connected. This method checks the connection explicitly by
calling the no_op server method. connected() only checks the value of the
'connected' object property.

=cut

sub ping {
    my $self = shift;

    my $resp = $self->{__rpc_xml_client}->send_request('no_op');

    if( ref $resp ) {
        $self->{__connected} = 1;
    } else {
        $self->{__connected} = 0;
    }

    return $self->connected;
}

=head2 error

  my $error = $moo->error;
  $moo->error('Whaaa!');

If an argument is given it adds the error string to the internal error array. If
called in scalar context it returns the last error occured. If you call error()
in list context the whole error array of the Audio::Moosic instance is returned.

=cut

sub error {
    my ($self, $error) = @_;

    if($error) {
        push(@{$self->{__errors}}, $error);
    } else {
        return wantarray ?
            @{$self->{__errors}} :
            @{$self->{__errors}}[@{$self->{__errors}} - 1];
    }
}

=head2 call

  $moo->call('foo');
  $moo->call('bar', RPC::XML::int->new(3));

This method calls a xml-rpc method on the moosic server. The first argument
should be the method name. The arguments of that method should follow behind.

If the request to the moosic server could not be sent the Audio::Moosic instance
disconnects from the server and puts the error message into the internal error
array. Access it via error(). The object won't send any calls anymore if such an
error occured. You should try to reconnect.

If the request could be sent, but returned an error the error message is added
to the error array accessable via error().

If any error occured call() returns undef. If everything went fine the value of
the response is returned.

Normally you don't need to call this method. It is only used by other moosic
methods to send their calls more easily. If a new moosic method is not supported
by this library yet you'll maybe need to use call() manually. Please notice me
if that happens so I'll add the new method.

=cut

sub call {
    my ($self, $method, @args) = @_;
    return unless $self->connected;
    my $resp = $self->{__rpc_xml_client}->send_request($method, @args);

    unless( ref $resp ) {
        my $error = qq/Lost connection to moosic server: "$resp"/;
        if( my $function = (caller(1))[3]) { $error .= " in $function()"; }
        $self->error($error);
        $self->{__connected} = 0;
        return;
    }

    if( $resp->is_fault ) {
        my $error = 'Error: '. $resp->code .': "'. $resp->string .'"';
        if( my $function = (caller(1))[3]) { $error .= " in $function()"; }
        $self->error($error);
        return;
    }

    return $resp->value;
}

=head2 api_version

  @api = $moo->api_version;
  $api = $moo->api_version;

Return the moosic servers API version. If called in scalar context a version
string like '1.3' is returned. In list context the mayor and minor numbers of
the API version are returned.

=cut

sub api_version {
    my $self = shift;
    my $resp = $self->call('api_version') or return;
    return wantarray ? @{$resp} : join('.', @{$resp});
}

=head2 append

  $moo->append('/home/florian/whatever.ogg');
  $moo->append('/home/florian/foo.ogg', '/home/florian/bar.mp3');

Add songs to the moosic queue. The files to add should be the arguments for the
append method. append() returns 1 if there were no errors or something false if
there were some.

=cut

sub append {
    my ($self, @items) = @_;
    return $self->call('append', RPC::XML::array->new(
                map { RPC::XML::base64->new($_) } @items
    ));
}

=head2 clear

  $moo->clear;

Clears the moosic queue. Only the current song remains playing.

=cut

sub clear {
    my $self = shift;
    return $self->call('clear');
}

=head2 crop

  $moo->crop(4);
  $moo->crop(3, 4);

Remove all playlist items that don't fall within a given range. If the range is
represented by one integer all items whose index is greater than or equal to the
value will be removed. Two intergers represent all items whose index is greater
than or equal to the value of first integer and less than the value of the
second integer.

=cut

sub crop {
    my ($self, @range) = @_;
    return $self->call('crop', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 crop_list

  $moo->crop_list(1, 4, 3);

Remove all queued items exept those referenced by a list of positions.

=cut

sub crop_list {
    my ($self, @range) = @_;
    return $self->call('crop_list', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 current

  print $moo->current;

Return the name of the current playing song.

=cut

sub current {
    my $self = shift;
    return $self->call('current');
}

=head2 current_time

  print $moo->current_time;

Return the amount of time the current song has been playing.

=cut

sub current_time {
    my $self = shift;
    return $self->call('current_time');
}

=head2 cut

  $moo->cut(3);
  $moo->cut(4, 10);

Remove all queued items that fall within a given range. See crop() for details
on how that range should look like.

=cut

sub cut {
    my ($self, @range) = @_;
    return $self->call('cut', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 cut_list

  $moo->cut_list(3, 7, 9);

Remove all queued items referenced by list of positions.

=cut

sub cut_list {
    my ($self, @range) = @_;
    return $self->call('cut_list', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 die

  $moo->die;

Tell the server to terminate itself.

=cut

sub die {
    my $self = shift;
    ($self->call('die') and $self->disconnect) or return;
}

=head2 filter

  $moo->filter('foo');
  $moo->filter('bar', 4);
  $moo->filter('moo', 7, 11);

Remove all items that don't match the given regular expression. You may limit
this operation to a specific range which is described in crop().

=cut

sub filter {
    my ($self, $regex, @range) = @_;
    return $self->call('filter',
            RPC::XML::base64->new($regex),
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @range )
    );
}

=head2 get_history_limit

  $limit = $moo->get_history_limit;

Get the limit on the size of the history list stored in servers memory.

=cut

sub get_history_limit {
    my $self = shift;
    return $self->call('get_history_limit');
}

=head2 getconfig

  @config = $moo->getconfig;

Return a list of the server's filetype-player associations.

=cut

sub getconfig {
    my ($self, $key) = @_;
    my $resp = $self->call('getconfig');
    return @{$resp};
    #TODO support $key to read single config options
}

=head2 halt_queue

  $moo->halt_queue;

Stop any new songs from being played. Use run_queue() to reverse this state.

=cut

sub halt_queue {
    my $self = shift;
    return $self->call('halt_queue');
}

=head2 haltqueue

See halt_queue().

=cut

sub haltqueue {
    my $self = shift;
    $self->halt_queue;
}

=head2 history

  %hist = $moo->history;

Return a list of items that has been recently played. If a positive integer
argument is given than no more than number of items will be returned. Otherwise
the entire history is printed.

history() returns an array of hashrefs like that:
  @history = (
    { title => 'foo', start => 123.45, stop => 543.21 },
    { title => 'bar', start => 234.56, stop => 654.32 },
    ...
  );

=cut

sub history {
    my ($self, $num) = @_;

    return map {
        title    => $_->[0],
        start    => $_->[1],
        stop    => $_->[2] }, @{$self->call('history',
                RPC::XML::int->new( $num || 0 )) };
}

=head2 indexed_list

  %list = $moo->indexed_list;
  %list = $moo->indexed_list(1);
  %list = $moo->indexed_list(2, 5);

List the song queue's contents. If a range is specified, only the items that
fall within that range are listed.

indexed_list() returns a hash like that:
  %list = (
    list => [ 'foo', 'bar', 'moo', ... ],
    start => 4
  );

=cut

sub indexed_list {
    my ($self, @range) = @_;

    return $self->call('indexed_list', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 insert

  $moo->insert(4, 'foo.ogg', 'bar.mp3');

Insert items at a given position in the queue.

=cut

sub insert {
    my $self = shift;
    my $num = pop;
    my @items = @_;

    return $self->call('insert',
            RPC::XML::array->new( map { RPC::XML::base64->new($_) } @items ),
            RPC::XML::int->new( $num )
    );
}

=head2 is_looping

  $moo->toggle_loop_mode if $moo->is_looping;

Check whether the loop mode is on or not.

=cut

sub is_looping {
    my $self = shift;
    return $self->call('is_looping');
}

=head2 is_paused

  $moo->toggle_pause if $moo->is_paused;

Check whether the current song is paused or not.

=cut

sub is_paused {
    my $self = shift;
    return $self->call('is_paused');
}

=head2 is_queue_running

  if($moo->is_queue_running) {
    ...;
  }

Check whether the queue consumption (advancement) is activated.

=cut

sub is_queue_running {
    my $self = shift;
    return $self->call('is_queue_running');
}

=head2 last_queue_update

  $time = $moo->last_queue_update

Return the time at which the song queue was last modified.

=cut

sub last_queue_update {
    my $self = shift;
    return $self->call('last_queue_update');
}

=head2 length

  $length = $moo->length

Return the number of items in the song queue.

=cut

sub length {
    my $self = shift;
    return $self->call('length');
}

=head2 list

  @list = $moo->list();
  @list = $moo->list(2);
  @list = $moo->list(4, 8);
  $list_ref = $moo->list()

List the song queue's contents. If a range is specified, only the items that
fall within that range are listed. Returns an array if called in list context
or an array reference if it's called in scalar context.

=cut

sub list {
    my ($self, @range) = @_;

    my $list = $self->call('list', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));

    return wantarray ?
        @{$list} :
        $list;
}

=head2 move

  $moo->move(10, 4);
  $moo->move(4, 7, 1);

Move a range of items to a new position within the queue.

=cut

sub move {
    my $self = shift;
    my $num = pop;
    my @range = @_;

    return $self->call('move',
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @range ),
            RPC::XML::int->new( $num )
    );
}

=head2 move_list

  $moo->move(3, 5, 7, 11);

Move the items referenced by a list of positions to a new position.

=cut

sub move_list {
    my $self = shift;
    my $num = pop;
    my @range = @_;

    return $self->call('move_list',
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @range ),
            RPC::XML::int->new( $num )
    );
}

=head2 next

  $moo->next;
  $moo->next(5);

Stop the current song (if any), and jumps ahead to a song that is currently in
the queue. The skipped songs are recorded in the history as if they had been
played. When called without arguments, this behaves very much like the skip()
method, except that it will have an effect even if nothing is currently playing.

=cut

sub next {
    my ($self, $num) = @_;

    return $self->call('next', RPC::XML::int->new( $num || 1 ));
}

=head2 no_op

  $moo->no_op

Do nothing, successfully.

=cut

sub no_op {
    my $self = shift;
    return $self->call('no_op');
}

=head2 pause

  $moo->pause;

Pause the currently playing song.

=cut

sub pause {
    my $self = shift;
    return $self->call('pause');
}

=head2 prepend

  $moo->prepend('foo.ogg', 'bar.mp3');

Add items to the beginning of the queue.

=cut

sub prepend {
    my ($self, @items) = @_;

    return $self->call('prepend', RPC::XML::array->new(
                map { RPC::XML::base64->new($_) } @items
    ));
}

=head2 previous

  $moo->previous;
  $moo->previous(3);

Stops the current song (if any), removes the most recently played song from the
history, and puts these songs at the head of the queue. When loop mode is on,
the songs at the tail of the song queue are used instead of the most recently
played songs in the history.

=cut

sub previous {
    my ($self, $num) = @_;

    return $self->call('previous', RPC::XML::int->new( $num || 1 ));
}

=head2 putback

  $moo->putback;

Place the currently playing song at the beginning of the queue.

=cut

sub putback {
    my $self = shift;
    return $self->call('putback');
}

=head2 queue_length

  $length = $moo->queue_length;

Return the number of items in the song queue.

=cut

sub queue_length {
    my $self = shift;
    return $self->call('queue_length');
}

=head2 reconfigure

  $moo->reconfigure;

Tell the server to reread its player configuration file.

=cut

sub reconfigure {
    my $self = shift;
    return $self->call('reconfigure');
}

=head2 remove

  $moo->remove('regex');
  $moo->remove('regex', 4);
  $moo->remove('regex', 1, 3);

Remove all items that match the given regular expression. You can limit this
operation by giving a range as described in crop() as last argument.

=cut

sub remove {
    my ($self, $regex, @range) = @_;

    return $self->call('remove',
            RPC::XML::base64->new( $regex ),
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @range )
    );
}

=head2 replace

  $moo->replace('foo.ogg', 'bar.mp3');

Replace the contents of the queue with the given items. This is equivalent to
calling clear() and prepend() in succession, except that this operation is
atomic.

=cut

sub replace {
    my ($self, @items) = @_;

    return $self->call('replace', RPC::XML::array->new(
                map { RPC::XML::base64->new($_) } @items
    ));
}

=head2 reverse

  $moo->reverse;
  $moo->reverse(2);
  $moo->reverse(5, 7);

Reverse the order of the items in the queue. You can limit this operation by
giving a range as described in crop() as last argument.

=cut

sub reverse {
    my ($self, @range) = @_;

    return $self->call('reverse', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 run_queue

  $moo->run_queue;

Allows new songs to be played again after halt_queue() has been called.

=cut

sub run_queue {
    my $self = shift;
    return $self->call('run_queue');
}

=head2 runqueue

See run_queue().

=cut

sub runqueue {
    my $self = shift;
    return $self->run_queue;
}

=head2 set_history_limit

  $moo->set_history_limit(44);

Set the limit on the size of the history list stored in memory.

=cut

sub set_history_limit {
    my ($self, $limit) = @_;

    return $self->call('set_history_limit', RPC::XML::int->new( $limit ));
}

=head2 set_loop_mode

  $moo->set_loop_mode(0);
  $moo->set_loop_mode(1);

Turn loop mode on or off.

=cut

sub set_loop_mode {
    my ($self, $mode) = @_;

    return $self->call('set_loop_mode', RPC::XML::boolean->new( $mode ));
}

=head2 showconfig

  my $config = $moo->showconfig;
  my %config = $moo->showconfig;

Return the server's player configuration. If showconfig() is called in scalar
context a scalar containing the textual description of the configuration is
returned. If you call showconfig() in list context a hash which maps the
configuration regular expression to the player commands is returned.

=cut

sub showconfig {
    my $self = shift;

    my $config = $self->call('showconfig');
    return unless $config;
    return $config unless wantarray;

    my @config;
    foreach(split("\n", $config)) {
        s/^\s+//;
        chomp;
        push(@config, $_);
    }

    return @config;
}

=head2 shuffle

  $moo->shuffle;
  $moo->shuffle(2);
  $moo->shuffle(4, 6);

Rearrange the contents of the queue into a random order. You can limit this
operation by giving a range as described for crop() as last argument.

=cut

sub shuffle {
    my ($self, @range) = @_;

    return $self->call('shuffle', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 skip

  $moo->skip;

Skips the rest of the current song to play the next song in the queue. This only
has an effect if there actually is a current song.

=cut

sub skip {
    my $self = shift;
    return $self->call('skip');
}

=head2 sort

  $moo->sort;
  $moo->sort(2);
  $moo->sort(4, 6);

Arrange the contents of the queue into sorted order.

=cut

sub sort {
    my ($self, @range) = @_;

    return $self->call('sort', RPC::XML::array->new(
                map { RPC::XML::int->new($_) } @range
    ));
}

=head2 stop

  $moo->stop;

Stop playing the current song and stops new songs from playing. The current
song is returned to the head of the song queue and is not recorded in the
history list. If loop mode is on, the current song won't be placed at the end of
the song queue when it is stopped.

=cut

sub stop {
    my $self = shift;
    return $self->call('stop');
}

=head2 sub

  $moo->sub('regex', 'substitition');
  $moo->sub('regex', 'substitition', 2);
  $moo->sub('regex', 'substitition', 1, 7);

Perform a regular expression substitution on the items in the queue. You can
limit this operation by giving a range as described for crop() as last argument.

=cut

sub sub {
    my ($self, $regex, $subst, @range) = @_;

    return $self->call('sub',
            RPC::XML::base64->new( $regex ),
            RPC::XML::base64->new( $subst ),
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @range )
    );
}

=head2 sub_all

  $moo->sub_all('regex', 'substition');
  $moo->sub_all('regex', 'substition', 2);
  $moo->sub_all('regex', 'substition', 1, 7);

Performs a global regular expression substitution on the items in the queue.

=cut

sub sub_all {
    my ($self, $regex, $subst, @range) = @_;

    return $self->call('sub_all',
            RPC::XML::base64->new( $regex ),
            RPC::XML::base64->new( $subst ),
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @range )
    );
}

=head2 swap

  $moo->swap( [7, 10], [ 5 ]  );

Swap the items contained in one range with the items contained in the other
range. The ranges for the swap() method needs to be passed as array references
in contrast to other methods that use ranges.

=cut

sub swap {
    my ($self, $range1, $range2) = @_;

    return $self->call('swap',
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @{$range1} ),
            RPC::XML::array->new( map { RPC::XML::int->new($_) } @{$range2} )
    );
}

=head2 listMethods

  @methods = $moo->listMethods;

Return an array of all available XML-RPC methods on this server.

=cut

sub listMethods {
    my $self = shift;
    return $self->call('system.listMethods');
}

=head2 methodHelp

  $help = $moo->methodHelp('sub');

Given the name of a method, return a help string.

=cut

sub methodHelp {
    my ($self, $method) = @_;

    return $self->call('syste.methodHelp',
            RPC::XML::string->new( $method )
    );
}

=head2 methodSignature

  $signature = $moo->methodSignature;

Given the name of a method, return an array of legal signatures. Each signature
is an array of scalars. The first item of each signature is the return type, and
any others items are parameter types.  =cut

=cut

sub methodSignature {
    my ($self, $method) = @_;

    return $self->call('system.methodSignature',
            RPC::XML::string->new( $method )
    );
}

=head2 multicall

  $moo->multicall(...);

Process an array of calls, and return an array of results. This is not
implemented yet.

=cut

sub multicall {
    my ($self, @cmds) = @_;
    require Carp;
    Carp::carp(__PACKAGE__."::multicall() isn't implemented yet."); #TODO
}

=head2 toggle_loop_mode

  $moo->toggle_loop_mode;

Turn loop mode on if it is off, and turns it off if it is on.

=cut

sub toggle_loop_mode {
    my $self = shift;
    return $self->call('toggle_loop_mode');
}

=head2 toggle_pause

  $moo->toggle_pause;

Pause the current song if it is playing, and unpauses if it is paused.

=cut

sub toggle_pause {
    my $self = shift;
    return $self->call('toggle_pause');
}

=head2 unpause

  $moo->unpause;

Unpauses the current song.

=cut

sub unpause {
    my $self = shift;
    return $self->call('unpause');
}

=head2 version

  $version = $moo->version;

Return the Moosic server's version string.

=cut

sub version {
    my $self = shift;
    return $self->call('version');
}

=head1 HELPER METHODS

The following methods aren't methods defined by the moosic API but should be
usefull when dealing with a moosic server.

=head2 play

  $moo->play();

Start playing. If the playback is paused it will be unpaused. If the queue is
stopped it will be started.

=cut

sub play {
    my $self = shift;

    return $self->unpause() if $self->is_paused();
    return $self->run_queue();
}

=head2 can_play

  $moo->append( $song ) if $moo->can_play( $song );

Takes a list of songs as argument and returns all items that can be played by
the moosic daemon.

=cut

sub can_play {
    my $self = shift;
    my @can_play;

    my @config = $self->getconfig();
    for my $track ( @_ ) {
        for( @config ) {
            push @can_play, $track if $track =~ qr/$_->[0]/;
        }
    }

    return @can_play;
}

package Audio::Moosic::Inet;

use strict;
use warnings;
use base qw( Audio::Moosic );

sub connect {
    my ($self, $host, $port) = @_;
    return if $self->connected;

    my $location = "http://$host\:$port";
    $self->disconnect;
    $self->{__rpc_xml_client} =    RPC::XML::Client->new($location);

    $self->ping or return;
    $self->{__client_config} = { location => $location };
}

package Audio::Moosic::Unix;

use strict;
use warnings;
use base qw( Audio::Moosic );


sub connect {
    _init();

    my ($self, $filename) = @_;
    return if $self->connected;

    $filename = ($ENV{HOME} || '/tmp') . '/.moosic/socket' unless $filename;
    my $location  = "http://$filename";
    $self->disconnect;
    $self->{__rpc_xml_client} = RPC::XML::Client->new($location);

    $self->ping or return;
    $self->{__client_config} = { location => $location };
}

sub _init {

    unless( eval 'require LWP::Protocol::http::SocketUnix' ) {
        require Carp;
        Carp::croak('You need LWP::Protocol::http::SocketUnix to connect to a local'.
                " moosic server using a UNIX socket.\nPlease install it!");
    }

    LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocketUnix' );
}

1;

=head1 BUGS

=over 4

=item * check arguments more strictly

expecially for constructors.

=back

If you find some others please report them to Florian Ragwitz
E<lt>flora@cpan.orgE<gt>

=head1 TODO

=over 4

=item * implement system_multicall

=item * improve client_config

=item * maybe use autoloader to load subs on demand

create the method arguments from methodSignature.

=back

=head1 SEE ALSO

moosic(1), moosicd(1), http://nanoo.org/~daniel/moosic/

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Florian Ragwitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
