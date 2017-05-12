package Cdk::Fselect;

@ISA	= qw (Cdk);

#
# This creates a new file selector object.
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
   my $height	= Cdk::checkReq ($name, "Height", $params{'Height'});
   my $width	= Cdk::checkReq ($name, "Width", $params{'Width'});
   my $title	= Cdk::checkDef ($name, "Title", $params{'Title'}, "");
   my $label	= Cdk::checkDef ($name, "Label", $params{'Label'}, "");
   my $dattrib	= Cdk::checkDef ($name, "Dattrib", $params{'Dattrib'}, "</B>");
   my $fattrib	= Cdk::checkDef ($name, "Fattrib", $params{'Fattrib'}, "</N>");
   my $lattrib	= Cdk::checkDef ($name, "Lattrib", $params{'Lattrib'}, "</B>");
   my $sattrib	= Cdk::checkDef ($name, "Sattrib", $params{'Sattrib'}, "</B>");
   my $hlight	= Cdk::checkDef ($name, "Highlight", $params{'Highlight'}, "A_REVERSE");
   my $filler	= Cdk::checkDef ($name, "Filler", $params{'Filler'}, ".");
   my $fAttr	= Cdk::checkDef ($name, "Fieldattr", $params{'Fieldattr'}, "A_NORMAL");
   my $xpos	= Cdk::checkDef ($name, "Xpos", $params{'Xpos'}, "CENTER");
   my $ypos	= Cdk::checkDef ($name, "Ypos", $params{'Ypos'}, "CENTER");
   my $box	= Cdk::checkDef ($name, "Box", $params{'Box'}, "TRUE");
   my $shadow	= Cdk::checkDef ($name, "Shadow", $params{'Shadow'}, "FALSE");

   # Create the thing.
   $self->{'Me'} = Cdk::Fselect::New ($title, $label, $height, $width,
					$dattrib, $fattrib, $lattrib, $sattrib,
					$hlight, $fAttr, $filler,
					$xpos, $ypos, $box, $shadow);
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
      $self->{'Info'} = Cdk::Fselect::Activate ($self->{'Me'}, $params{'Input'});
   }
   else
   {
      $self->{'Info'} = Cdk::Fselect::Activate ($self->{'Me'});
   }
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
   if (defined $params{'Directory'})
   {
      Cdk::Fselect::SetDirectory ($self->{'Me'}, $params{'Directory'});
   }
   if (defined $params{'FillerChar'})
   {
      Cdk::Fselect::SetFillerChar ($self->{'Me'}, $params{'FillerChar'});
   }
   if (defined $params{'Highlight'})
   {
      Cdk::Fselect::SetHighlight ($self->{'Me'}, $params{'Highlight'});
   }
   if (defined $params{'DirAttribute'})
   {
      Cdk::Fselect::SetDirAttribute ($self->{'Me'}, $params{'DirAttribute'});
   }
   if (defined $params{'LinkAttribute'})
   {
      Cdk::Fselect::SetLinkAttribute ($self->{'Me'}, $params{'LinkAttribute'});
   }
   if (defined $params{'FileAttribute'})
   {
      Cdk::Fselect::SetFileAttribute ($self->{'Me'}, $params{'FileAttribute'});
   }
   if (defined $params{'SocketAttribute'})
   {
      Cdk::Fselect::SetSocketAttribute ($self->{'Me'}, $params{'SocketAttribute'});
   }
   if (defined $params{'ULChar'})
   {
      Cdk::Fselect::SetULChar ($self->{'Me'}, $params{'ULChar'});
   }
   if (defined $params{'URChar'})
   {
      Cdk::Fselect::SetURChar ($self->{'Me'}, $params{'URChar'});
   }
   if (defined $params{'LLChar'})
   {
      Cdk::Fselect::SetLLChar ($self->{'Me'}, $params{'LLChar'});
   }
   if (defined $params{'LRChar'})
   {
      Cdk::Fselect::SetLRChar ($self->{'Me'}, $params{'LRChar'});
   }
   if (defined $params{'VChar'})
   {
      Cdk::Fselect::SetVerticalChar ($self->{'Me'}, $params{'VChar'});
   }
   if (defined $params{'HChar'})
   {
      Cdk::Fselect::SetHorizontalChar ($self->{'Me'}, $params{'HChar'});
   }
   if (defined $params{'BoxAttribute'})
   {
      Cdk::Fselect::SetBoxAttribute ($self->{'Me'}, $params{'BoxAttribute'});
   }
   if (defined $params{'BGColor'})
   {
      Cdk::Fselect::SetBackgroundColor ($self->{'Me'}, $params{'BGColor'});
   }
   if (defined $params{'Box'})
   {
      Cdk::Fselect::SetBox ($self->{'Me'}, $params{'Box'});
   }
}
#
# This function allows the user to get the current value from the widget.
#
sub get
{
   my $self	= shift;
   return (Cdk::Fselect::Get ($self->{'Me'}));
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
   Cdk::Fselect::Bind ($self->{'Me'}, $params{'Key'}, $params{'Function'});
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
   Cdk::Fselect::PreProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Fselect::PostProcess ($self->{'Me'}, $params{'Function'});
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
   Cdk::Fselect::Draw ($self->{'Me'}, $box);
}

#
# This erases the object.
#
sub erase
{
   my $self	= shift;
   Cdk::Fselect::Erase ($self->{'Me'});
}

#
# This cleans the info inside the entry object.
#
sub clean
{
   my $self	= shift;
   Cdk::Fselect::Clean ($self->{'Me'});
}

#
# This function raises the object.
#
sub raise
{
   my $self	= shift;
   Cdk::Fselect::Raise ($self->{'Me'});
}

#
# This function lowers the object.
#
sub lower
{
   my $self	= shift;
   Cdk::Fselect::Lower ($self->{'Me'});
}

#
# This function registers the object.
#
sub register
{
   my $self	= shift;
   Cdk::Fselect::Register ($self->{'Me'});
}

#
# This function unregisters the object.
#
sub unregister
{
   my $self	= shift;
   Cdk::Fselect::Unregister ($self->{'Me'});
}

#
# This function returns the pointer to the window.
#
sub getwin
{
   my $self	= shift;
   Cdk::Fselect::GetWindow ($self->{'Me'});
}

1;
