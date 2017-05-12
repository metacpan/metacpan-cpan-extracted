#
# Courier::Filter
# A purely Perl-based filter framework for the Courier MTA.
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Filter.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter - Purely Perl-based mail filter framework for the Courier MTA

=cut

package Courier::Filter;

=head1 VERSION

0.200

=cut

use version; our $VERSION = qv('0.200');

use warnings;
use strict;
#use threads;
#BEGIN { require threads if ... }

use Error ':try';

use IO::Handle;
use IO::Socket::UNIX;
use IO::Select;

use Courier::Config;
use Courier::Message;
use Courier::Error;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

    use Courier::Filter;
    use Courier::Filter::Logger::Moo;
    use Courier::Filter::Module::Foo;
    use Courier::Filter::Module::Bar;

    my $filter = Courier::Filter->new(
        mandatory   => 1,
        logger      => Courier::Filter::Logger::Moo->new( ... ),
        modules     => [
            Courier::Filter::Module::Foo->new( ... ),
            Courier::Filter::Module::Bar->new( ... )
        ],
        testing     => 0,
        debugging   => 0
    );
    
    my $exit_code = $filter->run() || 0;

    exit($exit_code);

=head1 DESCRIPTION

B<For an architectural and administrative overview of the B<Courier::Filter>
framework, see L<Courier::Filter::Overview>.>

The B<Courier::Filter> class is the heart of the Courier::Filter framework.  To
drive a B<courierfilter> filter process, create a B<Courier::Filter> object,
passing the filter modules and loggers you want to use to the constructor, and
call the C<run()> method.

Courier::Filter will then take care of creating the courierfilter socket in the
right place in a safe manner, listening for connections from Courier, asking
filter modules for consideration of messages, notifying Courier of whether
messages should be accepted or rejected, logging message rejections, catching
and logging errors, and finally removing the socket when being terminated by
Courier.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter>; throws I<Courier::Error>,
Perl exceptions

Creates a new C<Courier::Filter> object.  Also creates the courierfilter socket
in the right place in a safe manner.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<name>

The name of the filter process.  Used to build the socket name.  Defaults to
the base name of the process (C<$0>).

=item B<mandatory>

A boolean value controlling whether the filter process should act as a
mandatory courierfilter.  If B<true>, users will not be able to bypass the
filter modules in this filter process from their individual B<localmailfilter>
filters.  Technically, this controls whether the courierfilter socket will be
created in the C<allfilters> (B<true>) or the C<filters> (B<false>) directory
in Courier's run-time state directory (see L<Courier::Config/"runtime_dir">).
Defaults to B<true>.

=begin comment

=item B<threads>

The number of worker threads that should be employed for considering messages.
If B<undef> or B<0>, no multi-threading will be used and everything (socket
connection handling, message consideration, and logging) will be done in a
single thread.  The unthreaded mode is is the most memory-conserving mode and
is generally the best choice for single-processor systems.  Otherwise, i.e. if
set to B<a positive number>, a pool of an according number of worker threads
will be employed for considering messages.  The worker threads are created
during the startup of Courier::Filter and process messages that are dispatched
to them by the main thread.  Logging is also done in a single separate thread.
The multi-threaded mode requires a certain amount of memory for each thread but
is a viable way to distribute work on multi-processor systems.  No more than
two threads per processor are recommended.  Defaults to B<undef>.

=end comment

=item B<logger>

A B<Courier::Filter::Logger> object that will be used for logging message
rejections and error messages.  You may override this for individual filter
modules for which you do not want the global logger to be used.  If no logger
is specified, logging is disabled.

=item B<modules>

I<Required>.  A so-called B<filter module group> structure.  A module group is
a reference to an array that may contain filter module objects (i.e. instances
of sub-classes of B<Courier::Filter::Module>), as well as other module groups.
Thus, a module group is essentially a tree structure with filter modules as its
leaves.  When considering messages, Courier::Filter walks the tree in a
recursive-descent, depth-first order, asking every filter module for
consideration of the message's acceptability.

For instance, given the following filter module group:

    [$m1, $m2, [$m3, [$m4, $m5]], $m6]

Courier::Filter queries the filter modules in ascending order from 1 to 6.

The acceptability result returned by each module determines how Courier::Filter
proceeds with considering the current message:

=over

=item *

If a module states an B<explicit reject>, Courier::Filter aborts the
consideration process and rejects the message.

=item *

If a module states an B<implicit accept>, Courier::Filter just proceeds to the
next module in turn.

=item *

If a module states an B<explicit accept>, Courier::Filter skips the rest of the
current module group and proceeds to the next item in the superordinate module
group, assuming the whole group to be an implicit accept.

=back

For instance, take the nested filter module group from above:

    [$m1, $m2, [$m3, [$m4, $m5]], $m6]
    |          |     '---g3---'|     |
    |          '----group 2----'     |
    '------------group 1-------------'

Let's assume Courier::Filter queries the filter module $m3.  If $m3 states an
B<explicit reject>, the consideration process is aborted and the current
message is rejected.  If $m3 states an B<implicit accept>, Courier::Filter
proceeds to $m4.  If $m3 states an B<explicit accept>, the rest of group 2
(including all of group 3) is skipped and the acceptability result of group 2
is assumed an implicit accept, so Courier::Filter proceeds to $m6.

If no B<explicit reject> has occured when Courier::Filter reaches the end of
the main module group, or a module in the main group states an B<explicit
accept>, the message is accepted.

Using nested groups of filter modules with normal or inverse polarity, it
should be possible to implement sufficiently complex filtering policies to
satisfy very most needs.

=item B<trusting>

A boolean value controlling whether the I<whole> filter process should I<not>
apply any filtering to trusted messages.  For details on how the trusted status
is determined, see the description of the C<trusted> property in
Courier::Message.  In most MTA configurations, this option can be used to
white-list so-called outbound messages.  Defaults to B<false>.

=item B<testing>

A boolean value controlling whether the I<whole> filter process should run in
"testing" mode.  In testing mode, planned message rejections will be logged as
usual, but no messages will actually be rejected.  Defaults to B<false>.

NOTE:  You may also enable testing mode on individual filter module objects,
see L<Courier::Filter::Module/"new">.  Enabling testing mode globally is not
the same as individually enabling testing mode on all filter modules, though.
When global testing mode is enabled, Courier::Filter only ignores the I<final>
result, but still follows the rules of the normal consideration process, e.g.
aborting as soon as a filter module states an B<explicit reject>, etc.  When an
individual filter module is in testing mode, its I<individual> result is
ignored, and the consideration process is continued with the next filter
module.  So individually enabling testing mode on all filter modules allows you
to thoroughly test the correctness and performance of all installed filter
modules, or even to gather stochastically indepent statistics on the hit/miss
rates of your filter modules.

=item B<debugging>

A boolean value controlling whether extra debugging information should be
logged by Courier::Filter.  Defaults to B<false>.  You need to enable debugging
mode for filter modules separately.

=for comment
TODO: Filter modules' debugging mode should really default to Courier::Filter's
global debugging mode.

=back

=cut

sub new {
    my ($class, %options) = @_;
    
    $0 =~ m{([^/]+)$};
    my $name        = $options{name} || $1;
    my $mandatory   = defined($options{mandatory}) ? $options{mandatory} : TRUE;
    my $threads     = $options{threads};
    my $logger      = $options{logger};
    my $modules     = [ @{$options{modules}} ] || [];
    my $trusting    = $options{trusting};
    my $testing     = $options{testing};
    my $debugging   = $options{debugging};
    
    my $socket_dir =
        Courier::Config->runtime_dir . '/' .
        ( $mandatory ? 'allfilters' : 'filters' );
    my $socket_dir_unused =
        Courier::Config->runtime_dir . '/' .
        ( !$mandatory ? 'allfilters' : 'filters' );
    
    my $socket_prename          = "$socket_dir/.$name";
    my $socket_name             = "$socket_dir/$name";
    my $socket_prename_unused   = "$socket_dir_unused/.$name";
    my $socket_name_unused      = "$socket_dir_unused/$name";
    
    if (-e $socket_name) {
        -S $socket_name
            or throw Courier::Error("$socket_name already exists but is not a socket");
        
        # Try to connect to socket to see if it is alive or
        # if it is left over from a crashed Courier::Filter:
        my $test_socket = IO::Socket::UNIX->new( Peer => $socket_name );
        
        not defined($test_socket)
            or throw Courier::Error("Live socket $socket_name found -- is Courier::Filter already running?");
        
        # Socket exists but is dead. Remove it:
        unlink($socket_name);
    }
    
    unlink($socket_prename);
    unlink($socket_prename_unused);
    unlink($socket_name_unused);
    
    my $socket = IO::Socket::UNIX->new(
        Local   => $socket_prename,
        Listen  => SOMAXCONN
    )
        or  throw Courier::Error("Unable to create socket $socket_prename");
    
    rename($socket_prename, $socket_name)
        or  unlink($socket_prename),
            throw Courier::Error("Unable to rename socket $socket_prename to $socket_name");
    
    chmod(0660, $socket_name)
        or  throw Courier::Error("Unable to chmod socket $socket_name");
    
    IO::Handle->new_from_fd(3, '>')->close();
    
    my $filter = {
        name        => $name,
        mandatory   => $mandatory,
        threads     => $threads,
        logger      => $logger,
        modules     => $modules,
        trusting    => $trusting,
        testing     => $testing,
        debugging   => $debugging,
        socket      => $socket,
        socket_name => $socket_name,
        terminate   => FALSE
    };
    
    return bless($filter, $class);
}

=back

=begin comment

=head2 Destructor

The following destructor is provided:

=over

=item B<destroy>

Removes the courierfilter socket when the B<Courier::Filter> object is
destroyed.  There is no need to call this explicitly.

=end comment

=cut

sub destroy {
    my ($filter) = @_;
    
    return if not $filter->{terminate};
    
    $filter->{'socket'}->close();
    unlink($filter->{socket_name});
    
    # Dissolve worker thread pool:
#    foreach my $thread (threads->list) {
#        $thread->join()
#            if $thread->tid and $thread != threads->self;
#    }
    
    return;
}

=begin comment

=back

=end comment

=head2 Instance methods

The following instance methods are provided:

=over

=item B<run>: throws I<Courier::Error>, Perl exceptions

Runs the Courier::Filter.  Listens for connections from Courier on the
courierfilter socket, asks the configured filter modules for consideration of
messages, notifies Courier of whether messages should be accepted or rejected,
and logs message rejections.  When Courier requests termination of the
courierfilter, removes the socket and returns.

=cut

sub run {
    my ($filter) = @_;
    my $class = ref($filter);
    
    my $socket = $filter->{'socket'};
    my $select = IO::Select->new(\*STDIN, $socket);
    
    while (not $filter->{terminate}) {
        
        # Wait for incoming connection requests
        # or EOF from STDIN:
        ########################################
        
        my @ready_handles = $select->can_read();
        
        foreach my $handle (@ready_handles) {
            if ($handle == $socket) {
                # Incoming connection request.
                $filter->handle_connection($socket);
#                threads->new(\&handle_connection, $filter, $socket)->detach();
            }
            elsif ($handle == \*STDIN and STDIN->eof()) {
                # STDIN got closed.
                $filter->{terminate} = TRUE;
            }
            else {
                # Received data from unknown handle or from STDIN.
                # This shouldn't happen.
                throw Courier::Error("Received data from unknown handle or from STDIN");
            }
        }
    }
    
    return;
}

=begin comment

=item B<handle_connection($socket)>: returns I<string>, I<string>; throws Perl
exceptions

Handles a single incoming connection to the courierfilter socket.  Reads the
message file name and zero or more control file names from the connection.
Asks filter modules for consideration of the message's acceptability, and
notifies Courier of whether the message should be accepted or rejected.  Also
returns the SMTP status response I<text> and I<code> given to Courier.

=end comment

=cut

sub handle_connection {
    my ($filter, $socket) = @_;
    my $class = ref($filter);
    
    my $connection = $socket->accept();
    
    my $message_file_name;
    my @control_file_names;
    
    while (my $file_name = <$connection>) {
        chomp($file_name);
        last unless $file_name;
        
        # Normalize file name:
        $file_name =
            Courier::Config->runtime_dir . '/tmp/' . $file_name
            if $file_name !~ m(^/);
        
        if (not defined($message_file_name)) {
            $message_file_name = $file_name;
        }
        else {
            push(@control_file_names, $file_name);
        }
    }
    
    return
        if not defined($message_file_name);
    
    my $message = Courier::Message->new(
        file_name           => $message_file_name,
        control_file_names  => \@control_file_names,
        filter              => $filter
    );
    
    my ($result, $code);
    
    # BEGIN XXX
    #STDERR->print(
    #    "DEBUG: authenticated_user = '" .
    #    ($message->authenticated_user || '(undef)') .
    #    "'\n"
    #);
    # END XXX
    
    ($result, $code) = $filter->consult_modules($filter->modules, $message)
        if $filter->testing
        or not ($filter->trusting and $message->trusted);
    
    ($result, $code) = (undef, undef)
        if $filter->testing
        or ($filter->trusting and $message->trusted);
    
    if ($result) {
        $code ||= 550;
    }
    else {
        $result = 'Ok';
        $code ||= 200;
    }
    
    my @lines = split(/\n/, $result);
    my $last_line = pop(@lines);
    $connection->print("$code-$_\n") foreach @lines;
    $connection->print("$code $last_line\n");
    
    $connection->close();
    
    return ($result, $code);
}

=begin comment

=item B<consult_modules>: returns I<string>, I<string>

Walks the given modules group structure in a recursive-descent, depth-first
order, and asks every filter module for consideration of the given message's
acceptability.  Returns the group's acceptability result.

=end comment

=cut

sub consult_modules {
    my ($filter, $modules, $message) = @_;
    
    ref($modules) eq 'ARRAY'
        or throw Courier::Error('Invalid modules group structure, array-ref expected');

    foreach my $module (@$modules) {
        my ($result, @code);
        
        if (UNIVERSAL::isa($module, 'Courier::Filter::Module')) {
            # Single module, make it consider the message:
            
            next if $module->trusting and $message->trusted;
                # ...except when the module trusts the message.
            
            my $logger = $module->logger || $filter->logger;

            ($result, @code) = eval { $module->consider($message) };
            if ($@) {
                $logger->log_error(ref($module) . ': ' . $@) if $logger;
                ($result, @code) = ('Mail filters temporarily unavailable.', 432);
            }
            
            # Log rejection:
            $logger->log_rejected_message($message, $result)
                if $result and $logger;

            # Ignore result if module is in testing mode:
            next if $module->testing;
        }
        else {
            # Something else, try to interpret it as a modules group:
            ($result, @code) = $filter->consult_modules($module, $message);
        }
        
        return $result ? ($result, @code) : undef
            if defined($result);
    }

    return undef;
}

=item B<name>: returns I<string>

Returns the name of the filter process, as set through the constructor's
C<name> option.

=cut

sub name {
    my ($filter) = @_;
    # Read-only!
    return $filter->{name};
}

=item B<mandatory>: returns I<boolean>

Returns a boolean value indicating whether the filter process is a mandatory
courierfilter, as set through the constructor's C<mandatory> option.

=cut

sub mandatory {
    my ($filter) = @_;
    # Read-only!
    return $filter->{mandatory};
}

=begin comment

=item B<threads>: returns I<integer>

Returns the number of filter threads, as set through the constructor's
C<threads> option.

=end comment

=cut

sub threads {
    my ($filter) = @_;
    # Read-only!
    return $filter->{threads};
}

=item B<logger>: returns I<Courier::Filter::Logger>

=item B<logger($logger)>: returns I<Courier::Filter::Logger>

If C<$logger> is specified, installs a new global logger.  Returns the (newly)
configured global logger.

=cut

sub logger {
    my ($filter, @logger) = @_;
    $filter->{logger} = $logger[0]
        if @logger;
    return $filter->{logger};
}

=item B<modules>: returns I<array-ref>

=item B<modules(\@modules)>: returns I<array-ref>

If C<\@modules> is specified, installs a new filter module group structure.
Returns the (newly) configured filter modules group structure.

=cut

sub modules {
    my ($filter, @modules) = @_;
    $filter->{modules} = $modules[0]
        if @modules;
    return $filter->{modules};
}

=item B<trusting>: returns I<boolean>

Returns a boolean value indicating the trusting mode, as set through the
constructor's C<trusting> option.

=cut

sub trusting {
    my ($filter) = @_;
    # Read-only!
    return $filter->{trusting};
}

=item B<testing>: returns I<boolean>

Returns a boolean value indicating the global testing mode, as set through the
constructor's C<testing> option.

=cut

sub testing {
    my ($filter) = @_;
    # Read-only!
    return $filter->{testing};
}

=item B<debugging>: returns I<boolean>

=item B<debugging($debugging)>: returns I<boolean>

If C<$debugging> is specified, sets the global debugging mode.  Returns a
boolean value indicating the (newly) configured global debugging mode.

=cut

sub debugging {
    my ($filter, @debugging) = @_;
    $filter->{debugging} = $debugging[0]
        if @debugging;
    return $filter->{debugging};
}

=back

=cut

BEGIN {
    no warnings 'once';
    *DESTROY = \&destroy;
}

=head1 SEE ALSO

L<courier-filter-perl>, L<Courier::Filter::Overview>,
L<Courier::Filter::Module>, L<Courier::Filter::Logger>

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 REFERENCES

=over

=item The B<courierfilter> interface

L<http://www.courier-mta.org/courierfilter.html>

=back

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
