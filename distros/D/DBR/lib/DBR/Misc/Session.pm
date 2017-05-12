package DBR::Misc::Session;

use strict;
use base 'DBR::Common';
use DateTime::TimeZone;
use Carp;

sub new {
      my( $package ) = shift;

      my %params = @_;
      my $self = {
		  logger   => $params{logger},
		  admin    => $params{admin} ? 1 : 0,
		  fudge_tz => $params{fudge_tz},
		  use_exceptions => $params{use_exceptions} ? 1 : 0,
		 };

      bless( $self, $package );

      croak ('logger is required') unless $self->{logger};

      my $tz = '';
      $self->{tzref} = \$tz;
      $self->timezone('server') or confess "failed to initialize timezone";

      return $self;
}


sub timezone {
      my $self = shift;
      my $tz   = shift;

      return ${$self->{tzref}} unless defined($tz);

      if($tz eq 'server' ){
	    eval {
		  my $tzobj = DateTime::TimeZone->new( name => 'local');
		  $tz = $tzobj->name;
	    };
	    if($@){
		  if($self->{fudge_tz}){
			$self->_log( "Failed to determine local timezone. Fudging to UTC");
			$tz = 'UTC';
		  }else{
			return $self->_error( "Failed to determine local timezone ($@)" );
		  }
	    }
      }

      DateTime::TimeZone->is_valid_name( $tz ) or return $self->_error( "Invalid Timezone '$tz'" );

      $self->_logDebug2('Set timezone to ' . $tz);

      return ${$self->{tzref}} = $tz;
}
sub timezone_ref{ $_[0]->{tzref} }

sub is_admin{ $_[0]->{admin} }
sub use_exceptions{ $_[0]->{use_exceptions} }

sub _session { $_[0] }

sub _log{
      my $self    = shift;
      my $message = shift;
      my $mode    = shift;

      my ( undef,undef,undef, $method) = caller(2);
      $self->{logger}->log($message,$method,$mode);

      return 1;
}

sub _directlog{
      my $self = shift;
      my $message = shift;
      my $method  = shift;
      my $mode    = shift;

      $self->{logger}->log($message,$method,$mode)
}

1;
