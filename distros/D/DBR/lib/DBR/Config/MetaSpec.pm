package DBR::Config::MetaSpec;

# a work barely in progress... ;)

use strict;
use base 'DBR::Common';
use DBR::Config::Field;
use JSON;

use Data::Dumper;

sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  session       => $params{session},
		  conf_instance => $params{conf_instance},
		  targ_instance => $params{targ_instance},
		 };

      bless( $self, $package );

      return $self->_error('session object must be specified')
        unless $self->{session};

      return $self->_error('conf_instance object must be specified')
        unless $self->{conf_instance};

      return $self->_error('targ_instance object must be specified')
        unless $self->{targ_instance};

      $self->{schema_id} = $self->{targ_instance}->schema_id or
	return $self->_error('Target instance must have a schema');

      return( $self );
}

sub process {
      my $self = shift;
      my %params = @_;

      #print "SPEC TO PROCESS:\n" . Dumper( $params{spec} ) . "\n";

      my $schema = $self->{targ_instance}->schema;
      die "failed to get schema!\n" unless defined $schema;
      die "no schema available?!\n" unless ref( $schema );

      my $dbrh = $self->{conf_instance}->connect
        or die "failed to get V1 connection to the config metadata database\n";

      return 1;
}

1;
