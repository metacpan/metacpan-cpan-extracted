package Cdk::Slider;

#
# This creates a new Slider object
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
   my $low	= Cdk::checkReq ($name, "Low", $params{'Low'});
   my $high	= Cdk::checkReq ($name, "High", $params{'High'});
   my $width	= Cdk::checkReq ($name, "Width", $params{'Width'});
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $label	= Cdk::checkDef ($name, "Label", $params{'Label'}, "");
   my $inc	= Cdk::checkDef ($name, "Inc", $params{'Inc'}, 1);
   my $fastInc	= Cdk::checkDef ($name, "Fastinc", $params{'Fastinc'}, 5);
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $start	= Cdk::checkDef ($name, "Start", $params{'Start'}, $params{'Low'});
   my $filler	= Cdk::checkDef ($name, "Filler", $params{'Filler'}, "</R> ");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Slider::New ($title, $label,
					$start, $low, $high,
					$inc, $fastinc,
					$width, $xpos, $ypos,
					$filler, $box, $shadow);
   bless $self;
}

#
# This activates the object.
#
sub activate
{
   my $self             = shift;
   my %params           = @_;
   my $name             = "$self->{'Type'}::activate";

   # Activate the object...
   if (defined $params{'Input'})
   {
      $self->{'Info'} = Cdk::Slider::Activate ($self->{'Me'}, $params{'Input'});
   }
   else
   {
      $self->{'Info'} = Cdk::Slider::Activate ($self->{'Me'});
   }
   return $self->{'Info'};
}

#
# This injects a character into the widget.
#
sub inject
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::inject";

   # Set the values.
   my $character = Cdk::checkReq ($name, "Input", $params{'Input'});

   return Cdk::Slider::Inject ($self->{'Me'}, $character);
}

#
# This allows us to bind a key to an action.
#
sub bind
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::bind";
 
   # Set the values.
   my $key = Cdk::checkReq ($name, "Key", $params{'Key'});
   my $function	= Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Slider::Bind ($self->{'Me'}, $key, $params{'Function'});
}

#
# This allows us to set a pre-process function.
#
sub preProcess
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::preProcess";
 
   # Set the values.
   my $function = Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Slider::PreProcess ($self->{'Me'}, $params{'Function'});
}

#
# This allows us to set a post-process function.
#
sub postProcess
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::postProcess";
 
   # Set the values.
   my $function = Cdk::checkReq ($name, "Function", $params{'Function'});
   Cdk::Slider::PostProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Slider::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Slider::Erase ($self->{'Me'});
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
   if (defined $params{'Value'})
   {
      Cdk::Slider::SetValue ($self->{'Me'}, $params{'Value'});
   }
   if (defined $params{'Low'})
   {
      Cdk::Slider::SetLowHigh ($self->{'Me'}, $params{'Low'}, $params{'High'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Slider::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Slider::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Slider::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Slider::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Slider::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Slider::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Slider::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Slider::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Slider::SetBox ($self->{'Me'}, $params{'Box'});
   }
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Slider::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Slider::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Slider::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Slider::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Slider::GetWindow ($self->{'Me'});
}

1;
