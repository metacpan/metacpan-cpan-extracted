package Cdk::Debug;

@ISA	= qw (Cdk);

#
# This creates a new Label object
#
sub DumpScreenRegList
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";
   
   # Retain the type of the object.
   $self->{'Type'}	= $type;
   
   # Set up the parameters passed in.
   my $mesg = Cdk::checkReq ("($name) Missing 'Message' value.", $params{'Message'});

   # Call the thing.
   Cdk::Debug::DumpScreenRegList ($params{'Message'}, $mesg);
}

1;
