package Cdk::Viewer;

@ISA	= qw (Cdk);

#
# This creates a new Viewer object.
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
   my $buttons	= Cdk::checkReq ($name, "Buttons", $params{'Buttons'});
   my $height	= Cdk::checkReq ($name, "Height", $params{'Height'});
   my $width	= Cdk::checkReq ($name, "Width", $params{'Width'});
   my $hlight	= Cdk::checkDef ($name, "Highlight", $params{'Highlight'}, "A_REVERSE");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Viewer::New ($params{'Buttons'},
					$height, $width, $hlight,
					$xpos, $ypos,
					$box, $shadow);
   bless $self;
}

#
# This activates the viewer.
#
sub activate
{
   my $self		= shift;
   my %params		= @_;
   my $name		= "$self->{'Type'}::activate";
 
   # Activate the object...
   $self->{'Info'} = Cdk::Viewer::Activate ($self->{'Me'});
   return ($self->{'Info'});
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
   if (defined $params{'Info'})
   {
      my $interpret = $params{'Interpret'} || 1;
      Cdk::Viewer::SetInfo ($self->{'Me'}, $params{'Info'}, $interpret);
   }
   if (defined $params{'Title'})
   {
      Cdk::Viewer::SetTitle ($self->{'Me'}, $params{'Title'});
   }
   if (defined $params{'Highlight'})
   {
      Cdk::Viewer::SetHighlight ($self->{'Me'}, $params{'Highlight'});
   }
   if (defined $params{'InfoLine'})
   {
      Cdk::Viewer::SetInfoLine ($self->{'Me'}, $params{'InfoLine'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Viewer::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Viewer::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Viewer::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Viewer::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Viewer::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Viewer::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Viewer::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Viewer::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Viewer::SetBox ($self->{'Me'}, $params{'Box'});
   }
}

#
# This draws the object.
#
sub draw
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::draw";

   # Set up the parameters passed in.
   my $box = Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   
   # Draw the object.
   Cdk::Viewer::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Viewer::Erase ($self->{'Me'});
}

#
# This allows us to bind a key to an action.
#
sub bind
{
   my $self     = shift;
   my %params   = @_;
   my $name     = "$self->{'Type'}::bind";

   # Set the values.
   my $key = Cdk::checkReq ($name, "Key", $params{'Key'});
   my $function = Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Entry::Bind ($self->{'Me'}, $key, $params{'Function'});
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Viewer::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Viewer::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Viewer::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Viewer::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Viewer::GetWindow ($self->{'Me'});
}

1;
