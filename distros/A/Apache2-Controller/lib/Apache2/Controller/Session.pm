package Apache2::Controller::Session;

=head1 NAME

Apache2::Controller::Session - Apache2::Controller with Apache::Session

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

Set your A2C session subclass as a C<PerlHeaderParserHandler>.

This example assumes use of L<Apache2::Controller::Session::Cookie>.

 # get configuration directives:
 PerlLoadModule Apache2::Controller::Directives

 # cookies will get path => /somewhere
 <Location /somewhere>
     SetHandler              modperl

     # see Apache2::Controller::Dispatch for dispatch subclass info
     PerlInitHandler         MyApp::Dispatch

     # see Apache2::Controller::DBI::Connector for database directives

     A2C_Session_Cookie_Opts name  myapp_sessid
     A2C_Session_Class         Apache::Session::MySQL
     A2C_Session_Secret        jfa803m8cma083ak803kjf9-32

     PerlHeaderParserHandler  Apache2::Controller::DBI::Connector  MyApp::Session
 </Location>

In controllers, tied session hash is C<< $r->pnotes->{a2c}{session} >>.

In this example above, you implement C<get_options()> 
in your session subclass to return the options hashref to
C<tie()> for L<Apache::Session::MySQL>.  

If you do not implement get_options(), it will try to create
directories to use Apache::Session::File
using C<< /tmp/a2c_sessions/<request hostname>/ >>
and C<< /var/lock/a2c_sessions/<request hostname> >>

=head1 DESCRIPTION

This is a module to make an L<Apache::Session> store available
to methods in your controllers.  It is not just a session id -
if you just need a tracking mechanism or a way to store data
in cookies, you should roll your own handler with L<Apache2::Cookie>.

Your session module uses an Apache2::Controller::Session tracker module 
as a base and you specify your L<Apache::Session> options either as
config variables or by implementing a method C<<getoptions()>>.

Instead of having a bunch of different options for all the different
L<Apache::Session> types, it's easier for me to make you provide
a method C<session_options()> in your subclass that will return a 
has of the appropriate options for your chosen session store.

=head2 CONFIG ALTERNATIVE 1: directives or PerlSetVar variables

If you do not implement a special C<getoptions()> method
or use settings other than these, these are the default:
 
 <Location /elsewhere>
     PerlHeaderParserHandler MyApp::ApacheSessionFile

     A2C_Session_Class    Apache::Session::File
     A2C_Session_Opts  Directory       /tmp/sessions 
     A2C_Session_Opts  LockDirectory   /var/lock/sessions
 </Location>

Until directives work and the kludgey PerlSetVar syntax goes away,
spaces are not allowed in the argument values.  Warning!  
The kludgey PerlSetVar syntax will go away when
directives work properly.

=head2 CONFIG ALTERNATIVE 2: C<< YourApp::YourSessionClass->get_options() >>

Implement C<get_options()> in your subclass to return the final options 
hashref for your L<Apache::Session> session type.

For example, if your app uses DBIx::Class, maybe you want to
go ahead and init your schema so you can get the database 
handle directly and pass that to your session class.

See
L<Apache2::Controller::DBI::Connector|Apache2::Controller::DBI::Connector>
for directives to set database connection in pnotes->{a2c}{dbh}.

Here's a code example for Location /somewhere above:

 package MyApp::Session;
 use strict;
 use warnings FATAL => 'all';

 use base qw( Apache2::Controller::Session::Cookie );

 use English '-no_match_vars';
 use Apache2::Controller::X;

 sub get_options {
     my ($self) = @_; 

     my $r = $self->{r};
     eval {
         $r->pnotes->{a2c}{dbh} ||= DBI->connect(
             'dbi:mysql:database=myapp;host=mydbhost';
             'myuser', 'mypassword'
         );
     };
     a2cx "cannot connect to DB: $EVAL_ERROR" if $EVAL_ERROR;
     
     my $dbh = $r->pnotes->{a2c}{dbh};    # save handle for later use
                                        # in controllers, etc.

     return {
         Handle      => $dbh,
         LockHandle  => $dbh,
     };
 }

If you do it this way or use Apache::DBI, 
be careful about transactions.  See L<DATABASE TRANSACTION SAFETY> below.

 # ...

In your controller module, access the session in C<< pnotes->{a2c}{session} >>.
 
 package MyApp::Controller::SomeWhere::Overtherainbow;
 use base qw( Apache2::Controller Apache2::Request );
 # ...
 sub default {
     my ($self) = @_;

     my $session = $self->pnotes->{a2c}{session};
     $session->{foo} = 'bar';

     # session will be saved by a PerlLogHandler
     # that was automatically pushed by Apache2::Controller::Session

     # and in my example

     return Apache2::Const::HTTP_OK;
 }

=head1 DATABASE TRANSACTION SAFETY 

When this handler runs, it ties the session into a special
hash that it keeps internally, and loads a copy into
C<< $r->pnotes->{a2c}{session} >>.  So, modifying the session hash
is fine, as long as you do not dereference it, or as long
as you save your changes back to C<< $r->pnotes->{a2c}{session} >>.

No changes are auto-committed.  The one in pnotes is
copied back into the tied session hash in a C<PerlLogHandler>,
after the server finishes output but I<before> it closes
the connection to the client.  If the connection is detected
to be aborted in the C<PerlLogHandler> phase, changes are NOT 
saved into the session object.

If you implemented C<get_options()> as per above and decided
to save your $dbh for later use in your controllers, feel free
to start transactions and use them normally.  Just make sure you
use L<perlfunc/eval> correctly and roll back or commit your
transactions. 

If you decide to push a C<PerlLogHandler> 
to roll back transactions for broken connections or something, 
or C<PerlCleanupHandler> to do something else (don't use
post-connection phases for database transactions or you'll get out of sync),
be aware
that this handler 'unshifts' a log handler closure that
saves the copy in pnotes back into the tied hash.
It does this by re-ordering the C<PerlLogHandler> stack with
L<Apache2::RequestUtil/get_handlers> and C<set_handlers()>.
So if you push another post-response handler that wants to
choose whether to save the session or not, be aware that
it may not work as you expect unless you re-order that
phase's handler stack again.

=head1 TO SAVE OR NOT TO SAVE

Generally in your code, it's complicated to decide whether everything
has worked before you save anything to the session.  It's easier just
to save stuff, and then if something goes wrong, it is as if this
rolls back.

A C<PerlLogHandler> subroutine is 'unshifted' to the request stack
which decides whether to save changes to the session.  By default,
it saves changes only if A) the connection is not aborted,
and B) your controller set HTTP status < 300,
i.e. it returned C<OK> (0), one of the C<HTTP_CONTINUE> family (100+)
or one of the C<HTTP_OK> family (200+).  

So for an C<HTTP_SERVER_ERROR>, or throwing an exception, redirecting,
forbidding access, etc (>= 300), it normally would not save changes.
If your L<Apache2::Controller> controller module returns one of these 
non-OK statuses, but you want to force the saving of the session contents, 
set C<< $self->pnotes->{a2c}{session_force_save} = 1 >> before
your response phase controller returns a status to L<Apache2::Controller>.

If the connection is aborted mid-way (i.e. the pipe was broken
due to a network failure or the user clicked 'stop'
in the browser), then the session will not be saved,
whether you set the force save flag or not.
(If this is not useful and correct behavior contact me and I
will add another switch, but it seems right to me.)

It actually re-orders the C<PerlLogHandler> stack so that
its handlers run first, before the handler pushed by 
L<Apache2::Controller::DBI::Connector> commits the database
transaction, for example.

This used to push a C<PerlCleanupHandler> to save the session,
which made sense at the time, but the OpenID auth tests revealed
that the Cleanup handler is apparently assigned a thread to
process it independently, even under prefork with C<Apache::Test>.
So, the test script was firing off a new request 
before the old request Cleanup handler ran to save the session,
which resulted in sporadic and inconsistent failures... 
yeah, THOSE kind, you know the type, the most maddening ones.

Apache::Session does not always save automatically, for
example if you change something in the bottom tier of
a multi-level hash.  If you want to, set the directive flag
C<A2C_Session_Always_Save> and this will set a top-level
timestamp C<< $r->pnotes->{a2c}{session}{a2c_timestamp} >> 
on the way out to trigger L<Apache::Session> to save everything.
But if you are potentially accessing the session contents without
setting it every time, you should just set a top-level timestamp
manually to indicate to L<Apache::Session> that you want 
things saved at the end of every request, but this may
slow you down on a busy site, so it is not the default.
See L<Apache2::Controller::Directives/A2C_Session_Always_Save>
and L<Apache::Session/BEHAVIOR>.

=head1 IMPLEMENTING TRACKER SUBCLASSES

See L<Apache2::Controller::Session::Cookie> for how to implement
a custom tracker subclass.  This implements C<$sid = get_session_id()> 
which gets a session id from a cookie, and C<set_session_id($sid)> 
which sets the session id in the cookie.

Perhaps some custom tracker subclass would implement
C<get_session_id()> to get the session_id out of the request 
query params, and C<set_session_id()> would push a C<PerlOutputFilterHandler>
to post-process all other handler output and append the session id param
onto any url links that refer to our site.  That would be cool...
release your own plug-in.
If you wanted to do it with combined cookies and url params in 
this way you could 
overload C<get_session_id()> and C<set_session_id()>, etc. etc.

=head1 ERRORS

C<<Apache2::Controller::Session>> will throw an error exception if the
session setup encounters an error.  

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller::NonResponseBase 
    Apache2::Controller::Methods 
);

use YAML::Syck;
use Log::Log4perl qw(:easy);
use File::Spec;
use Digest::SHA qw( sha224_base64 );

use Apache2::Const -compile => qw( OK );
use Apache2::RequestUtil ();
use Apache2::Controller::X;
use Apache2::Controller::Const qw( $DEFAULT_SESSION_SECRET );

=head2 process

The C<process()> method
attaches or creates a session, and pushes a PerlLogHandler
closure to save the session after the end of the request.

It sets the session id cookie
with an expiration that you set in your subclass as C<our $expiration = ...>
in a format that is passed to Apache2::Cookie.  (i.e. '3M', '2D', etc.)
Don't set that if you want them to expire at the end of the
browser session.

=cut

my %used;   # i feel used!

sub process {
    my ($self) = @_;
    my $r = $self->{r};

    my $session_id = $self->get_session_id();
    DEBUG "processing session: ".($session_id ? $session_id : '[new session]');

    my $directives = $self->get_directives();
    my $class = $directives->{A2C_Session_Class} || 'Apache::Session::File';
    DEBUG "using session class $class";

    do { 
        eval "use $class;"; 
        a2cx $EVAL_ERROR if $EVAL_ERROR;
        $used{$class} = 1;
    } if !exists $used{$class};

    my $options = $self->get_options(); 
    DEBUG sub{"Creating session with options:\n".Dump($options)};

    my %tied_session = ();
    my $tieobj = undef;
    ($session_id, $tieobj) = $self->tie_session(
        \%tied_session,
        $class,
        $session_id,
        $options,
    );

    # set the session id in the tracker, however that works
    $session_id ||= $tied_session{_session_id};
    DEBUG "session_id is '$session_id'";

    # put the session id value in pnotes
    $r->pnotes->{a2c}{session_id} = $session_id; 

    $self->set_session_id($session_id);

    my %session_copy = (%tied_session);
    $r->pnotes->{a2c}{session} = \%session_copy;
    $r->pnotes->{a2c}{_tied_session} = \%tied_session;

    DEBUG "ref of real tied_session is '".\%tied_session."'";

    # set state detection handler as the first handler in
    # the last phase that connection is open
    
    my @log_handlers = qw(
        Apache2::Controller::Log::DetectAbortedConnection
        Apache2::Controller::Log::SessionSave
    );

    # we reset the whole PerlLogHandler stack to make sure session
    # gets saved before the database commit happens... lame!
    push @log_handlers, 
        grep defined, 
        @{ $r->get_handlers('PerlLogHandler') || [] };

    DEBUG sub {"reordering the PerlLogHandler stack:\n".Dump(\@log_handlers)};
    $r->set_handlers(PerlLogHandler => \@log_handlers);

    DEBUG "returning OK";
    return Apache2::Const::OK;
}

=head2 tie_session

Separate tying the session so it can be called again to set a new cookie
if the existing cookie is not found in the data store.  Is this a good
idea?  Not sure.  Does it expose to being able to create infinite sessions?
Somehow a non-existent session has to be able to be cleared.  This issue
cropped up when I put a `find -atime` in cron to clear out old session
files when using Apache::Session::File in /dev/shm.  (Or when rebooting.)
We can't ask the user to clear their cookies every time this happens.
So, if tying fails saying "Object does not exist in the data store" 
then it tries again with an undefined session id.  Returns session id.

=cut

sub tie_session {
    my ($self, $tied_session, $class, $session_id, $options, $recursion) = @_;
    $recursion ||= 0;
    $recursion++;
    a2cx "Recursion limit exceeded" if $recursion > 5;

    my $tieobj = undef;

    eval {
        tie %{$tied_session}, $class, $session_id, $options;
        DEBUG 'Finished tie.';
        $tieobj = tied(%{$tied_session});
        DEBUG sub {
            'Session is '.($tieobj ? 'tied' : 'not tied').", contents:"
            .Dump($tied_session);
        };
    };
    if (my $err = $EVAL_ERROR) {
        if ($err =~ /Object does not exist in the data store/) {
            ($session_id, $tieobj) = $self->tie_session(
                $tied_session,
                $class,
                undef,
                $options,
            );
        }
        else {
            a2cx $err;
        }
    }

    a2cx "no session_id" if !$tied_session->{_session_id};
    a2cx "no tied obj"   if !defined $tieobj;
    a2cx "session_id mismatch" 
        if defined $session_id && $session_id ne $tied_session->{_session_id};

    return ($session_id, $tieobj);
}

=head2 signature

 my $signature_string = $self->signature($session_id);

Return the string which is the signature of the session id
plus the secret.

Override this in a subclass if you want to use something other
than SHA224.  See L<Digest::SHA/sha224_base64>.

The secret is the value associated with the directive A2C_Session_Secret,
or the default if that directive was not used.

See L<Apache2::Controller::Session::Cookie>,
L<Apache2::Controller::Directives/A2C_Session_Secret>,
L<Apache2::Controller::Const/$DEFAULT_SESSION_SECRET>.

=cut

sub signature {
    my ($self, $sid) = @_;
    a2cx "no sid param" if !defined $sid;

    my $secret = $self->{secret} 
        ||= $self->get_directive('A2C_Session_Secret') 
        || $DEFAULT_SESSION_SECRET;

    my $sig = sha224_base64( $sid . $secret );
    DEBUG sub { Dump({
        sid     => $sid,
        secret  => $secret,
        sig     => $sig,
    })};
    return sha224_base64( $sid . $secret );
}

=head2 get_options

If you do not configure C<<A2C_Session_Opts>> or override the subroutine,
the default C<get_options> method assumes default Apache2::Session::File.

Default settings try to create C<</tmp/A2C/$hostname/sess>>
and C<</tmp/A2C/$hostname/lock>>. (uses C<<File::Spec->tmpdir>>,
so it should work on Windoze?).

If you want to do something differently, use your
own settings or overload C<get_options()>.

=cut

my %created_temp_dirs;

sub get_options {
    my ($self) = @_;

    my $opts = $self->get_directive('A2C_Session_Opts');
    
    if (!$opts) {
        my $hostname = $self->{r}->hostname();
        my $tmp = File::Spec->tmpdir();
        my $dir = File::Spec->catfile($tmp, 'A2C', $hostname);
        my $sess = File::Spec->catfile($dir, 'sess');
        my $lock = File::Spec->catfile($dir, 'lock');

        if (!exists $created_temp_dirs{$hostname}) {
            do { mkdir $_ || a2cx "Cannot create $_: $OS_ERROR" }
                for grep !-d, $dir, $sess, $lock;
            $created_temp_dirs{$hostname} = 1;
        }

        $opts = {
            Directory       => $sess,
            LockDirectory   => $lock,
        };
    }

    DEBUG "returning session opts:\n".Dump($opts);
    return $opts;
}

=head1 DIRECTIVES

Apache2 configuration directives.  L<Apache2::Controller::Directives>

=over 4

=item A2C_Session_Class

=item A2C_Session_Opts

=back

=head1 SEE ALSO

L<Apache2::Controller::Session::Cookie>

L<Apache2::Controller::Dispatch>

L<Apache2::Controller>

L<Apache::Session>

=head1 THANKS

Thanks to David Ihern for edumacating me about the
proper session cookie signature algorithm.

=head1 AUTHOR

Mark Hedges, C<< <hedges at formdata.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut


1;
