package Cdk::Entry;

@ISA	= qw (Cdk);

#
# This creates a new Entry object.
#
sub new
{
   my $type		= shift;
   my %params		= @_;
   my $self		= {};
   my $name		= "${type}::new";

   # Retain the type of the object.
   $self->{'Type'} = $type;
   
   # Set up the parameters passed in.
   my $max	= Cdk::checkReq ($name, "Max", $params{'Max'});
   my $fWidth	= Cdk::checkReq ($name, "Width", $params{'Width'});
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $label	= Cdk::checkDef ($name, "Label", $params{'Label'}, "");
   my $filler	= Cdk::checkDef ($name, "Filler", $params{'Filler'}, ".");
   my $min	= Cdk::checkDef ($name, "Min", $params{'Min'}, 0);
   my $dispType	= Cdk::checkDef ($name, "Dtype", $params{'Dtype'}, "MIXED");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $fAttr	= Cdk::checkDef ($name, "Fattrib", $params{'Fieldattr'}, "A_NORMAL");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Entry::New ($title, $params{'Label'},
					$min, $max, $fWidth,
					$filler, $dispType,
					$xpos, $ypos, $fAttr,
					$box, $shadow);
   bless  $self;
}

#
# This activates the object
#
sub activate
{
   my $self		= shift;
   my %params		= @_;
   my $name		= "$self->{'Type'}::activate";

   # Activate the object...
   if (defined $params{'Input'})
   {
      $self->{'Info'} = Cdk::Entry::Activate ($self->{'Me'}, $params{'Input'});
   }
   else
   {
      $self->{'Info'} = Cdk::Entry::Activate ($self->{'Me'});
   }
   return ($self->{'Info'});
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

   return (Cdk::Entry::Inject ($self->{'Me'}, $character));
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
      Cdk::Entry::SetValue ($self->{'Me'}, $params{'Value'});
   }
   if (defined $params{'Min'})
   {
      Cdk::Entry::SetMin ($self->{'Me'}, $params{'Min'});
   }
   if (defined $params{'Max'})
   {
      Cdk::Entry::SetMax ($self->{'Me'}, $params{'Max'});
   }
   if (defined $params{'FillerChar'})
   {
      Cdk::Entry::SetFillerChar ($self->{'Me'}, $params{'FillerChar'});
   }
   if (defined $params{'HiddenChar'})
   {
      Cdk::Entry::SetHiddenChar ($self->{'Me'}, $params{'HiddenChar'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Entry::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Entry::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Entry::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Entry::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Entry::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Entry::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Entry::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Entry::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Entry::SetBox ($self->{'Me'}, $params{'Box'});
   }
}

#
# This function allows the user to get the current value from the widget.
#
sub get
{
   my $self	= shift;
   return (Cdk::Entry::Get ($self->{'Me'}));
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

   Cdk::Entry::Bind ($self->{'Me'}, $params{'Key'}, $params{'Function'});
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
   Cdk::Entry::PreProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Entry::PostProcess ($self->{'Me'}, $params{'Function'});
}

#
# This draws the object.
#
sub draw
{
   my $self	= shift;
   my %params	= @_;
   my $name	= "$self->{'Type'}::draw";

   # Set the values.
   my $box = Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   
   # Draw the object.
   Cdk::Entry::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Entry::Erase ($self->{'Me'});
}

#
# This cleans the info inside the entry object.
#
sub clean
{
   my $self	= shift;
   Cdk::Entry::Clean ($self->{'Me'});
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Entry::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Entry::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Entry::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Entry::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Entry::GetWindow ($self->{'Me'});
}

1;
