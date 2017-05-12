package Apache::Backend::POE;
use strict;

BEGIN { eval { require Apache } }
use Apache::Backend::POE::Connection;
use Carp qw(carp);

our $VERSION = '0.02';

# a lot of code used from Apache::DBI...

# 1: report about new connect
# 2: full debug output
$Apache::Backend::POE::DEBUG = 0;

my %Connected;    # cache for objects
my @ChildConnect; # connections to be established when a new httpd child is created
my %Rollback;     # keeps track of pushed PerlCleanupHandler which can do a rollback after the request has finished
my %PingTimeOut;  # stores the timeout values per data_source, a negative value de-activates ping, default = 0
my %LastPingTime; # keeps track of last ping per data_source
my $Idx;          # key of %Connected and %Rollback.


# supposed to be called in a startup script.
# stores the data_source of all connections, which are supposed to be created upon
# server startup, and creates a PerlChildInitHandler, which initiates the connections.

sub connect_on_init { 
    # provide a handler which creates all connections during server startup

    # TODO - Should check for mod_perl 2 and do the right thing there
    carp "Apache.pm was not loaded\n" and return unless $INC{'Apache.pm'};
	# push the init handler ONCE
    if(!@ChildConnect and Apache->can('push_handlers')) {
        Apache->push_handlers(PerlChildInitHandler => \&childinit);
    }
    # store connections
    push @ChildConnect, [@_];
}


# supposed to be called in a startup script.
# stores the timeout per data_source for the ping function.
# use a DSN without attribute settings specified within !

sub setPingTimeOut { 
    my $class = shift;
    my $timeout = shift || 0;
    my $alias = shift || 'backend';
    # sanity check
    if ($timeout =~ /\-*\d+/) {
        $PingTimeOut{"poe:$alias"} = $timeout;
    }
}

# the connect method called from POE::connect

sub connect {
	my $poe = shift;
    
	my $prefix = "$$ Apache::Backend::POE            ";
	print STDERR "$prefix ref: ".ref($poe)." in connect\n" if $Apache::Backend::POE::DEBUG > 1;

    my @args = map { defined $_ ? $_ : "" } @_;
	$Idx = join(',',@args);
	my %opts = @args;
	
	# defaults
	$opts{alias} ||= 'backend';
	
    my $dsn = "poe:$opts{alias}";
	
	print STDERR "$prefix dsn: $dsn  args:".join(',',@args)."\n" if $Apache::Backend::POE::DEBUG;


    # don't cache connections created during server initialization; they
    # won't be useful after ChildInit, since multiple processes trying to
    # work over the same connection simultaneously will receive
    # unpredictable results.
    if ($Apache::ServerStarting and $Apache::ServerStarting == 1) {
        print STDERR "$prefix skipping connection during server startup, read the docs !!\n" if $Apache::Backend::POE::DEBUG > 1;
		return Apache::Backend::POE::Connection->new(@args)->connect($poe);
    }

 	# I plan to have transaction support

    # this PerlCleanupHandler is supposed to initiate a rollback after the script has finished if AutoCommit is off.
#    my $needCleanup = ($opts{AutoCommit}) ? 1 : 0;
    # TODO - Fix mod_perl 2.0 here
#    if(!$Rollback{$Idx} and !$needCleanup and Apache->can('push_handlers')) {
#        print STDERR "$prefix push PerlCleanupHandler\n" if $Apache::Backend::POE::DEBUG > 1;
#        Apache->push_handlers("PerlCleanupHandler", \&cleanup);
#        # make sure, that the rollback is called only once for every 
#        # request, even if the script calls connect more than once
#        $Rollback{$Idx} = 1;
#    }

    # do we need to ping the connection ?
    $PingTimeOut{$dsn}  = 0 unless $PingTimeOut{$dsn};
    $LastPingTime{$dsn} = 0 unless $LastPingTime{$dsn};
    my $now = time;
    my $needping = (($PingTimeOut{$dsn} == 0 or $PingTimeOut{$dsn} > 0)
		    and (($now - $LastPingTime{$dsn}) >= $PingTimeOut{$dsn})
		   ) ? 1 : 0;
#    print STDERR "$prefix need ping: ".($needping == 1 ? "yes" : "no")." \n" if $Apache::Backend::POE::DEBUG > 1;
    $LastPingTime{$dsn} = $now;

    # check first if there is already a object cached
    # if this is the case, possibly verify the object 
    # using the ping-method. Use eval for checking the connection 
    # handle in order to avoid problems (dying inside ping) when 
    # handle is invalid.
#	require Data::Dumper;
#	print STDERR Data::Dumper->Dump([\%Connected]);
	
    #if ($Connected{$Idx} and (!$needping or eval{$Connected{$Idx}->ping})) {
	$needping = 1;
	PING: {
		if ($Connected{$Idx}) {
			if ($needping) {
				print STDERR "$prefix going to ping\n" if $Apache::Backend::POE::DEBUG > 1;
				
				my $rt = eval{ $Connected{$Idx}->ping };
				
				print STDERR "$prefix ping rt: ----------- $rt\n" if $Apache::Backend::POE::DEBUG > 1;
				last PING unless ($rt == 1);
				if ($@) {
					print STDERR "$prefix ping error: $@\n" if $Apache::Backend::POE::DEBUG;
					last PING;
				}
			}
			print STDERR "$prefix using cached connection to '$Idx'\n" if $Apache::Backend::POE::DEBUG;
   			return (bless $Connected{$Idx}, 'Apache::Backend::POE::Conn');
	    }
	}

	
    # either there is no object cached or it is not valid,
    # so get a new object and store it in the cache
    delete $Connected{$Idx};
	$Connected{$Idx} = Apache::Backend::POE::Connection->new(@args)->connect($poe);
    return undef if !$Connected{$Idx};

    # return the new object
    print STDERR "$prefix new connect to '$Idx'\n" if $Apache::Backend::POE::DEBUG;
    return (bless $Connected{$Idx}, 'Apache::Backend::POE::Conn');
}


# The PerlChildInitHandler creates all connections during server startup.
# Note: this handler runs in every child server, but not in the main server.

sub childinit {
    my $prefix = "$$ Apache::Backend::POE            ";
    print STDERR "$prefix PerlChildInitHandler\n" if $Apache::Backend::POE::DEBUG > 1;
    if (@ChildConnect) {
        foreach my $aref (@ChildConnect) {
            my $class = shift @$aref;
            my $conn = Apache::Backend::POE::Connection->new(@$aref);
			
			my $idx = join(',',(map { defined $_ ? $_ : "" } @$aref));
			delete $Connected{$idx};
			$Connected{$idx} = $conn->connect($class);
				
			my %opts = @$aref;

			# defaults
			$opts{alias} ||= 'backend';

			my $dsn = "poe:$opts{alias}";
    		print STDERR "$prefix PerlChildInitHandler created new connection for $dsn\n" if $Apache::Backend::POE::DEBUG > 1;
			$LastPingTime{$dsn} = time;
        }
    }
    1;
}


# The PerlCleanupHandler is supposed to initiate a rollback after the script has finished if AutoCommit is off.
# Note: the PerlCleanupHandler runs after the response has been sent to the client
# TODO cleanup rollback code

sub cleanup {
    my $prefix = "$$ Apache::Backend::POE            ";
    print STDERR "$prefix PerlCleanupHandler\n" if $Apache::Backend::POE::DEBUG > 1;
    my $dbh = $Connected{$Idx};
    #if ($Rollback{$Idx} and $dbh and $dbh->{Active} and !$dbh->{AutoCommit} and eval {$dbh->rollback}) {
    #    print STDERR "$prefix PerlCleanupHandler rollback for $Idx\n" if $Apache::Backend::POE::DEBUG > 1;
    #}
    delete $Rollback{$Idx};
    1;
}


# This function can be called from other handlers to perform tasks on all cached objects.

sub all_handlers {
  return \%Connected;
}


# overload disconnect
# I have plans for a non mod_perl backend module, so this disconnect 
{
  package Apache::Backend::POE::Conn;
  no strict;
  @ISA=qw(Apache::Backend::POE::Connection);
  use strict;
  sub disconnect {
      my $prefix = "$$ Apache::Backend::POE            ";
      print STDERR "$prefix disconnect (overloaded)\n" if $Apache::Backend::POE::DEBUG > 1;
      1;
  };
}


# prepare menu item for Apache::Status

Apache::Status->menu_item(

    'POE' => 'Backend POE connections',
    sub {
        my($r, $q) = @_;
        my(@s) = qw(<TABLE><TR><TD>Datasource</TD><TD>Username</TD></TR>);
        for (keys %Connected) {
            push @s, '<TR><TD>', join('</TD><TD>', (split($;, $_))[0,1]), "</TD></TR>\n";
        }
        push @s, '</TABLE>';
        return \@s;
   }

) if ($INC{'Apache.pm'}                      # is Apache.pm loaded?
      and Apache->can('module')               # really?
      and Apache->module('Apache::Status'));  # Apache::Status too?

1;

__END__


=head1 NAME

Apache::Backend::POE - Communicate with a POE server using persistent connections

=head1 SYNOPSIS

 # Configuration in httpd.conf:

 PerlModule Apache::Backend::POE

 # use in startup.pl
 
 Apache::Backend::POE->connect_on_init(
 	host => 'localhost',
	port => 2021,
	alias => 'poeky'
 );

 # in your mod_perl script

 # use in mod_perl handler
 my $poe = Apache::Backend::POE->connect(
 	host => 'localhost',
	port => 2021,
	alias => 'poeky'
 );
 
 unless (defined $poe) {
 	return SERVER_ERROR;
 }

 # use msg_send and msg_read like the example POE server

=head1 DESCRIPTION

This module allows you to communicate with a POE server using persistent connections. 

=head1 CONFIGURATION

The module should be loaded upon startup of the Apache daemon.
Add the following line to your httpd.conf or startup.pl:

 PerlModule Apache::Backend::POE

A common usage is to load the module in a startup file via the PerlRequire 
directive.

There are two configurations which are server-specific and which can be done 
upon server startup: 

 Apache::Backend::POE->connect_on_init(host => $host, port => $port, alias => $alias);

This can be used as a simple way to have apache servers establish connections 
on process startup. Alias defaults to 'backend'

 Apache::Backend::POE->setPingTimeOut($timeout, $alias);

This configures the usage of the ping method, to validate a connection. 
Setting the timeout to 0 will always validate the connection using the ping
method (default). Setting the timeout < 0 will de-activate the validation of
the connection object. Setting the timeout > 0 will ping the connection only if
the last access was more than timeout seconds before. Alias defaults to 'backend'

For the menu item 'Backend POE connections' you need to call Apache::Status BEFORE 
Apache::Backend::POE ! For an example of the configuration order see startup.pl. 

To enable debugging the variable $Apache::Backend::POE::DEBUG must be set. This 
can either be done in startup.pl or in the user script. Setting the variable 
to 1, just reports about a new connect. Setting the variable to 2 enables full 
debug output. 

=head1 PREREQUISITES

Note that this module needs mod_perl-1.08 or higher, apache_1.3.0 or higher 
and that mod_perl needs to be configured with the appropriate call-back hooks: 

  PERL_CHILD_INIT=1 PERL_STACKED_HANDLERS=1. 

Also, Storable should be the same version on both the client and server.

=head1 MOD_PERL 2.0

Apache::Backend::POE might not work under mod_perl 2.0.
Please send patches.

=head1 SERVER

See the examples directory for a POE server to get you started.

=head1 TODO

=item *
Authentication

=item *
SSL encryption

=item *
Rollback support

=item *
Create L<Backend::POE> module for non mod_perl applications.

=item *
Improve the documentation.

=item *
Support for other serializers like L<YAML>.

=head1 BUG REPORTS

File bug reports at:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache::Backend::POE>

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<POE>, L<Filter::Reference>

=head1 AUTHOR

David Davis <xantus@cpan.org>

=head1 THANKS

Ask Bjoern Hansen, and Edmund Mergl for L<Apache::DBI>

=head1 COPYRIGHT

Copyright 2005 by David Davis and Teknikill Software

This libaray is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
