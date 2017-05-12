package Apache::Scoreboard;

$Apache::Scoreboard::VERSION = '2.10';

use strict;
use warnings FATAL => 'all';

use Carp;

BEGIN {
    require mod_perl2;
    die "This module was built against mod_perl 2.0 ",
        "and can't be used with $mod_perl::VERSION, "
            unless $mod_perl::VERSION > 1.99;
}

# so that it can be loaded w/o mod_perl (.e.g MakeMaker requires this
# file when Apache::Scoreboard is some other module's PREREQ_PM)
if ($ENV{MOD_PERL}) {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $Apache::Scoreboard::VERSION);
}
else {
    require Apache::DummyScoreboard;
}

use constant DEBUG => 0;

my $ua;

sub http_fetch {
    my($self, $url) = @_;

    Carp::croak("no url argument was passed") unless $url;

    require LWP::UserAgent;
    unless ($ua) {
	no strict 'vars';
	$ua = LWP::UserAgent->new;
	$ua->agent(join '/', __PACKAGE__, $VERSION);
    }

    my $request = HTTP::Request->new('GET', $url);
    my $response = $ua->request($request);
    die "failed to execute: 'GET $url', response: ",
        $response->status_line unless $response->is_success;

    # XXX: fixme
#    my $type = $response->header('Content-type');
#    unless ($type eq Apache::Scoreboard::REMOTE_SCOREBOARD_TYPE) {
#	warn "invalid scoreboard Content-type: $type" if DEBUG;
#	return undef;
#    }

    $response->content;
}

sub fetch {
    my($self, $pool, $url) = @_;
    $self->thaw($pool, $self->http_fetch($url));
}

sub fetch_store {
    my($self, $url, $file) = @_;
    $self->store($self->http_fetch($url), $file);
}

sub store {
    my($self, $frozen_image, $file) = @_;
    croak "undefined image passed" unless $frozen_image;
    open my $fh, ">$file" or die "open $file: $!";
    print $fh $frozen_image;
    close $fh;
}

sub retrieve {
    my($self, $pool, $file) = @_;
    open my $fh, $file or die "open $file: $!";
    local $/;
    my $data = <$fh>;
    close $fh;
    $self->thaw($pool, $data);
}

1;
__END__

=head1 NAME

Apache::Scoreboard - Perl interface to the Apache scoreboard structure





=head1 SYNOPSIS

 # Configuration in httpd.conf:
 # mod_status should be compiled in (it is by default)
 ExtendedStatus On

 # in your perl code:
  use Apache::Scoreboard ();

  #inside httpd
  my $image = Apache::Scoreboard->image;

  #outside httpd
  my $image = Apache::Scoreboard->fetch("http://localhost/scoreboard");





=head1 DESCRIPTION

Apache keeps track of server activity in a structure known as the
C<scoreboard>.  There is a I<slot> in the scoreboard for each child
server and its workers (be it threads or processes), containing
information such as status, access count, bytes served and cpu time,
and much more.  This same information is used by C<mod_status> to
provide current server statistics in a human readable
form. C<Apache::Scoreboard> provides the Perl API to access the
scoreboard. C<Apache::VMonitor> is an extended equivalent of
C<mod_status> written in Perl.




=head1 The C<Apache::Scoreboard> Methods



=head2 C<fetch>

This method fetches the C<Apache::Scoreboard> object from a remote
server, which must contain the following configuration:

  PerlModule Apache::Scoreboard
  <Location /scoreboard>
     SetHandler modperl
     PerlHandler Apache::Scoreboard::send
     order deny,allow
     deny from all
     #same config you have for mod_status
     allow from 127.0.0.1 ...
  </Location>

If the remote server is not configured to use mod_perl or simply for a
smaller footprint, see the I<apxs> directory for the C module
I<mod_scoreboard_send>, which once built (like any other Apache
module) can be configured as following:

  LoadModule scoreboard_send_module libexec/mod_scoreboard_send.so
  
  <Location /scoreboard>
     SetHandler scoreboard-send-handler
     order deny,allow
     deny from all
     allow from 127.0.0.1 ...
  </Location>

The image can then be fetched via http:

  my $image = Apache::Scoreboard->fetch("http://remote-hostname/scoreboard");

Note that if the the code processing the scoreboard running under the
same server, you should be using the C<L<image()|/image>> method,
which retrieves the scoreboard directly from the server memory.



=head2 C<fetch_store>

  Apache::Scoreboard->fetch_store($retrieve_url, $local_filename);

Fetches a remote scoreboard and stores it in the file.

see C<L<retrieve()|/retrieve>> and C<L<store()|/store>>.




=head2 C<freeze>

  my $image = Apache::Scoreboard->fetch($pool, $retrieve_url);

Freeze the image so it can be later restored and used. The frozen
image for example can be stored on the filesystem and then read in:

  my $image = Apache::Scoreboard->fetch($pool, $retrieve_url);
  my $frozen_image = $image->freeze;
  Apache::Scoreboard->store($frozen_image, $store_file);

See C<L<store()|/store>>.





=head2 C<image>

This method returns an object for accessing the scoreboard structure
when running inside the server:

  my $image = Apache::Scoreboard->image;

If you want to fetch a scoreboard from a different server, or if the
code runs outside the mod_perl server use the C<L<fetch()|/fetch>> or
the C<L<fetch_store()|/fetch_store>> methods.





=head2 C<parent_score>

This method returns a object of the first parent score entry in the
list, blessed into the
C<L<Apache::ScoreboardParentScore|/The_Apache::ScoreboardParentScore_Methods>>
class:

  my $parent_score = $image->parent_score;

Iterating over the list of scoreboard slots is done like so:

  for (my $parent_score = $image->parent_score;
       $parent_score;
       $parent_score = $parent_score->next) {
      my $pid = $parent_score->pid; # pid of the child

      # Apache::ScoreboardWorkerScore object
      my $wscore = $parent_score->worker_score;
      ...
  }




=head2 C<pids>

Returns an reference to an array containing all child pids:

  my $pids = $image->pids;

META: check whether we get them all (if there is a hole due to a proc
in the middle of the list that was killed)



=head2 C<retrieve>

The I<fetch_store> method is used to fetch the image once from a
remote server and save it to disk.  The image can then be read by
other processes with the I<retrieve> function.  This way, multiple
processes can access a remote scoreboard with just a single request to
the remote server.  Example:

  Apache::Scoreboard->fetch_store($retrieve_url, $local_filename);
  
  my $image = Apache::Scoreboard->retrieve($local_filename);




=head2 C<send>

  Apache::Scoreboard::send();

a response handler which sends the scoreboard image. See
C<L<fetch()|/fetch>> for details.




=head2 C<server_limit>

Returns a server limit for the given Apache server.

  my $server_limit = $image->server_limit;

use this instead of the deprecated C<Apache::Const::SERVER_LIMIT>
constant.




=head2 C<store>

  Apache::Scoreboard->store($frozen_image, $store_file);

stores a C<L<frozen|/freeze>> image on the filesystem.



=head2 C<thaw>

  my $thawed_image = Apache::Scoreboard->thaw($pool, $frozen_image);

thaws a C<L<frozen|/freeze>> image, turning it into the
C<L<Apache::Scoreboard|/The_Apache::Scoreboard_Methods>> object.




=head2 C<thread_limit>

Returns a threads limit per process for the given image.

  my $thread_limit = $image->thread_limit;

use this instead of the deprecated C<Apache::Const::THREAD_LIMIT>
constant.











=head1 The C<Apache::ScoreboardParentScore> Class

To get the C<Apache::ScoreboardParentScore> object use the
C<L<$image->parent_score()|/parent_score>> and
C<L<$parent_score->next()|/next>> methods.



=head2 C<next>

Returns the next I<Apache::ScoreboardParentScore> object in the list
of parent scores (servers):

  my $parent_score_next = $parent_score->next;




=head2 C<next_active_worker_score>

  my $worker_score_next = $parent_score->next_active_worker_score($worker_score)

Returns the next active
C<L<Apache::ScoreboardWorkerScore|/The_Apache::ScoreboardWorkerScore_Methods>>
object of the given parent score. An active worker is defined as a
worker that does something at the moment this method was called (for
the live L<image|/image>) or if it did something when the snapshot of
the scoreboard was taken (via C<L<send()|/send>> or
C<L<freeze()|/freeze>>.

This is how to traverse all active workers for the given parent score:

  for (my $worker_score = $parent_score->worker_score;
          $worker_score;
          $worker_score = $parent_score->next_active_worker_score($worker_score)
      ) {
      # do something with $worker_score
  }

See also: C<L<worker_score()|/worker_score>>,
C<L<next_live_worker_score()|/next_live_worker_score>> and
C<L<next_worker_score()|/next_worker_score>>.




=head2 C<next_live_worker_score>

  my $worker_score_next = $parent_score->next_live_worker_score($worker_score)

Returns the next live
C<L<Apache::ScoreboardWorkerScore|/The_Apache::ScoreboardWorkerScore_Methods>>
object of the given parent score. The live worker is defined as a
worker that have served/serves at least one request and isn't yet
dead.

This is how to traverse all workers for the given parent score:

  for (my $worker_score = $parent_score->worker_score;
          $worker_score;
          $worker_score = $parent_score->next_live_worker_score($worker_score)
      ) {
      # do something with $worker_score
  }

See also: C<L<worker_score()|/worker_score>>,
C<L<next_active_worker_score()|/next_active_worker_score>> and
C<L<next_worker_score()|/next_worker_score>>.



=head2 C<next_worker_score>

  my $worker_score_next = $parent_score->next_worker_score($worker_score)

Returns the next
C<L<Apache::ScoreboardWorkerScore|/The_Apache::ScoreboardWorkerScore_Methods>>
object of the given parent score.

This is how to traverse all workers for the given parent score:

  for (my $worker_score = $parent_score->worker_score;
          $worker_score;
          $worker_score = $parent_score->next_worker_score($worker_score)
      ) {
      # do something with $worker_score
  }

See also: C<L<worker_score()|/worker_score>>,
C<L<next_active_worker_score()|/next_active_worker_score>> and
C<L<next_live_worker_score()|/next_live_worker_score>>.



=head2 C<pid>

Returns the pid of the parent score (server):

  my $pid = $parent_score->pid;




=head2 C<worker_score>

Returns the first
C<L<Apache::ScoreboardWorkerScore|/The_Apache::ScoreboardWorkerScore_Methods>>
object of the given parent score:

  my $worker_score = $parent_score->worker_score;

See also: C<L<next_active_worker_score()|/next_active_worker_score>>,
C<L<next_live_worker_score()|/next_live_worker_score>> and
C<L<next_worker_score()|/next_worker_score>>.










=head1 The C<Apache::ScoreboardWorkerScore> Methods

To get the C<Apache::ScoreboardWorkerScore> object use the following
methods: C<L<worker_score()|/worker_score>>,
C<L<next_active_worker_score()|/next_active_worker_score>>,
C<L<next_live_worker_score()|/next_live_worker_score>> and
C<L<next_worker_score()|/next_worker_score>>.




=head2 C<access_count>

The access count of the worker:

  my $count = $worker_score->access_count;



=head2 C<bytes_served>

Total number of bytes served by this child:

  my $bytes = $worker_score->bytes_served;



=head2 C<client>

The ip address or hostname of the client:

  #e.g.: 127.0.0.1
  my $client = $worker_score->client;




=head2 C<conn_bytes>

Number of bytes served by the last connection in this child:

  my $bytes = $worker_score->conn_bytes;




=head2 C<conn_count>

Number of requests served by the last connection in this child:

  my $count = $worker_score->conn_count;



=head2 C<most_recent>


META: complete



=head2 C<my_access_count>

META: complete



=head2 C<my_bytes_served>

META: complete



=head2 C<request>

The first 64 characters of the HTTP request:

  #e.g.: GET /scoreboard HTTP/1.0
  my $request = $worker_score->request;



=head2 C<req_time>

Returns the time taken to process the request in milliseconds:

  my $req_time = $worker_score->req_time;

This feature was ported in Apache 2.0.53.




=head2 C<start_time>

In a list context this method returns a 2 element list with the seconds and
microseconds since the epoch, when the request was started.  In scalar
context it returns floating seconds like Time::HiRes::time()

  my($tv_sec, $tv_usec) = $worker_score->start_time;

  my $secs = $worker_score->start_time;

META: as of Apache 2.0.53 it's yet unavailable (needs to be ported)





=head2 C<status>

  $status = $worker_score->status();

This method returns the status of the given worker as a
dual-variable. In the string context it gives a single letter, which
can be mapped to the long description via the following list

  "_" Waiting for Connection
  "S" Starting up
  "R" Reading Request
  "W" Sending Reply
  "K" Keepalive (read)
  "D" DNS Lookup
  "C" Closing connection
  "L" Logging
  "G" Gracefully finishing
  "I" Idle cleanup of worker
  "." Open slot with no current process

In the numerical context it returns the numerical status (which
corresponds to a C define like SERVER_DEAD, SERVER_READY, etc) for
which we don't really have the use at the moment. You should use the
string context to get the status.



=head2 C<stop_time>

In a list context this method returns a 2 element list with the seconds and
microseconds since the epoch, when the request was finished.  In scalar
context it returns floating seconds like Time::HiRes::time()

  my($tv_sec, $tv_usec) = $worker_score->stop_time;

  my $secs = $worker_score->stop_time;

META: as of Apache 2.0.53 it's yet unavailable (needs to be ported)




=head2 C<thread_num>

XXX




=head2 C<tid>

XXX




=head2 C<times>

In a list context, returns a four-element list giving the user and
system times, in seconds, for this process and the children of this
process.

  my($user, $system, $cuser, $csystem) = $worker_score->times;

In a scalar context, returns the overall CPU percentage for this
worker:

  my $cpu = $worker_score->times;




=head2 C<vhost>

Returns the vhost string if there is one.

  my $vhost = $worker_score->vhost;










=head1 Outside of mod_perl Usage

C<Apache::DummyScoreboard> is used internally if the code is not
running under mod_perl. It has almost the same functionality with some
limitations. See the C<Apache::DummyScoreboard> manpage for more info.



=head1 SEE ALSO

Apache::VMonitor(3), GTop(3)

=head1 AUTHOR

Doug MacEachern

Stas Bekman

Malcolm J Harwood
