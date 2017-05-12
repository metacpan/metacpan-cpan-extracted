# Storage Driver backend for memcached

package CGI::Session::Driver::memcache;
use strict;

#use Carp;

use CGI::Session::Driver;

our $sess_space = "sessions";
our $memd_connerror = "Need a connection handle to live memcached\n";
our @ISA        = ('CGI::Session::Driver');
our $VERSION    = '0.10';
our $trace = 0;
BEGIN {
    # keep historical behavior
    no strict 'refs';
    # WHY would we want unbuffered output ? Having this can mess up mod_perl runtime.
    # 
    #$| = 1;
    # Introspect %INC to see if CGI::Session::Driver::memcache has been
    # loaded from expected install-location (Patch %INC if necessary)
    #if (!$INC{'CGI/Session/Driver/memcache.pm'}) {...}
}
#sub new {}

# Developer info:
# - CGI::Session::new (as class / constructor method, forwards args to load)
#  - CGI::Session::load() (Create self-stub, parse_dsn(), _load_pluggables())


# CGI::Session::Driver init method to be called 
# merely validate a connection to memcached exists
sub init {
    my $self = shift;
    #DEBUG:print CGI::header('text/plain');
    #DEBUG:require Data::Dumper;print(Dumper($self));
    # Require Handle to memcached connection
    my $memd  = $self->{'Handle'} || die($memd_connerror);
    if ($trace) {
       #die("Vary: Using Connection: $memd\n");
    }
    # Must add ?
    # Problem: Because of shallow copy does not persist
    #$self->{'_DSN'}->{'driver'} = 'memcache';
    # TODO: Optionally grab a connection to memcached
    # Cache::memcache->new('servers' => [$self->{'servers'}]);
    # Success (see Driver.pm)
    #$self->{'_STATUS'} = 55;
    return 1;
}
# Combine Session space and ID for truly unique ID
# TODO: Add self to have session instance specific $sess_space
sub _useid {
   if ($trace) {
      require Data::Dumper;
      my @ci = caller(1);
      #print(Data::Dumper::Dumper(\@ci));
      print("$ci[3] : useid: $sess_space:$_[0]\n");}
   # Allow instace specific ID-space prefix ???
   # my $use_space = $_[1] && $_[1]->{'space'} ? $_[1]->{'space'} : $sess_space;
   "$sess_space:$_[0]";
}

# Retrieve Session (will be passed to deserializer)
sub retrieve {
    my ($self, $sid) = @_;
    my $memd = $self->{'Handle'};
    if ($trace) {print("retrieve: Using $memd\n");}
    if (!$memd) {die($memd_connerror);}
    # Return Session to be de-serialized
    my $r = $memd->get(_useid($sid));
    if (!$r) {return(0);}
    return $r;
}

# Store serialized session
sub store {
   my ($self, $sid, $datastr) = @_;
   my $memd = $self->{'Handle'};
   if (!$memd) {die($memd_connerror);}
   my $ok = $memd->set(_useid($sid),  $datastr);
   #if (!$ok) {$self->set_error( "store(): \$dbh->do failed " . $dbh->errstr );}
   return $ok ? 1 : 0;
}

# Remove Session
sub remove {
   my ($self, $sid) = @_;
   my $memd = $self->{'Handle'};
   if (!$memd) {die($memd_connerror);}
   $memd->delete(_useid($sid));
   return 1;
}

# execute $coderef for each session id passing session id as the first and the only
# argument
sub traverse {
   my ($self, $coderef) = @_;
   die("Traversing unsupported for memcached (for obvious security reasons)");
}
sub DESTROY {}
1;
__END__

=head1 NAME

CGI::Session::Driver::memcache - Store CGI::Session objects in memcache daemon

=head1 SYNOPSIS

  my $memd = new Cache::Memcached({
    servers => ['localhost:11211'],
  });
  if (!$memd) {die("No Connection to Memcached !");}

  my $cgi = CGI->new();
  my $sess = CGI::Session->new("driver:memcache", $cgi, {'Handle' => $memd});

  # Get and Set the standard CGI::Session way
  # Get
  my $v = $sess->param('greet_en');
  # Set
  $sess->param('greet_en', "Hi !");

=head1 DESCRIPTION

CGI::Session::Driver::memcache is a storage driver (only referred as 'driver' in
CGI::Session lingo) for persisting CGI Sessions into a fast memcached server.

It requires you to instantiate memcached connection using any
of the available Perl memcache client libraries and pass it to CGI::Session constructor
along with "DSN" "driver:memcache" (see SYNOPSIS).

You do not need to learn any of CGI::Session::Driver::memcache, but only use
it as a driver. All your learning efforts should go to CGI::Session (see also
CGI::Session::Tutorial). Only learning related to this driver is how to create
a connection (see $memd above) using one of the Perl Memcached client modules and
passing it to CGI::Session constructor.

=head1 METHODS

Not applicable to CGI::Session API user. CGI::Session::Driver::memcache implements
methods required by CGI::Session::Driver (interface).
Note that CGI::Session::Driver method 'traverse' (accessible via CGI::Session->find())
is not supported currently (partially because Perl APIs do not support iterating the keys of cache).

=head1 Why CGI::Session::Driver::memcache ?

While it is possible to use memcache client directly to store sessions into
memcache server, the CGI::Session provides a nice modular abstraction with
a lot  of thought put into it.
Developing session management directly against memcached makes setting up a memcache server a hard
dependency for the app.
By using CGI::Session in between the app and session storage backend it is easy to "right-size"
storage backend according to requirements of current project.

=cut

#CGI::Session modularity also allows your application to be configured with the wealth of storage
#backends (ASCII file, DBM, DBI, ..) and serialization methods to be used
#(for example flat files in absence of database or memcache servers).

=head1 Setting up Memcached Server

See F<README> in the package for short tutorials on setting up the memcached
server and testing the installation from command line.

=head1 BUGS

This driver requires Memcached connection handle to be passed to CGI::Session constructor as "raw" connection handle ({'Handle' => $memd}), making
caller responsible for passing a valid connection. This is actually good for relieving CGI::Session from the intricacies of suppporting various Memcached client
modules with differences in constructions (the rest of the main API on these module is generally very similar).

This driver and CGI::Session underpinnings do very little to ensure the server is actually alive.
The situation is even worse for Memcached client modules that return valid client instance
without server running (This is very different from lot of other DB Modules like DBI/DBD* or Net::LDAP,
where any problems with server raises exceptions or returns undefined handles).
Make sure your server is alive by either Calling stats() on Memcached client:

   my $stats = $memd->stats(); # Allows: [$keys]
   if (ref($stats) || !$stats->{'total'}) {die("No stats from Memcached - Memcached not running ?");}

... or by doing a set/get test sequence:

   my $testval = "it_is_".time();
   my $ok = $memd->set("whatstime", $testval);
   if (!$ok) {die("Setting k-v in memcached failed - Memcached not running ?");}
   # Optional get to double verify reading back
   my $itis_t = $memd->get("whatstime") || '';
   if (!$itis_t) {die("Value stored to Memcached earlier could not be read back !");}

=head1 SEE ALSO

L<CGI::Session>, L<CGI::Session::Tutorial>, L<Cache::Memcached::libmemcached>
for excellent list of Perl memcache client APIs (links to the module can be
found there).

See memcached website (L<http://memcached.org/>) for more information on
memcache deamon.

=head1 CREDITS

Creators of CGI::Session for a great modular web session API.

=head1 AUTHOR and COPYRIGHT

Copyright (c) 2010-2013 Olli Hollmen <olli.hollmen@gmail.com>. All rights reserved.
This library is free software. You can modify and or distribute it under the
same terms as Perl itself.
