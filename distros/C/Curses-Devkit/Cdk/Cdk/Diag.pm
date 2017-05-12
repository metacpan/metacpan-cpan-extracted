package Cdk::Diag;

@ISA	= qw (Cdk);

#
# This creates a new Label object
#
sub getScreenRegList
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";
   
   # Retain the type of the object.
   $self->{'Type'} = $type;
   
   # Set up the parameters passed in.
   my $mesg = Cdk::checkReq ($name, "Message", $params{'Message'});

   # Call the thing.
   Cdk::Diag::DumpScreenRegList ($mesg);
}

#
# This writes to the log file.
#
sub Log
{
   my($mesgType, $widgetType, $mesg)	= @_;

   # If the environment flag CDKDIAG is not set then get out.
   return if (! defined $ENV{'CDKDIAG'});

   # Set up the local vars.
   my $filename	= $ENV{'CDKLOGFILE'}	|| "cdkdiag.log";
   my $date = qx (date); chomp $date;
   my $diagType = uc $ENV{'CDKDIAG'};

   # Only write the output if the diagnostics tell us to.
   if ($diagType eq "ALL" || $diagType =~ uc $widgetType)
   {
      # Open the file
      open (XXX, ">>$filename");
      select (XXX); $| = 1;
      print XXX "\n</29>*** Diagnostic Start:  Program=<$0> Time: <$date> ***\n" if ! $DIAGFLAG;

      # Check the message type.
      print XXX "</24>$mesgType - ($widgetType) $mesg\n" if ($mesgType eq "Diag");
      print XXX "</16>$mesgType - ($widgetType) $mesg\n" if ($mesgType eq "Error");
      close (XXX);
      $DIAGFLAG	= 1;
   }
}

1;
