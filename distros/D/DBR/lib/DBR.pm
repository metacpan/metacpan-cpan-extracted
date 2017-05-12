# the contents of this file are Copyright (c) 2004-2009 Daniel Norman
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR;

use strict;
use DBR::Handle;
use DBR::Config;
use DBR::Config::Instance;
use DBR::Misc::Session;
use Scalar::Util 'blessed';
use base 'DBR::Common';
use DBR::Util::Logger;
use Carp;

our $VERSION = '1.5';

my %APP_BY_CONF;
my %CONF_BY_APP;
my %OBJECTS;
my $CT;

sub import {
      my $pkg = shift;
      my %params = @_;

      my ($callpack, $callfile, $callline) = caller;

      my $app  = $params{app};
      my $exc  = exists $params{use_exceptions} ? $params{use_exceptions} || 0 : 1;
      my $conf;

      if( $params{conf} ){
	    croak "conf file '$params{conf}' not found" unless -e $params{conf};

	    $conf = $params{conf};
	    $app ||= $APP_BY_CONF{ $conf } ||= 'auto_' . $CT++; # use existing app id if conf exists, or make one up
	    $CONF_BY_APP{ $app } = $conf;
      }elsif ( defined $app && length $app ){
	    $conf = $CONF_BY_APP{ $app };
      }

      return 1 unless $app; # No import requested

      if($conf){
	    $OBJECTS{ $app }{ $exc } ||= DBR->new(
						  -logger => DBR::Util::Logger->new(
										    -logpath  => $params{logpath} || '/tmp/dbr_auto.log',
										    -logLevel => $params{loglevel} || 'warn'
										   ),
						  -conf           => $conf,
						  -use_exceptions => $exc,
						 );
      }

      my $dbr = $OBJECTS{ $app }{ $exc } or croak "No DBR object could be located";

      no strict 'refs';
      *{"${callpack}::dbr_connect"} =
	sub {
	      shift if blessed($_[0]) || $_[0]->isa( [caller]->[0] );
	      $dbr->connect(@_);
	};
        
      *{"${callpack}::dbr_instance"} =
	sub {
	      shift if blessed($_[0]) || $_[0]->isa( [caller]->[0] );
	      $dbr->get_instance(@_);
	};
        

}
sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {logger => $params{-logger}};

      bless( $self, $package );

      return $self->_error("Error: -conf must be specified") unless $params{-conf};

      return $self->_error("Failed to create DBR::Util::Session object") unless
	$self->{session} = DBR::Misc::Session->new(
						   logger   => $self->{logger},
						   admin    => $params{-admin} ? 1 : 0, # make the user jump through some hoops for updating metadata
						   fudge_tz => $params{-fudge_tz},
						   use_exceptions => $params{-use_exceptions},
						  );

      return $self->_error("Failed to create DBR::Config object") unless
	my $config = DBR::Config->new( session => $self->{session} );

      $config -> load_file(
			   dbr  => $self,
			   file => $params{-conf}
			  ) or return $self->_error("Failed to load DBR conf file");


      DBR::Config::Instance->flush_all_handles(); # Make it safer for forking

      return( $self );
}


sub setlogger {
      my $self = shift;
      $self->{logger} = shift;
}

sub session { $_[0]->{session} }

sub connect {
      my $self = shift;
      my $name = shift;
      my $class = shift;
      my $flag;

      if ($class && $class eq 'dbh') {	# legacy
	    $flag = 'dbh';
	    $class = undef;
      }

      my $instance = DBR::Config::Instance->lookup(
						   dbr    => $self,
						   session => $self->{session},
						   handle => $name,
						   class  => $class
						  ) or return $self->_error("No config found for db '$name' class '$class'");

      return $instance->connect($flag);

}

sub get_instance {
      my $self = shift;
      my $name = shift;
      my $class = shift;
      my $flag;

      if ($class && $class eq 'dbh') {	# legacy
	    $flag = 'dbh';
	    $class = undef;
      }

      my $instance = DBR::Config::Instance->lookup(
						   dbr    => $self,
						   session => $self->{session},
						   handle => $name,
						   class  => $class
						  ) or return $self->_error("No config found for db '$name' class '$class'");
      return $instance;
}

sub timezone{
      my $self = shift;
      my $tz   = shift;
      $self->{session}->timezone($tz) or return $self->_error('Failed to set timezone');
}

sub remap{
      my $self = shift;
      my $class = shift;

      return $self->_error('class must be specified') unless $class;

      $self->{globalclass} = $class;

      return 1;
}

sub unmap{ undef $_[0]->{globalclass}; return 1 }
sub flush_handles{ DBR::Config::Instance->flush_all_handles }
sub DESTROY{ $_[0]->flush_handles }

1;

=pod

=head1 NAME

DBR - Database Repository ORM (object-relational mapper).

=head1 DESCRIPTION

DBR (Database Repository) is a fairly directed attempt at an Object Relational Mapper.
It is not trying to be all things to all people. It's focus is on managing large schemas with an
emphasis on metadata, rather than defining schema structure with code.

See L<DBR::Manual> for more details.

=head1 SYNOPSIS

 use DBR ( conf => '/path/to/my/DBR.conf' );
 
 my $music   = dbr_connect('music');
 my $artists = $music->artist->all;
 
 print "Artists:\n";
 while (my $artist = $artists->next) {
       print "\t" . $artist->name . "\n";
 }

=head1 EXPORT

 use DBR (
          conf           => '/path/to/my/DBR.conf' # Required ( unless app is specified )
          
          # Remaining parameters are optional
          app            => 'myapp' # auto generated by default
          use_exceptions => 1,                  # default
          logpath        => '/tmp/dbr_auto.log' # default
          loglevel       => 'warn'              # default. allows: none info warn error debug debug2 debug3
      );

Note: specify parameter: app => 'myappname' to allow multiple libraries to share one connection pool.
Only the library loaded first needs to specify conf and the other parameters. Subsequent libraries can then specify only app => 'myappname'

When you "use DBR" with arguments, as above, the default behavior is to export the following methods into your class

=head2 dbr_connect( $schema [, $class] );

Connect to an instance of the specified schema

 my $music = dbr_connect('music');

Optionally accepts a $class argument, to specify which instance. Defaults to "master"

Returns a L<DBR::Handle> object representing your connection handle

=head2 dbr_instance( $schema [, $class] );

Similar to dbr_connect, but returns a L<DBR::Config::Instance> object instead of a L<DBR::Handle> object.

 my $instance = dbr_connect('music');
 
An instance object represents the instance of the database schema in question, without necessarily being connected to it.

=head1 METHODS

=head2 new

Constructor. Useful in situations where you do not wish to export dbr_connect and dbr_instance into your class ( described above )

 my $logger = new DBR::Util::Logger( -logpath => 'dbr.log' );
 my $dbr    = new DBR(
                      -logger => $logger,
                      -conf => '/path/to/my/DBR.conf'
                  );
 my $handle = $dbr->connect( 'music' );

=head3 arguments

=over 1

=item -logger

L<DBR::Util::Logger> object ( required )

=item -conf

path to the DBR.conf you wish to use ( required )

=item -use_exceptions

Boolean. Causes all DBR errors to raise an exception, rather than logging an returning false ( default )

=item -admin

Boolean. Enables configuration objects to write changes to metadata DB ( don't use )

=item -fudge_tz

Boolean. Prevents DBR from aborting in the event that it cannot determine the system timezone.

=back

Returns a L<DBR> object.

=head2 connect

Same arguments as dbr_connect above

=head2 get_instance

Same arguments as dbr_instance above

=head2 flush_handles

Disconnects all active database connections. Useful if you need to fork your process

=cut

