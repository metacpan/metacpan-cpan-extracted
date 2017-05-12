package DBR::Common;

use strict;
use Time::HiRes;
use Carp;

my %TIMERS;

sub _uniq{
    my $self = shift;
    my $has_undef;
    my %uniq;
    return grep{ defined($_)?(  !$uniq{$_}++  ):(  !$has_undef++  ) } @_;

}

sub _split{
      my $self = shift;
      my $value = shift;

      my $out;
      if(ref($value)){
	    $out = $value;
      }else{
	    $value =~ s/^\s*|\s*$//g;
	    $out = [ split(/\s+/,$value) ];
      }

      return wantarray? (@$out): $out;
}

sub _arrayify{
      my $self = shift;
      my @out = map { ref($_) eq 'ARRAY' ? (@$_) : ($_) } @_;
      return wantarray? (@out) : \@out;
}

sub _hashify{
      my $self = shift;
      my %out;
      while(@_){
	    my $k = shift;
	    if(ref($k) eq 'HASH'){
		  %out = (%out,%$k);
		  next;
	    }
	    my $v = shift;
	    $out{ $k } = $v;
      }
      return wantarray? (%out) : \%out;
}

# returns true if all elements of Arrayref A (or single value) are present in arrayref B
sub _b_in{
      my $self = shift;
      my $value1 = shift;
      my $value2 = shift;
      $value1 = [$value1] unless ref($value1);
      $value2 = [$value2] unless ref($value2);
      return undef unless (ref($value1) eq 'ARRAY' && ref($value2) eq 'ARRAY');
      my %valsA = map {$_ => 1} @{$value2};
      my $results;
      foreach my $val (@{$value1}) {
            unless ($valsA{$val}) {
                  return 0;
            }
      }
      return 1;
}

sub _stopwatch{
      my $self = shift;
      my $label = shift;

      my ( $package, $filename, $line, $method ) = caller( 1 ); # First caller up
      $method ||= '';
      my ($m) = $method =~ /([^\:]*)$/;

      if($label){
	    my $elapsed = Time::HiRes::time() - $TIMERS{$method};
	    my $seconds = sprintf('%.8f',$elapsed);
	    $self->_logDebug2( "$m ($label) took $seconds seconds");
      }

      $TIMERS{ $method } = Time::HiRes::time(); # Logger could be slow

      return 1;
}

sub _log       {
      my $s = shift->_session or return 1;
      $s->_log( shift, 'INFO'  );
      return 1
}
sub _logDebug  {
      my $s = shift->_session or return 1;
      $s->_log( shift, 'DEBUG'  );
      return 1
}
sub _logDebug2  {
      my $s = shift->_session or return 1;
      $s->_log( shift, 'DEBUG2'  );
      return 1
}
sub _logDebug3  {
      my $s = shift->_session or return 1;
      $s->_log( shift, 'DEBUG3'  );
      return 1
}

sub _warn       {
      my $s = shift->_session or return 1;
      $s->_log( shift, 'WARN'  );
      return 1
}

sub _error     {
      my $s = shift->_session;

      if(!$s || $s->use_exceptions){
	    local $Carp::CarpLevel = 1;
	    croak shift;
      }


      if($s){
	    $s->_log( shift, 'ERROR' )
      }else{
	    print STDERR "DBR ERROR: " . shift() . "\n";
      }
      return undef;
}

sub _session { $_[0]->{session} }
sub is_debug { $_[0]->{debug}  }

package DBR::Common::DummySession;


# sub _error {
#       my $self = shift;
#       my $message = shift;

#       my ( $package, $filename, $line, $method) = caller(1);
#       if ($self->session){
# 	    $self->session->logErr($message,$method);
#       }else{
# 	    print STDERR "DBR ERROR: $message ($method, line $line)\n";
#       }
#       return undef;
# }

# sub _logDebug{
#       my $self = shift;
#       my $message = shift;
#       my ( $package, $filename, $line, $method) = caller(1);
#       if ($self->session){
# 	    $self->session->logDebug($message,$method);
#       }elsif($self->is_debug){
# 	    print STDERR "DBR DEBUG: $message\n";
#       }
# }
# sub _logDebug2{
#       my $self = shift;
#       my $message = shift;
#       my ( $package, $filename, $line, $method) = caller(1);
#       if ($self->session){
# 	    $self->session->logDebug2($message,$method);
#       }elsif($self->is_debug){
# 	    print STDERR "DBR DEBUG2: $message\n";
#       }
# }
# sub _logDebug3{
#       my $self = shift;
#       my $message = shift;
#       my ( $package, $filename, $line, $method) = caller(1);
#       if ($self->session){
# 	    $self->session->logDebug3($message,$method);
#       }elsif($self->is_debug){
# 	    print STDERR "DBR DEBUG3: $message\n";
#       }

# }

# #HERE HERE HERE - do some fancy stuff with dummy subroutines in the symbol table if nobody is in debug mode

# sub _log{
#       my $self = shift;
#       my $message = shift;
#       my ( $package, $filename, $line, $method) = caller(1);
#       if ($self->session){
# 	    $self->session->log($message,$method,'INFO');
#       }else{
# 	    print STDERR "DBR: $message\n";
#       }
#       return 1;
# }

1;
