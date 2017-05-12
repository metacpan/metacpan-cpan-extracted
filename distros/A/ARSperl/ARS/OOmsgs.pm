#
#    ARSperl - An ARS v2-v4 / Perl5 Integration Kit
#
#    Copyright (C) 1995-1999 Joel Murphy, jmurphy@acsu.buffalo.edu
#                            Jeff Murphy, jcmurphy@acsu.buffalo.edu
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms as Perl itself. 
#    
#    Refer to the file called "Artistic" that accompanies the source distribution 
#    of ARSperl (or the one that accompanies the source distribution of Perl
#    itself) for a full description.
#
#    Official Home Page: 
#    http://www.arsperl.org/
#
#    Mailing List (must be subscribed to post):
#    See URL above.
#

sub internalDie {
    my ($this, $msg, $trace) = (shift, shift, shift);
    
    $msg = "[no message available]" unless (defined($msg) && ($msg ne ""));
    $trace = "[no traceback available]" 
	unless (defined($trace) && ($trace ne ""));
    
    die "$msg\n\nTRACEBACK:\n\n$trace\n";
}

sub internalWarn {
    my ($this, $msg, $trace) = (shift, shift, shift);

    $msg = "[no message available]" unless (defined($msg) && ($msg ne ""));
    $trace = "[no traceback available]" 
	unless (defined($trace) && ($trace ne ""));
    
    warn "$msg\n\nTRACEBACK:\n\n$trace\n";
}

# 81000 = Usage Errors
# 81001 = Field Name Not In VUI
# 81002 = Invalid Field ID
# 81003 = Unknown Field Data Type
# 81004 = Unable to Xlate Enum Value
# 81005 = misspelled/invalid parameter

# .catch is a hash ref

sub initCatch {
  my $this = shift;

  $this->setCatch(&ARS::AR_RETURN_WARNING => "internalWarn");
  $this->setCatch(&ARS::AR_RETURN_ERROR   => "internalDie");
  $this->setCatch(&ARS::AR_RETURN_FATAL   => "internalDie");
}

sub setCatch {
  my $this = shift;
  my $type = shift;
  my $func = shift;

  $this->{'.catch'}->{$type} = $func;
}

# this routine is periodically called to see if any exceptions
# have occurred. if they have, and an exception handler is specified,
# we will call the handler and pass it the exception.

sub tryCatch {
    my $this = shift;
    
    if(defined($this->{'.catch'}) && ref($this->{'.catch'}) eq "HASH") {
	foreach (&ARS::AR_RETURN_WARNING, &ARS::AR_RETURN_ERROR, 
	         &ARS::AR_RETURN_FATAL) {
	    if(defined($this->{'.catch'}->{$_}) && $this->hasMessageType($_)) {
		my $stackTrace = Carp::longmess("exception generated");
		&{$this->{'.catch'}->{$_}}($_, $this->messages(), 
					   $stackTrace);
	    }
	}
    }
}

sub pushMessage {
    my ($this, $type, $num, $text) = (shift, shift, shift, shift);
    $ARS::ars_errhash{numItems}++;
    push @{$ARS::ars_errhash{messageType}}, $type;
    push @{$ARS::ars_errhash{messageNum}}, $num;
    push @{$ARS::ars_errhash{messageText}}, $text;
    $this->tryCatch();
}

sub messages {
  my(%mTypes) = ( 0 => "OK", 1 => "WARNING", 2 => "ERROR", 3 => "FATAL",
		  4 => "INTERNAL ERROR",
		  -1 => "TRACEBACK");
  my ($this, $type, $str) = (shift, shift, undef);

  return $ars_errstr if(!defined($type));

  for(my $i = 0; $i < $ARS::ars_errhash{numItems}; $i++) {
    if(@{$ARS::ars_errhash{'messageType'}}[$i] == $type) {
      $s .= sprintf("[%s] %s (ARERR \#%d)", 
		    $mTypes{@{$ARS::ars_errhash{messageType}}[$i]}, 
		    @{$ARS::ars_errhash{messageText}}[$i], 
		    @{$ARS::ars_errhash{messageNum}}[$i]); 
      $s .= "\n" if($i < $ARS::ars_errhash{numItems}-1); 
    }
  }
  return $s;
}


sub errors {
  my $this = shift;
  return $this->messages(&ARS::AR_RETURN_ERROR);
}

sub warnings {
  my $this = shift;
  return $this->messages(&ARS::AR_RETURN_WARNING);
}

sub fatals {
  my $this = shift;
  return $this->messages(&ARS::AR_RETURN_FATAL);
}

sub hasMessageType {
  my ($this, $t) = (shift, shift);
  return $t if !defined($t);
  for(my $i = 0; $i < $ARS::ars_errhash{numItems}; $i++) {
    return 1 
      if(@{$ARS::ars_errhash{'messageType'}}[$i] == $t);
  }
  return 0;
}

sub hasFatals {
  my $this = shift;
  return $this->hasMessageType(&ARS::AR_RETURN_FATAL);
}

sub hasErrors {
  my $this = shift;
  return $this->hasMessageType(&ARS::AR_RETURN_ERROR);
}

sub hasWarnings {
  my $this = shift;
  return $this->hasMessageType(&ARS::AR_RETURN_WARNING);
}

1;
