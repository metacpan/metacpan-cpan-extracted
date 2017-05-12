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
#    http://www.arsperl.org
#
#    Mailing List (must be subscribed to post):
#    See URL above.
#



# Object Oriented Hoopla

sub newObject {
  my ($class, @p) = (shift, @_);
  my ($self) = {};
  my ($blessed) = bless($self, $class);
  my ($server, $username, $password, $catch, $ctrl, $dbg, $tcpport) = 
    rearrange([SERVER,USERNAME,PASSWORD,CATCH,CTRL,DEBUG,TCPPORT],@p);
  # should the OO layer emit debugging information?

  $self->{'.debug'} = 0;
  $self->{'.debug'} = 1 if(defined($dbg));

  $self->initCatch();

  # what error handlers should be called automatically by the OO layer?
  # if a handler is 'undef' then the OO layer will ignore that type of
  # exception (warning, error or fatal). it is then upto the user to
  # check ->hasErrors(), etc. 
  # this should be a hash ref.

  if(defined($catch) && ref($catch) ne "HASH") {
      $self->pushMessage(&ARS::AR_RETURN_ERROR,
			  81000,
			  "catch parameter should be a HASH reference. (you gave me ".ref($catch)." reference)"
			 );
  }

  $self->{'.catch'} = $catch if (defined($catch));


  # if we've received a ctrl parameter, then we'll used that
  # and ignore the other three parameters. in addition, we'll
  # leave it upto the user to call ars_Logoff() since they must've
  # called ars_Login() in order to pass us the ctrl parameter.
  # this allows the user to mix-and-match OO and non-OO ARS module
  # routines with greater ease.

  if(defined($ctrl)) {
      print "new connection object: reusing existing ctrl struct.\n"
	  if $self->{'.debug'};
      if(ref($ctrl) ne "ARControlStructPtr") {
	  $self->pushMessage(&ARS::AR_RETURN_ERROR,
			     81000,
			     "ctrl parameter should be an ARControlStructPtr reference. you passed a ".ref($ctrl)." reference."
			     );

      }
      $self->{'ctrl'} = $ctrl;
      $self->{'.nologoff'} = 1;
  } else {
      print "new connection object: ($server, $username, $password)\n" 
	  if $self->{'.debug'};
      $self->{'ctrl'} = ars_Login($server, $username, $password, "","", $tcpport);
      $self->{'.nologoff'} = 0;
      $self->tryCatch();
  }

  return $blessed;
}

sub DESTROY {
	my ($self) = shift;
	print "destroying connection object: " if $self->{'.debug'};
	if(defined($self->{'.nologoff'}) && $self->{'.nologoff'} == 0) {
		print "ars_Logoff called.\n" if $self->{'.debug'};
		ars_Logoff($self->{'ctrl'}) if defined($self->{'ctrl'});
	} else {
		print "ars_Logoff suppressed.\n" if $self->{'.debug'};
	}
}

sub ctrl {
	my $this = shift;
	return $this->{'ctrl'};
}

sub print {
  my $this = shift;

  my($cacheId, $operationTime, $user, $password, $lang,
     $server) = ars_GetControlStructFields($this->{'ctrl'});

  print "connection object details:\n";
  print "\tcacheId       = $cacheId\n";
  print "\toperationTime = ".localtime($operationTime)."\n";
  print "\tuser          = $user\n";
  print "\tpassword      = $password\n";
  print "\tserver        = $server\n";
  print "\tlang          = $lang\n";
}

sub availableSchemas {
  my $this = shift;
  my ($changedSince, $schemaType, $name) =  
    rearrange([CHANGEDSINCE,SCHEMATYPE,NAME],@_);

  $changedSince = 0 unless defined($changedSince);
  $schemaType = ARS::AR_LIST_SCHEMA_ALL unless defined($schemaType);
  $name = "" unless defined($name);

  return ars_GetListSchema($this->{'ctrl'},
			   $changedSince,
			   $schemaType, undef,
			   $name);
}

sub openForm {
  my $this = shift;
  my($form, $vui) = rearrange([FORM,VUI], @_);

  $this->pushMessage(&ARS::AR_RETURN_ERROR,
		     81000,
		     "usage: c->openForm(-form => name, -vui => vui)\nform parameter is required.")    
      if(!defined($form) || ($form eq ""));
  $this->tryCatch();

  return new ARS::form(-form => $form,
		       -vui => $vui,
		       -connection => $this);
}

1;

