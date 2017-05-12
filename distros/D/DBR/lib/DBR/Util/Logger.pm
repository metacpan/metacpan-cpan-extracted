package DBR::Util::Logger;

use vars qw(@ISA @EXPORT);

@ISA = ('Exporter');

use strict;
use Carp;
use FileHandle;

=pod

=head1 NAME

DBR::Util::Logger


=head1 SYNOPSIS

  use DBR::Util::Logger;

  $logger = new DBR::Util::Logger( [
                                        -user_id  => $user_id, # Optional
                                        -logPath  => $alternatePath,
                                        -logLevel => 'level' # None, Info, Warn, Debug, Debug2, Debug3
                                        -bDebug   => $boolDebug, # Deprecated
                                        -noLog    => $boolNoLog, # Deprecated ]
                                    );

=head1 DESCRIPTION

The purpose of the Logger Object is to log script information 
on a per user basis, as well as keep a transaction log of
all DB related API Calls.

=head1 METHODS

=head2 new (Constructor)

=over 4

=item B<-user_id>

=item B<-logpath>

=item B<-logLevel>

=back

=cut

sub new {
      my( $pkg, %in ) = @_;

      my( $self ) = {};

      bless( $self, $pkg );

      my $level;
      if ($in{-logLevel}) {
	    $level = $in{-logLevel}
      } else {
	    $level = 'none' if $in{-noLog};
	    $level = 'debug' if $in{-bDebug};
      }

      $level = lc($level);


      my @levels = qw'none error warn info debug debug2 debug3';
      my $ct = 0;
      my %levmap;
      map {$levmap{$_} = $ct++} @levels;
      $self->{levmap} = \%levmap;

      $level = 'info' unless defined($levmap{$level});
      $self->{loglevel} = $levmap{$level};

      $self->{logbase} =  $in{-logPath} || $in{-logpath} || '';

      if ( $in{-user_id} ) {
	    $self->{user_id} = $in{-user_id};
      }

      return( $self );
}

=pod

=head2 log

This method provides logging (optionally on a per user basis).

=cut

sub log {
      my $self   = shift;
      my $msg    = shift;
      my $caller = shift;
      my $type   = shift;

      return unless( $self->{loglevel} );

      $type ||= 'info';
      $type = lc($type);

      return unless $self->{levmap}->{$type};
      return unless $self->{levmap}->{$type} <= $self->{loglevel};

      my $fh = $self->{HANDLE};

      if (!defined($fh)) {
	    my $logpath;
	    if ( $self->{user_id} ) {
		  my $user_id = ( ('0'x(9 - length ($self->{user_id}))) . $self->{user_id});
		  my $user_a = substr( $user_id, 0, 3 );
		  my $user_b = substr( $user_id, 3, 3 );
		  $logpath   = "$self->{logbase}/$user_a/$user_b/$user_id";
	    } else {
		  $logpath   = $self->{logbase};
	    }


	    $fh = new FileHandle;
	    $fh->autoflush(1);

	    my $dirpath = $logpath;
	    $dirpath =~ s/[^\/]*$//; # strip filename

	    $self->_prepdir($dirpath) || print STDERR "DBR::Util::Logger: FAILED to Prepare log path $dirpath\n";
	    sysopen( $fh, $logpath, O_WRONLY|O_CREAT|O_APPEND, 0666 ) || print STDERR "DBR::Util::Logger: FAILED to open log $logpath\n";

	    $self->{HANDLE} = $fh;

	    $self->log( "New Logger $logpath opened by $caller",'DBR::Util::Logger','debug2'); # Yes, its recursive, but only once.

      }

      my($s,$m,$h,$D,$M,$Y) = getTime();
      $type = uc($type);
      print $fh "$Y$M$D$h$m$s\t$type\t$caller\t$msg\n";

}

sub _prepdir{
      my $self  = shift;
      my $dir  = shift;

      $dir =~ s/\/$//g; # Strip trailing slashes
      return 1 if -d $dir;

      my $path;
      for (split(/\/+/,$dir)){
	    $path .= ((defined($path)?'/':'') . $_);
	    (!length($path) || -d $path) && next;
	    if(-e _) {
		  print STDERR "DBR::Util::Logger: ERROR! $path exists, but is not a directory.\n";
		  return undef
	    }
	    mkdir($path, 0775 ) || print STDERR "DBR::Util::Logger: Failed to mkdir $path\n" && return undef;
      }

      return 1;
}

=pod

=head2 logErr,logWarn, logInfo, logDebug, logDebug2, logDebug3

wrappers around log

=cut

sub logErr      { my $self = shift; $self->log( shift, shift, 'ERROR' ); }
sub logWarn     { my $self = shift; $self->log( shift, shift, 'WARN' ); }
sub logInfo     { my $self = shift; $self->log( shift, shift, 'INFO' ); }
sub logDebug    { my $self = shift; $self->log( shift, shift, 'DEBUG' ); }
sub logDebug2   { my $self = shift; $self->log( shift, shift, 'DEBUG2' ); }
sub logDebug3   { my $self = shift; $self->log( shift, shift, 'DEBUG3' ); }


sub DESTROY{
      my $self = shift;

      if(defined($self->{HANDLE})){
	    $self->{HANDLE}->close();
      }
}

=pod

=head2 getTime

accepts null or unix time as input (if null, current time is assumed)
returns an array like localtime, except that year is adjust to 4 digits and
month is 1-12 instead of 0-11

=cut
sub getTime {
      my($time) = @_;
      $time ||= time;
      my(@time) = localtime($time);
      $time[4]++;
      my($i);
      for ($i=0;$i<=$#time;$i++) {
	    if (length($time[$i])<2) {
		  $time[$i] = "0$time[$i]";
	    }
      }

      $time[5] += 1900;

      return(@time);
}

1;
