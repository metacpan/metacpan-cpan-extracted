package Cdk::Label;

@ISA	= qw (Cdk);

#
# This creates a new Label object
#
sub new
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";
   
   # Retain the type of the object.
   $self->{'Type'}	= $type;
   
   # Set up the parameters passed in.
   my $mesg	= Cdk::checkReq ($name, "Message", $params{'Message'});
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Label::New ($params{'Message'}, $ypos, $xpos, $box, $shadow);
   bless $self;
}

#
# This sets several parameters of the widget.
#
sub set
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::set";

   #
   # Check the parameters sent in.
   #
   if (defined $params{'Message'})
   {
      Cdk::Label::SetMessage ($self->{'Me'}, $params{'Message'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Label::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Label::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Label::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Label::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Label::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Label::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Label::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Label::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Label::SetBox ($self->{'Me'}, $params{'Box'});
   }
}
   
#
# This draws the label object.
#
sub draw
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::draw";

   # Set up the parameters passed in.
   my $box = Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");

   # Draw the object.
   Cdk::Label::Draw ($self->{'Me'}, $box);
}

#
# This erases the object from the screen.
#
sub erase
{
   my $self	= shift;
   Cdk::Label::Erase ($self->{'Me'});
}

#
# This gives the user the ability to wait until a key is hit.
#
sub wait
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::wait";

   # Set up the parameters passed in.
   my $key = Cdk::checkDef ($name, "Key", $params{'Key'}, '');

   # Sit and wait.
   Cdk::Label::Wait ($self->{'Me'}, $key);
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Label::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Label::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Label::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Label::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Label::GetWindow ($self->{'Me'});
}

1;
